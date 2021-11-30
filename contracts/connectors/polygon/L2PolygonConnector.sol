// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.4;

import { FxBaseChildTunnel } from "./FxBaseChildTunnel.sol";

contract L2PolygonConnector is FxBaseChildTunnel {
    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

    // TODO setup auth
    function setRoot(address _rootTunnel) external {
        setFxRootTunnel(_rootTunnel);
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {}

    function sendMessageToRoot(bytes memory message) public {
        _sendMessageToRoot(message);
    }
}
