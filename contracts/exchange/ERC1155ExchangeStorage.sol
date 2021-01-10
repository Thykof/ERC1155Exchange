pragma solidity 0.6.2;


contract ERC1155ExchangeStorage {
    uint256 public tokenId;
    mapping (address => uint) public pendingWithdrawals;
    TradableERC1155Interface public tokenContract;

    OrderBookLibrary.OrderBook private bids; // buy side
    OrderBookLibrary.OrderBook private asks; // sell side
}
