// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/optimism/IL2ERC20Bridge.sol";
import "./interfaces/polygon/IChildToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MerkleTree.sol";
import "./interfaces/Types.sol";
import "./L1Router.sol";

contract ERC20Gateway is Types {
    using SafeERC20 for IERC20;

    uint256 public immutable SOURCE_CHAIN_ID;
    uint256 public immutable DESTINATION_CHAIN_ID;

    mapping(uint256 => address) public canonicalTokenPerChainID;

    MerkleTree public merkleTree;

    address public l1Router;

    uint256 public amountOutboundEnqueued = 0;
    uint256 public amountAwaitingClaim = 0;

    mapping(bytes32 => address) public transferHashToOwner;
    mapping(bytes32 => bool) public validatedRoots;

    uint256 public nextTransferID;

    //
    // Optimism related vars
    //
    address public L2ERC20Bridge;

    //
    // EVENTS
    //
    event TransferInitiated(uint256 transferID, uint256 amount);
    event TransferBought(uint256 transferID, address buyer);

    constructor(
        address _sendingToken,
        address _destinationToken,
        uint256 _destinationChainID,
        address _l1Router,
        address _l2ERC20Bridge
    ) {
        uint256 sourceChainID;
        assembly {
            sourceChainID := chainid()
        }

        SOURCE_CHAIN_ID = sourceChainID;
        DESTINATION_CHAIN_ID = _destinationChainID;

        canonicalTokenPerChainID[sourceChainID] = _sendingToken;
        canonicalTokenPerChainID[_destinationChainID] = _destinationToken;

        merkleTree = new MerkleTree();
        l1Router = _l1Router;
        L2ERC20Bridge = _l2ERC20Bridge;
        nextTransferID = 0;
    }

    // on the source side the user enters from here
    // lets assume its only ERC20s for now
    function send(
        address _from,
        uint256 _amount,
        address _receivingAddress
    ) external {
        // transfer the token custody from user to this contract
        IERC20(canonicalTokenPerChainID[SOURCE_CHAIN_ID]).safeTransferFrom(_from, address(this), _amount);

        uint256 currentTransferID = nextTransferID;

        // enqueueOutput
        merkleTree.enqueueOutbound(
            OutboundRequest(_from, _receivingAddress, DESTINATION_CHAIN_ID, _amount, currentTransferID)
        );

        // increment transfer ID
        nextTransferID++;

        amountOutboundEnqueued = amountOutboundEnqueued + _amount;

        // TODO edit the event to emit relavent data
        emit TransferInitiated(currentTransferID, _amount);
    }

    // need to push to destination via L1
    function pushToDestination() external {
        // TODO normal token withdraw on optimism
        // The _to address should be our router contract on L1
        // TODO make this generic and use connectors to enable this
        if (SOURCE_CHAIN_ID == 250) {
            IL2ERC20Bridge(L2ERC20Bridge).withdrawTo(
                canonicalTokenPerChainID[SOURCE_CHAIN_ID],
                l1Router,
                amountOutboundEnqueued,
                2000000,
                abi.encodePacked(merkleTree.get_root())
            );
        }

        if (SOURCE_CHAIN_ID == 137) {
            IChildToken(canonicalTokenPerChainID[SOURCE_CHAIN_ID]).withdraw(amountOutboundEnqueued);
        }
    }

    // TODO allow only L2 connector to update
    function recieve(bytes32 _root) external {
        // set state root
        validatedRoots[_root] = true;
    }

    function buy(OutboundRequest calldata _request) external {
        bytes32 transferHash = merkleTree.createTransferHash(_request);
        require(transferHashToOwner[transferHash] == address(0), "Already bought");

        // transfer the token custody from LP to user
        IERC20(canonicalTokenPerChainID[DESTINATION_CHAIN_ID]).safeTransferFrom(
            msg.sender,
            _request.receiver,
            _request.amount
        );

        // update owner
        transferHashToOwner[transferHash] = msg.sender;

        emit TransferBought(_request.transferID, msg.sender);
    }

    // withdraw money as LP
    function withdraw(
        bytes32 _root,
        OutboundRequest calldata _request,
        uint256 path,
        bytes32[] memory witness
    ) external {
        require(validatedRoots[_root], "Invalid root");
        bytes32 transferHash = merkleTree.createTransferHash(_request);
        require(merkleTree.verify(_root, transferHash, path, witness), "Invalid Proof");
        IERC20(canonicalTokenPerChainID[DESTINATION_CHAIN_ID]).safeTransfer(
            transferHashToOwner[transferHash],
            _request.amount
        );
    }
}
