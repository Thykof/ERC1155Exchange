pragma solidity 0.6.0;


library OrderStruct {
    struct Order {
        uint256 timestamp;
        uint256 price; // is it really necesssary?
        uint256 amount;
        address makerAccount;
    }
}
