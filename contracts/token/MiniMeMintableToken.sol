pragma solidity ^0.4.13;

import "./MiniMeToken.sol";
import '../zeppelin/math/SafeMath.sol';

/**
 * This contract inherits from the MinimeToken and adds minting capability.
 * When the sale is started, the token ownership is handed over to the Crowsdale contract.
 * The crowdsale contract will not call the "generateTokens()" call directly in the MinimeToken, 
 * but will instead use the minting functionality here.
 */
contract MiniMeMintableToken is MiniMeToken {
  using SafeMath for uint256;

  // Events to notify about Minting
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  // Flag to track whether minting is still allowed.
  bool public mintingFinished = false;

  // This map will keep track of how many tokens were issued during the token sale.
  // This value will then be used for vesting calculations from the point where the token contract is finished minting.
  mapping (address => uint256) issuedTokens;

  // Modifier to allow minting of tokens.
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  // Pass through consructor
  function MiniMeMintableToken(
    address _tokenFactory,
    address _parentToken,
    uint _parentSnapShotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
  ) 
  MiniMeToken(
    _tokenFactory,
    _parentToken,
    _parentSnapShotBlock,
    _tokenName,
    _decimalUnits,
    _tokenSymbol,
    _transfersEnabled
  )
  {
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyController canMint returns (bool) {

    // First, generate the tokens in the base Minime class balances.
    generateTokens(_to, _amount);

    // Save off the amount that this account has been issued during the minting period so vesting can be calculated.
    issuedTokens[_to] = issuedTokens[_to].add(_amount);

    // Trigger the minting event notification
    Mint(_to, _amount);

    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyController canMint returns (bool) {

    // Set the minting finished so that tokens can be transferred once vested.
    // This flag will prevent new tokens from being minted in the future.
    mintingFinished = true;

    // Trigger the notification that minting has finished.
    MintFinished();
    
    return true;
  }
}
