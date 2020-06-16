//pragma solidity ^0.6.6;
import "./Ownable.sol";
/**
 * @title Authorised
 * @dev The Authorised contract mantain the user/citizen address able to use the Recycle smart contract
 */
contract Authorised is Ownable{

  event NewAuthorisedAddress(address newAddress);

  mapping (address => uint) private authorisedAddress;

  /**
   * @dev The Authorised constructor setta come autorizzato il proprietario del contratto
   */
  constructor() internal {
    newAuthorised(msg.sender);
  }

    /**
   * @return true if `address` is the owner of the contract.
   * @dev da renderlo onlyAuthorised una volta fatto un primo test di controllo
   */
  function isAuthorised(address add) external view onlyAuthorised(add) returns(uint) {
    return authorisedAddress[add];
  }
  
   //@dev Throws if called by any account other than the authorised.
  modifier onlyAuthorised(address newAddress) {
    require (authorisedAddress[newAddress] == 1);  //  0 false | 1 true
    _;
  }


  function newAuthorised (address newAddress) public onlyOwner{
    authorisedAddress[newAddress] = 1;
    emit NewAuthorisedAddress(newAddress);
  }
}
