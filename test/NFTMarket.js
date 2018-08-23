const assertRejected = require("assert-rejected");
const web3Utils = require("web3-utils");

const ERC20Mock = artifacts.require("contracts/ERC20Mock.sol");
const ERC721Mock = artifacts.require("contracts/ERC721Mock.sol");
const NFTMarket = artifacts.require("contracts/NFTMarket.sol");

contract("NFTMarket", (accounts) => {
  const buyer = accounts[1];
  const seller = accounts[2];
  const buyerOptions = { from: buyer };
  const sellerOptions = { from: seller };

  const price = 256;
  // 0x0000000000000000000000000000000000000000000000000000000000000100;
  const priceHex = web3Utils.padLeft(web3Utils.toHex(price), 64);
  const zeroPriceHex = web3Utils.padLeft(web3Utils.toHex(0), 64);

  let coin;
  let erc721Mock;
  let nftMarket;
  let tokenId;

  beforeEach(async () => {
    coin = await ERC20Mock.new();
    erc721Mock = await ERC721Mock.new();
    nftMarket = await NFTMarket.new(coin.address, erc721Mock.address);

    await coin.mint(buyer, price);

    await erc721Mock.mint(seller);
    tokenId = await erc721Mock.tokenByIndex(0);
  });

  describe("0 addresses", () => {
    it("needs a valid ERC 20 address", async () => {
      await assertRejected(NFTMarket.new(0, erc721Mock.address));
    });
    it("needs a valid ERC 721 address", async () => {
      await assertRejected(NFTMarket.new(coin.address, 0));
    });
  });

  describe("listing", () => {
    it("lets the owner list an object", async () => {
      // TODO temporary workaround for
      // https://github.com/trufflesuite/truffle/issues/737
      // https://github.com/trufflesuite/truffle/issues/1171
      await erc721Mock.methods[
        "safeTransferFrom(address,address,uint256,bytes)"
      ](seller, nftMarket.address, tokenId, priceHex, sellerOptions);
      assert.isTrue(await nftMarket.isListed(tokenId));
    });

    it("won't let the owner set the price to 0", async () => {
      await assertRejected(
        erc721Mock.methods["safeTransferFrom(address,address,uint256,bytes)"](
          seller,
          nftMarket.address,
          tokenId,
          zeroPriceHex,
          sellerOptions,
        ),
      );
    });
  });

  describe("isListed", () => {
    it("knows who listed", async () => {
      await erc721Mock.methods[
        "safeTransferFrom(address,address,uint256,bytes)"
      ](seller, nftMarket.address, tokenId, priceHex, sellerOptions);
      assert.equal(await nftMarket.priceOf(tokenId), price);
      assert.equal(await nftMarket.sellerOf(tokenId), seller);
    });
  });

  describe("swap", () => {
    beforeEach(async () => {
      await erc721Mock.methods[
        "safeTransferFrom(address,address,uint256,bytes)"
      ](seller, nftMarket.address, tokenId, priceHex, sellerOptions);
    });

    it("allows the seller to unlist their item", async () => {
      await nftMarket.unlist(tokenId, sellerOptions);
      assert.equal(await erc721Mock.ownerOf(tokenId), seller);
    });

    it("swaps when the buyer initiates", async () => {
      await coin.approve(nftMarket.address, price, buyerOptions);
      await nftMarket.swap(tokenId, buyerOptions);
      assert.equal(await erc721Mock.ownerOf(tokenId), buyer);
      assert.equal(await coin.balanceOf(seller), price);
    });

    it("won't swap if the buyer does not approve enough", async () => {
      await coin.approve(nftMarket.address, price - 1, buyerOptions);
      await assertRejected(nftMarket.swap(tokenId, buyerOptions));
    });
  });
});
