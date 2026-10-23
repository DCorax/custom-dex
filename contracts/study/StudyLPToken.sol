// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StudyLPToken is ERC20 {
    error NotPool();

    address public immutable pool;

    modifier onlyPool() {
        if (msg.sender != pool) revert NotPool();
        _;
    }
    

    constructor(string memory name_,string memory symbol_) ERC20(name_, symbol_) {
    pool = msg.sender;
}

function mint(address to, uint256 amount) external onlyPool {
    _mint(to, amount);
}

function burn (address from, uint256 amount) external onlyPool {
 _burn(from, amount);
}


}

