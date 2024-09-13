//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pool} from "./Pool.sol";
import {Factory} from "./Factory.sol";
import {console} from "forge-std/console.sol";

contract DeFi {
    Factory factory;
    uint constant COLLATERAL = 50;
    uint constant BASE_INTEREST = 2;
    uint constant SECONDS_IN_A_DAY = 86400;
    uint constant DEPOSIT_INTEREST = 5;
    struct Loan {
        uint amount;
        uint interest;
        address cToken;
        bool paid;
        uint timestamp;
    }
    struct Deposit {
        uint amount;
        uint timestamp;
        bool withdrawn;
    }
    mapping(address => mapping(address => Deposit[])) public tokenDeposits;
    mapping(address => mapping(address => Loan[])) public tokenLoans;

    event Deposited(address indexed user, address indexed token, uint amount);
    event Borrowed(
        address indexed user,
        address indexed token,
        address indexed cToken,
        uint amount
    );
    event Withdrawn(
        address indexed user,
        address indexed token,
        uint depositIndex
    );
    event Repaid(address indexed user, address indexed token, uint borrowIndex);

    constructor(Factory _factory) {
        factory = _factory;
    }

    function deposit(address _token, uint _amount) public {
        Pool pool = factory.getTokenPool(_token);
        tokenDeposits[msg.sender][_token].push(
            Deposit({
                amount: _amount,
                timestamp: block.timestamp,
                withdrawn: false
            })
        );
        pool.deposit(msg.sender, _amount, false);
        emit Deposited(msg.sender, _token, _amount);
    }

    function withdraw(address _token, uint _depositIndex) public {
        Deposit storage deposit = tokenDeposits[msg.sender][_token][
            _depositIndex
        ];
        require(!deposit.withdrawn, "Already withdrawn");
        uint duration = (block.timestamp - deposit.timestamp) /
            SECONDS_IN_A_DAY;
        uint interest = (deposit.amount * duration * DEPOSIT_INTEREST) /
            (365 * 100);
        Pool pool = factory.getTokenPool(_token);
        tokenDeposits[msg.sender][_token][_depositIndex].withdrawn = true;
        pool.withdraw(msg.sender, deposit.amount + interest, false);
        emit Withdrawn(msg.sender, _token, _depositIndex);
    }

    function borrow(
        address _token,
        uint _amount,
        address _cToken
    ) public returns (uint) {
        IERC20 token = IERC20(_token);
        Pool pool = factory.getTokenPool(_token);
        require(
            token.balanceOf(address(pool)) >= _amount,
            "Insufficient Funds"
        );
        IERC20 cToken = IERC20(_cToken);
        uint cAmount = _amount + (_amount * COLLATERAL) / 100;
        require(
            cToken.balanceOf(msg.sender) >= cAmount,
            "Insufficient Balance in your account"
        );
        require(
            cToken.allowance(msg.sender, address(this)) >= cAmount,
            "Insufficient approved amount"
        );
        tokenLoans[msg.sender][_token].push(
            Loan({
                amount: _amount,
                cToken: _cToken,
                interest: currentInterest(_token),
                paid: false,
                timestamp: block.timestamp
            })
        );
        pool.withdraw(msg.sender, _amount, true);
        cToken.transferFrom(msg.sender, address(this), cAmount);
        emit Borrowed(msg.sender, _token, _cToken, _amount);
        return cAmount;
    }

    function repay(address _token, uint _borrowIndex) public {
        Loan storage loan = tokenLoans[msg.sender][_token][_borrowIndex];
        require(!loan.paid, "You've already paid the loan");
        uint duration = (block.timestamp - loan.timestamp) / SECONDS_IN_A_DAY;
        uint interest = (loan.amount * duration * loan.interest) / (365 * 100);
        uint total = loan.amount + interest;
        IERC20 token = IERC20(_token);
        Pool pool = factory.getTokenPool(_token);
        require(token.balanceOf(msg.sender) >= total, "Insufficient Funds");
        require(
            token.allowance(msg.sender, address(pool)) >= total,
            "Not enough amount"
        );
        pool.deposit(msg.sender, total, true);
        IERC20 cToken = IERC20(loan.cToken);
        cToken.transfer(
            msg.sender,
            loan.amount + (loan.amount * COLLATERAL) / 100
        );
        loan.paid = true;
        emit Repaid(msg.sender, _token, _borrowIndex);
    }

    function currentInterest(address _token) public view returns (uint) {
        Pool pool = factory.getTokenPool(_token);
        uint totalFunds = pool.totalFund();
        uint utilized = pool.utilizedFund();
        if (totalFunds == 0) {
            return BASE_INTEREST;
        }
        uint utilizedPercentage = (utilized * 100) / totalFunds;
        if (utilizedPercentage < 20) {
            return BASE_INTEREST + ((utilizedPercentage * 2) / 10);
        } else if (utilizedPercentage >= 20 && utilizedPercentage < 40) {
            return BASE_INTEREST + ((utilizedPercentage * 4) / 10);
        } else if (utilizedPercentage >= 40 && utilizedPercentage < 60) {
            return BASE_INTEREST + ((utilizedPercentage * 6) / 10);
        } else if (utilizedPercentage >= 60 && utilizedPercentage < 80) {
            return BASE_INTEREST + ((utilizedPercentage * 8) / 10);
        } else {
            return BASE_INTEREST + utilizedPercentage;
        }
    }

    function getUserLoans(
        address _user,
        address _token
    ) public view returns (Loan[] memory) {
        return tokenLoans[_user][_token];
    }

    function getUserDeposits(
        address _user,
        address _token
    ) public view returns (Deposit[] memory) {
        return tokenDeposits[_user][_token];
    }
}
