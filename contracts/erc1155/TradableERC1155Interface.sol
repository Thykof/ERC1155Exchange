pragma solidity 0.6.2;

import "./TradableERC1155InterfaceBase.sol";


interface TradableERC1155Interface is TradableERC1155InterfaceBase {
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/token/ERC1155/IERC1155.sol
    function isApprovedForAll(address account, address operator) external view returns (bool);
}
