const truffleAssert = require("truffle-assertions");

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

contract("ERC1155 Exchange (trade)", accounts => {
  const [owner, shareholder] = accounts;
  let tokenId = 1;
  const price = 700;
  let tokens;
  let exchange;
  let exchangeAddress;

  before(async () => {
    implementation = await ERC1155ExchangeImplementationV1.new();
    tokens = await TradableERC1155Token.new(implementation.address);
  });

  describe("Simple transaction", async () => {
    before(async () => {
      const { logs } = await tokens.newToken(owner, tokenId, 300);

      exchangeAddress = logs.find(l => l.event == "TokenCreated").args
        .exchangeAddress;
      await tokens.setApprovalForAll(exchangeAddress, true, { from: owner });
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress);
      await exchange.depositFeeCredit({ value: 42, from: shareholder });
      await exchange.addOrder(false, price, 10, { from: owner });
    });

    it("Check approval", async () => {
      assert.equal(await tokens.isApprovedForAll(owner, exchangeAddress), true);
    });

    it("Buy 2 tokens", async () => {
      const amount = 2;
      const result = await exchange.addOrder(true, price, amount, {
        value: price * amount,
        from: shareholder
      });

      checkOrderAdded(
        result,
        exchangeAddress,
        tokenId,
        price,
        amount,
        shareholder,
        true
      );
      checkTradeExecuted(
        result,
        exchangeAddress,
        tokenId,
        price,
        amount,
        shareholder,
        owner,
        shareholder
      );

      assert.equal(await exchange.pendingWithdrawals(owner), price * amount);
    });
  });

  describe("Complex transactions", async () => {
    before(async () => {
      tokenId = 2;
      const amount = 10;

      const { logs } = await tokens.newToken(owner, tokenId, 300);

      exchangeAddress = logs.find(l => l.event == "TokenCreated").args
        .exchangeAddress;
      await tokens.setApprovalForAll(exchangeAddress, true, { from: owner });
      await tokens.setApprovalForAll(exchangeAddress, true, {
        from: shareholder
      });
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress);
      await exchange.depositFeeCredit({ value: 50, from: owner });
      await exchange.depositFeeCredit({ value: 290, from: shareholder });
      await exchange.addOrder(false, price, amount, { from: owner });
    });

    it("Buy all", async () => {
      const amount = 10;
      let result = await exchange.addOrder(true, price, amount, {
        value: price * amount,
        from: shareholder
      });

      checkOrderAdded(
        result,
        exchangeAddress,
        tokenId,
        price,
        amount,
        shareholder,
        true
      );
      checkTradeExecuted(
        result,
        exchangeAddress,
        tokenId,
        price,
        amount,
        shareholder,
        owner,
        shareholder
      );

      assert.equal(await exchange.pendingWithdrawals(owner), price * amount);
    });

    it("Orderbooks must be empty", async () => {
      result = await exchange.getBestOrder(true);
      checkNullOrder(result);
      result = await exchange.getBestOrder(false);
      checkNullOrder(result);
    });

    it("Check fees credit", async () => {
      assert.equal((await exchange.feesCredits(shareholder)).toNumber(), 80);
      assert.equal((await exchange.bonusFeesCredits(owner)).toNumber(), 70);
    });

    it("Order: sell 5", async () => {
      // Sell order
      result = await exchange.addOrder(false, 800, 5, { from: shareholder });
      checkOrderAdded(
        result,
        exchangeAddress,
        tokenId,
        800,
        5,
        shareholder,
        false
      );

      // Buy order
      result = await exchange.addOrder(true, 800, 10, {
        value: 800 * 10,
        from: owner
      });
      checkOrderAdded(result, exchangeAddress, tokenId, 800, 10, owner, true);
      checkTradeExecuted(
        result,
        exchangeAddress,
        tokenId,
        800,
        5,
        owner,
        shareholder,
        owner
      );
      assert.equal((await exchange.feesCredits(owner)).toNumber(), 0);
      assert.equal((await exchange.bonusFeesCredits(owner)).toNumber(), 0);
      assert.equal(
        (await exchange.bonusFeesCredits(shareholder)).toNumber(),
        40
      );
      assert.equal(
        (await exchange.pendingWithdrawals(shareholder)).toNumber(),
        800 * 5
      );

      // Check orderbooks
      // buy side
      result = await exchange.getBestOrder(true);
      assert.notEqual(result.timestamp.toNumber(), 0);
      assert.equal(result.bestPrice.toNumber(), 800);
      assert.equal(result.amount.toNumber(), 5);
      assert.equal(result.makerAccount, owner);

      // Sell side
      result = await exchange.getBestOrder(false);
      checkNullOrder(result);

      // 2nd sell order
      result = await exchange.addOrder(false, 800, 5, { from: shareholder });
      checkOrderAdded(
        result,
        exchangeAddress,
        tokenId,
        800,
        5,
        shareholder,
        false
      );
      checkTradeExecuted(
        result,
        exchangeAddress,
        tokenId,
        800,
        5,
        owner,
        shareholder,
        shareholder
      );

      result = await exchange.getBestOrder(true);
      checkNullOrder(result);
      result = await exchange.getBestOrder(false);
      checkNullOrder(result);
    });

    it("Fees credits must be zero", async () => {
      assert.equal((await exchange.feesCredits(owner)).toNumber(), 0);
      assert.equal((await exchange.feesCredits(shareholder)).toNumber(), 0);
    });
  });

  describe("2nd order on same price", async () => {
    before(async () => {
      tokenId = 601;
      const { logs } = await tokens.newToken(owner, tokenId, 300);

      exchangeAddress = logs.find(l => l.event == "TokenCreated").args
        .exchangeAddress;
      await tokens.setApprovalForAll(exchangeAddress, true, { from: owner });
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress);
      await exchange.depositFeeCredit({ value: 10000, from: shareholder });
    });

    it("Add 2 orders with same price and fill them", async () => {
      await exchange.addOrder(false, price, 3, { from: owner });
      await exchange.addOrder(false, price, 7, { from: owner });

      let result = await exchange.addOrder(true, price, 9, {
        value: price * 9,
        from: shareholder
      });
      checkOrderAdded(
        result,
        exchangeAddress,
        tokenId,
        price,
        9,
        shareholder,
        true
      );
      checkTradeExecuted(
        result,
        exchangeAddress,
        tokenId,
        price,
        3,
        shareholder,
        owner,
        shareholder
      );
      checkTradeExecuted(
        result,
        exchangeAddress,
        tokenId,
        price,
        6,
        shareholder,
        owner,
        shareholder
      );
    });

    it("2nd Order must be partially fillder", async () => {
      let result;

      // bids orderbook is empty
      result = await exchange.getBestOrder(true);
      checkNullOrder(result);

      // asks: amount of 1 remaining
      result = await exchange.getBestOrder(false);
      assert.notEqual(result.timestamp.toNumber(), 0);
      assert.equal(result.bestPrice.toNumber(), price);
      assert.equal(result.amount.toNumber(), 1);
      assert.equal(result.makerAccount, owner);
    });
  });
});
