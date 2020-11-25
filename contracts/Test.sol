pragma solidity 0.6.0;

import "./OrderedMappingLibrary.sol";
import "./OrderListLibrary.sol";
import "./BokkyPooBahsRedBlackTreeLibrary.sol";
import "./OrderStruct.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Test {
    using OrderedMappingLibrary for OrderedMappingLibrary.OrderedMapping;
    using OrderListLibrary for OrderListLibrary.OrderList;
    using Counters for Counters.Counter;
    // using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;

    enum TokenState {
        NULL,
        CREATED,
        LAUNCHED,
        TRADING,
        RETIRED
    }

    struct Work {
        uint256 initialPrice;
        address owner;
        TokenState tokenState;
    }

    OrderedMappingLibrary.OrderedMapping private bidsPrice;
    // BokkyPooBahsRedBlackTreeLibrary.Tree private tree;
    Counters.Counter private counter;
    mapping (uint256 => OrderListLibrary.OrderList) private bidsPriceToOrderList;

    function getFirst() public view returns (uint256) {
        return bidsPrice.first();
    }

    function insertBid(uint256 key, uint256 value) public {
        bidsPrice.insert(key, value);
    }

    function newOrder(uint256 price, uint256 amount, address makerAccount) public {
        OrderStruct.Order memory order = OrderStruct.Order(price, amount, makerAccount);
        // Step1: execute order
        // TODO: check if there is a matching order

        // Step2: register order (if step1 skiped)
        if (bidsPrice.exists(price)) {
            // go to bidsPriceToOrderList
            OrderListLibrary.OrderList storage list = bidsPriceToOrderList[bidsPrice.getValue(price)];
            list.push(order);
        } else {
            // create OrderList
            counter.increment();
            bidsPrice.insert(price, counter.current());
            OrderListLibrary.OrderList storage list = bidsPriceToOrderList[counter.current()];
            list.queue.first = 1;
            list.push(order);
        }
    }
    // function insertTree(uint256 key) public {
    //     tree.insert(key);
    // }

    function batch(uint256 n) public {
        require(n > 1, "n <= 1");
        for (uint i = 1; i < n; i++) {
            bidsPrice.insert(i*100, i*10);
        }
    }
}
