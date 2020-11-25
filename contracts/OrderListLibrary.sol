pragma solidity 0.6.0;

import "./OrderStruct.sol";
import "./QueueLibrary.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


library OrderListLibrary {
    using QueueLibrary for QueueLibrary.Queue;
    using Counters for Counters.Counter;

    struct OrderList {
        QueueLibrary.Queue queue;
        mapping (uint256 => OrderStruct.Order) keyToOrder;
        Counters.Counter counter;
    }

    function push(
        OrderList storage self,
        OrderStruct.Order memory order
    )
        internal
    {
        self.counter.increment();

        require(
            self.keyToOrder[self.counter.current()].price == 0,
            "OrderListLibrary.push"
        );

        self.queue.enqueue(self.counter.current());
        self.keyToOrder[self.counter.current()] = order;
    }

    function pop(OrderList storage self)
        internal
        returns (uint256 price, uint256 amount, address makerAccount)
    {
        uint256 key = self.queue.dequeue();

        price = self.keyToOrder[key].price;
        amount = self.keyToOrder[key].amount;
        makerAccount = self.keyToOrder[key].makerAccount;
    }
}
