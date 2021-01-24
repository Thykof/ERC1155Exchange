const truffleAssert = require('truffle-assertions')

const { ZERO_ADDRESS } = require('./constants')

const checkNullOrder = result => {
  assert.equal(result.timestamp.toNumber(), 0)
  assert.equal(result.bestPrice.toNumber(), 0)
  assert.equal(result.amount.toNumber(), 0)
  assert.equal(result.makerAccount, ZERO_ADDRESS)
}

const checkOrderAdded = (result,
  exchangeAddress,
  tokenId,
  price,
  amount,
  maker,
  buySide
) => {
  let event = result.logs.find(l => l.event === 'OrderAdded')
  assert.equal(event.args.tokenId.toNumber(), tokenId)
  assert.equal(event.args.buySide, buySide)
  assert.equal(event.args.price.toNumber(), price)
  assert.equal(event.args.amount.toNumber(), amount)
  assert.equal(event.args.makerAccount, maker)
}

const checkTradeExecuted = (
  result,
  exchangeAddress,
  tokenId,
  price,
  amount,
  buyer,
  seller,
  taker
) => {
  let event = result.logs.find(l => {
    if (l.event === 'TradeExecuted') {
      return l.args.amount.toNumber() === amount
    }
    return false
  })
  assert.notEqual(event, undefined, "Event TradeExecuted not emited")
  assert.equal(event.args.tokenId.toNumber(), tokenId)
  assert.equal(event.args.price.toNumber(), price)
  assert.equal(event.args.amount.toNumber(), amount) // checked in the find()
  assert.equal(event.args.buyer, buyer)
  assert.equal(event.args.seller, seller)
  assert.equal(event.args.taker, taker)
  assert.equal(event.args.paidFees.toNumber(), price * amount * 0.03)


  event = result.logs.find(l => {
    if (l.event === 'TransferSingle') {
      return l.args.value.toNumber() === amount
    }
    return false
  })
  assert.notEqual(event, undefined, "Event TradeExecuted not emited")
  assert.equal(event.args.operator, exchangeAddress)
  assert.equal(event.args.from, seller)
  assert.equal(event.args.to, buyer)
  assert.equal(event.args.id.toNumber(), tokenId)
  assert.equal(event.args.value.toNumber(), amount) // checked in the find()
}

module.exports.checkNullOrder = checkNullOrder
module.exports.checkOrderAdded = checkOrderAdded
module.exports.checkTradeExecuted = checkTradeExecuted
