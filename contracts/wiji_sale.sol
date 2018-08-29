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

import "./zeppelin/ERC20.sol";
import "./zeppelin/SafeMath.sol";
import "./zeppelin/BasicToken.sol";
import "./zeppelin/StandardToken.sol";
import "./zeppelin/Ownable.sol";
import "./zeppelin/BurnableToken.sol";

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
// --------------------------       W I J I   S A L E      ------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------

import "./wiji_token.sol";

contract wiji_sale is Ownable
{
    using SafeMath for uint256;

    wiji_token public token_contract;

    // CONSTANTS ---------------------------------------------------------------
	// -------------------------------------------------------------------------

	uint8  public constant decimals                   = 18;

	// Maximum tokens that could be allocated (2 billion) it's unreachable because of token burns
	uint256 public constant TOKEN_MAX_CIRCULATION     = 2000000000 * (10**uint256(decimals));

	// Tokens to be sold (900m)
	uint256 public constant TOKENS_SALE_HARD_CAP      = 1000000000 * (10**uint256(decimals));
	// Tokens soft cap (100m)
	uint256 public constant TOKENS_SALE_SOFT_CAP      =  100000000 * (10**uint256(decimals));

	// Tokens for community unlocked every quarter (480m)
	uint256 public constant TOKENS_COMMUNITY_MAX      =  480000000 * (10**uint256(decimals));
	// Tokens for community unlocked on demand (300m)
	uint256 public constant TOKENS_RESERVE_MAX        =  300000000 * (10**uint256(decimals));
	// Tokens for team (180m)
	uint256 public constant TOKENS_TEAM_MAX           =  180000000 * (10**uint256(decimals));
	// Tokens for team + bounties + advisors (40m)
	uint256 public constant TOKENS_ADVISORS_MAX       =   40000000 * (10**uint256(decimals));


	// ICO tokens for sale, the remaining tokens of each sale will be reported to the next
	// step 1 pre-sale     : Mon, 18 Jun 2018 12:42:42 GMT -
	//                       100m token to sell - bonus 30%
	uint256 constant ICO_TOKEN_SALE_MAX_1             =  100000000 * (10**uint256(decimals));
	//uint256 ICO_TOKEN_SALE_DATE_1     = 1529325762;

	// step 2 public sale  : Mon, 09 Jul 2018 12:42:42 GMT -
	//                       200m token to sell - bonus 10%
	uint256 constant ICO_TOKEN_SALE_MAX_2             =  200000000 * (10**uint256(decimals));
	uint256 constant ICO_TOKEN_SALE_DATE_2            = 1531140162;

	// step 3 public sale  : Mon, 16 Jul 2018 12:42:42 GMT -
	//                       700m token to sell - bonus  0%
	uint256 constant ICO_TOKEN_SALE_MAX_3             =  700000000 * (10**uint256(decimals));
	uint256 constant ICO_TOKEN_SALE_DATE_3            = 1531744962;

	// End of public sale  : Sun, 26 Aug 2018 12:42:42 GMT -
	// 											 remaining token will be burned
	uint256 public constant ICO_TOKEN_SALE_END        = 1535287362;


	// PRIVATE class variables (c++ model) -------------------------------------
	// -------------------------------------------------------------------------

	// current community amount called
	uint256 community_amount_claimed                  = 0;
	// Last community quarter called
    uint256 last_community_quarter_called             = 0;

	// token sale status
	bool public    token_sale_closed                  = false;

	// Issue event index starting from 0.
	//uint256 public issue_index                        = 0;
	// Tokens sold
	uint256 public token_sold                         = 0;



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


	bool public    team_claimed                  	  = false;
	bool public    reserve_claimed                    = false;
	bool public    advisors_claimed                   = false;
	// calculation of token numbers
	uint256 public team_fund_tokens                   = 0;
	uint256 public reserve_fund_tokens                = 0;
	uint256 public advisors_fund_tokens               = 0;
	uint256 public community_fund_tokens              = 0; // max possible

    // White listed addresses (who passed the KYC process)
	// if contains the max amount the user can buy in ETH * 1000 units
	mapping(address => uint64) private white_list;
	address[] private white_list_LUT;

	// Contributions history
	mapping(address => uint256) public contributions;

    // MODIFIERS ---------------------------------------------------------------
	// -------------------------------------------------------------------------

	// Require that the buyers can still purchase
	modifier in_progress
	{
		require(token_contract.totalSupply() < TOKENS_SALE_HARD_CAP
						&& !token_sale_closed
						&& !is_token_sale_ended());
		_;
	}

	// Allow the closing to happen only once
	modifier before_close
	{
			require(!token_sale_closed);
			_;
	}

	modifier after_close
	{
			require(token_sale_closed);
			_;
	}

	// Require that the end of the sale has passed
	modifier after_token_sale
	{
			require(is_token_sale_ended());
			_;
	}

    /**
	 * CONSTRUCTOR
	 *
	 * @dev Initialize the WIJI ICO Sale
	 */
	constructor(wiji_token _token_contract) public
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
	* @dev This default function allows token to be purchased by directly
	*      sending ether to this smart contract.
	*/
	function () public payable
	{
        purchaseTokens(msg.sender);
	}

	/**
	* @dev   Issue token based on Ether received.
	* @param _beneficiary Address that newly issued token will be sent to.
	*/
	function purchaseTokens(address _beneficiary) public payable in_progress
	{
		uint256 max_user_cap = check_white_list_addr_internal(_beneficiary);
		//max_user_cap is in ETH * 1000 so it misses 18 - 3 zeros
		max_user_cap = max_user_cap.mul(10**uint256(15));

		// only accept white listed addresses
		require (max_user_cap > 0);

		//convert it in wei * 1000
		//max_user_cap = max_user_cap.mul(10**uint256(decimals - 2));

		// Minimum amount to invest
		uint256 MINIMUM_TOKEN_BUY      = 0.05 ether;
		// Maximum amount to invest
		uint256 MAXIMUM_TOKEN_BUY      = 4000 ether;

		// only accept a minimum amount of ETH?
		require (msg.value >= MINIMUM_TOKEN_BUY &&
		         msg.value <= MAXIMUM_TOKEN_BUY);

		//check for the authorized whitelist user cap
		require (contributions[_beneficiary].add(msg.value) <= max_user_cap);

		// compute how many tokens it will have
		uint256 _tokens_amount = compute_token_amount(msg.value);

		//check for hard cap
        require(token_contract.totalSupply().add(_tokens_amount) <= TOKENS_SALE_HARD_CAP);

		generate_tokens(_beneficiary, _tokens_amount);

		// increased after the token creation process, Openzeppelin increase it
		// before the issuing, it makes more sense to me to do it after, because
		// the issue can revert
		token_sold = token_sold.add(_tokens_amount);

		// increase the contribution of the user
		contributions[_beneficiary] = contributions[_beneficiary].add(msg.value);

	}


	/**
	* @dev   issue tokens for a single buyer
	* @param _beneficiary addresses that the tokens will be sent to.
	* @param _tokens_amount the amount of tokens, with decimals expanded (full).
	*/
	function generate_tokens(address _beneficiary, uint256 _tokens_amount) internal before_close
	{
		require (_beneficiary != address(0));
        require (_tokens_amount != 0);

		// compute without actually increasing it
		uint256 increased_total_supply = token_contract.totalSupply().add(_tokens_amount);

		// roll back if the max cap is reached (should be impossible)
		require(increased_total_supply <= TOKEN_MAX_CIRCULATION);

        // TODO : Change this
		// increase token total supply
		//totalSupply_ = increased_total_supply;
		// update the buyer's balance to number of tokens sent
		//balances[_beneficiary] = balances[_beneficiary].add(_tokens_amount);
		// event is fired when tokens issued
		//emit Issue(_beneficiary, _tokens_amount);
	}

    // TOKEN SALE FUNCTIONS  ----------------------------------------------------------
	// --------------------------------------------------------------------------------


	/**
	* @dev  Compute the amount of WIJI token that can be purchased.
	* @param eth_amount Amount of Ether to purchase WIJI.
	* @return Amount of WIJI token to purchase
	*/
	function compute_token_amount(uint256 eth_amount) internal view returns (uint256 tokens)
	{
		uint64 _now = get_now();
		require(_now <= ICO_TOKEN_SALE_END);

		// Base exchange rate is set to 1 ETH = 21000 WIJI other rates with discount
		uint256 BASE_RATE_0               = 21000 * DEBUG_MULTIPLICATOR;
		uint256 BASE_RATE_10              = 23100 * DEBUG_MULTIPLICATOR;
		uint256 BASE_RATE_30              = 27300 * DEBUG_MULTIPLICATOR;

		uint256 supply = token_contract.totalSupply();

		// if date is above the pre sale end 1 or the max number is sold then we propose next step
		if      ((_now <= ICO_TOKEN_SALE_DATE_2) &&  														// <= Mon, 09 Jul 2018 12:42:42 GMT
             (supply < ICO_TOKEN_SALE_MAX_1))													// total < 100m
			tokens = eth_amount.mul(BASE_RATE_30);
		else if ((_now <= ICO_TOKEN_SALE_DATE_3) && 														// <= Mon, 16 Jul 2018 12:42:42 GMT
             (supply < ICO_TOKEN_SALE_MAX_1 + ICO_TOKEN_SALE_MAX_2))	// total < 100m + 200m
			tokens = eth_amount.mul(BASE_RATE_10);
		else																																		// <= Sun, 26 Aug 2018 12:42:42 GMT
			tokens = eth_amount.mul(BASE_RATE_0);
	}

	/**
	* @dev  	calculate the current number of WIJI for 1 ether .
	* @return the current price.
	*/
	function price() public view returns (uint256 tokens)
	{
		return compute_token_amount(1 ether);
	}

	/**
	* @dev  	transfer the raised ETH to the owner, if the soft cap is reached
	*/
	function access_raised_funds() public onlyOwner
	{
		require (token_contract.totalSupply() >= TOKENS_SALE_SOFT_CAP);
		//owner_address.transfer(this.balance);
		owner_address.transfer(address(this).balance);
	}

	/**
	* @dev  	ask if the token sale is finished
  * @return a bool if it's finshed
	*/
	function is_token_sale_ended() public constant returns (bool)
	{
		return (ICO_TOKEN_SALE_END < get_now());
	}

	/**
	* @dev Finalize the sale and distribute the fund to all the parties
	*
	* 	Now we calculate the numbers of tokens to be issued the base numbers are :
	*		 SALE       50% : max TOKENS_SALE_HARD_CAP (1000m) - to be sold
	*		 COMMUNITY  24% : max TOKENS_COMMUNITY_MAX ( 480m) - less than 1% unlocked every quarter
	*		 RESERVE    15% : max TOKENS_RESERVE_MAX   ( 300m) - locked for 18 months asked on demand
	*		 TEAM        9% : max TOKENS_TEAM_MAX      ( 220m) - locked for 1 year
	*		 ADV+BOUNTY  2% : max TOKENS_ADVISORS_MAX  ( 	40m) - advisors + bounties unlocked
	*
	*/
	function  close_ico() public onlyOwner before_close
	{
		//if the soft_cap is not reached we can't close the ICO
		//if it's never reached then we can only launch the refund method
		require (token_contract.totalSupply() >= TOKENS_SALE_SOFT_CAP);

		// We calculate the ratio of what we have sold, max sold tokens are 1000m
		// we times it by 1000000 to use integers for calculation (everything is in wei)
		// ex : we have sold 150m (15%) tokens it's 150m * 1m / 1000m = 150000
		uint256 ratio_sold = token_sold.mul(1000000).div(TOKENS_SALE_HARD_CAP);


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

		// close the sale all future calculation will be based on the values
		token_sale_closed = true;
	}

	function  move_unlock_tokens(address _to, uint256 _value)
		public onlyOwner after_token_sale after_close
	{
        // TODO: Call wiji_token's transfer method
        //balances[address(this)] = balances[address(this)].sub(_value);
        //balances[_to] = balances[_to].add(_value);
        //emit Transfer(address(this), _to, _value);
	}

	/**
	* @dev  	Ask for the second half of team tokens
	*         locked for 1 year (365 days after ICO END)
	*/
	function  claim_locked_team_tokens() public onlyOwner after_token_sale after_close
	{
		require (!team_claimed);

		uint64 	_now = get_now();

		require (_now >= (ICO_TOKEN_SALE_END + (365*24*60*60)));

		//super.transferFrom(locked_fund_address, team_fund_address, team_fund_tokens);
		//generate_tokens(team_fund_address, team_fund_tokens);
		//super.transferFrom(address(this), team_fund_address, team_fund_tokens);
		move_unlock_tokens(team_fund_address, team_fund_tokens);

		team_claimed = true;
	}


	/**
	* @dev  	Ask for the reserve tokens
	*         locked for 18 months (547 days after ICO END)
	*/
	function  claim_locked_reserve_tokens() public onlyOwner after_token_sale after_close
	{
		require (!reserve_claimed);

		uint64 	_now = get_now();

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
	*         Q1 : 2.8m, Q2 : 4.2m, Q3 : 5.6m, Q4 : 7.0	m, Q5 : 8.2m, Q6 : 9.4m, etc.
	*         the acceleration is slow to grow with the community and respect early investors
	*         it's possible to miss a quarter and stop the claiming, it's a manual operation
	*         but it's impossible to claim twice a quarter
	* @param  power_factor : the power factor if it's too slow or too fast, can be adjusted
	*         during time (default 3)
	*/

	function  get_possible_community_tokens(uint256 power_factor) public onlyOwner after_token_sale after_close
	{
		uint64 _now = get_now();

		if (power_factor <= 0)
			power_factor = 3;

		// the initial formula used ln(x), but I had to change it because of
		// solidity limitation and gas used to compute logarithm
		// now the formula looks like this (floating adjusted):
		// 						R * (Q * F + 3) / 1000
		// with :
		//		R = remaining community tokens on the 480m max
		//		Q = current quarter number from the start
		//		F = power factor

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
	* @dev  	Add or modify an address in the white list
	*/
	function  set_address_to_whitelist(address addr, uint64 max) public onlyOwner
	{
		if (white_list[addr] == 0)
			white_list_LUT.push(addr);

		white_list[addr] = max;
	}

	/**
	* @dev  	Add multiple addresses to the white list
	*/
	function  set_addresses_to_whitelist(address[] addresses, uint64[] maxes) public onlyOwner
	{
		for (uint256 i = 0; i < addresses.length; i++)
			set_address_to_whitelist(addresses[i], maxes[i]);
	}

	/**
	* @dev  	check is an address is in the white list (internal)
  * @return the number of maximum allowed ETH
	*/
	function  check_white_list_addr_internal(address _addr) internal constant returns (uint64)
	{
		return white_list[_addr];
	}

	/**
	* @dev  	check is an address is in the white list
  * @return the number of maximum allowed ETH
	*/
	function  check_white_list_addr(address _addr)	public constant	onlyOwner returns (uint64)
	{
		return check_white_list_addr_internal(_addr);
	}

	/**
	* @dev
  * @return return the white list size
	*/
	function  get_white_list_length() public constant onlyOwner returns (uint64)
	{
		return uint64(white_list_LUT.length);
	}

	/**
	* @dev
  * @return return the addresses present in the list in an array[]
	*/
	function  get_whitelisted_addresses() public constant onlyOwner returns (address[])
	{
		return white_list_LUT;
	}


	// CONTRIBUTORS FUNCTIONS  --------------------------------------------------------
	// --------------------------------------------------------------------------------

	/**
	* @dev  	Amount of ETH contributed by an address (in case of refund)
  * @return return the number of ETH in wei
	*/
	function  get_contributed(address _addr)	public constant	onlyOwner returns (uint256)
	{
		return contributions[_addr];
	}

	/**
	* @dev  	Refund if the token sale doesn't reach the soft cap
  * @return none
	*/
	function  refund_contributor(address _addr) public onlyOwner after_token_sale
	{
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
	uint256 public constant DEBUG_MULTIPLICATOR				= 1000;

	// @dev Get the current date - used for debug
	function get_now() internal constant returns (uint64 tokens)
	{
		if (debug_fake_date > 0)
			return (debug_fake_date);
		return (uint64(block.timestamp));
	}

	// @dev DEBUG set a fake date for debug
	function debug_set_date(uint64 fake_date) public onlyOwner
	{
		debug_fake_date = fake_date;
	}

	function printf(string _msg, uint256 _val) public onlyOwner
	{
        // TODO
		//emit Print(_msg, _val);
	}

}