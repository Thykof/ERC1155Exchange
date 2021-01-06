pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./OrderBookLibrary.sol";
import "./ERC1155Interface.sol";


contract ERC1155Exchange {
    using OrderBookLibrary for OrderBookLibrary.OrderBook;
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
        if (buySide) {
            bids.addOrder(price, amount, makerAccount);
        } else {
            asks.addOrder(price, amount, makerAccount);
        }

        if (limitOrder) {
            if (checkForMatchingOrder(buySide, price)) {
                // there is matching order
                // in the oposite side
                // so let's fill the incomming order
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

    function fillOrderMarket(
        bool buySide,
        uint256 requestedAmount,
        address takerAccount
    )
        internal
    {
        uint256 orderCounter = 0;
        uint256 filledAmount = 0;

        uint256 timestamp;
        uint256 price;
        uint256 currentAmount;
        address makerAccount;

        while (filledAmount < requestedAmount) {
            // get order
            if (buySide) {
                (
                    timestamp,
                    price,
                    currentAmount,
                    makerAccount
                ) = asks.getOrder(orderCounter);
            } else {
                (
                    timestamp,
                    price,
                    currentAmount,
                    makerAccount
                ) = bids.getOrder(orderCounter);
            }

            // calculate requestedAmount
            if (currentAmount > requestedAmount) {
                // incomming (taker) order filled
                // matching (maker) order partially filled
                // TODO: reduce the amount of the maker order
                executeTrade(buySide, makerAccount, takerAccount, price, currentAmount);
            } else if (currentAmount < requestedAmount) {
                // incomming (taker) order may be partially filled
                // matching (maker) order filled
                // let's continue to fill maker orders
                filledAmount = filledAmount.add(currentAmount);
                orderCounter = orderCounter.add(1);
                executeTrade(buySide, makerAccount, takerAccount, price, currentAmount);
            } else {
                executeTrade(buySide, makerAccount, takerAccount, price, currentAmount);
            }

            // fill order
        }
    }

    function executeTrade(
        bool buySide,
        address makerAccount,
        address takerAccount,
        uint256 price,
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
            price,
            amount
        );
    }
}
