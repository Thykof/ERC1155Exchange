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
    }

    function testEnqueueAndReadHead() public {
        queue.enqueue(12);

        Assert.equal(
            queue.readHead(),
            12,
            "Head should be 12"
        );
    }

    function testDequeueAndReadHead() public {
        uint256 key = queue.dequeue();

        Assert.equal(
            queue.readHead(),
            0,
            "Head should be 0"
        );

        Assert.equal(
            key,
            12,
            "Key should be 12"
        );

        Assert.equal(
            queue.queue[0],
            0,
            "0 should be 0"
        );
        Assert.equal(
            queue.queue[1],
            0,
            "1 should be 0"
        );
        Assert.equal(
            queue.first,
            2,
            "First should be 2"
        );
        Assert.equal(
            queue.last,
            1,
            "Last should be 1"
        );
    }
}
