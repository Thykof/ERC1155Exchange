pragma solidity 0.6.2;

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

    OrderBookLibrary.OrderBook private orderBook; // TODO: reset this in beforEach hook

    function testAddOrder1() public {
        orderBook.buySide = true;

        uint256 orderCounter = orderBook.addOrder(520, 5, tx.origin);

        Assert.equal(
            orderCounter,
            1,
            "orderCounter should be 1"
        );

        Assert.equal(
            orderBook.prices.first(),
            520,
            "First price should be 520"
        );

        Assert.equal(
            orderBook.prices.last(),
            520,
            "Last price should be 520"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].queue.first,
            1,
            "queue first should be initialized to 1"
        );

        // test orderList.push()
        Assert.equal(
            orderBook.pricesToOrderList[520].keyToOrder[1].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].keyToOrder[1].amount,
            5,
            "amount should be 5"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].keyToOrder[1].makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].queue.first,
            1,
            "head should be 1"
        );
    }

    function testAddOrder2() public {
        uint256 orderCounter = orderBook.addOrder(520, 10, tx.origin);

        Assert.equal(
            orderCounter,
            2,
            "orderCounter should be 2"
        );

        Assert.equal(
            orderBook.prices.first(),
            520,
            "First price should be 520"
        );
        Assert.equal(
            orderBook.prices.last(),
            520,
            "Last price should be 520"
        );

        // test orderList.push()
        Assert.equal(
            orderBook.pricesToOrderList[520].keyToOrder[2].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].keyToOrder[2].amount,
            10,
            "amount should be 10"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].keyToOrder[2].makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].queue.last,
            2,
            "last should be 2"
        );
    }

    function testAddOrder3() public {
        uint256 orderCounter = orderBook.addOrder(600, 5, tx.origin);

        Assert.equal(
            orderCounter,
            1,
            "orderCounter should be 1"
        );

        Assert.equal(
            orderBook.prices.first(),
            520,
            "First price should be 520"
        );
        Assert.equal(
            orderBook.prices.last(),
            600,
            "Last price should be 600"
        );

        // test orderList.push()
        Assert.equal(
            orderBook.pricesToOrderList[600].keyToOrder[1].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
        );
        Assert.equal(
            orderBook.pricesToOrderList[600].keyToOrder[1].amount,
            5,
            "amount should be 10"
        );
        Assert.equal(
            orderBook.pricesToOrderList[600].keyToOrder[1].makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
        Assert.equal(
            orderBook.pricesToOrderList[600].queue.last,
            1,
            "last should be 1"
        );
    }

    function testGetBestOrder() public {
        (
            uint256 timestamp,
            uint256 price,
            uint256 amount,
            address makerAccount
        ) = orderBook.getBestOrder();

        Assert.notEqual(
            timestamp,
            0,
            "timestamp should not be 0"
        );
        Assert.equal(
            price,
            600,
            "price should be 600"
        );
        Assert.equal(
            amount,
            5,
            "amount should be 5"
        );
        Assert.equal(
            makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
    }

    function testCheckForMatchingOrder() public {
        Assert.equal(
            orderBook.checkForMatchingOrder(520),
            true,
            "order with price 520 exists."
        );

        Assert.equal(
            orderBook.checkForMatchingOrder(10),
            false,
            "order with price 10 does not exist."
        );
    }

    function testCloseFirstOrderAtPrice() public {
        orderBook.closeFirstOrderAtPrice(600);
        Assert.equal(
            orderBook.prices.exists(600),
            false,
            "600 price does not exists in tree price"
        );
    }

    function testUpdateAmount() public {
        orderBook.updateAmount(520, 2, 7);

        Assert.notEqual(
            orderBook.pricesToOrderList[520].keyToOrder[2].timestamp,
            0,
            "timestamp should be not be 0"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].keyToOrder[2].amount,
            7,
            "amount should be 7"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].keyToOrder[2].makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
        Assert.equal(
            orderBook.pricesToOrderList[520].queue.last,
            2,
            "last should be 2"
        );
    }
}
