pragma solidity 0.6.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Pausable.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";

import "../exchange/ProxyAndStorageForERC1155Exchange.sol";


contract TradableERC1155Token is ERC1155Pausable, ProxyAdmin {

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
            "TradableERC1155Token: Sender is not contract owner"
        );
        require(tokenId != 0, "TradableERC1155Token: tokenId can't be zero");
        require(
            tokenIdToProxyExchange[tokenId] == address(0),
            "TradableERC1155Token: token already created"
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

        return exchange;
    }
}
