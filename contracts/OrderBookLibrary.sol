pragma solidity 0.6.0;

import "./BokkyPooBahsRedBlackTreeLibrary.sol";
import "./OrderListLibrary.sol";
import "./OrderStruct.sol";


library OrderBookLibrary {
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    using OrderListLibrary for OrderListLibrary.OrderList;

    struct OrderBook {
        BokkyPooBahsRedBlackTreeLibrary.Tree prices;
        mapping (uint256 => OrderListLibrary.OrderList) pricesToOrderList;
    }

    function addOrder(
        OrderBook storage self,
        uint256 price,
        uint256 amount,
        address makerAccount
    )
        internal
    {
        if (!self.prices.exists(price)) {
            // create OrderList
            self.prices.insert(price);
            self.pricesToOrderList[price].queue.first = 1;
        }

        self.pricesToOrderList[price].push(
            price,
            amount,
            makerAccount
        );
    }

    function getBestOrder(OrderBook storage self)
        internal
        view
        returns (
            uint256 timestamp,
            uint256 price,
            uint256 amount,
            address makerAccount
        )
    {
        uint256 bestPrice = self.prices.first();
        (timestamp, price, amount, makerAccount) = self.pricesToOrderList[bestPrice].first();
    }

    // function getOrder(OrderBook storage self, uint256 index)
    //     internal
    //     view
    //     returns (
    //         uint256 bestPrice,
    //         uint256 amount,
    //         address makerAccount
    //     )
    // {
    //     // Returns the information of the order at position `index` in the
    //     // order book
    //     // `getBestOrder` is a shortcut for `getOrder(0)`
    //
    // }
}
