pragma solidity ^0.4.24;

// Note : this import must be wiji's version
import "./zeppelin/TimedCrowdsale.sol";
import "./zeppelin/Ownable.sol";


/**
 * @title StagedPriceCrowdsale
 * @dev Extension of Crowdsale contract that increases the price of tokens according to stages.
 * Note that what should be provided to the constructor is the initial and final _rates_, that is,
 * the amount of tokens per wei contributed. Thus, the initial rate must be greater than the final rate.
 */
contract StagedPriceCrowdsale is Ownable, TimedCrowdsale
{
  struct StagedPrice {
    uint256 date;
    uint256 rate;
    uint256 reserve;
    bool reserve_in_wei;
  }

  StagedPrice[] public stages;

  /**
   * @dev Constructor, takes initial stages and rates of tokens received per wei contributed.
   * @param _dates The stages dates
   * @param _rates The stage rates
   * param _stages The stages dates and rates. Note that the date is the starting point
   */
  constructor(uint256[4] _dates, uint256[4] _rates, uint256[4] _reserves, bool[4] _in_weis)
    TimedCrowdsale(_dates[0], _dates[_dates.length - 1])
  // Can't wait for ABIEncoderV2
  //constructor(StagedPrice[] _stages)
  //  TimedCrowdsale(_stages[0].date, _stages[_stages.length - 1].date)
    public
  {
    require(_dates.length == _rates.length);
    require(_dates.length == _reserves.length);
    require(_dates.length == _in_weis.length);
    for(uint256 j = 0; j < _dates.length; ++j)
      stages.push(StagedPrice(_dates[j], _rates[j], _reserves[j], _in_weis[j]));

    // Remove the above and uncomment this when ABIEncoderV2 is ready to ship to live
    // stages = _stages;

    uint256 last = stages.length - 1;
    for(uint256 i = 1; i < last; ++i)
    {
      require(stages[i].date > stages[i - 1].date);
      require(stages[i].rate > 0);
    }
    require(stages[last].date > stages[last - 1].date);

    require(stages[0].rate > 0);
    // The last stage represents the sale closing
    require(stages[last].rate == 0);
  }

  /*
   * @dev Update the closingTime variable from TimedCrowdsale
   */
  modifier updateClosingTime
  {
    _;
    closingTime = stages[stages.length - 1].date;
  }

  /**
   * @dev Returns the number of stages
   * @return The number of stages
   */
  function getNumberOfStages() public view returns (uint256)
  {
    return stages.length;
  }

  /**
   * @dev Returns the rate of tokens per wei at the present time.
   * @return The number of tokens a buyer gets per wei at a given time
   */
  function getCurrentRate() public view returns (uint256)
  {
    for(uint256 i = stages.length - 1; i >= 0; --i)
    // solium-disable-next-line security/no-block-members
      if(stages[i].date <= block.timestamp)
        return stages[i].rate;

    return 0;
  }

  /**
   * @dev Returns the current stage
   * @return The current stage
   */
  function getCurrentStage()
    public view onlyWhileOpen
    returns (uint256)
  {
    for(uint256 i = stages.length - 1; i >= 0; --i)
    // solium-disable-next-line security/no-block-members
      if(stages[i].date <= block.timestamp)
        return i;
  }

  /**
   * @dev Overrides parent method taking into account variable rate.
   * @param _weiAmount The value in wei to be converted into tokens
   * @return The number of tokens _weiAmount wei will buy at present time
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256 token_amount)
  {
    uint256             c_stage_ix = getCurrentStage();
    StagedPrice storage c_stage = stages[c_stage_ix];
    require(c_stage.rate > 0);
    
    token_amount = c_stage.rate.mul(_weiAmount);

    // If there is a reserve, use it
    if(c_stage.reserve > 0)
    {
      uint256 remaining_reserve_wei = 0;
      uint256 c_tokens = 0;
     
      // The reserve is in tokens
      if(c_stage.reserve_in_wei == false)
      {
        if(c_stage.reserve > token_amount)
        {
          c_stage.reserve -= token_amount;
          return token_amount;
        }
        else
        {
          remaining_reserve_wei = c_stage.reserve.div(c_stage.rate);
          c_tokens = c_stage.reserve;
        }
      }
      else // The reserve is in wei
      {
        if(c_stage.reserve > _weiAmount)
        {
          c_stage.reserve -= _weiAmount;
          return token_amount;
        }
        else
        {
          remaining_reserve_wei = c_stage.reserve;
          c_tokens = c_stage.rate.mul(remaining_reserve_wei);
        }
      }

      // Close the current stage since its reserve has been depleted
      // This is equivalent to making the next stage start now
      require(c_stage_ix < stages.length - 1);
      // solium-disable-next-line security/no-block-members
      stages[c_stage_ix + 1].date = block.timestamp;

      // The remaining wei will use the next stage's rates
      token_amount =  c_tokens +
                      _getTokenAmount(_weiAmount - remaining_reserve_wei);
    }

    return token_amount;
  }

}