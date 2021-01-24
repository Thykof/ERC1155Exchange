pragma solidity 0.6.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Pausable.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";

import "./TradableERC1155InterfaceBase.sol";
import "../exchange/ProxyAndStorageForERC1155Exchange.sol";


contract ERC1155Token is ERC1155Pausable, ProxyAdmin, TradableERC1155InterfaceBase {

    event TokenCreated(
        address account,
        uint256 tokenId,
        uint256 amount,
        address exchangeAddress
    );

    mapping(uint256 => address payable) public tokenIdToProxyExchange;
    uint256[] private tokenIdList;
    address private exchangeImplementationAddress;

    constructor(address initialImplementation) public ERC1155("") {
        exchangeImplementationAddress = initialImplementation;
    }

    function setPause(bool paused) public onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function newToken(
        address account,
        uint256 tokenId,
        uint256 amount
    )
        public
        whenNotPaused
        returns (ProxyAndStorageForERC1155Exchange exchange)
    {
        require(
            msg.sender == owner(),
            "ERC1155Token: Sender is not contract owner"
        );
        require(tokenId != 0, "ERC1155Token: tokenId can't be zero");
        require(
            tokenIdToProxyExchange[tokenId] == address(0),
            "ERC1155Token: token already created"
        );

        _mint(account, tokenId, amount, new bytes(0));

        exchange = new ProxyAndStorageForERC1155Exchange(
            exchangeImplementationAddress,
            abi.encodeWithSignature(
                "initialize(address,uint256,uint256,address)",
                address(this),
                tokenId,
                3,
                owner()
            )
        );
        tokenIdToProxyExchange[tokenId] = address(exchange);
        tokenIdList.push(tokenId);

        emit TokenCreated(account, tokenId, amount, address(exchange));
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
        require(
            msg.sender == tokenIdToProxyExchange[tokenId],
            "ERC1155Token: Bad caller"
        );

        safeTransferFrom(seller, buyer, tokenId, amount, new bytes(0));
    }
}
