pragma solidity 0.6.2;


interface ERC1155Interface {
    function executeTrade(
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
