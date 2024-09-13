//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DeFi} from "../src/DeFi.sol";
import {Factory} from "../src/Factory.sol";
import {Pool} from "../src/Pool.sol";
import {Token} from "../src/Token.sol";

contract DeFiTest is Test {
    Factory factory;
    DeFi deFi;
    Token token1;
    Token token2;
    Pool pool1;
    Pool pool2;
    address constant USER = address(1);
    address constant USER2 = address(2);
    uint constant DEPOSIT_AMOUNT = 15 * 10 ** 18;
    uint constant BORROW_AMOUNT = 5 * 10 ** 18;
    uint constant COLLATERAL_AMOUNT = 7.5 * 10 ** 18;
    uint constant SECONDS_IN_A_DAY = 86400;
    function setUp() external {
        vm.prank(USER);
        token1 = new Token("VueJS", "VUE");
        vm.prank(USER2);
        token2 = new Token("ReactJS", "REACT");
        factory = new Factory();
        factory.createPool(address(token1));
        factory.createPool(address(token2));
        pool1 = factory.getTokenPool(address(token1));
        pool2 = factory.getTokenPool(address(token2));
        deFi = new DeFi(factory);
    }

    function testDeposit() public {
        vm.startPrank(USER);
        token1.approve(address(pool1), DEPOSIT_AMOUNT);
        deFi.deposit(address(token1), DEPOSIT_AMOUNT);
        vm.stopPrank();
        vm.startPrank(USER2);
        token2.approve(address(deFi), COLLATERAL_AMOUNT);
        uint cAmount = deFi.borrow(address(token1), BORROW_AMOUNT, address(token2));
        console.log("balance",cAmount);
        vm.stopPrank();
        vm.startPrank(USER);
        token1.transfer(USER2, BORROW_AMOUNT);
        vm.warp(block.timestamp + SECONDS_IN_A_DAY * 365);
        vm.startPrank(USER2);
        token1.approve(address(pool1), BORROW_AMOUNT * 2);
        deFi.repay(address(token1), 0);
        vm.stopPrank();
    }
}
