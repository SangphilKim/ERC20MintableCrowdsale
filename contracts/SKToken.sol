pragma solidity ^0.4.23;

import "./MintableToken.sol";

contract SKToken is MintableToken{
	string public constant name = "SKToken";
	string public constant symbol = "SKT";
	uint public constant decimals = 18;
}
