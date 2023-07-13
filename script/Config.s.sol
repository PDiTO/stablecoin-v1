// SPDX License Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

struct ChainConfig {
    address wethAddress;
    address wbtcAddress;
    address wethPriceFeed;
    address wbtcPriceFeed;
    uint256 deployerPrivateKey;
    bool live;
}

contract Config is Script {
    ChainConfig public chainConfig;

    constructor() {
        if (block.chainid == 11155111) {
            chainConfig = getSepoliaConfig();
        } else {
            chainConfig = getLocalConfig();
        }
    }

    function getSepoliaConfig() public view returns (ChainConfig memory) {
        return
            ChainConfig({
                wethAddress: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
                wbtcAddress: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
                wethPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
                wbtcPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
                deployerPrivateKey: vm.envUint("PRIVATE_KEY"),
                live: true
            });
    }

    function getLocalConfig() public returns (ChainConfig memory) {
        if (chainConfig.live) {
            return chainConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator wethPriceFeedMock = new MockV3Aggregator(8, 1900e8);
        MockV3Aggregator wbtcPriceFeedMock = new MockV3Aggregator(8, 30000e8);
        ERC20Mock wethMock = new ERC20Mock();
        ERC20Mock wbtcMock = new ERC20Mock();
        wethMock.mint(msg.sender, 100e18);
        wbtcMock.mint(msg.sender, 100e8);
        vm.stopBroadcast();

        chainConfig = ChainConfig({
            wethAddress: address(wethMock),
            wbtcAddress: address(wbtcMock),
            wethPriceFeed: address(wethPriceFeedMock),
            wbtcPriceFeed: address(wbtcPriceFeedMock),
            deployerPrivateKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80,
            live: true
        });

        return chainConfig;
    }

    function getConfig() public view returns (ChainConfig memory) {
        return chainConfig;
    }
}
