const truffleAssert = require('truffle-assertions')

const { checkNullOrder, checkOrderAdded, checkTradeExecuted } = require('./utils')

const ERC1155Token = artifacts.require('ERC1155Token')
const ProxyAndStorageForERC1155Exchange = artifacts.require('ProxyAndStorageForERC1155Exchange')
const ERC1155ExchangeImplementationV1 = artifacts.require('ERC1155ExchangeImplementationV1')

contract("ERC1155", accounts => {

  const [owner, shareholder] = accounts
  console.log(owner, shareholder) // DEBUG
  let tokenId = 1
  const price = 700
  let tokens
  let exchange
  let exchangeAddress

  before(async () => {
    implementation = await ERC1155ExchangeImplementationV1.new()
    tokens = await ERC1155Token.new(implementation.address)
  })

  describe("Simple transaction", async () => {
    before(async () => {
      const {logs} = await tokens.newToken(owner, tokenId, 300)

      exchangeAddress = logs.find(l => l.event == "TokenCreated")
        .args.exchangeAddress
      await tokens.setApprovalForAll(exchangeAddress, true, { from: owner })
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
      await exchange.addOrder(false, price, 10, { from: owner })
    })

    it("Check approval", async () => {
      assert.equal(await tokens.isApprovedForAll(owner, exchangeAddress), true)
    })

    it("Buy one token", async () => {
      const amount = 2
      const result = await exchange.addOrder(true, price, amount,
        { value: price * amount, from: shareholder }
      )

      checkOrderAdded(result, exchangeAddress, tokenId, price, amount, shareholder, true)
      checkTradeExecuted(result, exchangeAddress, tokenId, price, amount, shareholder, owner, false, true)

      assert.equal(await exchange.pendingWithdrawals(owner), price * amount)
    })

  })

  describe("Complex transactions", async () => {
    before(async () => {
      tokenId = 2
      const amount = 10

      const {logs} = await tokens.newToken(owner, tokenId, 300)

      exchangeAddress = logs.find(l => l.event == "TokenCreated")
        .args.exchangeAddress
      await tokens.setApprovalForAll(exchangeAddress, true, { from: owner })
      await tokens.setApprovalForAll(exchangeAddress, true, { from: shareholder })
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
      await exchange.addOrder(false, price, 10, { from: owner })
    })

    it("Buy all", async () => {
      const amount = 10
      let result = await exchange.addOrder(true, price, amount,
        { value: price * amount, from: shareholder }
      )

      checkOrderAdded(result, exchangeAddress, tokenId, price, amount, shareholder, true)
      checkTradeExecuted(result, exchangeAddress, tokenId, price, amount, shareholder, owner, false, true)

      assert.equal(await exchange.pendingWithdrawals(owner), price * amount)

      result = await exchange.getBestOrder(true)
      checkNullOrder(result)
      result = await exchange.getBestOrder(false)
      checkNullOrder(result)
    })

    it("Orderbooks must be empty", async () => {
      result = await exchange.getBestOrder(true)
      checkNullOrder(result)
      result = await exchange.getBestOrder(false)
      checkNullOrder(result)
    })

    it("Order: sell 5", async () => {
      // Sell order
      await exchange.addOrder(false, 800, 5,
        { from: shareholder }
      )

      // Buy order
      result = await exchange.addOrder(true, 800, 10,
        { value: 800*10, from: owner }
      )
      checkOrderAdded(result, exchangeAddress, tokenId, 800, 10, owner, true)
      checkTradeExecuted(result, exchangeAddress, tokenId, 800, 5, owner, shareholder, true, true)

      // Check orderbooks
      // buy side
      result = await exchange.getBestOrder(true)
      assert.notEqual(result['0'].toNumber(), 0)
      assert.equal(result['1'].toNumber(), 800)
      assert.equal(result['2'].toNumber(), 5)
      assert.equal(result['3'], owner)

      // Sell side
      result = await exchange.getBestOrder(false)
      checkNullOrder(result)

      // 2nd sell order
      result = await exchange.addOrder(false, 800, 5,
        { from: shareholder }
      )
      checkOrderAdded(result, exchangeAddress, tokenId, 800, 5, shareholder, false)
      checkTradeExecuted(result, exchangeAddress, tokenId, 800, 5, owner, shareholder, false, false)

      result = await exchange.getBestOrder(true)
      checkNullOrder(result)
      result = await exchange.getBestOrder(false)
      console.log(result);
      checkNullOrder(result)
    })
  })
})
