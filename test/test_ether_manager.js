const truffleAssert = require('truffle-assertions')
const Web3 = require('web3')

const web3 = new Web3(Web3.givenProvider)

const TradableERC1155Token = artifacts.require('TradableERC1155Token')
const ProxyAndStorageForERC1155Exchange = artifacts.require('ProxyAndStorageForERC1155Exchange')
const ERC1155ExchangeImplementationV1 = artifacts.require('ERC1155ExchangeImplementationV1')

contract("ERC1155 EtherManager", accounts => {

  const [owner, shareholder] = accounts
  let tokenId = 1
  let price = 700
  let amount = 25000000
  let tokens
  let exchange
  let exchangeAddress

  before(async () => {
    implementation = await ERC1155ExchangeImplementationV1.new()
    tokens = await TradableERC1155Token.new(implementation.address)
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
      let balanceBefore = web3.utils.toBN(await web3.eth.getBalance(shareholder))

      let gasUsed = web3.utils.toBN((
        await exchange.withdrawFeeCredit(amount, { from: shareholder })
      ).receipt.gasUsed);

      let balanceAfter = web3.utils.toBN(await web3.eth.getBalance(shareholder))

      let gasPrice = web3.utils.toBN(await web3.eth.getGasPrice())
      let gasSpend = gasUsed.mul(gasPrice)
      let expectedBalance = balanceBefore.sub(web3.utils.toBN(gasSpend)).add(web3.utils.toBN(amount))

      assert.isTrue(balanceAfter.eq(expectedBalance))
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
      await exchange.addOrder(false, price, amount, { from: owner }) // owner place sell order
      await exchange.addOrder(true, price, amount, { value: price * amount, from: shareholder }) // shareholder buy

      let actualPendingWithdrawals = web3.utils.toBN((await exchange.pendingWithdrawals(owner)))
      let expectedPendingWithdrawals = web3.utils.toBN(price).mul(web3.utils.toBN(amount))
      assert.isTrue(
        actualPendingWithdrawals.eq(expectedPendingWithdrawals),
        'check pending withdrawals (equality)'
      )

      let gasPrice = web3.utils.toBN(await web3.eth.getGasPrice())

      let balanceBefore = web3.utils.toBN((await web3.eth.getBalance(owner)));
      let gasUsed = web3.utils.toBN((await exchange.withdraw({ from: owner })).receipt.gasUsed);
      let balanceAfter = web3.utils.toBN((await web3.eth.getBalance(owner)));
      let gasSpend = gasUsed.mul(gasPrice)
      let expectedBalance = balanceBefore.sub(gasSpend).add(expectedPendingWithdrawals)
      assert.isTrue(
        balanceAfter.eq(expectedBalance),
        'check balances (equality)'
      )
    })
  })

  describe("Fee rate", async () => {
    before(async () => {
      tokenId = 5
      const {logs} = await tokens.newToken(owner, tokenId, amount)

      exchangeAddress = logs.find(l => l.event == "TokenCreated")
        .args.exchangeAddress

      await tokens.setApprovalForAll(exchangeAddress, true, { from: owner })
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
      await exchange.depositFeeCredit({ value: price * amount / 100 * 3, from: shareholder })

    })

    it("Set new fee rate", async () => {
      await exchange.setFeeRate(9, { from: owner })
      assert.equal((await exchange.feeRate()).toNumber(), 9)
    })

    it("Must revert if caller is not operator", async () => {
      await truffleAssert.reverts(
        exchange.setFeeRate(12, { from: shareholder }),
        'ERC1155Exchange: caller is not operator'
      )
    })
  })
})
