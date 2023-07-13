// SPDX License Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title StableCoin
/// @author pdito
/// @notice A USD pegged algorithmic stablecoin, with ETC and BTC as collateral
/// @notice Liquidators keep 90% of the liquidation penalty, the remaining 10% is sent to protocol reserves
/// @notice This is a work in progress and should not be used in production

contract StableCoin is ERC20Burnable, Ownable {
    // *** Errors ***
    error StableCoin_CannotMintToZeroAddress();
    error StableCoin_CannotMintZeroAmount();
    error StableCoin_BurnExceedsBalance();

    constructor() ERC20("SC", "PDC") {}

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert StableCoin_CannotMintToZeroAddress();
        }

        if (_amount == 0) {
            revert StableCoin_CannotMintZeroAmount();
        }

        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) public override onlyOwner {
        // Confirm burn amount is less than or equal to balance
        uint256 balance = balanceOf(msg.sender);
        if (balance < _amount) {
            revert StableCoin_BurnExceedsBalance();
        }

        // Burn tokens
        super.burn(_amount);
    }
}
