// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pool {
    IERC20 public token;
    uint private total;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(address user, uint256 amount, bool repay) external {
        require(token.balanceOf(user) >= amount, "Insufficient balance");
        require(
            token.allowance(user, address(this)) >= amount,
            "Not enough spending allowance"
        );
        if (!repay) {
            total += amount;
        }
        token.transferFrom(user, address(this), amount);
    }

    function withdraw(address user, uint256 amount, bool loan) external {
        if (!loan) {
            total -= amount;
        }
        token.transfer(user, amount);
    }

    function totalFund() public view returns (uint) {
        return total;
    }

    function currentLiquidity() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function utilizedFund() public view returns (uint) {
        return totalFund() - currentLiquidity();
    }

    function fetchToken() public view returns (address) {
        return address(token);
    }
}
