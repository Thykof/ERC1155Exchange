pragma solidity 0.6.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";

import "./TradableERC1155InterfaceBase.sol";
import "../exchange/ProxyAndStorageForERC1155Exchange.sol";
import "../exchange/IERC1155Exchange.sol";


contract ERC1155Token is ERC1155(""), ProxyAdmin, TradableERC1155InterfaceBase {

    event TokenCreated(
        address account,
        uint256 tokenId,
        uint256 amount,
        address exchangeAddress
    );

    mapping(uint256 => address payable) private tokenIdToProxyExchange;
    uint256[] private tokenIdList;
    address private exchangeImplementationAddress;

    constructor(address initialImplementation) public {
        exchangeImplementationAddress = initialImplementation;
    }

    function upgrade(address implementation, uint256 tokenId, bool all)
        public
        onlyOwner
    {
        // does this function usefull? TODO: test upgrade directly with contract call
        if (all == true) {
            for (uint256 tokenId_ = 0; tokenId_ < tokenIdList.length; tokenId_++) {
                upgrade(
                    ProxyAndStorageForERC1155Exchange(
                        tokenIdToProxyExchange[tokenId_]
                    ),
                    implementation
                );
            }
        } else {
            upgrade(
                ProxyAndStorageForERC1155Exchange(
                    tokenIdToProxyExchange[tokenId]
                ),
                implementation
            );
        }
    }

    function newToken(
        address account,
        uint256 tokenId,
        uint256 amount
    )
        public
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
                "initialize(address,uint256,uint256)",
                address(this),
                tokenId,
                3
            )
        );
        tokenIdToProxyExchange[tokenId] = address(exchange);
        tokenIdList.push(tokenId);

        emit TokenCreated(account, tokenId, amount, address(exchange));
    }

    function setFeeRate(uint256 tokenId, uint256 newFeeRate, bool all)
        public
        onlyOwner
    {
        if (all == true) {
            for (uint256 tokenId_ = 0; tokenId_ < tokenIdList.length; tokenId_++) {
                IERC1155Exchange(tokenIdToProxyExchange[tokenId_]).setFeeRate(
                    newFeeRate
                );
            }
        } else {
            IERC1155Exchange(tokenIdToProxyExchange[tokenId]).setFeeRate(
                newFeeRate
            );
        }
    }

    function withdrawFeeBalance(uint256 tokenId, bool all) public onlyOwner {
        if (all == true) {
            for (uint256 tokenId_ = 0; tokenId_ < tokenIdList.length; tokenId_++) {
                IERC1155Exchange(
                    tokenIdToProxyExchange[tokenId_]
                ).withdrawFeeBalance();
            }
        } else {
            IERC1155Exchange(
                tokenIdToProxyExchange[tokenId]
            ).withdrawFeeBalance();
        }
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
            "ERC1155Token: Bad sender"
        );

        safeTransferFrom(seller, buyer, tokenId, amount, new bytes(0));
    }
}
