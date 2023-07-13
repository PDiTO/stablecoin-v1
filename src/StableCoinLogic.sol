// SPDX License Identifier: MIT

pragma solidity ^0.8.19;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {StableCoin} from "./StableCoin.sol";

/// @title StableCoinLogic
/// @author pdito
/// @notice A simplified logic engine for a USD pegged algorithmic stablecoin, with ETC and BTC as collateral
///
/// @notice This is a work in progress and should not be used in production

contract StableCoinLogic is ReentrancyGuard {
    // *** Errors *** //
    error StableCoinLogic_Init_CollateralAndPriceFeedLengthMismatch();
    error StableCoinLogic_ZeroAmount();
    error StableCoinLogic_UnacceptableCollateral();
    error StableCoinLogic_CollateralTransferInFailed();
    error StableCoinLogic_BreachedHealthFactor();
    error StableCoinLogic_MintFailed();

    // *** State *** //
    uint256 private constant COLLATERAL_RATIO = 150;

    address private immutable stableCoinAddress;
    address[] private collateralAddresses;
    mapping(address collateral => address priceFeed)
        private collateralPriceFeeds;

    mapping(address user => mapping(address collateral => uint256 amount))
        private collateralBalances;
    mapping(address user => uint256 stableCoinMinted) private stableCoinMinted;

    // *** Events *** //
    event DepositedCollateral(
        address indexed user,
        address indexed collateral,
        uint256 amount
    );

    // *** Modifiers *** //
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
            collateralAddresses.push(_collateralAddresses[i]);
            collateralPriceFeeds[_collateralAddresses[i]] = _priceFeedAddresses[
                i
            ];
        }
    }

    function depositCollateral(
        address _collateralAddress,
        uint256 _collateralAmount
    )
        public
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

    function depositCollateralAndMint(
        address _collateralAddress,
        uint256 _collateralAmount,
        uint256 _stableCoinAmount
    ) external {
        depositCollateral(_collateralAddress, _collateralAmount);
        mint(_stableCoinAmount);
    }

    function redeemCollateral() external {}

    function redeemCollateralAndBurn() external {}

    function mint(uint256 _amount) public nonZero(_amount) nonReentrant {
        stableCoinMinted[msg.sender] += _amount;
        _revertIfHealthBreach(msg.sender);
        bool success = StableCoin(stableCoinAddress).mint(msg.sender, _amount);
        if (!success) {
            revert StableCoinLogic_MintFailed();
        }
    }

    function burn() external {}

    function liquidate() external {}

    /// *** Internal Functions *** //
    function _usdValue(
        address _collateralAddress,
        uint256 _amount
    ) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            collateralPriceFeeds[_collateralAddress]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return ((uint256(price) * 1e10) * _amount) / 1e18;
    }

    function _collateralValue(
        address _user
    ) internal view returns (uint256 collateralValue) {
        for (uint256 i = 0; i < collateralAddresses.length; i++) {
            address collateralAddress = collateralAddresses[i];
            uint256 collateralAmount = collateralBalances[_user][
                collateralAddress
            ];
            collateralValue += _usdValue(collateralAddress, collateralAmount);
        }
    }

    function _health(address _user) internal view returns (uint256) {
        uint256 stableCoinValue = stableCoinMinted[_user];
        uint256 collateralValue = _collateralValue(_user);
        uint256 collateralValueAdjusted = (collateralValue * 100) /
            COLLATERAL_RATIO;
        return (collateralValueAdjusted * 1e18) / stableCoinValue;
    }

    function _revertIfHealthBreach(address _user) internal view {
        uint256 healthFactor = _health(_user);
        if (healthFactor < 1e18) {
            revert StableCoinLogic_BreachedHealthFactor();
        }
    }

    // *** Getters *** /
    function getUsdValue(
        address _collateralAddress,
        uint256 _amount
    ) external view returns (uint256) {
        return _usdValue(_collateralAddress, _amount);
    }

    function getHealth(address _user) external view returns (uint256) {
        return _health(_user);
    }

    function getCollateralValue(address _user) external view returns (uint256) {
        return _collateralValue(_user);
    }
}
