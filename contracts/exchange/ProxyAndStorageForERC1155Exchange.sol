pragma solidity 0.6.2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";


contract ProxyAndStorageForERC1155Exchange is TransparentUpgradeableProxy {
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
    {
        // Is this realy necessary?
    }
}
