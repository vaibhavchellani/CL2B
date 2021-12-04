// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.4;

import { FxBaseChildTunnel } from "./tunnel/FxBaseChildTunnel.sol";
import { ERC20Gateway } from "../../ERC20Gateway.sol";

contract L2PolygonConnector is FxBaseChildTunnel {
    address public polgyonERC20Gateway;

    constructor(address _fxChild, address _polygonERC20Gateway) FxBaseChildTunnel(_fxChild) {}

    // TODO setup auth
    function setRoot(address _rootTunnel) external {
        setFxRootTunnel(_rootTunnel);
    }

    function _processMessageFromRoot(
        uint256, /*stateId*/
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        bytes32 root = abi.decode(data, (bytes32));
        ERC20Gateway(polgyonERC20Gateway).recieve(root);
    }

    function sendMessageToRoot(bytes memory message) public {
        _sendMessageToRoot(message);
    }
}
