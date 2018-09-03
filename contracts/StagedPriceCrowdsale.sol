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
  }

  StagedPrice[] public stages;

  /**
   * @dev Constructor, takes initial stages and rates of tokens received per wei contributed.
   * @param _dates The stages dates
   * @param _rates The stage rates
   * param _stages The stages dates and rates. Note that the date is the starting point
   */
  constructor(uint256[2] _dates, uint256[2] _rates)
    TimedCrowdsale(_dates[0], _dates[_dates.length - 1])
  // Can't wait for ABIEncoderV2
  //constructor(StagedPrice[] _stages)
  //  TimedCrowdsale(_stages[0].date, _stages[_stages.length - 1].date)
    public
  {
    require(_dates.length == _rates.length);
    for(uint256 j = 0; j < _dates.length; ++j)
      stages.push(StagedPrice(_dates[j], _rates[j]));

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


  /**
   * @dev Add a stage to the crowdsale.
   * @param _date The date when the new stage starts
   * @param _rate The new stage rate
   * @return The index the new stage was inserted at
   */
  function addStagedRate(uint256 _date, uint256 _rate)
  // ABIEncoderV2 WHEN
  //function addStagedRate(StagedPrice _new_stage)
    public onlyOwner beforeOpen
    returns (uint256 _new_index)
  {
    StagedPrice memory _new_stage = StagedPrice(_date, _rate); // ABIEncoderV2

    require(_new_stage.date > stages[0].date);
    require(_new_stage.rate > 0);

    _new_index = stages.length;
    stages.length++;

    while(_new_stage.date < stages[_new_index - 1].date)
    {
      stages[_new_index] = stages[_new_index - 1];
      --_new_index;
    }

    stages[_new_index] = _new_stage;
  }

  /**
   * @dev Remove a stage from the crowdsale.
   * @param _index The stage index to remove
   * @return The new number of changes
   */
  function removeStagedRate(uint256 _index)
    public onlyOwner beforeOpen
    returns (uint256 _new_length)
  {
    require(_index > 0);
    require(_index < stages.length);

    _new_length = stages.length - 1;
    for(uint256 i = _index; i < _new_length; i++)
      //stages[i] = stages[++i]; This doesn't work in Solidity somehow
      stages[i] = stages[i + 1];

    --stages.length;
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
   * @dev Overrides parent method taking into account variable rate.
   * @param _weiAmount The value in wei to be converted into tokens
   * @return The number of tokens _weiAmount wei will buy at present time
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    uint256 currentRate = getCurrentRate();
    return currentRate.mul(_weiAmount);
  }

}