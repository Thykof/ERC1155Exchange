pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./OrderBookLibrary.sol";
import "./OrderListLibrary.sol";
import "./ERC1155Interface.sol";


contract ERC1155Exchange {
    using OrderBookLibrary for OrderBookLibrary.OrderBook;
    using OrderListLibrary for OrderListLibrary.OrderList;
    using SafeMath for uint256;

    uint256 public tokenId;
    mapping (address => uint) public pendingWithdrawals;

    OrderBookLibrary.OrderBook internal bids; // buy side
    OrderBookLibrary.OrderBook internal asks; // sell side

    ERC1155Interface private tokenContract;

    constructor(uint256 id) public {
        bids.buySide = true;
        asks.buySide = false;
        tokenContract = ERC1155Interface(msg.sender);
        tokenId = id;
    }

    function withdraw() public {
        // See https://docs.soliditylang.org/en/v0.6.2/common-patterns.html
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
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

        uint256 incommingOrderCounter;
        address makerAccount = msg.sender;


        if (buySide) {
            // Check ether value sent
            require(
                msg.value == getWeiPrice(price, amount),
                "ERC1155Exchange: not enough wei sent"
            );
            incommingOrderCounter = bids.addOrder(price, amount, makerAccount);
        } else {
            // Check if exchange contract is approved in token contract
            require(
                tokenContract.checkApproved(tokenId, msg.sender),
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
        OrderListLibrary.OrderList storage orderList = asks.pricesToOrderList[price];
        if (!buySide) {
            orderList = bids.pricesToOrderList[price];
        }
        uint256 orderCounter = orderList.firstKey();

        uint256 remainingAmount = requestedAmount; // at the end, we want this to be 0

        uint256 timestamp;
        uint256 currentAmount;
        address makerAccount;

        OrderBookLibrary.OrderBook storage makerOrderBook = asks;
        if (!buySide) {
            makerOrderBook = bids;
        }

        while (remainingAmount > 0 && orderList.exists(orderCounter)) {
            (
                timestamp,
                currentAmount,
                makerAccount
            ) = orderList.get(orderCounter);

            if (currentAmount > remainingAmount) {
                // incomming (taker) order filled
                // matching (maker) order partially filled
                executeTrade(price, buySide, makerAccount, takerAccount, remainingAmount);
                makerOrderBook.updateAmount(price, orderCounter, currentAmount.sub(remainingAmount));
                remainingAmount = remainingAmount.sub(remainingAmount); // => remainingAmount = 0
            } else if (currentAmount < remainingAmount) {
                // incomming (taker) order may be partially filled
                // matching (maker) order filled
                // let's continue to fill maker orders
                executeTrade(price, buySide, makerAccount, takerAccount, currentAmount);
                orderList.deleteFirstOrder();
                remainingAmount = remainingAmount.sub(currentAmount);
            } else {
                // currentAmount == remainingAmount
                // incomming (taker) order filled and matching (maker) order filled
                executeTrade(price, buySide, makerAccount, takerAccount, currentAmount);
                orderList.deleteFirstOrder();
                remainingAmount = remainingAmount.sub(currentAmount);
            }

            orderCounter = orderCounter.add(orderCounter);
        }

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
            incommingOrderBook.updateAmount(price, incommingOrderCounter, remainingAmount);
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

        // Add withdrawal for seller
        pendingWithdrawals[seller] = pendingWithdrawals[seller].add(
            getWeiPrice(price, amount)
        );
    }

    function getWeiPrice(
        uint256 price,
        uint256 amount
    )
        internal
        pure
        returns (uint256)
    {
        return price * amount;
    }
}
