pragma solidity 0.6.0;

import "./OrderedListLibrary.sol";
import "./BokkyPooBahsRedBlackTreeLibrary.sol";


contract Test {
    using OrderedListLibrary for OrderedListLibrary.OrderedList;
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;

    OrderedListLibrary.OrderedList private bids;
    BokkyPooBahsRedBlackTreeLibrary.Tree private tree;

    function getFirst() public view returns (uint256) {
        return bids.first();
    }

    function insertBid(uint256 key, uint256 value) public {
        bids.insert(key, value);
    }

    function insertTree(uint256 key) public {
        tree.insert(key);
    }

    function batch(uint256 n) public {
        require(n > 1, "n <= 1");
        for (uint i = 1; i < n; i++) {
            bids.insert(i*100, i*10);
        }
    }
}
