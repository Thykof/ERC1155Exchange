pragma solidity 0.6.0;

import "./OrderStruct.sol";
import "./QueueLibrary.sol";

import "@openzeppelin/contracts/utils/Counters.sol";


library OrderListLibrary {
    using QueueLibrary for QueueLibrary.Queue;
    using Counters for Counters.Counter;

    event LogOrder(uint256 timestamp, uint256 price, uint256 amount, address makerAccount);
    event Log(uint256 value);

    struct OrderList {
        QueueLibrary.Queue queue;
        Counters.Counter counter;
        mapping (uint256 => OrderStruct.Order) keyToOrder;
    }

    function push(
        OrderList storage self,
        uint256 price,
        uint256 amount,
        address makerAccount
    )
        internal
    {
        self.counter.increment();
        uint256 key = self.counter.current();
        self.queue.enqueue(key);
        self.keyToOrder[key].timestamp = block.timestamp;
        self.keyToOrder[key].price = price;
        self.keyToOrder[key].amount = amount;
        self.keyToOrder[key].makerAccount = makerAccount;
        emit LogOrder(key, price, amount, makerAccount);
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

    function first(OrderList storage self)
        internal
        // view
        returns (
            uint256 timestamp,
            uint256 price,
            uint256 amount,
            address makerAccount
        )
    {
        timestamp = self.queue.readHead();
        price = self.keyToOrder[timestamp].price;
        amount = self.keyToOrder[timestamp].amount;
        makerAccount = self.keyToOrder[timestamp].makerAccount;
        emit LogOrder(timestamp, price, amount, makerAccount);
        emit Log(self.queue.first);
    }
}
