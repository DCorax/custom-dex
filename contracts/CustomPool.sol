// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CustomLPToken} from "./CustomLPToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract CustomPool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    address private constant DEAD = address(0xdead);

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
    error Overflow();
    error InsufficientLiquidity();

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

    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired, address to)
        external
        nonReentrant
        returns (uint256 liquidity)
    {
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0Desired);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1Desired);
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - uint256(reserve0);
        uint256 amount1 = balance1 - uint256(reserve1);
        uint256 root = Math.sqrt(amount0 * amount1);
        if (root <= MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
        liquidity = root - MINIMUM_LIQUIDITY;
        _update(balance0, balance1);
        lpToken.mint(DEAD, MINIMUM_LIQUIDITY);
        lpToken.mint(to, liquidity);
    }

    function _update(uint256 balance0, uint256 balance1) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) revert Overflow();
        // casting to 'uint112' is safe because both balances are checked above
        // forge-lint: disable-next-line(unsafe-typecast)
        reserve0 = uint112(balance0);
        // forge-lint: disable-next-line(unsafe-typecast)
        reserve1 = uint112(balance1);
        // casting to 'uint32' is safe because wrap in year 2106 is expected , as in Uniswap v2
        // forge-lint: disable-next-line(unsafe-typecast)
        blockTimestampLast = uint32(block.timestamp);
    }
}
