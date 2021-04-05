pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/payment/escrow/Escrow.sol";

import "../../utils/ReentrancyGuardInternal.sol";
import "./EscrowPayable.sol";
import "../../erc1155/TradableERC1155Interface.sol";


contract EtherManager is ReentrancyGuardInternal {
    using SafeMath for uint256;

    event Log(uint256 x);
    address public operator;
    TradableERC1155Interface public tokenContract;
    uint256 public feeRate;

    EscrowPayable public escrow;
    EscrowPayable public escrowFeeCredit;
    EscrowPayable public escrowBonusFeeCredit;

    function initializeEtherManager() internal {
        escrow = new EscrowPayable();
        escrowFeeCredit = new EscrowPayable();
        escrowBonusFeeCredit = new EscrowPayable();
    }

    function setFeeRate(uint256 newFeeRate) public {
        require(msg.sender == operator, "ERC1155Exchange: caller is not operator");
        feeRate = newFeeRate;
    }

    function depositFeeCredit() public payable {
        require(msg.value > 0, "ERC1155Exchange: Can't deposit zero");
        escrowFeeCredit.deposit{ value: msg.value }(msg.sender);
    }

    function withdrawFeeCredit() public nonReentrant {
        escrowFeeCredit.withdraw(msg.sender);
    }

    function withdraw() public nonReentrant {
        escrow.withdraw(msg.sender);
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
        emit Log(0);
        // Calculate fees
        uint256 fees = amount.mul(price).mul(feeRate).div(100);
        if (fees == 0) {
            fees = 1;
        }
        uint256 feeUnit = fees.div(3);
        uint256 takerFees = feeRate.mul(2);
        uint256 bonusFees = feeUnit;

        // Pay fees
        // From bonus, first
        uint256 takenFromBonus;
        if (fees < escrowBonusFeeCredit.depositsOf(takerAccount)) {
            takenFromBonus = fees;
        } else {
            takenFromBonus = escrowBonusFeeCredit.depositsOf(takerAccount);
        }
        escrowBonusFeeCredit.pay(takerAccount, takenFromBonus, "ERC1155Exchange: error 73");
        if (takenFromBonus < fees) {
            // Then, From simple fee credit
            uint256 remainingFees = fees.sub(takenFromBonus); // fees taken from (no bonus) fee credit
            escrowFeeCredit.pay(
                takerAccount,
                remainingFees,
                "ERC1155Exchange: not enough fee credit"
            );
        }

        // tokenContract take the fees
        // escrow.deposit{ value: takerFees }(address(tokenContract));

        // Give the bonus to the maker
        escrowBonusFeeCredit.deposit{ value: bonusFees }(makerAccount);

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
