pragma solidity 0.6.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ERC1155Interface.sol";
import "./ERC1155Exchange.sol";


contract ERC1155Tokens is ERC1155(""), ERC1155Interface {
    using SafeMath for uint256;

    event TokenCreated(
        address account,
        uint256 tokenId,
        uint256 amount,
        address exchangeAddress
    );

    address public owner;
    mapping(address => uint256) private exchangesToTokenId;
    mapping(uint256 => address) private tokenIdToExchange;

    constructor() public {
        owner = msg.sender;
    }

    function newToken(
        address account,
        uint256 tokenId,
        uint256 amount
    )
        public
        returns (ERC1155Exchange exchange)
    {
        require(msg.sender == owner, "ERC1155Tokens: Sender is not contract owner");
        require(tokenId != 0, "ERC1155Tokens: tokenId can't be zero");
        require(tokenIdToExchange[tokenId] == address(0), "ERC1155Tokens: token already created");

        _mint(account, tokenId, amount, new bytes(0));

        exchange = new ERC1155Exchange(tokenId);
        exchangesToTokenId[address(exchange)] = tokenId;
        tokenIdToExchange[tokenId] = address(exchange);

        emit TokenCreated(account, tokenId, amount, address(exchange));
    }

    function checkApproved(
        uint256 tokenId,
        address account
    )
        public
        override
        returns (bool)
    {
        require(msg.sender != owner, "ERC1155Tokens: Sender is contract owner");

        uint256 id = exchangesToTokenId[msg.sender];
        require(id != 0, "ERC1155Tokens: Sender is not an exchange");
        require(id == tokenId, "ERC1155Tokens: bad tokenId");
        require(msg.sender == tokenIdToExchange[tokenId], "ERC1155Tokens: Bad sender");

        return isApprovedForAll(account, msg.sender);
    }

    function executeTrade(
        uint256 tokenId,
        address buyer,
        address seller,
        uint256 amount
    )
        public
        override
    {
        require(msg.sender != owner, "ERC1155Tokens: Sender is contract owner");

        uint256 id = exchangesToTokenId[msg.sender];
        require(id != 0, "ERC1155Tokens: Sender is not an exchange");
        require(id == tokenId, "ERC1155Tokens: bad tokenId");
        require(msg.sender == tokenIdToExchange[tokenId], "ERC1155Tokens: Bad sender");

        safeTransferFrom(seller, buyer, tokenId, amount, new bytes(0));
    }
}
