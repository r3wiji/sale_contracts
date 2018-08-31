pragma solidity ^0.4.24;

import "./zeppelin/SafeMath.sol";
import "./zeppelin/Crowdsale.sol";
import "./zeppelin/Ownable.sol";
import "./zeppelin/IndividuallyCappedCrowdsale.sol";


/**
 * @title IC_Crowdsale_LUT
 * @dev Extend IndividuallyCappedCrowdsale to have a LUT
 */
contract IC_Crowdsale_LUT is Ownable, Crowdsale, IndividuallyCappedCrowdsale
{
  address[] private caps_LUT;

  /**
   * @dev Sets a specific user's maximum contribution.
   * @param _beneficiary Address to be capped
   * @param _cap Wei limit for individual contribution
   */
  function setUserCap(address _beneficiary, uint256 _cap)
    public onlyOwner
 {
    super.setUserCap(_beneficiary, _cap);

    if(getUserCap(_beneficiary) == 0)
        caps_LUT.push(_beneficiary);
  }

  /**
   * @dev Sets a group of users' maximum contribution.
   * @param _beneficiaries List of addresses to be capped
   * @param _cap Wei limit for individual contribution
   */
  function setGroupCap(
    address[] _beneficiaries,
    uint256 _cap
  )
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _beneficiaries.length; i++)
    {
      setUserCap(_beneficiaries[i], _cap);
    }
  }



  /**
   * @dev Sets a group of users' maximum contribution.
   * @param _beneficiaries List of addresses to be capped
   * @param _caps Wei limit for individual contribution
   */
  function setGroupCap(
    address[] _beneficiaries,
    uint256[] _caps
  )
    external
    onlyOwner
  {
    require (_beneficiaries.length == _caps.length);
    for (uint256 i = 0; i < _beneficiaries.length; i++)
    {
      setUserCap(_beneficiaries[i], _caps[i]);
    }
  }

  /**
   * @dev Returns the number of registered users.
   * @return Number of users
   */
  function getNumberOfUsers() public view onlyOwner returns (uint256)
  {
    return caps_LUT.length;
  }

  /**
   * @dev Returns the list of registered.
   * @return The list of users
   */
  function getUserList() public view onlyOwner returns (address[])
  {
    return caps_LUT;
  }

}