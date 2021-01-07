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
        exchange.addOrder(true, 600, 5, address(1), true);
        exchange.addOrder(true, 520, 5, address(2), true);
        exchange.addOrder(true, 520, 10, address(3), true);
        exchange.addOrder(false, 700, 7, address(4), true);
    }

    function testFillOrderLimit() public {
        exchange.addOrder(false, 600, 5, address(5), true);
    }
}
