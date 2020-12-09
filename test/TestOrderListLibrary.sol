pragma solidity 0.6.0;

import "truffle/Assert.sol";
import "../contracts/OrderListLibrary.sol";
import "../contracts/QueueLibrary.sol";

import "@openzeppelin/contracts/utils/Counters.sol";


contract TestOrderListLibrary {
    using OrderListLibrary for OrderListLibrary.OrderList;
    using Counters for Counters.Counter;
    using QueueLibrary for QueueLibrary.Queue;

    OrderListLibrary.OrderList private orderList;

    constructor() public {
        orderList.queue.first = 1;
    }

    function testPush() public {
        orderList.push(110, 10, tx.origin);
        uint256 key = 1;

        Assert.equal(
            orderList.counter.current(),
            key,
            "counter should be key"
        );
        Assert.equal(
            orderList.keyToOrder[key].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
        );
        Assert.equal(
            orderList.keyToOrder[key].price,
            110,
            "price should be 110"
        );
        Assert.equal(
            orderList.keyToOrder[key].amount,
            10,
            "amount should be 10"
        );
        Assert.equal(
            orderList.keyToOrder[key].makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
        Assert.equal(
            orderList.queue.readHead(),
            1,
            "head should be 1"
        );
    }

    function testFirst() public {
        (uint256 timestamp,
        uint256 price,
        uint256 amount,
        address makerAccount) = orderList.first();
        Assert.notEqual(
            timestamp,
            0,
            "timestamp should not be 0"
        );
        Assert.equal(
            price,
            110,
            "price should be 110"
        );
        Assert.equal(
            amount,
            10,
            "amount should be 10"
        );
        Assert.equal(
            makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
    }

    function testPop() public {
        (uint256 timestamp,
        uint256 price,
        uint256 amount,
        address makerAccount) = orderList.pop();
        Assert.notEqual(
            timestamp,
            0,
            "timestamp should not be 0"
        );
        Assert.equal(
            price,
            110,
            "price should be 110"
        );
        Assert.equal(
            amount,
            10,
            "amount should be 10"
        );
        Assert.equal(
            makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
    }
}
