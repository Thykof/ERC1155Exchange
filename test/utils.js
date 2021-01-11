const truffleAssert = require('truffle-assertions')

const { ZERO_ADDRESS } = require('./constants')

const checkNullOrder = result => {
  assert.equal(result['0'].toNumber(), 0)
  assert.equal(result['1'].toNumber(), 0)
  assert.equal(result['2'].toNumber(), 0)
  assert.equal(result['3'], ZERO_ADDRESS)
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
  partiallyFilled,
  buySide
) => {
  let event

  event = result.logs.find(l => l.event === 'OrderFilled')
  assert.equal(event.args.tokenId.toNumber(), tokenId)
  assert.equal(event.args.partiallyFilled, partiallyFilled)
  assert.equal(event.args.buySide, buySide)
  assert.equal(event.args.price.toNumber(), price)
  assert.equal(event.args.amount.toNumber(), amount)
  assert.equal(event.args.makerAccount, seller)
  assert.equal(event.args.takerAccount, buyer)

  event = result.logs.find(l => l.event === 'TradeExecuted')
  assert.equal(event.args.tokenId.toNumber(), tokenId)
  assert.equal(event.args.buySide, buySide)
  assert.equal(event.args.amount.toNumber(), amount)
  assert.equal(event.args.buyerAccount, buyer)
  assert.equal(event.args.sellerAccount, seller)
  assert.equal(event.args.pendingWithdrawals.toNumber(), price * amount)

  event = result.logs.find(l => l.event === 'TransferSingle')
  assert.equal(event.args.operator, exchangeAddress)
  assert.equal(event.args.from, seller)
  assert.equal(event.args.to, buyer)
  assert.equal(event.args.id.toNumber(), tokenId)
  assert.equal(event.args.value.toNumber(), amount)
}

module.exports.checkNullOrder = checkNullOrder
module.exports.checkOrderAdded = checkOrderAdded
module.exports.checkTradeExecuted = checkTradeExecuted
