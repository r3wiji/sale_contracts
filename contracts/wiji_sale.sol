// --------------------------------------------------------------------------------------
//                             ____             _  _ _
//                            / __ \  __      _(_)(_|_)
//                           / / _` | \ \ /\ / / || | |
//                          | | (_| |  \ V  V /| || | |
//                           \ \__,_|   \_/\_/ |_|/ |_|
//                            \____/            |__/
// --------------------------------------------------------------------------------------
// ------------------------   WIJI token smart contract   -------------------------------
// ------------------------  Written by Yann Suissa 2018  -------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------

pragma solidity ^0.4.24;

// --------------------------------------------------------------------------------------
// -----------------     O P E N Z E P P E L I N  -  L I B R A R Y    -------------------
// -----------------             https://openzeppelin.org             -------------------
// --------------------------------------------------------------------------------------

import "./zeppelin/SafeMath.sol";
import "./zeppelin/Ownable.sol";
import "./zeppelin/Crowdsale.sol";
import "./zeppelin/MintedCrowdsale.sol";
import "./zeppelin/IndividuallyCappedCrowdsale.sol";
import "./zeppelin/TimedCrowdsale.sol";

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
// --------------------------       W I J I   S A L E      ------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------

import "./wiji_token.sol";
import "./IC_Crowdsale_LUT.sol";
import "./ClosableCrowdsale.sol";

contract wiji_sale is Ownable,
  Crowdsale, MintedCrowdsale,
  IndividuallyCappedCrowdsale, IC_Crowdsale_LUT,
  TimedCrowdsale, ClosableCrowdsale
{
  using SafeMath for uint256;

  wiji_token public token_contract;

  // CONSTANTS ---------------------------------------------------------------
  // -------------------------------------------------------------------------

  uint256 public constant DECIMAL_FACTOR = 10**18;

  // Maximum tokens that could be allocated (2 billion) it's unreachable because of token burns
  uint256 public constant TOKEN_MAX_CIRCULATION     = 2000000000 * DECIMAL_FACTOR;

  // Tokens to be sold (900m)
  uint256 public constant TOKENS_SALE_HARD_CAP      = 1000000000 * DECIMAL_FACTOR;
  // Tokens soft cap (100m)
  uint256 public constant TOKENS_SALE_SOFT_CAP      =  100000000 * DECIMAL_FACTOR;

  // Tokens for community unlocked every quarter (480m)
  uint256 public constant TOKENS_COMMUNITY_MAX      =  480000000 * DECIMAL_FACTOR;
  // Tokens for community unlocked on demand (300m)
  uint256 public constant TOKENS_RESERVE_MAX        =  300000000 * DECIMAL_FACTOR;
  // Tokens for team (180m)
  uint256 public constant TOKENS_TEAM_MAX           =  180000000 * DECIMAL_FACTOR;
  // Tokens for team + bounties + advisors (40m)
  uint256 public constant TOKENS_ADVISORS_MAX       =   40000000 * DECIMAL_FACTOR;


  // ICO tokens for sale, the remaining tokens of each sale will be reported to the next
  // step 1 pre-sale     : 01 Jan 2019 00:00:00 GMT -
  //                       100m token to sell - bonus 30%
  uint256 constant ICO_TOKEN_SALE_MAX_1             =  100000000 * DECIMAL_FACTOR;
  //uint256 ICO_TOKEN_SALE_DATE_1     = 1546300800;

  // step 2 public sale  : 01 Feb 2019 00:00:00 GMT -
  //                       200m token to sell - bonus 10%
  uint256 constant ICO_TOKEN_SALE_MAX_2             =  200000000 * DECIMAL_FACTOR;
  uint256 constant ICO_TOKEN_SALE_DATE_2            = 1548979200;

  // step 3 public sale  : 01 Mar 2019 00:00:00 GMT -
  //                       700m token to sell - bonus  0%
  uint256 constant ICO_TOKEN_SALE_MAX_3             =  700000000 * DECIMAL_FACTOR;
  uint256 constant ICO_TOKEN_SALE_DATE_3            = 1551398400;

  // End of public sale  : 01 Apr 2019 00:00:00 GMT -
  //                        remaining token will be burned
  uint256 public constant ICO_TOKEN_SALE_START      = 1546300800;
  uint256 public constant ICO_TOKEN_SALE_END        = 1554076800;


  // PRIVATE class variables (c++ model) -------------------------------------
  // -------------------------------------------------------------------------

  // current community amount called
  uint256 community_amount_claimed                  = 0;
  // Last community quarter called
  uint256 last_community_quarter_called             = 0;

  // Issue event index starting from 0.
  //uint256 public issue_index                        = 0;



  // ADDRESSES ---------------------------------------------------------------
  // -------------------------------------------------------------------------

  // The addresses of special owners
  // GANACHE-CLI ======================================
  address public owner_address                      = 0x25bfcE0Ce3798b0Ec0cF44783e4E8f6EdC83F342;
  address public team_fund_address                  = 0x0c1F188c72F8D9046B9682061f2E870c3c322F9b;
  address public reserve_fund_address               = 0xa94d7728ffDC55e8Bc9F63eFcb532a0d7B57662D;
  address public community_fund_address             = 0x04DD2fbEfE9A186EE83A8EaDB6Bc5992aa495263;
  address public advisors_fund_address              = 0x89f240e09c4f820B74039E767e52C38Cb2A9cA0c;

  // RINKEBY =========================================
  //address public owner_address                      = 0x7937f3e3E2cc0199741A7Bf69361997b40d3f854;
  //address public team_fund_address                  = 0xfc510EcD7a0cc9ac113ecDCb4715c37746220D1E;
  //address public reserve_fund_address               = 0x1e1368785432Dc657a179b266c86Bc525fC46791;
  //address public community_fund_address             = 0x6dB25c448d65760626632A6969dc5cF4F5E49852;
  //address public advisors_fund_address              = ??????;


  bool public    team_claimed                      = false;
  bool public    reserve_claimed                    = false;
  bool public    advisors_claimed                   = false;
  // calculation of token numbers
  uint256 public team_fund_tokens                   = 0;
  uint256 public reserve_fund_tokens                = 0;
  uint256 public advisors_fund_tokens               = 0;
  uint256 public community_fund_tokens              = 0; // max possible

    // MODIFIERS ---------------------------------------------------------------
  // -------------------------------------------------------------------------

  // Require that the end of the sale has passed
  modifier after_token_sale
  {
    require(get_now() > ICO_TOKEN_SALE_END);
    _;
  }

    /**
   * CONSTRUCTOR
   *
   * @dev Initialize the WIJI ICO Sale
   */
  constructor(wiji_token _token_contract)
    Crowdsale(1, msg.sender, _token_contract)
    TimedCrowdsale(ICO_TOKEN_SALE_START, ICO_TOKEN_SALE_END)
    public
  {
    require(_token_contract != address(0));
    token_contract = _token_contract;
  }


  // OWNER FUNCTIONS  ---------------------------------------------------------------
  // --------------------------------------------------------------------------------

  /**
  * @dev Set special addresses
  */
  function set_admin_addresses(address owner_address_,
                               address team_fund_address_,
                               address reserve_fund_address_,
                               address community_fund_address_,
                               address advisors_fund_address_) public onlyOwner
  {
    owner_address                  = owner_address_;
    team_fund_address              = team_fund_address_;
    reserve_fund_address           = reserve_fund_address_;
    community_fund_address         = community_fund_address_;
    advisors_fund_address          = advisors_fund_address_;

    transferOwnership(owner_address);
  }


  // TOKEN ISSUING FUNCTIONS  -------------------------------------------------------
  // --------------------------------------------------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _wei Value in wei involved in the purchase
     */
  function _preValidatePurchase(address _beneficiary, uint256 _wei)
    internal onlyWhileOpen is_open
  {
    // Minimum amount to invest
    uint256 MINIMUM_TOKEN_BUY      = 0.05 ether;
    // Maximum amount to invest
    uint256 MAXIMUM_TOKEN_BUY      = 4000 ether;

    // only accept a minimum amount of ETH?
    require (msg.value >= MINIMUM_TOKEN_BUY &&
             msg.value <= MAXIMUM_TOKEN_BUY);

    // Add OpenZeppelin's checks
    super._preValidatePurchase(_beneficiary, _wei);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokens Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokens)
    internal onlyWhileOpen is_open
  {
  //check for hard cap
    require(token_contract.totalSupply().add(_tokens) <= TOKENS_SALE_HARD_CAP);

    // Let OpenZeppelin do the processing
    super._processPurchase(_beneficiary, _tokens);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal
  {
    // Do nothing, funds are only forwarded when the ICO ends
  }

  /**
  * @dev   issue tokens for a single buyer
  * @param _beneficiary addresses that the tokens will be sent to.
  * @param _tokens_amount the amount of tokens, with decimals expanded (full).
  */
  function generate_tokens(address _beneficiary, uint256 _tokens_amount)
    internal is_open
  {
    require (_beneficiary != address(0));
    require (_tokens_amount != 0);

    // roll back if the max cap is reached (should be impossible)
    require(token_contract.totalSupply().add(_tokens_amount) <= TOKEN_MAX_CIRCULATION);

    // increase token total supply
    token_contract.mint(_beneficiary, _tokens_amount);
  }

  // TOKEN SALE FUNCTIONS  ----------------------------------------------------------
  // --------------------------------------------------------------------------------


 /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param eth_amount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 eth_amount)
    internal view onlyWhileOpen returns (uint256 tokens)
  {
    uint64 _now = get_now();

    // Base exchange rate is set to 1 ETH = 21000 WIJI other rates with discount
    uint256 BASE_RATE_0               = 21000 * DEBUG_MULTIPLICATOR;
    uint256 BASE_RATE_10              = 23100 * DEBUG_MULTIPLICATOR;
    uint256 BASE_RATE_30              = 27300 * DEBUG_MULTIPLICATOR;

    uint256 supply = token_contract.totalSupply();

    // if date is above the pre sale end 1 or the max number is sold then we propose next step
    if      ((_now <= ICO_TOKEN_SALE_DATE_2) &&                              // <= Mon, 09 Jul 2018 12:42:42 GMT
             (supply < ICO_TOKEN_SALE_MAX_1))                          // total < 100m
      tokens = eth_amount.mul(BASE_RATE_30);
    else if ((_now <= ICO_TOKEN_SALE_DATE_3) &&                             // <= Mon, 16 Jul 2018 12:42:42 GMT
             (supply < ICO_TOKEN_SALE_MAX_1 + ICO_TOKEN_SALE_MAX_2))  // total < 100m + 200m
      tokens = eth_amount.mul(BASE_RATE_10);
    else                                                                    // <= Sun, 26 Aug 2018 12:42:42 GMT
      tokens = eth_amount.mul(BASE_RATE_0);
  }

  /**
  * @dev    calculate the current number of WIJI for 1 ether .
  * @return the current price.
  */
  function price() public view returns (uint256 tokens)
  {
    return _getTokenAmount(1 ether);
  }

  /**
  * @dev    transfer the raised ETH to the owner, if the soft cap is reached
  */
  function access_raised_funds() public onlyOwner
  {
    require (token_contract.totalSupply() >= TOKENS_SALE_SOFT_CAP);
    //owner_address.transfer(this.balance);
    owner_address.transfer(address(this).balance);
  }

  /**
  * @dev Finalize the sale and distribute the fund to all the parties
  *
  *   Now we calculate the numbers of tokens to be issued the base numbers are :
  *     SALE       50% : max TOKENS_SALE_HARD_CAP (1000m) - to be sold
  *     COMMUNITY  24% : max TOKENS_COMMUNITY_MAX ( 480m) - less than 1% unlocked every quarter
  *     RESERVE    15% : max TOKENS_RESERVE_MAX   ( 300m) - locked for 18 months asked on demand
  *     TEAM        9% : max TOKENS_TEAM_MAX      ( 220m) - locked for 1 year
  *     ADV+BOUNTY  2% : max TOKENS_ADVISORS_MAX  (   40m) - advisors + bounties unlocked
  *
  */
  function  on_close_crowdsale()
    internal onlyOwner is_closed
  {
    //if the soft_cap is not reached we can't close the ICO
    //if it's never reached then we can only launch the refund method
    require (token_contract.totalSupply() >= TOKENS_SALE_SOFT_CAP);

    // We calculate the ratio of what we have sold, max sold tokens are 1000m
    // we times it by 1000000 to use integers for calculation (everything is in wei)
    // ex : we have sold 150m (15%) tokens it's 150m * 1m / 1000m = 150000
    uint256 ratio_sold = token_contract.totalSupply().mul(1000000).div(TOKENS_SALE_HARD_CAP);


    // ISSUE TEAM + BOUNTY + ADVISORS TOKEN at the end of the ICO
    // half team are issued - 110m max
    // --------------------------------------------------------------------------------

    // calculation of advisors + bounties and issue the tokens
    advisors_fund_tokens = TOKENS_ADVISORS_MAX.mul(ratio_sold).div(1000000);
    generate_tokens(advisors_fund_address, advisors_fund_tokens);
    // calculation of team tokens and issue the tokens
    team_fund_tokens = TOKENS_TEAM_MAX.mul(ratio_sold).div(1000000);
    generate_tokens(address(this), team_fund_tokens);
    // calculation of reserve tokens and issue the tokens
    reserve_fund_tokens = TOKENS_RESERVE_MAX.mul(ratio_sold).div(1000000);
    generate_tokens(address(this), reserve_fund_tokens);
    // calculation of community tokens and issue the tokens
    community_fund_tokens = TOKENS_COMMUNITY_MAX.mul(ratio_sold).div(1000000);
    generate_tokens(address(this), community_fund_tokens);
  }

  function  move_unlock_tokens(address _to, uint256 _value)
    public onlyOwner after_token_sale is_closed
  {
    token_contract.transferFrom(address(this), _to, _value);
  }

  /**
  * @dev    Ask for the second half of team tokens
  *         locked for 1 year (365 days after ICO END)
  */
  function  claim_locked_team_tokens()
    public onlyOwner after_token_sale is_closed
  {
    require (!team_claimed);

    uint64   _now = get_now();

    require (_now >= (ICO_TOKEN_SALE_END + (365*24*60*60)));

    //super.transferFrom(locked_fund_address, team_fund_address, team_fund_tokens);
    //generate_tokens(team_fund_address, team_fund_tokens);
    //super.transferFrom(address(this), team_fund_address, team_fund_tokens);
    move_unlock_tokens(team_fund_address, team_fund_tokens);

    team_claimed = true;
  }


  /**
  * @dev    Ask for the reserve tokens
  *         locked for 18 months (547 days after ICO END)
  */
  function  claim_locked_reserve_tokens()
    public onlyOwner after_token_sale is_closed
  {
    require (!reserve_claimed);

    uint64   _now = get_now();

    require (_now >= (ICO_TOKEN_SALE_END + (547*24*60*60)));

    //super.transferFrom(locked_fund_address, reserve_fund_address, reserve_fund_tokens);
    //generate_tokens(reserve_fund_address, reserve_fund_tokens);
    //super.transferFrom(address(this), reserve_fund_address, reserve_fund_tokens);
    move_unlock_tokens(reserve_fund_address, reserve_fund_tokens);

    reserve_claimed = true;
  }


  /**
  * @dev    Owner can ask for possible community tokens
  *         Those tokens are meant to be distributed to the contributors
  *         every quarters we unlock a part of the 480m max tokens here are the values :
  *         Q1 : 2.8m, Q2 : 4.2m, Q3 : 5.6m, Q4 : 7.0  m, Q5 : 8.2m, Q6 : 9.4m, etc.
  *         the acceleration is slow to grow with the community and respect early investors
  *         it's possible to miss a quarter and stop the claiming, it's a manual operation
  *         but it's impossible to claim twice a quarter
  * @param  power_factor : the power factor if it's too slow or too fast, can be adjusted
  *         during time (default 3)
  */

  function  get_possible_community_tokens(uint256 power_factor)
    public onlyOwner after_token_sale is_closed
  {
    uint64 _now = get_now();

    if (power_factor <= 0)
      power_factor = 3;

    // the initial formula used ln(x), but I had to change it because of
    // solidity limitation and gas used to compute logarithm
    // now the formula looks like this (floating adjusted):
    //             R * (Q * F + 3) / 1000
    // with :
    //    R = remaining community tokens on the 480m max
    //    Q = current quarter number from the start
    //    F = power factor

    // compute the quarter number after the ICO end.
    uint256 Q = (_now - ICO_TOKEN_SALE_END) / (91*24*60*60); //91 days by quarters

    //quarters unlocks can be done only once
    require (last_community_quarter_called < Q);

    uint256 coeff = Q.mul(power_factor) + 3;

    // calculation of amount
    uint256 community_token_to_add = (TOKENS_RESERVE_MAX - community_amount_claimed).mul(coeff).div(1000);

    //generate_tokens(community_fund_address, community_token_to_add);
    //super.transferFrom(locked_fund_address, community_fund_address, community_token_to_add);
    //super.transferFrom(address(this), community_fund_address, community_token_to_add);
    move_unlock_tokens(community_fund_address, community_token_to_add);

    // increase the amount done
    community_amount_claimed = community_amount_claimed.add(community_token_to_add);
    // move to the next (and wait to be able to do it again)
    last_community_quarter_called = Q;
  }


  // WHITELIST FUNCTIONS  -----------------------------------------------------------
  // --------------------------------------------------------------------------------

  /**
  * @dev    check is an address is in the white list. onlyOwner
    * @return the number of maximum allowed ETH
  */
  function  getUserCap(address _addr)
    public view  onlyOwner returns (uint256)
  {
    return super.getUserCap(_addr);
  }

  /**
  * @dev    Amount of ETH contributed by an address (in case of refund)
    * @return return the number of ETH in wei
  */
  function  getUserContribution(address _addr)
    public view onlyOwner returns (uint256)
  {
    return super.getUserContribution(_addr);
  }

  /**
  * @dev    Refund if the token sale doesn't reach the soft cap
  * @return none
  */
  function  refund_contributor(address _addr) public onlyOwner after_token_sale
  {
    require (1 == 0, "TODO");
    require (token_contract.totalSupply() < TOKENS_SALE_SOFT_CAP);

    if (contributions[_addr] > 0)
    {
      //transfer ETH (with a 0,5% fee)
      _addr.transfer(contributions[_addr].mul(995).div(1000));
      contributions[_addr] = 0;
    }
  }


  // DEBUG ONLY FUNCTIONS  ----------------------------------------------------------
  // --------------------------------------------------------------------------------

  uint64  public debug_fake_date                    = 0;
  uint256 public constant DEBUG_MULTIPLICATOR        = 1000;

  // @dev Get the current date - used for debug
  function get_now() internal constant returns (uint64 tokens)
  {
    if (debug_fake_date > 0)
      return (debug_fake_date);
    return (uint64(block.timestamp));
  }

  // @dev This modifier overrides TimedCrowdsale's. Remove it to use the real Zeppelin implementation
  modifier onlyWhileOpen
  {
    uint256 _now = get_now();
    require(_now >= openingTime && _now <= closingTime);
    _;
  }

  // @dev DEBUG set a fake date for debug
  function debug_set_date(uint64 fake_date) public onlyOwner
  {
    debug_fake_date = fake_date;
  }

  function printf(string _msg, uint256 _val) public
  {
    token_contract.printf(_msg, _val);
  }

}