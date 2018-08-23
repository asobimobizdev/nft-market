pragma solidity ^0.4.24;


/**
 * @title Migrations contract for truffle migrate
 */
contract Migrations {
    address public owner;
    uint public lastCompletedMigration;

    modifier restricted() {
        if (msg.sender == owner) {
            _;
        }
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
      * @dev Set the id of the last completed migration
      * @param completed The id to set
      */
    function setCompleted(uint completed) public restricted {
        lastCompletedMigration = completed;
    }

    /**
      * @dev Upgrade the contract at a given address
      * @param newAddress the address of the new contract
      */
    function upgrade(address newAddress) public restricted {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(lastCompletedMigration);
    }
}
