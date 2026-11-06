//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CustomPool} from "../contracts/CustomPool.sol";

contract CustomPoolTest is Test {
    CustomPool pool;
    address tokenA = makeAddr("tokenA");
    address tokenB = makeAddr("tokenB");
    address alice = makeAddr("alice");

    function setUp() public {
        pool = new CustomPool();
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
}
