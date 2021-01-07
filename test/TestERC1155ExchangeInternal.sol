pragma solidity 0.6.2;

import "truffle/Assert.sol";

import "../contracts/ERC1155Exchange.sol";


contract TestERC1155ExchangeInternal is ERC1155Exchange {
    function testAddOrderAndCheckForMatchingOrder() public {
        addOrder(true, 520, 1, address(0), true);
        addOrder(false, 700, 1, address(0), true);

        Assert.equal(
            checkForMatchingOrder(false, 520),
            true,
            "buy order with price 520 exists."
        );

        Assert.equal(
            checkForMatchingOrder(false, 10),
            false,
            "buy order with price 10 does not exist."
        );

        Assert.equal(
            checkForMatchingOrder(true, 700),
            true,
            "sell order with price 700 exists."
        );

        Assert.equal(
            checkForMatchingOrder(true, 999),
            false,
            "sell order with price 999 does not exist."
        );
    }
}
