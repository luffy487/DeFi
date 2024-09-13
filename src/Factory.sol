// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Pool} from "./Pool.sol";

contract Factory {
    mapping(address => Pool) public pools;
    mapping(address => address) public tokenPools;
    address[] public tokenList;

    function createPool(address _token, Pool _pool) public returns (Pool) {
        require(
            address(pools[_token]) == address(0),
            "Pool already exists for this token"
        );
        pools[_token] = _pool;
        tokenList.push(_token);
        return pools[_token];
    }

    function getTokenPool(address _token) public view returns (Pool) {
        return pools[_token];
    }

    function getAllTokens() public view returns (address[] memory) {
        return tokenList;
    }

    function getTokenPoolAddress(address _token) public view returns (address) {
        return address(pools[_token]);
    }
}
