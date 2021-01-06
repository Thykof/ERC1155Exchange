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

    OrderBookLibrary.OrderBook private orderbook;

    function testAddOrder1() public {
        orderbook.buySide = true;

        orderbook.addOrder(520, 5, tx.origin);

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
            orderbook.pricesToOrderList[520].keyToOrder[1].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[1].amount,
            5,
            "amount should be 5"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].keyToOrder[1].makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
        Assert.equal(
            orderbook.pricesToOrderList[520].queue.first,
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
            orderbook.pricesToOrderList[520].keyToOrder[2].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
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
            "last should be 2"
        );
    }

    function testAddOrder3() public {
        orderbook.addOrder(600, 5, tx.origin);

        Assert.equal(
            orderbook.prices.first(),
            520,
            "First price should be 520"
        );
        Assert.equal(
            orderbook.prices.last(),
            600,
            "Last price should be 600"
        );

        // test orderList.push()
        Assert.equal(
            orderbook.pricesToOrderList[600].keyToOrder[1].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
        );
        Assert.equal(
            orderbook.pricesToOrderList[600].keyToOrder[1].amount,
            5,
            "amount should be 10"
        );
        Assert.equal(
            orderbook.pricesToOrderList[600].keyToOrder[1].makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
        Assert.equal(
            orderbook.pricesToOrderList[600].queue.last,
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
        ) = orderbook.getBestOrder();

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

    // function testGetOrder1() public {
    //     (
    //         uint256 timestamp,
    //         uint256 price,
    //         uint256 amount,
    //         address makerAccount
    //     ) = orderbook.getOrder(0);
    //
    //     Assert.equal(
    //         price,
    //         600,
    //         "price should be 600"
    //     );
    //     Assert.notEqual(
    //         timestamp,
    //         0,
    //         "timestamp should not be 0"
    //         );
    //     Assert.equal(
    //         amount,
    //         5,
    //         "amount should be 5"
    //     );
    //     Assert.equal(
    //         makerAccount,
    //         tx.origin,
    //         "makerAccount should be tx.origin"
    //     );
    // }
    //
    // function testGetOrder2() public {
    //     (
    //         uint256 timestamp,
    //         uint256 price,
    //         uint256 amount,
    //         address makerAccount
    //     ) = orderbook.getOrder(1);
    //
    //     Assert.equal(
    //         price,
    //         520,
    //         "price should be 520"
    //     );
    //     Assert.notEqual(
    //         timestamp,
    //         0,
    //         "timestamp should not be 0"
    //         );
    //     Assert.equal(
    //         amount,
    //         5,
    //         "amount should be 5"
    //     );
    //     Assert.equal(
    //         makerAccount,
    //         tx.origin,
    //         "makerAccount should be tx.origin"
    //     );
    // }
    //
    // function testGetOrder3() public {
    //     (
    //         uint256 timestamp,
    //         uint256 price,
    //         uint256 amount,
    //         address makerAccount
    //     ) = orderbook.getOrder(2);
    //
    //     Assert.equal(
    //         price,
    //         520,
    //         "price should be 520"
    //     );
    //     Assert.notEqual(
    //         timestamp,
    //         0,
    //         "timestamp should not be 0"
    //         );
    //     Assert.equal(
    //         amount,
    //         10,
    //         "amount should be 10"
    //     );
    //     Assert.equal(
    //         makerAccount,
    //         tx.origin,
    //         "makerAccount should be tx.origin"
    //     );
    // }
    //
    // function testGetOrder4() public {
    //     (
    //         uint256 timestamp,
    //         uint256 price,
    //         uint256 amount,
    //         address makerAccount
    //     ) = orderbook.getOrder(3);
    //
    //     Assert.equal(
    //         price,
    //         0,
    //         "price should be 0"
    //     );
    //     Assert.equal(
    //         timestamp,
    //         0,
    //         "timestamp should be 0"
    //         );
    //     Assert.equal(
    //         amount,
    //         0,
    //         "amount should be 0"
    //     );
    //     Assert.equal(
    //         makerAccount,
    //         address(0),
    //         "makerAccount should be the 0 address"
    //     );
    // }

    function testCheckForMatchingOrder() public {
        Assert.equal(
            orderbook.checkForMatchingOrder(520),
            true,
            "order with price 520 exists."
        );

        Assert.equal(
            orderbook.checkForMatchingOrder(10),
            false,
            "order with price 10 does not exist."
        );
    }
}
