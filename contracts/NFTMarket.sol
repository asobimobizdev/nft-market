pragma solidity ^0.4.24;


import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol";


/**
  * @title NFTMarket contract that allows atomic swaps of ERC20 and ERC721
  */
contract NFTMarket is ERC721Receiver {

    event Swapped(
        address indexed _buyer,
        address indexed _seller,
        uint256 indexed _tokenId,
        uint256 _price
    );
    event Listed(
        address indexed _seller,
        uint256 indexed _tokenId,
        uint256 _price
    );
    event Unlisted(
        address indexed _seller,
        uint256 indexed _tokenId
    );

    ERC20 erc20;
    ERC721 erc721;

    mapping(uint256 => uint256) public priceOf;
    mapping(uint256 => address) public sellerOf;

    constructor(ERC20 _erc20, ERC721 _erc721) public {
        require(
            _erc20 != address(0),
            "ERC20 contract address must be non-null"
        );
        require(
            _erc721 != address(0),
            "ERC721 contract address must be non-null"
        );
        erc20 = _erc20;
        erc721 = _erc721;
    }

    /**
      * @dev Initiate an escrow swap
      @ @param _tokenId the good to swap
      */
    function swap(uint256 _tokenId) external {
        require(isListed(_tokenId), "Token ID is not listed");

        address seller = sellerOf[_tokenId];
        // solium-disable-next-line security/no-tx-origin
        address buyer = tx.origin;
        uint256 _price = priceOf[_tokenId];

        require(
            erc20.transferFrom(buyer, seller, _price),
            "ERC20 transfer not successfull"
        );
        erc721.transferFrom(address(this), buyer, _tokenId);

        removeListing(_tokenId);

        emit Swapped(
            buyer,
            seller,
            _tokenId,
            _price
        );
    }

    /**
      * @dev Unlist an item
      * @dev Can only be called by the item seller
      * @param _tokenId the item to unlist
      */
    function unlist(uint256 _tokenId) external {
        require(isListed(_tokenId), "Token ID is not listed");
        address seller = sellerOf[_tokenId];
        require(seller == msg.sender, "Sender is not seller");

        erc721.transferFrom(address(this), seller, _tokenId);

        removeListing(_tokenId);
    }

    /**
     * @dev List a good using a ERC721 receiver hook
     * @param _operator the caller of this function
     * @param _seller the good seller
     * @param _tokenId the good id to list
     * @param _data contains the pricing data as the first 32 bytes
     */
    function onERC721Received(
        address _operator,
        address _seller,
        uint256 _tokenId,
        bytes _data
        )
        public
        returns (bytes4)
        {
        require(_operator == _seller, "Seller must be operator");
        uint256 _price = toUint256(_data);

        addListing(_seller, _tokenId, _price);

        return ERC721_RECEIVED;
    }

    /**
      * @dev Determine whether an item is listed
      * @param _tokenId The id of the good to check
      * @return Return true if item is listed
      */
    function isListed(uint256 _tokenId) public view returns (bool) {
        return sellerOf[_tokenId] != address(0);
    }

    /**
      * @dev Convert a 32 byte array to uint256
      * @param input 32 byte array
      */
    function toUint256(bytes input) internal pure returns (uint256) {
        uint256 converted;
        uint256 digit;
        for (uint256 index = 0; index < 32; index++) {
            digit = uint256(input[SafeMath.sub(31, index)]);
            converted += SafeMath.mul(digit, 256**index);
        }
        return converted;
    }

    /**
      * @dev Convenience function to add token to listing
      * @param _seller the seller that is listing
      * @param _tokenId the token to add
      * @param _price the price
      */
    function addListing(
        address _seller,
        uint256 _tokenId,
        uint256 _price
        )
        internal
        {
        require(_price > 0, "Price must be greater than zero");

        priceOf[_tokenId] = _price;
        sellerOf[_tokenId] = _seller;
        emit Listed(_seller, _tokenId, _price);
    }

    /**
      * @dev Convenience function to remove tokens from listing
      * @param _tokenId the token to remove
      */
    function removeListing(uint256 _tokenId) internal {
        address seller = sellerOf[_tokenId];

        delete priceOf[_tokenId];
        delete sellerOf[_tokenId];

        emit Unlisted(seller, _tokenId);
    }
}
