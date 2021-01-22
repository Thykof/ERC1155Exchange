pragma solidity 0.6.2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

import "./ERC1155ExchangeEvents.sol";


contract ProxyAndStorageForERC1155Exchange is TransparentUpgradeableProxy,
    ERC1155ExchangeEvents {
    constructor(
        address exchangeImplementationAddress,
        bytes memory _data
    )
        public
        TransparentUpgradeableProxy(
            exchangeImplementationAddress,
            msg.sender,
            _data
        )
    {}
}
