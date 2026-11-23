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
    address bob = makeAddr("bob");

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

    function test_RevertWhen_InsufficientLiquidity() public {
        pool.initialize(tokenA, tokenB);
        MockToken(tokenA).mint(alice, 1000);
        MockToken(tokenB).mint(alice, 1000);

        vm.startPrank(alice);

        MockToken(tokenA).approve(address(pool), 1000);
        MockToken(tokenB).approve(address(pool), 1000);
        vm.expectRevert(CustomPool.InsufficientLiquidity.selector);
        pool.addLiquidity(1000, 1000, alice);

        vm.stopPrank();
    }

    function test_AddLiquidity_Second() public {
        pool.initialize(tokenA, tokenB);
        MockToken(tokenA).mint(alice, 1_000_000);
        MockToken(tokenB).mint(alice, 4_000_000);
        vm.startPrank(alice);
        MockToken(tokenA).approve(address(pool), 1_000_000);
        MockToken(tokenB).approve(address(pool), 4_000_000);
        pool.addLiquidity(1_000_000, 4_000_000, alice);
        vm.stopPrank();

        MockToken(tokenA).mint(bob, 100_000);
        MockToken(tokenB).mint(bob, 400_000);

        vm.startPrank(bob);
        MockToken(tokenA).approve(address(pool), 100_000);
        MockToken(tokenB).approve(address(pool), 400_000);
        uint256 liquidity = pool.addLiquidity(100_000, 400_000, bob);
        vm.stopPrank();

        assertEq(liquidity, 200_000);
        assertEq(pool.lpToken().balanceOf(bob), 200_000);
        assertEq(pool.lpToken().totalSupply(), 2_200_000);
        assertEq(pool.lpToken().balanceOf(address(0xdead)), 1000);

        (uint112 r0, uint112 r1,) = pool.getReserves();
        assertEq(r0, 1_100_000);
        assertEq(r1, 4_400_000);
    }

    function test_AddLiquidity_ExtraToken1StaysWithUser() public {
        pool.initialize(tokenA, tokenB);
        MockToken(tokenA).mint(alice, 1_000_000);
        MockToken(tokenB).mint(alice, 4_000_000);
        vm.startPrank(alice);
        MockToken(tokenA).approve(address(pool), 1_000_000);
        MockToken(tokenB).approve(address(pool), 4_000_000);
        pool.addLiquidity(1_000_000, 4_000_000, alice);
        vm.stopPrank();

        MockToken(tokenA).mint(bob, 100_000);
        MockToken(tokenB).mint(bob, 500_000);

        vm.startPrank(bob);
        MockToken(tokenA).approve(address(pool), 100_000);
        MockToken(tokenB).approve(address(pool), 500_000);
        uint256 liquidity = pool.addLiquidity(100_000, 500_000, bob);
        vm.stopPrank();
        assertEq(liquidity, 200_000);

        assertEq(pool.lpToken().balanceOf(bob), 200_000);
        assertEq(MockToken(tokenA).balanceOf(bob), 0);
        assertEq(MockToken(tokenB).balanceOf(bob), 100_000);

        (uint112 r0, uint112 r1,) = pool.getReserves();
        assertEq(r0, 1_100_000);
        assertEq(r1, 4_400_000);
    }

    function test_AddLiquidity_ExtraToken0StaysWithUser() public {
        pool.initialize(tokenA, tokenB);

        MockToken(tokenA).mint(alice, 1_000_000);
        MockToken(tokenB).mint(alice, 4_000_000);

        vm.startPrank(alice);
        MockToken(tokenA).approve(address(pool), 1_000_000);
        MockToken(tokenB).approve(address(pool), 4_000_000);
        pool.addLiquidity(1_000_000, 4_000_000, alice);
        vm.stopPrank();

        MockToken(tokenA).mint(bob, 300_000);
        MockToken(tokenB).mint(bob, 400_000);

        vm.startPrank(bob);
        MockToken(tokenA).approve(address(pool), 300_000);
        MockToken(tokenB).approve(address(pool), 400_000);
        uint256 liquidity = pool.addLiquidity(300_000, 400_000, bob);
        vm.stopPrank();
        assertEq(liquidity, 200_000);

        assertEq(pool.lpToken().balanceOf(bob), 200_000);
        assertEq(MockToken(tokenA).balanceOf(bob), 200_000);
        assertEq(MockToken(tokenB).balanceOf(bob), 0);

        (uint112 r0, uint112 r1,) = pool.getReserves();
        assertEq(r0, 1_100_000);
        assertEq(r1, 4_400_000);
    }

    function testFuzz_AddLiquidity_KeepsRecipe(uint256 amount0, uint256 amount1) public {
        amount0 = bound(amount0, 1, 1_000_000_000_000);
        amount1 = bound(amount1, 4, 1_000_000_000_000);

        pool.initialize(tokenA, tokenB);
        MockToken(tokenA).mint(alice, 1_000_000);
        MockToken(tokenB).mint(alice, 4_000_000);

        vm.startPrank(alice);
        MockToken(tokenA).approve(address(pool), 1_000_000);
        MockToken(tokenB).approve(address(pool), 4_000_000);
        pool.addLiquidity(1_000_000, 4_000_000, alice);
        vm.stopPrank();

        MockToken(tokenA).mint(bob, amount0);
        MockToken(tokenB).mint(bob, amount1);

        vm.startPrank(bob);
        MockToken(tokenA).approve(address(pool), amount0);
        MockToken(tokenB).approve(address(pool), amount1);
        pool.addLiquidity(amount0, amount1, bob);
        vm.stopPrank();

        uint256 taken0 = amount0 - MockToken(tokenA).balanceOf(bob);
        uint256 taken1 = amount1 - MockToken(tokenB).balanceOf(bob);
        assertTrue(taken0 == amount0 || taken1 == amount1);

        (uint112 r0, uint112 r1,) = pool.getReserves();
        assertApproxEqAbs(uint256(r1), uint256(r0) * 4, 3);
    }
}
