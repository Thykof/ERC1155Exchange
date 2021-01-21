pragma solidity 0.6.2;


interface IERC1155Exchange {
    function setFeeRate(uint256 newFeeRate) external;
    function withdrawFeeBalance() external;
}
