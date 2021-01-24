pragma solidity 0.6.2;

import "@openzeppelin/contracts/proxy/Initializable.sol";

import "../erc1155/TradableERC1155Interface.sol";
import "../libraries/OrderBookLibrary.sol";


contract MockERC1155ExchangeImplementationV2 is Initializable {
    uint256 public tokenId;
    OrderBookLibrary.OrderBook internal bids; // buy side
    OrderBookLibrary.OrderBook internal asks; // sell side
    address internal operator;
    uint256 public feeRate;
    TradableERC1155Interface public tokenContract;

    // this function replace the constructor
    function initialize(
        address tradableERC1155,
        uint256 _tokenId,
        uint256 _feeRate,
        address _operator
    )
        public
        initializer
    {
        bids.buySide = true;
        asks.buySide = false;
        tokenContract = TradableERC1155Interface(tradableERC1155);
        tokenId = _tokenId;
        feeRate = _feeRate;
        operator = _operator;
    }

    function myFunction(
    )
        public
        pure
    {
        revert("Mock reverts!");
    }
}
