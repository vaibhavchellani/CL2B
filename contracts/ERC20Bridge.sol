// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/optimism/IL2ERC20Bridge.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MerkleTree.sol";
import "./interfaces/Types.sol";
import "./L1Router.sol";

contract ERC20Bridge is Types {
    using SafeERC20 for IERC20;

    address public immutable SENDING_TOKEN_ADDRESS;
    address public immutable DESTINATION_TOKEN_ADDRESS;
    uint256 public SOURCE_CHAIN_ID;
    uint256 public DESTINATION_CHAIN_ID;
    MerkleTree public merkleTree;
    address public l1Router;

    uint256 public amountOutboundEnqueued = 0;
    uint256 public amountAwaitingClaim = 0;

    mapping(bytes32 => address) public transferHashToOwner;

    uint256 public nextTransferID;

    //
    // Optimism related vars
    //
    address public L2ERC20Bridge;

    constructor(
        address _sendingToken,
        address _destinationToken,
        uint256 _destinationChainID,
        address _l1Router,
        address _mt,
        address _L2ERC20Bridge
    ) {
        SENDING_TOKEN_ADDRESS = _sendingToken;
        DESTINATION_TOKEN_ADDRESS = _destinationToken;
        uint256 sourceChainID;
        assembly {
            sourceChainID := chainid()
        }
        SOURCE_CHAIN_ID = sourceChainID;
        DESTINATION_CHAIN_ID = _destinationChainID;
        merkleTree = MerkleTree(_mt);
        l1Router = _l1Router;
        L2ERC20Bridge = _L2ERC20Bridge;
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
        IERC20(SENDING_TOKEN_ADDRESS).safeTransferFrom(_from, address(this), _amount);

        // enqueueOutput
        merkleTree.enqueueOutbound(
            OutboundRequest(_from, _receivingAddress, DESTINATION_CHAIN_ID, _amount, nextTransferID)
        );

        // increment transfer ID
        nextTransferID++;

        amountOutboundEnqueued = amountOutboundEnqueued + _amount;

        // TODO emit event that off-chain actors can act on
    }

    // need to push to destination via L1
    function pushToDestination() external {
        // TODO normal token withdraw on optimism
        // The _to address should be our router contract on L1
        IL2ERC20Bridge(L2ERC20Bridge).withdrawTo(
            SENDING_TOKEN_ADDRESS,
            l1Router,
            amountOutboundEnqueued,
            111111,
            abi.encodePacked(merkleTree.get_root())
        );
    }

    // what to do post state root is received here
    // TODO receives L1 blockhash + tokens
    function recieve() external pure {
        // TODO do state proof validation here
        // dependant on L2 implementation
        // can probably build one for EVM
        // can lookup the example in optimism's codebase
    }

    function buy(OutboundRequest calldata _request) external {
        bytes32 transferHash = merkleTree.createTransferHash(_request);
        require(transferHashToOwner[transferHash] == address(0), "Already bought");

        // transfer the token custody from LP to user
        IERC20(DESTINATION_TOKEN_ADDRESS).safeTransferFrom(msg.sender, _request.receiver, _request.amount);

        // update owner
        transferHashToOwner[transferHash] = msg.sender;

        // TODO emit event of completion
    }

    // withdraw money as LP
    function withdraw() external {
        // TODO need to prove that it exists in the state
        // 1. need to find L2 state root from L1 state root
        // 2. need to find app level merkle root from L2 state root
        // 3. update validatedRoots
        // 4. claim by LPer
    }
}
