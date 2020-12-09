pragma solidity 0.6.0;

import "truffle/Assert.sol";
import "../contracts/OrderBookLibrary.sol";
import "../contracts/BokkyPooBahsRedBlackTreeLibrary.sol";
import "../contracts/QueueLibrary.sol";

import "@openzeppelin/contracts/utils/Counters.sol";


contract TestOrderBookLibrary {
    using OrderBookLibrary for OrderBookLibrary.OrderBook;
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    using Counters for Counters.Counter;
    using QueueLibrary for QueueLibrary.Queue;

    OrderBookLibrary.OrderBook private orderbook;

    function testAddOrder1() public {
        orderbook.addOrder(520, 10, tx.origin);

        Assert.equal(
            orderbook.prices.first(),
            520,
            "First price should be 520"
        );

        Assert.equal(
            orderbook.prices.last(),
            520,
            "Last price should be 520"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].queue.first,
            1,
            "queue first should be initialized to 1"
        );

        // test orderList.push()
        Assert.equal(
            orderbook.pricesToOrderList[520].counter.current(),
            1,
            "counter should be key"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[1].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[1].price,
            520,
            "price should be 520"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[1].amount,
            10,
            "amount should be 10"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[1].makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].queue.readHead(),
            1,
            "head should be 1"
        );
    }

    function testAddOrder2() public {
        orderbook.addOrder(520, 10, tx.origin);

        Assert.equal(
            orderbook.prices.first(),
            520,
            "First price should be 520"
        );
        Assert.equal(
            orderbook.prices.last(),
            520,
            "Last price should be 520"
        );

        // test orderList.push()
        Assert.equal(
            orderbook.pricesToOrderList[520].counter.current(),
            2,
            "counter should be key"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[2].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[2].price,
            520,
            "price should be 520"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[2].amount,
            10,
            "amount should be 10"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[2].makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].queue.last,
            2,
            "head should be 2"
        );
    }

    function testGetBestOrder() public {
        (
            uint256 timestamp,
            uint256 price,
            uint256 amount,
            address makerAccount
        ) = orderbook.getBestOrder();

        Assert.equal(
            orderbook.pricesToOrderList[520].queue.first,
            1,
            "queue first should be initialized to 1"
        );
    }
}
