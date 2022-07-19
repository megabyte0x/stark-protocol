// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Context.sol";

contract guarantee_contract is Context {
    address private deployer;
    address private borrower;
    address private lender;

    struct GuranteeDetails {
        uint256 totalAmount; // * Total amount borrowed by the borrower
        uint256 totalAmountToPay; // * Total amount left to be paid
        uint256 amountPaidTotal; // * Amount paid by the borrower in total
        uint256 timeRentedSince; // * Time when the deal started
        uint256 timeRentedUntil; // * Time when the deal will end
    }

    GuranteeDetails private deal;

    constructor(
        address _borrower,
        address _lender,
        uint256 _totalAmount,
        uint256 _timeRentedUntil
    ) {
        deployer = _msgSender();
        borrower = _borrower;
        lender = _lender;

        GuranteeDetails storage dealDetails = deal;

        dealDetails.timeRentedSince = block.timestamp;
        dealDetails.timeRentedUntil = block.timestamp + _timeRentedUntil;
        dealDetails.totalAmount = _totalAmount;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "ERR:BO"); // BO => Borrower only
        _;
    }

    // * FUNCTION: To get the address of the borrower.
    function getBorrower() public view returns (address) {
        return borrower;
    }

    // * FUNCTION: To get the address of the lender.
    function getLender() public view returns (address) {
        return lender;
    }

    // * FUNCTION: To get the detials of the Deal.
    function getDealDetails() public view returns (GuranteeDetails memory) {
        return deal;
    }

    // * FUNCTION: To get the amount left to be paid
    function getTotalAmountLeft() public view returns (uint256) {
        return deal.totalAmountToPay;
    }

    function repay() external payable onlyBorrower {
        GuranteeDetails storage dealDetails = deal;
        require(dealDetails.amountPaidTotal < dealDetails.totalAmount, "ERR:NM"); // NM => No more installments

        uint256 value = msg.value;
        require(value <= 0, "ERR:MA"); // MA => Minimum Amount should be greater than zero

        (bool success, ) = lender.call{value: amtToLender}("");
        require(success, "ERR:OT"); //OT => On Transfer

        dealDetails.amountPaidTotal += value;
        dealDetails.totalAmountToPay -= value;

        if(dealDetails.amountPaidTotal == dealDetails.totalAmount){
            // emit Event
            // Release the collateral
        }  
    }
}