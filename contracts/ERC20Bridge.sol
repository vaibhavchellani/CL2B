// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MerkleTree.sol";
import "./Types.sol";

contract ERC20Bridge is Types {
    using SafeERC20 for IERC20;

    address public immutable SENDING_TOKEN_ADDRESS;
    address public immutable DESTINATION_TOKEN_ADDRESS;
    uint256 public SOURCE_CHAIN_ID;
    uint256 public DESTINATION_CHAIN_ID;
    MerkleTree public merkleTree;

    constructor(
        address _sendingToken,
        address _destinationToken,
        uint256 _destinationChainID,
        address _mt
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
    }

    // on the source side the user enters from here
    // lets assume its only ERC20s for now
    function send(
        address _from,
        uint256 amount,
        address _receivingAddress
    ) external {
        // transfer the token custody from user to this contract
        IERC20(SENDING_TOKEN_ADDRESS).safeTransferFrom(_from, address(this), amount);

        // enqueueOutput
        merkleTree.enqueueOutbound(OutboundRequest(_from, _receivingAddress, DESTINATION_CHAIN_ID, amount));
    }

    function recieve() external pure {}
}
