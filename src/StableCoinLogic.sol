// SPDX License Identifier: MIT

pragma solidity ^0.8.19;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {StableCoin} from "./StableCoin.sol";

/// @title StableCoinLogic
/// @author pdito
/// @notice A simplified logic engine for a USD pegged algorithmic stablecoin, with ETC and BTC as collateral
///
/// @notice This is a work in progress and should not be used in production

contract StableCoinLogic is ReentrancyGuard {
    // *** Errors ***
    error StableCoinLogic_Init_CollateralAndPriceFeedLengthMismatch();
    error StableCoinLogic_ZeroAmount();
    error StableCoinLogic_UnacceptableCollateral();
    error StableCoinLogic_CollateralTransferInFailed();

    // *** State ***
    uint256 private constant COLLATERAL_RATIO = 150;

    address private immutable stableCoinAddress;
    mapping(address collateral => address priceFeed)
        private collateralPriceFeeds;

    mapping(address user => mapping(address collateral => uint256 amount))
        private collateralBalances;

    // *** Events ***
    event DepositedCollateral(
        address indexed user,
        address indexed collateral,
        uint256 amount
    );

    // *** Modifiers ***
    modifier nonZero(uint256 _amount) {
        if (_amount == 0) {
            revert StableCoinLogic_ZeroAmount();
        }
        _;
    }

    modifier acceptableCollateral(address _collateralAddress) {
        if (collateralPriceFeeds[_collateralAddress] == address(0)) {
            revert StableCoinLogic_UnacceptableCollateral();
        }
        _;
    }

    constructor(
        address _stableCoinAddress,
        address[] memory _collateralAddresses,
        address[] memory _priceFeedAddresses
    ) {
        stableCoinAddress = _stableCoinAddress;

        if (_collateralAddresses.length != _priceFeedAddresses.length) {
            revert StableCoinLogic_Init_CollateralAndPriceFeedLengthMismatch();
        }

        for (uint256 i = 0; i < _collateralAddresses.length; i++) {
            collateralPriceFeeds[_collateralAddresses[i]] = _priceFeedAddresses[
                i
            ];
        }
    }

    function depositCollateral(
        address _collateralAddress,
        uint256 _collateralAmount
    )
        external
        nonZero(_collateralAmount)
        acceptableCollateral(_collateralAddress)
        nonReentrant
    {
        collateralBalances[msg.sender][_collateralAddress] += _collateralAmount;
        emit DepositedCollateral(
            msg.sender,
            _collateralAddress,
            _collateralAmount
        );
        bool success = IERC20(_collateralAddress).transferFrom(
            msg.sender,
            address(this),
            _collateralAmount
        );

        if (!success) {
            revert StableCoinLogic_CollateralTransferInFailed();
        }
    }

    function depositCollateralAndMint() external {}

    function redeemCollateral() external {}

    function redeemCollateralAndBurn() external {}

    function mint(uint256 _amount) external nonZero(_amount) nonReentrant {}

    function burn() external {}

    function liquidate() external {}

    function getCollateralRatio() external view {}
}
