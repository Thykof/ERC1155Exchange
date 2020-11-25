pragma solidity 0.6.0;

import "./BokkyPooBahsRedBlackTreeLibrary.sol";


library OrderedMappingLibrary {
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;

    struct OrderedMapping {
        BokkyPooBahsRedBlackTreeLibrary.Tree tree;
        mapping (uint256 => uint256) keyToValue;
    }

    function getValue(OrderedMapping storage self, uint256 key)
        internal
        view
        returns (uint256)
    {
        return self.keyToValue[key];
    }

    function first(OrderedMapping storage self) internal view returns (uint256) {
        return self.keyToValue[self.tree.first()];
    }

    function insert(OrderedMapping storage self, uint256 key, uint256 value)
        internal
    {
        self.tree.insert(key);
        self.keyToValue[key] = value;
    }

    function exists(OrderedMapping storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self.tree.exists(key);
    }
}
