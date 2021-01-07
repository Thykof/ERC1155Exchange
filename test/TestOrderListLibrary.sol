pragma solidity 0.6.2;

import "truffle/Assert.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../contracts/OrderListLibrary.sol";
import "../contracts/QueueLibrary.sol";


contract TestOrderListLibrary {
    using OrderListLibrary for OrderListLibrary.OrderList;
    using Counters for Counters.Counter;
    using QueueLibrary for QueueLibrary.Queue;
    using SafeMath for uint256;

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

    function testDeleteFirstOrder() public {
        uint256 orderCounter = orderList.firstKey();
        orderList.deleteFirstOrder();

        (uint256 timestamp,
        uint256 amount,
        address makerAccount) = orderList.get(orderCounter);

        Assert.equal(
            timestamp,
            0,
            "timestamp should be 0"
        );
        Assert.equal(
            amount,
            0,
            "amount should be 0"
        );
        Assert.equal(
            makerAccount,
            address(0),
            "makerAccount should be 0x"
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
            orderList.exists(2),
            true,
            "0 exists"
        );

        orderList.push(6, tx.origin);

        Assert.equal(
            orderList.exists(3),
            true,
            "1 exists"
        );
    }

    function testIsEmpty() public {
        Assert.equal(
            orderList.isEmpty(),
            false,
            "orderList is not empty"
        );
    }

    function testGet() public {
        uint256 orderCounter = orderList.firstKey();

        (uint256 timestamp,
        uint256 amount,
        address makerAccount) = orderList.get(orderCounter);

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
        makerAccount) = orderList.get(orderCounter.add(2));

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

    function testUpdateAmount() public {
        // Get orderCounter for order with amount 12
        uint256 orderCounter = orderList.firstKey().add(2);

        orderList.updateAmount(orderCounter, 10);
        (uint256 timestamp,
        uint256 amount,
        address makerAccount) = orderList.get(orderCounter);
        Assert.equal(
            amount,
            10,
            "amount should be 10"
        );
    }
}
