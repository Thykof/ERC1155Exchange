pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./BokkyPooBahsRedBlackTreeLibrary.sol";
import "./OrderListLibrary.sol";
import "./QueueLibrary.sol";


library OrderBookLibrary {
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    using OrderListLibrary for OrderListLibrary.OrderList;
    using SafeMath for uint256;
    using QueueLibrary for QueueLibrary.Queue;

    struct OrderBook {
        BokkyPooBahsRedBlackTreeLibrary.Tree prices;
        mapping (uint256 => OrderListLibrary.OrderList) pricesToOrderList;
        bool buySide;
    }

    function addOrder(
        OrderBook storage self,
        uint256 price,
        uint256 amount,
        address makerAccount
    )
        internal
        returns (uint256)
    {
        if (!self.prices.exists(price)) {
            // create OrderList
            self.prices.insert(price);
            self.pricesToOrderList[price].queue.first = 1;
        }

        return self.pricesToOrderList[price].push(
            amount,
            makerAccount
        );
    }

    function getBestOrder(OrderBook storage self)
        internal
        view
        returns (
            uint256 timestamp,
            uint256 bestPrice,
            uint256 amount,
            address makerAccount
        )
    {
        if (self.buySide) {
            bestPrice = self.prices.last();
            (timestamp, amount, makerAccount) = self.pricesToOrderList[bestPrice].first();
        } else {
            bestPrice = self.prices.first();
            (timestamp, amount, makerAccount) = self.pricesToOrderList[bestPrice].first();
        }
    }

    // function getOrder(OrderBook storage self, uint256 index)
    //     internal
    //     view
    //     returns (
    //         uint256 timestamp,
    //         uint256 currentPrice,
    //         uint256 amount,
    //         address makerAccount
    //     )
    // {
    //     // Returns the information of the order at position `index` in the order book
    //     // `getBestOrder` is a shortcut for `getOrder(0)`
    //     uint256 globalIndex = 0; // compared to given `index`
    //     if (self.buySide) {
    //         currentPrice = self.prices.last();
    //     } else {
    //         currentPrice = self.prices.first();
    //     }
    //     uint256 currentOrderIndex = 0;
    //
    //     do {
    //         while (self.pricesToOrderList[currentPrice].exists(currentOrderIndex)) {
    //             // loop over orders
    //             if (index == globalIndex) {
    //                 // get order
    //                 (
    //                     timestamp,
    //                     amount,
    //                     makerAccount
    //                 ) = self.pricesToOrderList[currentPrice]
    //                     .get(currentOrderIndex);
    //                 return (
    //                     timestamp,
    //                     currentPrice,
    //                     amount,
    //                     makerAccount
    //                 );
    //             } else {
    //                 currentOrderIndex = currentOrderIndex.add(1);
    //                 globalIndex = globalIndex.add(1);
    //             }
    //         }
    //         // end of order list loop
    //         currentOrderIndex = 0;
    //
    //         // loop over prices
    //         if (self.buySide) {
    //             currentPrice = self.prices.prev(currentPrice);
    //         } else {
    //             currentPrice = self.prices.next(currentPrice);
    //         }
    //     } while (globalIndex <= index);
    // }
    //
    function getOrderByPriceAndIndex(
        OrderBook storage self,
        uint256 price,
        uint256 orderKey
    )
        internal
        view
        returns (
            uint256 timestamp,
            uint256 amount,
            address makerAccount
        )
    {
        (
            timestamp,
            amount,
            makerAccount
        ) = self.pricesToOrderList[price].get(orderKey);
    }

    function updateAmount(
        OrderBook storage self,
        uint256 price,
        uint256 orderCounter,
        uint256 newAmount
    )
        internal
    {
        self.pricesToOrderList[price].updateAmount(orderCounter, newAmount);
    }

    function checkForMatchingOrder(
        OrderBook storage self,
        uint256 price
    )
        internal
        view
        returns (bool)
    {
        if (self.prices.exists(price)) {
            return self.pricesToOrderList[price].exists(0);
        }
        return false;
    }

    function closeOrder(
        OrderBook storage self,
        uint256 price,
        uint256 key
    )
        internal
    {
        self.pricesToOrderList[price].deleteOrder(key);
    }
}
