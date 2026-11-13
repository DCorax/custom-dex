//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CustomPool} from "../contracts/CustomPool.sol";
import {MockToken} from "./mocks/MockToken.sol";

contract CustomPoolTest is Test {
    CustomPool pool;
    address tokenA;
    address tokenB;
    address alice = makeAddr("alice");

    function setUp() public {
        pool = new CustomPool();
        tokenA = address(new MockToken("Token A", "TKA"));
        tokenB = address(new MockToken("Token B", "TKB"));
    }

    function test_FactoryIsCreator() public view {
        assertEq(pool.factory(), address(this));
    }

    function test_Initialize_SetsTokens() public {
        pool.initialize(tokenA, tokenB);
        assertEq(pool.token0(), tokenA);
        assertEq(pool.token1(), tokenB);
    }

    function test_RevertWhen_NotFactory() public {
        vm.prank(alice);
        vm.expectRevert(CustomPool.NotFactory.selector);
        pool.initialize(tokenA, tokenB);
    }

    function test_RevertWhen_AlreadyInitialized() public {
        pool.initialize(tokenA, tokenB);
        vm.expectRevert(CustomPool.AlreadyInitialized.selector);
        pool.initialize(tokenA, tokenB);
    }

    function test_RevertWhen_ZeroAddress() public {
        vm.expectRevert(CustomPool.ZeroAddress.selector);
        pool.initialize(tokenA, address(0));
    }

    function test_Initialize_LinksLPToken() public {
        pool.initialize(tokenA, tokenB);
        assertEq(pool.lpToken().pool(), address(pool));
    }

    function test_GetReserves_ZeroAfterInitialize() public {
        pool.initialize(tokenA, tokenB);
        (uint112 r0, uint112 r1, uint32 ts) = pool.getReserves();
        assertEq(r0, 0);
        assertEq(r1, 0);
        assertEq(ts, 0);
    }

    function test_AddLiquidity_First() public {
        pool.initialize(tokenA, tokenB);

        MockToken(tokenA).mint(alice, 1_000_000);
        MockToken(tokenB).mint(alice, 4_000_000);

        vm.startPrank(alice);

        MockToken(tokenA).approve(address(pool), 1_000_000);
        MockToken(tokenB).approve(address(pool), 4_000_000);
        uint256 liquidity = pool.addLiquidity(1_000_000, 4_000_000, alice);

        vm.stopPrank();

        assertEq(liquidity, 1_999_000);
        assertEq(pool.lpToken().balanceOf(alice), 1_999_000);

        assertEq(pool.lpToken().balanceOf(address(0xdead)), 1000);

        (uint112 r0, uint112 r1,) = pool.getReserves();
        assertEq(r0, 1_000_000);
        assertEq(r1, 4_000_000);
    }
}
