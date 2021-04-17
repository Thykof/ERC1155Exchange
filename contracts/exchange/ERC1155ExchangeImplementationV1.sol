pragma solidity 0.6.2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ERC1155ExchangeEvents.sol";
import "./ERC1155ExchangeOrderBook.sol";
import "./EtherManager.sol";
import "../libraries/OrderBookLibrary.sol";
import "../libraries/OrderListLibrary.sol";
import "../libraries/BokkyPooBahsRedBlackTreeLibrary.sol";
import "../erc1155/TradableERC1155Interface.sol";


contract ERC1155ExchangeImplementationV1 is
    EtherManager,
    ERC1155ExchangeOrderBook,
    ERC1155ExchangeEvents,
    Initializable {
    using SafeMath for uint256;
    using OrderBookLibrary for OrderBookLibrary.OrderBook;
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    using OrderListLibrary for OrderListLibrary.OrderList;

    uint256 public tokenId;

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

    function addOrder(
        bool buySide,
        uint256 price,
        uint256 amount
    )
        public
        payable
    {
        require(amount > 0, "ERC1155Exchange: amount must be over zero");
        require(!tokenContract.paused(), "ERC1155Exchange: ERC1155 is paused");

        uint256 incommingOrderCounter;
        address makerAccount = msg.sender;


        if (buySide) {
            // Check ether value sent
            require(
                msg.value == getWeiPrice(price, amount),
                "ERC1155Exchange: invalid amount wei sent"
            );
            incommingOrderCounter = bids.addOrder(price, amount, makerAccount);
        } else {
            // Check if exchange contract is approved in token contract
            require(
                tokenContract.isApprovedForAll(makerAccount, address(this)),
                "ERC1155Exchange: sender has not approved exchange contract"
            );
            incommingOrderCounter = asks.addOrder(price, amount, makerAccount);
        }

        if (checkForMatchingOrder(buySide, price)) {
            // there is matching order in the oposite side
            // so let's fill the incomming order
            fillOrderLimit(
                buySide,
                price,
                amount,
                makerAccount,
                incommingOrderCounter
            );
        }

        emit OrderAdded(
            tokenId,
            buySide,
            price,
            amount,
            makerAccount
        );
    }

    function checkForMatchingOrder(bool buySide, uint256 price)
        internal
        view
        returns (bool)
    {
        if (buySide) {
            bool foundMatchingOrder = asks.checkForMatchingOrder(price);
            return foundMatchingOrder;
        } else {
            return bids.checkForMatchingOrder(price);
        }
    }

    function fillOrderLimit(
        bool buySide,
        uint256 price,
        uint256 requestedAmount,
        address takerAccount,
        uint256 incommingOrderCounter
    )
        internal
    {
        // Get matching order book
        OrderBookLibrary.OrderBook storage matchingOrderBook = asks;
        if (!buySide) {
            matchingOrderBook = bids;
        }

        // Get matching order list
        OrderListLibrary.OrderList storage orderList = asks
            .pricesToOrderList[price];

        if (!buySide) {
            orderList = bids.pricesToOrderList[price];
        }

        uint256 orderCounter = orderList.firstKey();

        uint256 remainingAmount = requestedAmount; // at the end, we want this to be 0

        OrderListLibrary.Order memory currentOrder;


        while (remainingAmount > 0 && orderList.exists(orderCounter)) {
            (
                currentOrder.timestamp,
                currentOrder.amount,
                currentOrder.makerAccount
            ) = orderList.get(orderCounter);

            if (currentOrder.amount > remainingAmount) {
                // incomming (taker) order filled
                // matching (maker) order partially filled
                executeTrade(
                    price,
                    buySide,
                    currentOrder.makerAccount,
                    takerAccount,
                    remainingAmount
                );

                matchingOrderBook.updateAmount(
                    price,
                    orderCounter,
                    currentOrder.amount.sub(remainingAmount)
                );
                // => remainingAmount = 0
                remainingAmount = remainingAmount.sub(remainingAmount);
            } else if (currentOrder.amount < remainingAmount) {
                // incomming (taker) order may be partially filled
                // matching (maker) order filled
                // let's continue to fill maker orders
                executeTrade(
                    price,
                    buySide,
                    currentOrder.makerAccount,
                    takerAccount,
                    currentOrder.amount
                );

                matchingOrderBook.closeFirstOrderAtPrice(price);
                remainingAmount = remainingAmount.sub(currentOrder.amount);
            } else {
                // currentOrder.amount == remainingAmount
                // incomming (taker) order filled and matching (maker) order filled
                executeTrade(
                    price,
                    buySide,
                    currentOrder.makerAccount,
                    takerAccount,
                    currentOrder.amount
                );

                matchingOrderBook.closeFirstOrderAtPrice(price);
                remainingAmount = 0;
            }

            orderCounter = orderCounter.add(orderCounter);
        }

        // Get taker order book
        OrderBookLibrary.OrderBook storage incommingOrderBook = asks;
        if (buySide) {
            incommingOrderBook = bids;
        }

        if (remainingAmount == 0) {
            // delete incomming order
            incommingOrderBook.closeFirstOrderAtPrice(price);
        } else {
            // Update amount of the incomming (taker) order
            // incomming order partially filled
            incommingOrderBook.updateAmount(
                price,
                incommingOrderCounter,
                remainingAmount
            );
        }
    }

    function executeTrade(
        uint256 price,
        bool buySide,
        address makerAccount,
        address takerAccount,
        uint256 amount
    )
        internal
    {
        address buyer;
        address seller;

        if (buySide) {
            buyer = takerAccount;
            seller = makerAccount;
        } else {
            buyer = makerAccount;
            seller = takerAccount;
        }

        tokenContract.safeTransferFrom(
            seller,
            buyer,
            tokenId,
            amount,
            new bytes(0)
        );

        // Add withdrawal for seller
        pendingWithdrawals[seller] = pendingWithdrawals[seller].add(
            getWeiPrice(price, amount)
        );

        uint256 fees = payFees(price, amount, makerAccount, takerAccount);

        emit TradeExecuted(
            tokenId,
            price,
            amount,
            buyer,
            seller,
            takerAccount,
            fees
        );
    }
}
