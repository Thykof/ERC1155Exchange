pragma solidity 0.6.0;

// https://programtheblockchain.com/posts/2018/03/23/storage-patterns-stacks-queues-and-deques/

import "@openzeppelin/contracts/math/SafeMath.sol";


library QueueLibrary {
    using SafeMath for uint256;

    struct Queue {
        uint256 first; // to be initialized to 1
        uint256 last;
    }

    function enqueue(Queue storage self) internal returns (uint256) {
        self.last = self.last.add(1);
        return self.last;
    }

    function dequeue(Queue storage self) internal returns (uint256 key) {
        require(self.last >= self.first, "QueueLibrary: empty queue");

        key = self.first;

        self.first = self.first.add(1);
    }

    function exists(Queue storage self,uint256 index) internal view returns (bool) {
        return self.first <= index && index <= self.last;
    }
}
