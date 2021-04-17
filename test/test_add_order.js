const truffleAssert = require('truffle-assertions')

const { checkNullOrder, checkOrderAdded, checkTradeExecuted } = require('./utils')

const TradableERC1155Token = artifacts.require('TradableERC1155Token')
const ProxyAndStorageForERC1155Exchange = artifacts.require('ProxyAndStorageForERC1155Exchange')
const ERC1155ExchangeImplementationV1 = artifacts.require('ERC1155ExchangeImplementationV1')

contract("ERC1155", accounts => {

  const [owner, shareholder] = accounts
  let tokenId = 1
  const price = 700
  const amount = 2
  let tokens
  let exchange
  let exchangeAddress

  before(async () => {
    implementation = await ERC1155ExchangeImplementationV1.new()
    tokens = await TradableERC1155Token.new(implementation.address)
  })

  describe("Test reverts", async () => {
    before(async () => {
      const {logs} = await tokens.newToken(owner, tokenId, 300)

      exchangeAddress = logs.find(l => l.event == "TokenCreated")
        .args.exchangeAddress
      exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
    })

    it("Must revert: missing approval", async () => {
      await truffleAssert.reverts(
        exchange.addOrder(false, price, amount,
          { value: price * amount, from: shareholder }),
        'ERC1155Exchange: sender has not approved exchange contract'
      )
    })

    it("Must revert: amount is 0", async () => {
      await truffleAssert.reverts(
        exchange.addOrder(false, price, 0,
          { value: 0, from: shareholder }),
        'ERC1155Exchange: amount must be over zero'
      )
    })

    it("Must revert: not paid", async () => {
      await tokens.setApprovalForAll(exchangeAddress, true, { from: shareholder })

      await truffleAssert.reverts(
        exchange.addOrder(true, price, amount,
          { value: 0, from: shareholder }),
        'ERC1155Exchange: invalid amount wei sent'
      )

      await truffleAssert.reverts(
        exchange.addOrder(true, price, amount,
          { value: 699, from: shareholder }),
        'ERC1155Exchange: invalid amount wei sent'
      )

      await exchange.addOrder(false, 10, 1,
        { value: price, from: shareholder })
    })
  })
})
