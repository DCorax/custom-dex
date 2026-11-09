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

    error NotFactory();
    error AlreadyInitialized();
    error ZeroAddress();

    constructor() {
        factory = msg.sender;
    }

    ///@notice Links the pool to two tokens and deploys its LP token. Factory only, once.
    function initialize(address token0_, address token1_) external {
        if (msg.sender != factory) revert NotFactory();
        if (address(lpToken) != address(0)) revert AlreadyInitialized();
        if (token0_ == address(0) || token1_ == address(0)) revert ZeroAddress();
        token0 = token0_;
        token1 = token1_;
        lpToken = new CustomLPToken("CustomLPToken", "CLPT");
    }

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
}
