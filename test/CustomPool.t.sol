//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CustomPool} from "../contracts/CustomPool.sol";

contract CustomPoolTest is Test {
    CustomPool pool;


    function setUp() public {
        pool = new CustomPool();
    }

    function test_FactoryIsCreator() public view {
        assertEq(pool.factory(), address(this));
    }
}
