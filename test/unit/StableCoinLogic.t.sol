// SPDX License Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";

import {Config, ChainConfig} from "../../script/Config.s.sol";
import {DeployStableCoin} from "../../script/DeployStableCoin.s.sol";

import {StableCoin} from "../../src/StableCoin.sol";
import {StableCoinLogic} from "../../src/StableCoinLogic.sol";

contract StableCoinLogicTest is Test {
    DeployStableCoin deployer;
    StableCoin stableCoin;
    StableCoinLogic stableCoinLogic;
    Config config;
    ChainConfig chainConfig;

    address public testUser = makeAddr("testUser");

    function setUp() public {
        deployer = new DeployStableCoin();
        (stableCoin, stableCoinLogic, config) = deployer.run();
        chainConfig = config.getConfig();

        ERC20Mock(chainConfig.wethAddress).mint(testUser, 100e18);
        ERC20Mock(chainConfig.wbtcAddress).mint(testUser, 5e8);
    }

    // *** Setup *** //
    function testUserSetup() public {
        assertEq(
            100e18,
            ERC20Mock(chainConfig.wethAddress).balanceOf(testUser)
        );
        assertEq(5e8, ERC20Mock(chainConfig.wbtcAddress).balanceOf(testUser));
    }

    // *** Feeds *** //
    function testGetUsdValue() public {
        uint256 ethAmount = 10e18;
        uint256 expectedUsdValue = 10e18 * 1900;
        uint256 actualUsdValue = stableCoinLogic.getUsdValue(
            chainConfig.wethAddress,
            ethAmount
        );
        assertEq(expectedUsdValue, actualUsdValue);
    }

    // *** Deposit *** //
    function testRevertZeroDeposit() public {
        vm.startPrank(testUser);
        vm.expectRevert(StableCoinLogic.StableCoinLogic_ZeroAmount.selector);
        stableCoinLogic.depositCollateral(chainConfig.wethAddress, 0);
    }
}
