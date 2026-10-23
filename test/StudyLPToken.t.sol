//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StudyLPToken} from "../contracts/study/StudyLPToken.sol";

contract StudyLPTokenTest is Test {
    StudyLPToken lp;
    address alice = makeAddr("alice");

    function setUp() public {
        lp = new StudyLPToken("Study LP", "SLP");
    }

    function test_PoolIsCreator() public view {
        assertEq(lp.pool(), address(this));
    }

    function test_PoolCanMintAndBurn() public {
        lp.mint(alice, 100);
        assertEq(lp.balanceOf(alice),100);

        lp.burn(alice,40);
        assertEq(lp.balanceOf(alice), 60);
        assertEq(lp.totalSupply(), 60);
    }

    function  test_RevertWhen_NotPoolMints() public {
        vm.prank(alice);
        vm.expectRevert(StudyLPToken.NotPool.selector);
        lp.mint(alice, 100);
    }

    function test_RevertWhen_NotPoolBurns() public {
        lp.mint(alice, 100);
        vm.prank(alice);
        vm.expectRevert(StudyLPToken.NotPool.selector);
        lp.burn(alice, 100);
    }
}