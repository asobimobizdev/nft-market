pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";


/**
 * @title ERC721Mock contract
 */
contract ERC721Mock is Ownable, ERC721Token("ERC721Mock", "MCK") {
    uint256 public tokenCount = 1;

    /**
      * @dev Mint a token
      * @dev Can only be called by the contract owner
      * @param _to The receiver of the newly minted token
      */
    function mint(address _to) onlyOwner public {
        super._mint(_to, tokenCount);

        tokenCount++;
    }
}
