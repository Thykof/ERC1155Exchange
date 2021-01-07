pragma solidity 0.6.2;

import "truffle/Assert.sol";

import "../contracts/ERC1155Exchange.sol";
import "../contracts/ERC1155Tokens.sol";


contract TestERC1155Exchange {

    ERC1155Tokens private token;
    ERC1155Exchange private exchange;

    function beforeEach() public {
        token = new ERC1155Tokens();

        exchange = token.newToken(address(1), 1, 300);
    }

    function beforeEachAgain() public {
        exchange.addOrder(true, 600, 5);
        exchange.addOrder(true, 520, 5);
        exchange.addOrder(true, 520, 10);
        exchange.addOrder(false, 700, 7);
    }

    function testFillOrderLimit() public {
        exchange.addOrder(false, 600, 5);
    }
}
