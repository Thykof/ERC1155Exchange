pragma solidity 0.6.0;

// https://programtheblockchain.com/posts/2018/03/23/storage-patterns-stacks-queues-and-deques/

import "@openzeppelin/contracts/math/SafeMath.sol";


library QueueLibrary {
    using SafeMath for uint256;

    event Log(uint256 value);

    struct Queue {
        mapping(uint256 => uint256) queue;
        uint256 first; // to be initialized to 1
        uint256 last;
    }

    function readHead(Queue storage self)
        internal
        view
        returns (uint256)
    {
        return self.queue[self.first];
    }

    function enqueue(Queue storage self, uint256 key) internal {
        self.last = self.last.add(1);
        self.queue[self.last] = key;
    }

    function dequeue(Queue storage self) internal returns (uint256) {
        require(self.last >= self.first, "QueueLibrary: non-empty queue");

        uint256 key = self.queue[self.first];

        delete self.queue[self.first];
        self.first = self.first.add(1);

        return key;
    }
}
