pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./OrderBookLibrary.sol";
import "./OrderListLibrary.sol";
import "./ERC1155Interface.sol";


contract ERC1155Exchange {
    using OrderBookLibrary for OrderBookLibrary.OrderBook;
    using OrderListLibrary for OrderListLibrary.OrderList;
    using SafeMath for uint256;

    // Copied from:
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/token/ERC1155/IERC1155.sol
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event OrderAdded(
        uint256 indexed tokenId,
        bool buySide,
        uint256 price,
        uint256 indexed amount,
        address indexed makerAccount
    );

    event OrderFilled(
        uint256 indexed tokenId,
        bool partiallyFilled,
        bool buySide,
        uint256 price,
        uint256 amount,
        address indexed makerAccount,
        address indexed takerAccount
    );

    event TradeExecuted(
        uint256 indexed tokenId,
        bool buySide,
        uint256 amount,
        address indexed buyerAccount,
        address indexed sellerAccount,
        uint256 pendingWithdrawals
    );

    uint256 public tokenId;
    mapping (address => uint) public pendingWithdrawals;

    OrderBookLibrary.OrderBook internal bids; // buy side
    OrderBookLibrary.OrderBook internal asks; // sell side

    ERC1155Interface private tokenContract;

    struct SimpleOrder {
        uint256 timestamp;
        uint256 amount;
        address makerAccount;
    }

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
                tokenContract.checkApproved(tokenId, makerAccount),
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
        OrderListLibrary.OrderList storage orderList = asks.pricesToOrderList[price];
        if (!buySide) {
            orderList = bids.pricesToOrderList[price];
        }
        uint256 orderCounter = orderList.firstKey();

        uint256 remainingAmount = requestedAmount; // at the end, we want this to be 0

        SimpleOrder memory currentOrder;

        OrderBookLibrary.OrderBook storage makerOrderBook = asks;
        if (!buySide) {
            makerOrderBook = bids;
        }

        while (remainingAmount > 0 && orderList.exists(orderCounter)) {
            (
                currentOrder.timestamp,
                currentOrder.amount,
                currentOrder.makerAccount
            ) = orderList.get(orderCounter);

            if (currentOrder.amount > remainingAmount) {
                // incomming (taker) order filled
                // matching (maker) order partially filled
                executeTrade(price, buySide, currentOrder.makerAccount, takerAccount, remainingAmount);
                emit OrderFilled(
                    tokenId,
                    false,
                    buySide,
                    price,
                    remainingAmount,
                    currentOrder.makerAccount,
                    takerAccount
                );

                makerOrderBook.updateAmount(price, orderCounter, currentOrder.amount.sub(remainingAmount));
                remainingAmount = remainingAmount.sub(remainingAmount); // => remainingAmount = 0
            } else if (currentOrder.amount < remainingAmount) {
                // incomming (taker) order may be partially filled
                // matching (maker) order filled
                // let's continue to fill maker orders
                executeTrade(price, buySide, currentOrder.makerAccount, takerAccount, currentOrder.amount);
                emit OrderFilled(
                    tokenId,
                    true,
                    buySide,
                    price,
                    currentOrder.amount,
                    currentOrder.makerAccount,
                    takerAccount
                );

                orderList.deleteFirstOrder();
                remainingAmount = remainingAmount.sub(currentOrder.amount);
            } else {
                // currentOrder.amount == remainingAmount
                // incomming (taker) order filled and matching (maker) order filled
                executeTrade(price, buySide, currentOrder.makerAccount, takerAccount, currentOrder.amount);
                emit OrderFilled(
                    tokenId,
                    false,
                    buySide,
                    price,
                    currentOrder.amount,
                    currentOrder.makerAccount,
                    takerAccount
                );

                orderList.deleteFirstOrder();
                remainingAmount = remainingAmount.sub(currentOrder.amount);
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
            buyer = takerAccount;
            seller = makerAccount;
        } else {
            buyer = makerAccount;
            seller = takerAccount;
        }

        tokenContract.executeTrade(
            tokenId,
            buyer,
            seller,
            amount
        );

        // Add withdrawal for seller
        pendingWithdrawals[seller] = pendingWithdrawals[seller].add(
            getWeiPrice(price, amount)
        );

        emit TradeExecuted(
            tokenId,
            buySide,
            amount,
            buyer,
            seller,
            pendingWithdrawals[seller]
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
