pragma solidity 0.6.0;

import "./BokkyPooBahsRedBlackTreeLibrary.sol";


library OrderedListLibrary {
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;

    struct OrderedList {
        BokkyPooBahsRedBlackTreeLibrary.Tree tree;
        mapping (uint256 => uint256) keyToValue;
    }

    function first(OrderedList storage self) internal view returns (uint256) {
        return self.keyToValue[self.tree.first()];
    }

    function insert(OrderedList storage self, uint256 key, uint256 value) internal {
        self.tree.insert(key);
        self.keyToValue[key] = value;
    }

}
