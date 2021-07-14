const BigNumber = require("bignumber.js");
const truffleAssert = require("truffle-assertions");
const Web3 = require("web3");

const web3 = new Web3(Web3.givenProvider);

const {
  checkNullOrder,
  checkOrderAdded,
  checkTradeExecuted
} = require("./utils");

const TradableERC1155Token = artifacts.require("TradableERC1155Token");
const ProxyAndStorageForERC1155Exchange = artifacts.require(
  "ProxyAndStorageForERC1155Exchange"
);
const ERC1155ExchangeImplementationV1 = artifacts.require(
  "ERC1155ExchangeImplementationV1"
);
const MockERC1155ExchangeImplementationV2 = artifacts.require(
  "MockERC1155ExchangeImplementationV2"
);

contract("ERC1155 Upgradeable Proxy", accounts => {
  let tokenId = 1;
  const [owner, shareholder] = accounts;
  let proxyExchangeAddress;
  let token;
  let implementation;
  let mock;

  before(async () => {
    implementation = await ERC1155ExchangeImplementationV1.new();
    console.log("implementation: ", implementation.address);
    mock = await MockERC1155ExchangeImplementationV2.new();
    console.log("mock: ", mock.address);
  });

  describe("Simple upgrade", async () => {
    before(async () => {
      token = await TradableERC1155Token.new(implementation.address);
      console.log("token: ", token.address);

      const { logs } = await token.newToken(owner, tokenId, 300);
      proxyExchangeAddress = logs.find(l => l.event == "TokenCreated").args
        .exchangeAddress;
      console.log("exchange: ", proxyExchangeAddress);
    });

    it("Check the proxy admin", async () => {
      let r = await web3.eth.getStorageAt(
        proxyExchangeAddress,
        "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
      );
      assert.equal(r, token.address.toLowerCase()); // admin of the proxy exchange is the token contract
    });

    // it("Check proxy admin", async () => {
    //   let proxy = await ProxyAndStorageForERC1155Exchange.at(proxyExchangeAddress)
    //   assert.equal(await proxy.admin(), token.address, { from: shareholder }) // reverts
    // })

    it("Upgrade", async () => {
      await token.upgrade(proxyExchangeAddress, mock.address, { from: owner });
      //  ProxyAdmin          Proxy      new implementation

      assert.equal(
        await token.tokenIdToProxyExchange(1),
        proxyExchangeAddress,
        { from: shareholder }
      );

      newExchange = await MockERC1155ExchangeImplementationV2.at(
        proxyExchangeAddress
      );
      await truffleAssert.reverts(
        newExchange.myFunction({ from: shareholder }),
        "Mock reverts!"
      );
    });
  });
});
