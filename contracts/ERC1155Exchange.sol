pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./OrderBookLibrary.sol";
import "./OrderListLibrary.sol";
import "./ERC1155Interface.sol";


contract ERC1155Exchange {
    using OrderBookLibrary for OrderBookLibrary.OrderBook;
    using OrderListLibrary for OrderListLibrary.OrderList;
    using SafeMath for uint256;

    OrderBookLibrary.OrderBook internal bids; // buy side
    OrderBookLibrary.OrderBook internal asks; // sell side

    ERC1155Interface private tokenContract;

    constructor() public {
        bids.buySide = true;
        asks.buySide = false;
        tokenContract = ERC1155Interface(msg.sender);
    }

    function addOrder(
        bool buySide,
        uint256 price,
        uint256 amount,
        address makerAccount,
        bool limitOrder
    )
        public
    {
        require(amount > 0, "ERC1155Exchange: amount must be over zero");

        uint256 incommingOrderCounter;

        if (buySide) {
            incommingOrderCounter = bids.addOrder(price, amount, makerAccount);
        } else {
            incommingOrderCounter = asks.addOrder(price, amount, makerAccount);
        }

        if (limitOrder) {
            if (checkForMatchingOrder(buySide, price)) {
                // there is matching order
                // in the oposite side
                // so let's fill the incomming order
                fillOrderLimit(
                    buySide,
                    price,
                    amount,
                    makerAccount,
                    incommingOrderCounter
                );
            }
        } else {
            fillOrderMarket(buySide, amount, makerAccount);
        }

    }

    function checkForMatchingOrder(bool buySide, uint256 price)
        internal
        view
        returns (bool)
    {
        if (buySide) {
            return asks.checkForMatchingOrder(price);
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
        OrderListLibrary.OrderList storage orderList = asks
            .pricesToOrderList[price];
        if (!buySide) {
            orderList = bids.pricesToOrderList[price];
        }
        uint256 orderCounter = orderList.firstKey();

        uint256 filledAmount = 0; // and the end, we want this to be equal to `requestedAmount`

        uint256 timestamp;
        uint256 currentAmount;
        address makerAccount;

        while (filledAmount < requestedAmount) {
            (
                timestamp,
                currentAmount,
                makerAccount
            ) = orderList.get(orderCounter);

            if (currentAmount > requestedAmount) {
                // incomming (taker) order filled
                // matching (maker) order partially filled
                executeTrade(buySide, makerAccount, takerAccount, requestedAmount);
                orderList.updateAmount(orderCounter, currentAmount.sub(requestedAmount));
                return;
            } else if (currentAmount < requestedAmount) {
                // incomming (taker) order may be partially filled
                // matching (maker) order filled
                // let's continue to fill maker orders
                executeTrade(buySide, makerAccount, takerAccount, currentAmount);
                orderList.deleteOrder(orderCounter);
                filledAmount = filledAmount.add(currentAmount);
            } else {
                // currentAmount == requestedAmount
                executeTrade(buySide, makerAccount, takerAccount, currentAmount);
                orderList.deleteOrder(orderCounter);
                return;
            }

            orderCounter = orderCounter.add(orderCounter);
        }

        // TODO: updateAmount of the incomming (taker) order
        OrderBookLibrary.OrderBook storage orderBook = asks;
        if (buySide) {
            orderBook = bids;
        }
        uint256 newAmount = requestedAmount.sub(filledAmount);
        orderBook.updateAmount(price, incommingOrderCounter, newAmount);
    }

    function fillOrderMarket(
        bool buySide,
        uint256 requestedAmount,
        address takerAccount
    )
        internal
    {
        // method variables
        uint256 orderCounter = 0;
        uint256 filledAmount = 0; // and the end, we want this to be equal to `requestedAmount`
        OrderBookLibrary.OrderBook storage orderBook = asks;
        if (!buySide) {
            orderBook = bids;
        }

        // order variables
        uint256 timestamp;
        uint256 price;
        uint256 currentAmount;
        address makerAccount;

        while (filledAmount < requestedAmount) {
            // get order
            (
                timestamp,
                currentAmount,
                makerAccount
            ) = orderBook.getOrderByPriceAndIndex(price, orderCounter);

            // calculate requestedAmount
            if (currentAmount > requestedAmount) {
                // incomming (taker) order filled
                // matching (maker) order partially filled
                orderBook.updateAmount(price, orderCounter, currentAmount.sub(requestedAmount));
                executeTrade(buySide, makerAccount, takerAccount, requestedAmount);
                return;
            } else if (currentAmount < requestedAmount) {
                // incomming (taker) order may be partially filled
                // matching (maker) order filled
                // let's continue to fill maker orders
                filledAmount = filledAmount.add(currentAmount);
                orderCounter = orderCounter.add(1);
                executeTrade(buySide, makerAccount, takerAccount, currentAmount);
            } else {
                // matching order amount is eaqul to requestedAmount
                executeTrade(buySide, makerAccount, takerAccount, currentAmount);
                return;
            }
        }
    }

    function executeTrade(
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
            buyer = makerAccount;
            seller = takerAccount;
        } else {
            buyer = takerAccount;
            seller = makerAccount;
        }

        tokenContract.executeTrade(
            buyer,
            seller,
            amount
        );
    }
}
