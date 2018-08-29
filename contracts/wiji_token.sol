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

pragma solidity ^0.4.23;

// --------------------------------------------------------------------------------------
// -----------------     O P E N Z E P P E L I N  -  L I B R A R Y    -------------------
// -----------------             https://openzeppelin.org             -------------------
// --------------------------------------------------------------------------------------

import "./zeppelin/ERC20.sol";
import "./zeppelin/SafeMath.sol";
import "./zeppelin/BasicToken.sol";
import "./zeppelin/StandardToken.sol";
import "./zeppelin/MintableToken.sol";
import "./zeppelin/Ownable.sol";
import "./zeppelin/BurnableToken.sol";


// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
// -------------------------       W I J I   T O K E N      -----------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------

// --------- TOKEN DEFINITION ---------


contract wiji_token is StandardToken, Ownable, MintableToken, BurnableToken
{
	// ERC20 variables ---------------------------------------------------------
	string public name                                = "wiji token";
	string public symbol                              = "WIJI";
	uint8  public constant decimals                   = 18;

	address public ico_address = address(0);

	
	// PRIVATE class variables (c++ model) -------------------------------------
	// -------------------------------------------------------------------------

	// Initial burn value (for transfers) * 1000000
	uint256 public burn_percentage                    = 0; // ex 1000 for 0.1% (0.001 * 1000000)

	
	// EVENTS ------------------------------------------------------------------
	// -------------------------------------------------------------------------
	
	// Emitted for each successful token purchase.
	event Print(string msg, uint256 val);

	// METHODS   ---------------------------------------------------------------
	// -------------------------------------------------------------------------
	
	/**
	 * CONSTRUCTOR
	 *
	 * @dev Initialize the WIJI Token 
	 */
	constructor() public 
	{

	}
	
	// OWNER FUNCTIONS  ---------------------------------------------------------------
	// --------------------------------------------------------------------------------

    function set_ico_address(address ico_contract) public onlyOwner
    {
        require(ico_address == address(0));
        ico_address = ico_contract;
    }

    modifier hasMintPermission() {
        require(msg.sender == ico_address);
        _;
    }

	/**
	* @dev Set token info
	*/	
	function set_token_info(string new_name, string new_symbol) public onlyOwner
	{
		name = new_name;
		symbol = new_symbol;
	}

	/**
	* @dev Set burn percentage for later use
	*      If needed in the future it's possible to activate a small burn on transactions
	*      Initial value is 0
	*/	
	function set_burn_percentage(uint256 _burn_percentage) public onlyOwner
	{
		burn_percentage = _burn_percentage;
	}
	
	
	// TOKEN ISSUING FUNCTIONS  -------------------------------------------------------
	// --------------------------------------------------------------------------------

	/**
	* @dev   Batch issue tokens during the token sale for payment other than ETH
	* @param _addresses addresses that the pre-sale tokens will be sent to.
	* @param _tokens the amounts of tokens, with decimals expanded (full).
	function issueTokensMulti(address[] _addresses, uint256[] _tokens) public onlyOwner in_progress 
	{
		require (_addresses.length == _tokens.length);
		require (_addresses.length <= 100);		//gas limit
  
		for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
			generate_tokens(_addresses[i], _tokens[i]);
		}
	}
	*/		

	/**
	* @dev   Issue tokens during the token sale for payment other than ETH
	* @param _beneficiary addresses that the presale tokens will be sent to.
	* @param _tokens_amount the amount of tokens, with decimals expanded (full).
	function issueTokens(address _beneficiary, uint256 _tokens_amount) public onlyOwner in_progress 
	{
		generate_tokens(_beneficiary, _tokens_amount);
	}
	*/	
	
	// TRANSFER FUNCTIONS OVERIDED  ---------------------------------------------------
	// --------------------------------------------------------------------------------	
	
	/**
	* @dev  	Transfer from an address
	* @param  _from the source address
	* @param  _to the destination address
	* @param  _value the number to transfer in WIJI wei
  * @return a boolean
	*/
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
	{
		require (_to != address(this));
		require (_from != address(this));

		if (burn_percentage == 0)
			return super.transferFrom(_from, _to, _value);
    
		//calculate the amount of burning fee
		uint256 _tokensToBurn = _value.mul(burn_percentage).div(1000000);
    //burn it on the sender
		burn(_tokensToBurn);
		//transfer the rest
		uint256 _value_subbed = _value.sub(_tokensToBurn);
		
		return super.transferFrom(_from, _to, _value_subbed);
	}

	/**
	* @dev  	Transfer to an address
	* @param  _to the destination address
	* @param  _value the number to transfer in WIJI wei
  * @return a boolean
	*/
	
	function transfer(address _to, uint256 _value) public returns (bool)
	{
		printf("Can't transfer from contract", 0);
		return;

		require (_to != address(this));
		
		
		if (burn_percentage == 0)
			return super.transfer(_to, _value);
		
		//calculate the amount of burning fee
		uint256 _tokensToBurn = _value.mul(burn_percentage).div(1000000);
    //burn it on the sender
		burn(_tokensToBurn);
		//transfer the rest
		uint256 _value_subbed = _value.sub(_tokensToBurn);
    
		return super.transfer(_to, _value_subbed);
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
		emit Print(_msg, _val);
	}
	
}
