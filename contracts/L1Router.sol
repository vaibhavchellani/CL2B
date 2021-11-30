// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.4;

import "./interfaces/Types.sol";
import "./interfaces/optimism/IL1ERC20Bridge.sol";

contract L1Router {
    // TODO add event that shows changes to this map
    mapping(uint256 => address) public gatewayByChainID;

    mapping(uint256 => address) public tokenByChainID;

    address public L1Token;
    address public L1ERC20TokenBridge;

    constructor(address _l1Token, address _L1ERC20OptimismBridge) {
        L1Token = _l1Token;
        L1ERC20TokenBridge = _L1ERC20OptimismBridge;
    }

    // TODO add auth for who can modify it
    function addNewGateway(uint256 _chainID, address _gateway) external {
        require(gatewayByChainID[_chainID] == address(0));
        gatewayByChainID[_chainID] = _gateway;
    }

    // TODO add auth for who can modify it
    function addNewToken(uint256 _chainID, address _token) external {
        require(tokenByChainID[_chainID] == address(0));
        tokenByChainID[_chainID] = _token;
    }

    // claims tokens from sending chain
    // pushes the tokens and sending chain state root or L1 blockhash
    // downstream
    function claimAndPushToDestination(
        uint256 _amount,
        bytes calldata _data,
        uint256 _sendingChainID
    ) external {
        IL1ERC20Bridge(L1ERC20TokenBridge).finalizeERC20Withdrawal(
            L1Token,
            tokenByChainID[_sendingChainID],
            gatewayByChainID[_sendingChainID],
            address(this),
            _amount,
            _data
        );
    }

    function checkIfFinalised() external {}
}
