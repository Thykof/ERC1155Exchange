const truffleAssert = require('truffle-assertions')

const ERC1155Token = artifacts.require('ERC1155Token')
const ProxyAndStorageForERC1155Exchange = artifacts.require('ProxyAndStorageForERC1155Exchange')
const ERC1155ExchangeImplementationV1 = artifacts.require('ERC1155ExchangeImplementationV1')

contract("ERC1155ExchangeOrderBook", accounts => {

  const [owner, shareholder] = accounts
  let tokenId = 1
  const price = 700
  const amount = 2
  let tokens
  let exchange
  let exchangeAddress

  before(async () => {
    implementation = await ERC1155ExchangeImplementationV1.new()
    tokens = await ERC1155Token.new(implementation.address)

    const {logs} = await tokens.newToken(owner, tokenId, 300)

    exchangeAddress = logs.find(l => l.event == "TokenCreated")
    .args.exchangeAddress
    exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
    await tokens.setApprovalForAll(exchangeAddress, true, { from: owner })
    await tokens.setApprovalForAll(exchangeAddress, true, { from: shareholder })
    await exchange.depositFeeCredit({ value: 500, from: owner })
    await exchange.depositFeeCredit({ value: 2090, from: shareholder })
  })

  describe("Test getNextPrice", async () => {
    it("When no order", async () => {
      assert.equal(await exchange.getNextPrice(false, 1), 0)
      assert.equal(await exchange.getNextPrice(true, 1000000), 0)
    })

    it("When only one price", async () => {
      // sell side
      await exchange.addOrder(false, price, amount, { from: owner })
      result = await exchange.getBestOrder(false)
      assert.equal(result.bestPrice.toNumber(), price)

      result = await exchange.getNextPrice(false, result.bestPrice.toNumber())
      assert.equal(result.toNumber(), 0)

      // buy side
      await exchange.addOrder(true, 500, amount, { from: owner, value: 500*amount })
      result = await exchange.getBestOrder(true)
      assert.equal(result.bestPrice.toNumber(), 500)

      result = await exchange.getNextPrice(true, result.bestPrice.toNumber())
      assert.equal(result.toNumber(), 0)
    })

    it("When 2 orders at same price", async () => {
      // sell side
      await exchange.addOrder(false, price, amount, { from: owner })

      // best order is still `price`
      result = await exchange.getBestOrder(false)
      assert.equal(result.bestPrice.toNumber(), price)

      assert.equal((await exchange.getNextPrice(false, price)).toNumber(), 0)

      // buy side
      await exchange.addOrder(true, 500, amount, { from: owner, value: 500*amount })

      // best order is still `price`
      result = await exchange.getBestOrder(true)
      assert.equal(result.bestPrice.toNumber(), 500)

      assert.equal((await exchange.getNextPrice(true, 500)).toNumber(), 0)
    })

    it("When 2 orders at different prices", async () => {
      // sell side
      await exchange.addOrder(false, price+10, amount, { from: owner })

      // best order is still `price`
      result = await exchange.getBestOrder(false)
      assert.equal(result.bestPrice.toNumber(), price)

      assert.equal((await exchange.getNextPrice(false, price)).toNumber(), price+10)


      // buy side
      await exchange.addOrder(true, 490, amount, { from: owner, value: 490*amount })

      // best order is still `price`
      result = await exchange.getBestOrder(true)
      assert.equal(result.bestPrice.toNumber(), 500)

      assert.equal((await exchange.getNextPrice(true, 500)).toNumber(), 490)
    })
  })

  describe("Test getOrderAtPrice", async () => {
    it("When no order", async () => {
      assert.equal(await exchange.getOrderAtPrice(false, 1), 0)
      assert.equal(await exchange.getOrderAtPrice(true, 1000000), 0)
    })
  })
})
