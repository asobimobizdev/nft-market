pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/CappedToken.sol";


/**
 * @title ERC20Mock is the CappedToken implementation for ASOBI COIN
 * @dev ERC20Mock is limited to 16,500,000,000 ABX
 * @dev ERC20Mock has 18 decimals of precision
 * @dev ERC20Mock has the symbol MCC
 */
contract ERC20Mock is CappedToken(16500000000 ether) {
    string public name = "ERC20Mock";
    string public symbol = "MCC";
    uint256 public decimals = 18;
}
