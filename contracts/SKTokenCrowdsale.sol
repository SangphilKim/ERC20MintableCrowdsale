pragma solidity ^0.4.23;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SKToken.sol";

/**
 * @title SKTokenCrowdsale
 * @dev SKTokenCrowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to an owner
 * as they arrive.
 */
contract SKTokenCrowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  uint256 public startTime = 0;
  uint256 public endTime;
  bool public isFinished = false;

  // how many ETH cost 1000 SKT. rate = 1000 SKT/ETH. It's always an integer!
  //formula for rate: rate = 1000 * (SKT in USD) / (ETH in USD)
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  string public saleStatus = "Don't started";

  uint public tokensMinted = 0;

  uint public minimumSupply = 1; //minimum token amount to sale at one transaction

  uint public constant HARD_CAP_TOKENS = 2500000 * 10**18;

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount, uint256 _tokensMinted);


  function SKTokenCrowdsale(uint256 _rate) public {
    require(_rate > 0);
	require (_rate < 1000);

    token = createTokenContract();
    startTime = now;
    rate = _rate;
	saleStatus = "PreSale";
  }

  function startCrowdSale() public onlyOwner {
	  saleStatus = "CrowdSale";
  }

  function finishCrowdSale() public onlyOwner {
	  isFinished = true;
	  saleStatus = "Finished";
	  endTime = now;
  }

  function setRate(uint _rate) public onlyOwner {
	  require (_rate > 0);
	  require (_rate <=1000);
	  rate = _rate;
  }

  function createTokenContract() internal returns (SKToken) {
    return new SKToken();
  }


  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens();
  }

  // low level token purchase function
  function buyTokens() public payable {
	require(!isFinished);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(1000).div(rate);

    require(tokensMinted.add(tokens) <= HARD_CAP_TOKENS);

    weiRaised = weiRaised.add(weiAmount);

    token.mint(msg.sender, tokens);
	tokensMinted = tokensMinted.add(tokens);
    TokenPurchase(msg.sender, weiAmount, tokens, tokensMinted);

    forwardFunds();
  }


  function forwardFunds() internal {
    owner.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = startTime > 0 && !isFinished;
    bool validAmount = msg.value >= (minimumSupply * 10**18 * rate).div(1000);
    return withinPeriod && validAmount;
  }
