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

  before(async () => {
    implementation = await ERC1155ExchangeImplementationV1.new()
    tokens = await ERC1155Token.new(implementation.address)
  })

  describe("Test token creation", async () => {
    it("Only owner can create", async () => {
      await truffleAssert.reverts(
        tokens.newToken(owner, 1, 300, { from: shareholder }),
        "ERC1155Token: Sender is not contract owner"
      )
    })

    it("Token id is not zero", async () => {
      await truffleAssert.reverts(
        tokens.newToken(owner, 0, 300, { from: owner }),
        "ERC1155Token: tokenId can't be zero"
      )
    })

    it("Can't create twice", async () => {
      await tokens.newToken(owner, 1, 300, { from: owner })

      await truffleAssert.reverts(
        tokens.newToken(owner, 1, 300, { from: owner }),
        "ERC1155Token: token already created"
      )
    })
  })
})
