// --------------------------------------------------------------------------------------
//                             ____             _  _ _
//                            / __ \  __      _(_)(_|_)
//                           / / _` | \ \ /\ / / || | |
//                          | | (_| |  \ V  V /| || | |
//                           \ \__,_|   \_/\_/ |_|/ |_|
//                            \____/            |__/
// --------------------------------------------------------------------------------------
// -----------------------    Closable ICO smart contract   -----------------------------
// -----------------------  Written by Valentin Peiro 2018  -------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------

pragma solidity ^0.4.24;

// --------------------------------------------------------------------------------------
// -----------------     O P E N Z E P P E L I N  -  L I B R A R Y    -------------------
// -----------------             https://openzeppelin.org             -------------------
// --------------------------------------------------------------------------------------

import "./zeppelin/Ownable.sol";
import "./zeppelin/Crowdsale.sol";

// --------------------------------------------------------------------------------------
// --------------------------       ClosableCrowdsale      ------------------------------
// --------------------------------------------------------------------------------------

contract ClosableCrowdsale is Ownable, Crowdsale
{
  bool public crowdsaleClosed = false;

  modifier is_open
  {
    require(crowdsaleClosed == false);
    _;
  }

  modifier is_closed
  {
    require(crowdsaleClosed == true);
    _;
  }

  function close_crowdsale() external onlyOwner is_open
  {
    crowdsaleClosed = true;
    on_close_crowdsale();
  }

  function on_close_crowdsale() internal onlyOwner is_closed
  {
    // To be extended
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    is_open
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}