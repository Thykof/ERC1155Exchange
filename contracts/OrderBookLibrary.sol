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
        // TODO: add tests
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

    function closeFirstOrderAtPrice(
        OrderBook storage self,
        uint256 price
    )
        internal
    {
        self.pricesToOrderList[price].deleteFirstOrder();

        if (self.pricesToOrderList[price].isEmpty()) {
            self.prices.remove(price);
        }
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
            return !self.pricesToOrderList[price].isEmpty();
        }
        return false;
    }
}
