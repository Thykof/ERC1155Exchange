const truffleAssert = require('truffle-assertions')
const Web3 = require('web3')

const web3 = new Web3(Web3.givenProvider)

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
    const {logs} = await tokens.newToken(owner, tokenId, 1)
    exchangeAddress = logs.find(l => l.event == "TokenCreated")
    .args.exchangeAddress
    await tokens.setApprovalForAll(exchangeAddress, true, { from: owner })
    exchange = await ERC1155ExchangeImplementationV1.at(exchangeAddress)
  })

  it("Initially not paused", async () => {
    assert.equal(await tokens.paused(), false)
  })

  describe("When paused", async () => {
    before(async () => {
      await tokens.setPause(true)
    })

    it("Check if paused", async () => {
      assert.equal(await tokens.paused(), true)
    })

    it("Can't create token", async () => {
      await truffleAssert.reverts(
        tokens.newToken(owner, 2, 10),
        "Pausable: paused"
      )
    })

    it("Can't add order", async () => {
      await truffleAssert.reverts(
        exchange.addOrder(false, price, 10),
        "ERC1155Exchange: ERC1155 is paused"
      )
    })

    it("Can't transfert token", async () => {
      await truffleAssert.reverts(
        tokens.safeTransferFrom(owner, shareholder, tokenId, 1, 0),
        "ERC1155Pausable: token transfer while paused"
      )
    })

    it("User can't unpause", async () => {
      await truffleAssert.reverts(
        tokens.setPause(false, { from: shareholder }),
        "Ownable: caller is not the owner"
      )
    })

    it("Owner unpause", async () => {
      await tokens.setPause(false, { from: owner }),
      assert.equal(await tokens.paused(), false)
    })
  })
})
