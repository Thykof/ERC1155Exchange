pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../libraries/OrderBookLibrary.sol";
import "../libraries/BokkyPooBahsRedBlackTreeLibrary.sol";
import "../libraries/OrderListLibrary.sol";


contract ERC1155ExchangeOrderBook {
    using SafeMath for uint256;
    using OrderBookLibrary for OrderBookLibrary.OrderBook;
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    using OrderListLibrary for OrderListLibrary.OrderList;

    OrderBookLibrary.OrderBook internal bids; // buy side
    OrderBookLibrary.OrderBook internal asks; // sell side

    function getBestOrder(
        bool buySide
    )
        public
        view
        returns (
            uint256 timestamp,
            uint256 bestPrice,
            uint256 amount,
            address makerAccount
        )
    {
        if (buySide) {
            return bids.getBestOrder();
        } else {
            return asks.getBestOrder();
        }
    }

    // may be used one day for market order
    // function getNextPrice(
    //     bool buySide,
    //     uint256 price
    // )
    //     public
    //     view
    //     returns (
    //         uint256
    //     )
    // {
    //     if (buySide) {
    //         return bids.prices.prev(price);
    //     } else {
    //         return asks.prices.next(price);
    //     }
    // }
    //
    // function getOrderAtPrice(
    //     bool buySide,
    //     uint256 price,
    //     uint256 index
    // )
    //     public
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         address
    //     )
    // {
    //     OrderListLibrary.OrderList storage orderList = asks
    //         .pricesToOrderList[price];
    //
    //     if (buySide) {
    //         orderList = bids.pricesToOrderList[price];
    //     }
    //
    //     uint256 orderCounter = index.add(orderList.firstKey());
    //
    //     return orderList.get(orderCounter);
    // }
}
