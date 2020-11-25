pragma solidity 0.6.0;


contract OrderBookLibrary {
    struct OrderBook {
        OrderedMappingLibrary.OrderedMapping prices;
        mapping (uint256 => OrderListLibrary.OrderList) pricesToOrderList;
        Counters.Counter counter;
    }
}
