pragma solidity 0.6.2;


interface TradableERC1155InterfaceBase {
    function executeTrade(
        uint256 tokenId,
        address buyer,
        address seller,
        uint256 amount
    ) external;
}
