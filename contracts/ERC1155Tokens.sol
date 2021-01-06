pragma solidity 0.6.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ERC1155Interface.sol";
import "./ERC1155Exchange.sol";


contract ERC1155Tokens is ERC1155(""), ERC1155Interface {
    using SafeMath for uint256;

    address public owner;
    mapping(address => uint256) private exchangesToTokenId;

    constructor() public {
        owner = msg.sender;
    }

    function newToken(address account, uint256 tokenId, uint256 amount) public {
        require(msg.sender == owner, "ERC1155Tokens: Sender is not contract owner");

        _mint(account, tokenId, amount, new bytes(0));

        ERC1155Exchange exchangeAddress = new ERC1155Exchange();
        exchangesToTokenId[address(exchangeAddress)] = tokenId;
    }

    function executeTrade(
        address buyer,
        address seller,
        uint256 amount
    )
        public
        override
    {
        require(msg.sender != owner, "ERC1155Tokens: Sender is contract owner");

        uint256 tokenId = exchangesToTokenId[msg.sender];
        require(tokenId != 0, "ERC1155Tokens: Sender is not an exchange");

        safeTransferFrom(seller, buyer, tokenId, amount, new bytes(0));
    }
}
