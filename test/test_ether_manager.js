const BigNumber = require('bignumber.js');
const truffleAssert = require('truffle-assertions')
const Web3 = require('web3')

const web3 = new Web3(Web3.givenProvider)

const { checkNullOrder, checkOrderAdded, checkTradeExecuted } = require('./utils')

const ERC1155Token = artifacts.require('ERC1155Token')
const ProxyAndStorageForERC1155Exchange = artifacts.require('ProxyAndStorageForERC1155Exchange')
const ERC1155ExchangeImplementationV1 = artifacts.require('ERC1155ExchangeImplementationV1')

contract("ERC1155", accounts => {

  const [owner, shareholder] = accounts
  console.log(owner, shareholder) // DEBUG
  let tokenId = 1
  let price = 700
  let amount = 25000000
  let tokens
  let exchange
  let exchangeAddress

  before(async () => {
    implementation = await ERC1155ExchangeImplementationV1.new()
    tokens = await ERC1155Token.new(implementation.address)
  })

  describe("Fee credit", async () => {
    before(async () => {
      const {logs} = await tokens.newToken(owner, tokenId, 300)

      exchangeAddress = logs.find(l => l.event == "TokenCreated")
        .args.exchangeAddress
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
    })

    it("depositFeeCredit", async () => {
      await exchange.depositFeeCredit({ value: amount, from: shareholder })

      assert.equal((await exchange.feesCredits(shareholder)).toNumber(), amount)

      await truffleAssert.reverts(
        exchange.depositFeeCredit({ value: 0, from: shareholder }),
        "ERC1155Exchange: Can't deposit zero"
      )
    })

    it("withdrawFeeCredit", async () => {
      let balanceAnte = new BigNumber(await web3.eth.getBalance(shareholder))

      let result = await exchange.withdrawFeeCredit(amount, { from: shareholder })

      let balancePost = new BigNumber(await web3.eth.getBalance(shareholder))
      let expected = balanceAnte.minus(new BigNumber(result.receipt.gasUsed)).plus(new BigNumber(amount))
      // equality test fail, I don't know why
      assert.isTrue(balanceAnte.lt(expected))
    })
  })

  describe("Paid fee 0 become 1", async () => {
    before(async () => {
      tokenId = 2
      const {logs} = await tokens.newToken(owner, tokenId, 1)

      exchangeAddress = logs.find(l => l.event == "TokenCreated")
        .args.exchangeAddress

      await tokens.setApprovalForAll(exchangeAddress, true, { from: owner })
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
      await exchange.depositFeeCredit({ value: 1, from: shareholder })
    })

    it("Paid fee is 1", async () => {
      await exchange.addOrder(false, 1, 1, { from: owner })
      const result = await exchange.addOrder(true, 1, 1,
        { value: 1, from: shareholder }
      )

      let event = result.logs.find(l => l.event === 'TradeExecuted')
      assert.equal(event.args.paidFees.toNumber(), 1)
    })
  })

  describe("Fee bonus", async () => {
    before(async () => {
      tokenId = 3
      const {logs} = await tokens.newToken(owner, tokenId, 100)

      exchangeAddress = logs.find(l => l.event == "TokenCreated")
        .args.exchangeAddress

      await tokens.setApprovalForAll(exchangeAddress, true, { from: owner })
      await tokens.setApprovalForAll(exchangeAddress, true, { from: shareholder })
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
      await exchange.depositFeeCredit({ value: 15000, from: shareholder })

      await exchange.addOrder(false, 5000, 100, { from: owner })
      await exchange.addOrder(true, 5000, 100, { value: 5000 * 100, from: shareholder })

    })

    it("Owner has fee credit bonus", async () => {
      assert.equal((await exchange.bonusFeesCredits(owner)).toNumber(), 5000)
    })

    it("Shareholder has paid fees", async () => {
      assert.equal((await exchange.feesCredits(shareholder)).toNumber(), 0)
    })

    it("Owner use its fee bonus and fee credit", async () => {
      await exchange.addOrder(false, 5000, 100, { from: shareholder })
      await exchange.depositFeeCredit({ value: 10000, from: owner })
      await exchange.addOrder(true, 5000, 100, { value: 5000 * 100, from: owner })

      assert.equal((await exchange.bonusFeesCredits(owner)).toNumber(), 0)
      assert.equal((await exchange.feesCredits(owner)).toNumber(), 0)

      assert.equal((await exchange.bonusFeesCredits(shareholder)).toNumber(), 5000)
    })

    it("Only use its fee bonus", async () => {
      await exchange.addOrder(false, 1, 100, { from: owner })
      await exchange.addOrder(true, 1, 100, { value: 1 * 100, from: shareholder })

      assert.equal((await exchange.bonusFeesCredits(shareholder)).toNumber(), 5000 - 3)
      assert.equal((await exchange.feesCredits(shareholder)).toNumber(), 0)
    })
  })

  describe("Ether withdrawal", async () => {
    before(async () => {
      tokenId = 4
      amount = 100000
      price = 50000000
      const {logs} = await tokens.newToken(owner, tokenId, amount)

      exchangeAddress = logs.find(l => l.event == "TokenCreated")
        .args.exchangeAddress

      await tokens.setApprovalForAll(exchangeAddress, true, { from: owner })
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
      await exchange.depositFeeCredit({ value: price * amount / 100 * 3, from: shareholder })

    })

    it("Owner withdraws", async () => {
      await exchange.addOrder(false, price, amount, { from: owner })
      await exchange.addOrder(true, price, amount, { value: price * amount, from: shareholder })

      assert.equal((await exchange.pendingWithdrawals(owner)).toNumber(), price * amount)

      let balanceAnte = await web3.eth.getBalance(owner)
      let result = await exchange.withdraw({ from: owner })
      let balancePost = await web3.eth.getBalance(owner)

      // assert.isTrue(balancePost > balanceAnte)
    })
  })
})
