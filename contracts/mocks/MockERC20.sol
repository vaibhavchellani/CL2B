// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockERC20 {
    constructor() {
        new ERC20("", "");
    }
}
