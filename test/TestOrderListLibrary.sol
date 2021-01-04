pragma solidity 0.6.2;

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
        orderList.push(10, tx.origin);
        uint256 key = 1;

        Assert.equal(
            orderList.keyToOrder[key].timestamp,
            block.timestamp,
            "timestamp should be block.timestamp"
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
            orderList.queue.first,
            1,
            "head should be 1"
        );
    }

    function testFirst() public {
        (uint256 timestamp,
        uint256 amount,
        address makerAccount) = orderList.first();

        Assert.notEqual(
            timestamp,
            0,
            "timestamp should not be 0"
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
        uint256 amount,
        address makerAccount) = orderList.pop();

        Assert.notEqual(
            timestamp,
            0,
            "timestamp should not be 0"
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

    function testExists() public {
        Assert.equal(
            orderList.exists(0) || orderList.exists(1) || orderList.exists(2),
            false,
            "should be false"
        );

        orderList.push(5, tx.origin);

        Assert.equal(
            orderList.exists(0),
            true,
            "0 exists"
        );

        orderList.push(6, tx.origin);

        Assert.equal(
            orderList.exists(1),
            true,
            "1 exists"
        );
    }

    function testGet() public {
        (uint256 timestamp,
        uint256 amount,
        address makerAccount) = orderList.get(0);

        Assert.notEqual(
            timestamp,
            0,
            "timestamp should not be 0"
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

        orderList.push(12, tx.origin);
        (timestamp,
        amount,
        makerAccount) = orderList.get(2);

        Assert.notEqual(
            timestamp,
            0,
            "timestamp should not be 0"
        );
        Assert.equal(
            amount,
            12,
            "amount should be 12"
        );
        Assert.equal(
            makerAccount,
            tx.origin,
            "makerAccount should be tx.origin"
        );
    }
}
