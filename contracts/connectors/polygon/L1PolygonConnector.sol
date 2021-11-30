// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.4;

import { FxBaseRootTunnel } from "./FxBaseRootTunnel.sol";

contract L1PolygonConnector is FxBaseRootTunnel {
    constructor(address _checkpointManager, address _fxRoot) FxBaseRootTunnel(_checkpointManager, _fxRoot) {}

    function sendMessageToChild(bytes memory message) public {
        _sendMessageToChild(message);
    }

    function _processMessageFromChild(bytes memory data) internal override {}
}
