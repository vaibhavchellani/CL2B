// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.4;

interface Types {
    struct OutboundRequest {
        address from;
        address receiver;
        uint256 destinationChainID;
        uint256 amount;
    }
}
