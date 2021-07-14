pragma solidity 0.6.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


/// @title ERC1155Token
/// @notice
/// @dev
contract ERC1155Token is ERC1155("") {
    /// @notice
    string public name = "My ERC1155 token for trading!";
}
