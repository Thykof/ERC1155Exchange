const truffleAssert = require('truffle-assertions')

const { ZERO_ADDRESS } = require('./constants')

const checkNullOrder = result => {
  assert.equal(result['0'].toNumber(), 0)
  assert.equal(result['1'].toNumber(), 0)
  assert.equal(result['2'].toNumber(), 0)
  assert.equal(result['3'], ZERO_ADDRESS)
}

const checkTradeExecuted = (result, exchangeAddress, tokenId, price, amount, seller, buyer) => {
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
}

module.exports.checkNullOrder = checkNullOrder
module.exports.checkTradeExecuted = checkTradeExecuted
