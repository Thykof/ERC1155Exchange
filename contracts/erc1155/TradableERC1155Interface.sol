pragma solidity 0.6.2;


interface TradableERC1155Interface {
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/token/ERC1155/IERC1155.sol
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function paused() external view returns (bool);
}
