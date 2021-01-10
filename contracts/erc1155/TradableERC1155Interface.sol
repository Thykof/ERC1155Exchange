pragma solidity 0.6.2;


interface TradableERC1155Interface {
    function executeTrade(
        uint256 tokenId,
        address buyer,
        address seller,
        uint256 amount
    ) external;

    function checkApproved(
        uint256 tokenId,
        address account
    )
    external
    returns (bool);
}
