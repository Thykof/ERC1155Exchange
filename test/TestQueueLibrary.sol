pragma solidity 0.6.0;

import "truffle/Assert.sol";
import "../contracts/QueueLibrary.sol";


contract TestQueueLibrary {
    using QueueLibrary for QueueLibrary.Queue;

    QueueLibrary.Queue private queue = QueueLibrary.Queue({
        first: 1,
        last: 0
    });

    function testInitialization() public {
        Assert.equal(
            queue.first,
            1,
            "First should be 1"
        );

        Assert.equal(
            queue.last,
            0,
            "Last should be 0"
        );

        Assert.equal(
            queue.exists(0) || queue.exists(1),
            false,
            "0 and 1 do not exists"
        );
    }

    function testEnqueue() public {
        uint256 key = queue.enqueue();

        Assert.equal(
            key,
            1,
            "key should be 1"
        );

        Assert.equal(
            queue.first,
            1,
            "first should be 1"
        );

        Assert.equal(
            queue.last,
            1,
            "Last should be 1"
        );
    }

    function testExists1() public {
        Assert.equal(
            queue.exists(1),
            true,
            "1 exists"
        );
    }

    function testDequeue() public {
        uint256 key = queue.dequeue();

        Assert.equal(
            key,
            1,
            "Key should be 1"
            );

        Assert.equal(
            queue.first,
            2,
            "first should be 2"
        );

        Assert.equal(
            queue.last,
            1,
            "Last should be 1"
        );
    }

    function testExists2() public {
        Assert.equal(
            queue.exists(1) || queue.exists(2),
            false,
            "1 and 2 do not exists"
        );
    }
}
