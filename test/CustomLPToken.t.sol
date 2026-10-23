//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CustomLPToken} from "../contracts/CustomLPToken.sol";

contract CustomLPTokenTest is Test {
    CustomLPToken lp;
    address alice = makeAddr("alice");

    function setUp() public {
        lp = new CustomLPToken("CustomToken","CLPT");
    }

    function test_Creator() public {
        assertEq(lp.pool(),address(this));
    }

    function test_Viev_Process() public {
        lp.mint(alice, 100);
        assertEq(lp.balanceOf(alice), 100);

        lp.burn(alice, 60);
        assertEq(lp.balanceOf(alice), 40);
        assertEq(lp.totalSupply(), 40);

    }

    function test_MintNootPool() public{
        vm.prank(alice);
        vm.expectRevert(CustomLPToken.NotPool.selector);
        lp.mint(alice,100);
    }

    function test_MintNootPoolBurn() public{
        lp.mint(alice,100);
        vm.prank(alice);
        vm.expectRevert(CustomLPToken.NotPool.selector);
        lp.burn(alice,100);

    }

}

