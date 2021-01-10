const truffleAssert = require('truffle-assertions')

const ERC1155Tokens = artifacts.require('ERC1155Tokens')
const ERC1155Exchange = artifacts.require('ERC1155Exchange')

contract("ERC1155", accounts => {

  const [seller, buyer] = accounts
  console.log(seller, buyer) // DEBUG
  const tokenId = 1
  const price = 700
  let tokens
  let exchange
  let exchangeAddress

  describe("Simple transaction", async () => {
    before(async function () {
      tokens = await ERC1155Tokens.new()

      const {logs} = await tokens.newToken(seller, tokenId, 300)

      exchangeAddress = logs
      .find(l => l.event == "TokenCreated").args.exchangeAddress
      console.log(exchangeAddress);

      await tokens.setApprovalForAll(exchangeAddress, true, { from: seller })
      // await tokens.setApprovalForAll(exchangeAddress, true, { from: buyer })

      exchange = await ERC1155Exchange.at(exchangeAddress)
    })

    it("Check approval", async () => {
      assert.equal(await tokens.isApprovedForAll(seller, exchangeAddress), true)
    })

    it("Place a sell order", async () => {
      const {logs} = await exchange.addOrder(false, price, 10, { from: seller })
    })

    it("Buy one token", async () => {
      const amount = 2
      const result = await exchange.addOrder(true, price, amount,
        { value: price * amount, from: buyer })

      truffleAssert.eventEmitted(result, 'OrderAdded', ev =>
        ev.tokenId.toNumber() === tokenId &&
        ev.buySide === true &&
        ev.price.toNumber() === price &&
        ev.amount.toNumber() === amount &&
        ev.makerAccount === buyer
      )

      truffleAssert.eventEmitted(result, 'OrderFilled', ev =>
        ev.tokenId.toNumber() === tokenId &&
        ev.partiallyFilled === false &&
        ev.buySide === true &&
        ev.price.toNumber() === price &&
        ev.amount.toNumber() === amount &&
        ev.makerAccount === seller &&
        ev.takerAccount === buyer
      )

      truffleAssert.eventEmitted(result, 'TradeExecuted', ev =>
        ev.tokenId.toNumber() === tokenId &&
        ev.buySide === true &&
        ev.amount.toNumber() === amount &&
        ev.buyerAccount === buyer &&
        ev.sellerAccount === seller &&
        ev.pendingWithdrawals.toNumber() === price * amount
      )

      truffleAssert.eventEmitted(result, 'TransferSingle', ev =>
        ev.operator === exchangeAddress &&
        ev.from === seller &&
        ev.to === buyer &&
        ev.id.toNumber() === tokenId &&
        ev.value.toNumber() === amount
      )

      assert.equal(await exchange.pendingWithdrawals(seller), price * amount)
    })

  })

  describe("Complex transactions", async () => {
    before(async () => {
      tokens = await ERC1155Tokens.new()

      const {logs} = await tokens.newToken(seller, tokenId, 300)

      exchangeAddress = logs
      .find(l => l.event == "TokenCreated").args.exchangeAddress
      console.log(exchangeAddress);

      await tokens.setApprovalForAll(exchangeAddress, true, { from: seller })
      // await tokens.setApprovalForAll(exchangeAddress, true, { from: buyer })

      exchange = await ERC1155Exchange.at(exchangeAddress)
    })

    beforeEach(async () => {
      const {logs} = await exchange.addOrder(false, price, 10, { from: seller })
    })

    it("Buy all", async () => {
      const amount = 10
      const result = await exchange.addOrder(true, price, amount,
        { value: price * amount, from: buyer })

      truffleAssert.eventEmitted(result, 'OrderAdded', ev =>
        ev.tokenId.toNumber() === tokenId &&
        ev.buySide === true &&
        ev.price.toNumber() === price &&
        ev.amount.toNumber() === amount &&
        ev.makerAccount === buyer
      )

      truffleAssert.eventEmitted(result, 'OrderFilled', ev =>
        ev.tokenId.toNumber() === tokenId &&
        ev.partiallyFilled === false &&
        ev.buySide === true &&
        ev.price.toNumber() === price &&
        ev.amount.toNumber() === amount &&
        ev.makerAccount === seller &&
        ev.takerAccount === buyer
      )

      truffleAssert.eventEmitted(result, 'TradeExecuted', ev =>
        ev.tokenId.toNumber() === tokenId &&
        ev.buySide === true &&
        ev.amount.toNumber() === amount &&
        ev.buyerAccount === buyer &&
        ev.sellerAccount === seller &&
        ev.pendingWithdrawals.toNumber() === price * amount
      )

      truffleAssert.eventEmitted(result, 'TransferSingle', ev =>
        ev.operator === exchangeAddress &&
        ev.from === seller &&
        ev.to === buyer &&
        ev.id.toNumber() === tokenId &&
        ev.value.toNumber() === amount
      )

      assert.equal(await exchange.pendingWithdrawals(seller), price * amount)
    })
  })

})
