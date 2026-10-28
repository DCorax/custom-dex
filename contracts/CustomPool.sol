// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CustomLPToken} from "./CustomLPToken.sol";

contract CustomPool {
    address public factory;
    address public token0;
    address public token1;
    CustomLPToken public lpToken;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    constructor(){
        factory = msg.sender;
    }
}
