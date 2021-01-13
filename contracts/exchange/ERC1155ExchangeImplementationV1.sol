pragma solidity 0.6.2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ERC1155ExchangeEvents.sol";
import "../libraries/OrderBookLibrary.sol";
import "../libraries/OrderListLibrary.sol";
import "../libraries/BokkyPooBahsRedBlackTreeLibrary.sol";
import "../erc1155/TradableERC1155Interface.sol";


contract ERC1155ExchangeImplementationV1 is ERC1155ExchangeEvents, Initializable {

    using SafeMath for uint256;
    using OrderBookLibrary for OrderBookLibrary.OrderBook;
    using OrderListLibrary for OrderListLibrary.OrderList;
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;

    struct SimpleOrder {
        uint256 timestamp;
        uint256 amount;
        address makerAccount;
    }

    uint256 public feeRate;

    uint256 public tokenId;
    mapping (address => uint) public pendingWithdrawals;
    mapping (address => uint) public feesCredits; // deposit and withdrawal allowed
    mapping (address => uint) public bonusFeesCredits; // no deposit, no withdrawal
    TradableERC1155Interface public tokenContract;

    OrderBookLibrary.OrderBook internal bids; // buy side
    OrderBookLibrary.OrderBook internal asks; // sell side

    // this function replace the constructor
    function initialize(
        address tradableERC1155,
        uint256 _tokenId,
        uint256 _feeRate
    )
        public
        initializer
    {
        bids.buySide = true;
        asks.buySide = false;
        tokenContract = TradableERC1155Interface(tradableERC1155);
        tokenId = _tokenId;
        feeRate = _feeRate;
    }

    function setFeeRate(uint256 newFeeRate) public {
        require(msg.sender == address(tokenContract));
        feeRate = newFeeRate;
    }

    function withdraw() public {
        // See https://docs.soliditylang.org/en/v0.6.2/common-patterns.html
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function depositFeeCredit() public payable {
        require(msg.value > 0, "ERC1155Exchange: Can't deposit zero");
        feesCredits[msg.sender] = feesCredits[msg.sender].add(msg.value);
    }

    function withdrawFeeCredit(uint256 amount) public {
        feesCredits[msg.sender] = feesCredits[msg.sender].sub(
            amount,
            "ERC1155Exchange: withdrawal amount exceed balance"
        );
        msg.sender.transfer(amount);
    }

    function getBestOrder(
        bool buySide
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            address
        )
    {
        if (buySide) {
            return bids.getBestOrder();
        } else {
            return asks.getBestOrder();
        }
    }

    function getNextPrice(
        bool buySide,
        uint256 price
    )
        public
        view
        returns (
            uint256
        )
    {
        if (buySide) {
            return bids.prices.prev(price);
        } else {
            return asks.prices.next(price);
        }
    }

    function getOrderAtPrice(
        bool buySide,
        uint256 price,
        uint256 index
    )
        public
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        OrderListLibrary.OrderList storage orderList = asks.pricesToOrderList[price];
        if (buySide) {
            orderList = bids.pricesToOrderList[price];
        }

        uint256 orderCounter = index.add(orderList.firstKey());

        return orderList.get(orderCounter);
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

                makerOrderBook.updateAmount(price, orderCounter, currentOrder.amount.sub(remainingAmount));
                remainingAmount = remainingAmount.sub(remainingAmount); // => remainingAmount = 0
            } else if (currentOrder.amount < remainingAmount) {
                // incomming (taker) order may be partially filled
                // matching (maker) order filled
                // let's continue to fill maker orders
                executeTrade(price, buySide, currentOrder.makerAccount, takerAccount, currentOrder.amount);

                matchingOrderBook.closeFirstOrderAtPrice(price);
                remainingAmount = remainingAmount.sub(currentOrder.amount);
            } else {
                // currentOrder.amount == remainingAmount
                // incomming (taker) order filled and matching (maker) order filled
                executeTrade(price, buySide, currentOrder.makerAccount, takerAccount, currentOrder.amount);

                matchingOrderBook.closeFirstOrderAtPrice(price);
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

    function payFees(
        uint256 price,
        uint256 amount,
        address makerAccount,
        address takerAccount
    )
        internal
        returns (uint256)
    {
        // Calculate fees
        uint256 feesUnit = amount.mul(price).mul(feeRate).div(100).div(3);
        uint256 fees = feesUnit.mul(2);
        bonusFeesCredits[makerAccount] = bonusFeesCredits[makerAccount]
            .add(feesUnit);
        if (fees == 0) {
            fees = 1;
        }

        // Pay fees
        uint256 takenFromBonus = min(fees, bonusFeesCredits[takerAccount]);
        uint256 remainingFees = fees.sub(takenFromBonus);
        bonusFeesCredits[takerAccount] = bonusFeesCredits[takerAccount]
            .sub(takenFromBonus);
        feesCredits[takerAccount] = feesCredits[takerAccount].sub(
            remainingFees,
            "ERC1155Exchange: not enough fee credit"
        );
        pendingWithdrawals[address(tokenContract)] = pendingWithdrawals[address(tokenContract)]
            .add(remainingFees);

        return fees;
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

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }
}
