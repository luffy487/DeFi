//SPDX-License-Identifier:MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {DeFi} from "../src/DeFi.sol";
import {Factory} from "../src/Factory.sol";
import {Pool} from "../src/Pool.sol";
import {Token} from "../src/Token.sol";

contract DeployDeFi is Script {
    Factory factory;
    Token token1;
    Token token2;
    Token token3;
    Token token4;
    Pool pool1;
    Pool pool2;
    Pool pool3;
    Pool pool4;

    function run() public {
        vm.startBroadcast();
        token1 = new Token("Vue Js", "VUE");
        token2 = new Token("Node Js", "NODE");
        token3 = new Token("React Js", "REACT");
        token4 = new Token("Next Js", "NEXT");
        pool1 = new Pool(address(token1));
        pool2 = new Pool(address(token2));
        pool3 = new Pool(address(token3));
        pool4 = new Pool(address(token4));
        factory = new Factory();
        factory.createPool(address(token1), pool1);
        factory.createPool(address(token2), pool2);
        factory.createPool(address(token3), pool3);
        factory.createPool(address(token4), pool4);
        new DeFi(factory);
        vm.stopBroadcast();
    }
}
