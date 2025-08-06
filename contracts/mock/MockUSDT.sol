// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './MockERC20.sol';

contract MockUSDT is MockERC20 {

    constructor() MockERC20("Teather USD", "USDT", 18) {
        _mint(0xa9315C1C008c022c4145E993eC9d1a3AF73D0A62, 1000_000 ether);
    }
}