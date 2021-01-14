pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./QueueLibrary.sol";


library OrderListLibrary {
    using SafeMath for uint256;
    using QueueLibrary for QueueLibrary.Queue;

    struct Order {
        uint256 timestamp;
        uint256 amount;
        address makerAccount;
    }

    struct OrderList {
        QueueLibrary.Queue queue;
        mapping (uint256 => Order) keyToOrder;
    }

    function push(
        OrderList storage self,
        uint256 amount,
        address makerAccount
    )
        internal
        returns (uint256)
    {
        uint256 key = self.queue.enqueue();
        self.keyToOrder[key].timestamp = block.timestamp;
        self.keyToOrder[key].amount = amount;
        self.keyToOrder[key].makerAccount = makerAccount;
        return key;
    }

    function deleteFirstOrder(OrderList storage self)
        internal
    {
        // WARNING: must be called be orderBook only
        uint256 key = self.queue.dequeue();
        delete self.keyToOrder[key];
    }

    function first(OrderList storage self)
        internal
        view
        returns (
            uint256 timestamp,
            uint256 amount,
            address makerAccount
        )
    {
        uint256 key = self.queue.first;

        timestamp = self.keyToOrder[key].timestamp;
        amount = self.keyToOrder[key].amount;
        makerAccount = self.keyToOrder[key].makerAccount;
    }

    function firstKey(OrderList storage self) internal view returns (uint256) {
        return self.queue.first;
    }

    function get(OrderList storage self, uint256 key)
        internal
        view
        returns (
            uint256 timestamp,
            uint256 amount,
            address makerAccount
        )
    {
        timestamp = self.keyToOrder[key].timestamp;
        amount = self.keyToOrder[key].amount;
        makerAccount = self.keyToOrder[key].makerAccount;
    }

    function isEmpty(OrderList storage self) internal view returns (bool) {
        return !self.queue.exists(self.queue.first);
    }

    function exists(OrderList storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self.queue.exists(key);
    }

    function updateAmount(
        OrderList storage self,
        uint256 key,
        uint256 newAmount
    )
        internal
    {
        self.keyToOrder[key].amount = newAmount;
    }
}
