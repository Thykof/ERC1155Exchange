pragma solidity 0.6.2;


contract ERC1155ExchangeEvents {
    // Copied from:
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/token/ERC1155/IERC1155.sol
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    // Exchange events
    event OrderAdded(
        uint256 indexed tokenId,
        bool buySide,
        uint256 price,
        uint256 indexed amount,
        address indexed makerAccount
    );

    event OrderFilled(
        uint256 indexed tokenId,
        bool partiallyFilled,
        bool buySide,
        uint256 price,
        uint256 amount,
        address indexed makerAccount,
        address indexed takerAccount
    );

    event TradeExecuted(
        uint256 indexed tokenId,
        bool buySide,
        uint256 amount,
        address indexed buyerAccount,
        address indexed sellerAccount,
        uint256 pendingWithdrawals
    );
}
