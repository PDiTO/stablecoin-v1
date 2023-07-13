// SPDX License Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {StableCoinLogic} from "../src/StableCoinLogic.sol";
import {Config} from "./Config.s.sol";

contract DeployStableCoin is Script {
    address[] public collateralAddresses;
    address[] public collateralPriceFeeds;

    function run() external returns (StableCoin, StableCoinLogic, Config) {
        Config config = new Config();
        (
            address wethAddress,
            address wbtcAddress,
            address wethPriceFeed,
            address wbtcPriceFeed,
            uint256 deployerPrivateKey, // live

        ) = config.chainConfig();

        collateralAddresses = [wethAddress, wbtcAddress];
        collateralPriceFeeds = [wethPriceFeed, wbtcPriceFeed];

        vm.startBroadcast(deployerPrivateKey);
        StableCoin stableCoin = new StableCoin();
        StableCoinLogic stableCoinLogic = new StableCoinLogic(
            address(stableCoin),
            collateralAddresses,
            collateralPriceFeeds
        );

        stableCoin.transferOwnership(address(stableCoinLogic));
        vm.stopBroadcast();

        return (stableCoin, stableCoinLogic, config);
    }
}
