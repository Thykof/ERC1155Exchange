const BigNumber = require("bignumber.js");
const truffleAssert = require("truffle-assertions");
const Web3 = require("web3");

const web3 = new Web3(Web3.givenProvider);

const ERC1155Token = artifacts.require("ERC1155Token");

contract("ERC1155 Token", accounts => {
  const [owner, shareholder] = accounts;

  before(async () => {
    tokens = await ERC1155Token.new();
  });

  describe("Approval", async () => {
    it("isApprovedForAll", async () => {
      assert.equal(await tokens.isApprovedForAll(shareholder, owner), false);
    });
  });
});
