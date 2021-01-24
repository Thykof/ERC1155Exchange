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
  })
})
