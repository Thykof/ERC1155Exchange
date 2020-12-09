pragma solidity 0.6.0;

import "./OrderBookLibrary.sol";


contract Test {
    using OrderBookLibrary for OrderBookLibrary.OrderBook;

    event LogOrder(uint256 timestamp, uint256 price, uint256 amount, address makerAccount);
    event Log(uint256 value);

    OrderBookLibrary.OrderBook private bids;

    enum TokenState {
        NULL,
        CREATED,
        LAUNCHED,
        TRADING,
        RETIRED
    }

    struct Work {
        uint256 initialPrice;
        address owner;
        TokenState tokenState;
    }

    function newOrder(uint256 price, uint256 amount, address makerAccount)
        public
    {
        // TODO: check if there is a matching order
        bids.addOrder(price, amount, makerAccount);
    }

    function getBestOrder()
        public
        // view
        returns (uint256 timestamp,
        uint256 price,
        uint256 amount,
        address makerAccount)
    {
        (timestamp, price, amount, makerAccount) = bids.getBestOrder();
    }
}
