// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.4;

import "./interfaces/Types.sol";
import "./interfaces/optimism/IL1ERC20Bridge.sol";
import { IRootChainManager } from "./interfaces/polygon/IRootchainManager.sol";
import "./connectors/polygon/L1PolygonConnector.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract L1Router {
    using SafeERC20 for IERC20;

    // TODO add event that shows changes to this map
    mapping(uint256 => address) public gatewayByChainID;

    // TODO add event that shows changes to this map
    mapping(uint256 => address) public tokenByChainID;

    address public L1Token;
    address public L1ERC20TokenBridge;

    // polgon vars
    L1PolygonConnector public polygonConnector;
    address public l1Erc20Predicate;
    IRootChainManager public rootchainManager;

    constructor(
        address _l1Token,
        address _L1ERC20OptimismBridge,
        address _polygonL1RootConnector,
        address _rootchainManager
    ) {
        L1Token = _l1Token;
        L1ERC20TokenBridge = _L1ERC20OptimismBridge;

        polygonConnector = L1PolygonConnector(_polygonL1RootConnector);
        rootchainManager = IRootChainManager(_rootchainManager);
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
        uint256 _sendingChainID,
        uint256 _destinationChainID
    ) external {
        IL1ERC20Bridge(L1ERC20TokenBridge).finalizeERC20Withdrawal(
            L1Token,
            tokenByChainID[_sendingChainID],
            gatewayByChainID[_sendingChainID],
            address(this),
            _amount,
            _data
        );

        if (_destinationChainID == 137) {
            IERC20(L1Token).allowance(address(this), l1Erc20Predicate);
            rootchainManager.depositFor(gatewayByChainID[_destinationChainID], L1Token, abi.encodePacked(_amount));

            // set the app level MR via state sync
            polygonConnector.sendMessageToChild(_data);
        }
    }

    function checkIfFinalised() external {}
}
