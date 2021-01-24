pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "../erc1155/TradableERC1155Interface.sol";


contract EtherManager {
    using SafeMath for uint256;

    address internal operator;
    TradableERC1155Interface public tokenContract;
    uint256 public feeRate;
    mapping (address => uint) public pendingWithdrawals;

    // deposit and withdrawal allowed
    mapping (address => uint) public feesCredits;

    // no deposit, no withdrawal
    mapping (address => uint) public bonusFeesCredits;

    function setFeeRate(uint256 newFeeRate) public {
        require(msg.sender == operator, "ERC1155Exchange: caller is not operator");
        feeRate = newFeeRate;
    }

    function withdraw() public {
        // See https://docs.soliditylang.org/en/v0.6.2/common-patterns.html
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function depositFeeCredit() public payable {
        require(msg.value > 0, "ERC1155Exchange: Can't deposit zero");
        feesCredits[msg.sender] = feesCredits[msg.sender].add(msg.value);
    }

    function withdrawFeeCredit(uint256 amount) public {
        feesCredits[msg.sender] = feesCredits[msg.sender].sub(
            amount,
            "ERC1155Exchange: withdrawal amount exceed balance"
        );
        msg.sender.transfer(amount);
    }

    function payFees(
        uint256 price,
        uint256 amount,
        address makerAccount,
        address takerAccount
    )
        internal
        returns (uint256)
    {
        // Calculate fees
        uint256 fees = amount.mul(price).mul(feeRate).div(100);
        uint256 bonusFees = fees.div(3);
        bonusFeesCredits[makerAccount] = bonusFeesCredits[makerAccount]
            .add(bonusFees);

        if (fees == 0) {
            fees = 1;
        }

        // Pay fees
        uint256 takenFromBonus = Math.min(fees, bonusFeesCredits[takerAccount]);
        uint256 remainingFees = fees.sub(takenFromBonus);
        bonusFeesCredits[takerAccount] = bonusFeesCredits[takerAccount]
            .sub(takenFromBonus);
        feesCredits[takerAccount] = feesCredits[takerAccount].sub(
            remainingFees,
            "ERC1155Exchange: not enough fee credit"
        );
        pendingWithdrawals[address(tokenContract)] = pendingWithdrawals[
            address(tokenContract)
        ].add(remainingFees);

        return fees;
    }

    function getWeiPrice(
        uint256 price,
        uint256 amount
    )
        internal
        pure
        returns (uint256)
    {
        return price * amount;
    }
}
