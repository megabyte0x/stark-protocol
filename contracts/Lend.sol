//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

contract Lend is Context {
    address private deployer;
    address private borrower;
    address private lender;

    struct DealDetials {
        uint256 totalAmount; // * Total amount borrowed by the borrower
        uint256 amountPaidTotal; // * Amount paid by the borrower in total
        uint256 instalmentAmt; // * Amount to be paid per insalment
        uint256 timeRentedSince; // * Time when the deal started
        uint256 interestRate; // * Interest rate decided by the lender.
        uint8 noOfInstalments; // * No of instalments in which borrower will pay amount
        bool addedInstalments; // * If borrower got more instalments after request.
    }

    DealDetials private deal;

    constructor(
        address _borrower,
        address _lender,
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint8 _noOfInstalments
    ) {
        deployer = _msgSender();
        borrower = _borrower;
        lender = _lender;

        DealDetials storage dealDetails = deal;

        dealDetails.instalmentAmt = _instalmentAmount;
        dealDetails.noOfInstalments = _noOfInstalments;
        dealDetails.totalAmount = _totalAmount;
        dealDetails.interestRate = _interestRate;
        dealDetails.timeRentedSince = uint256(block.timestamp);
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "ERR:BO"); // BO => Borrower only
        _;
    }

    modifier onlyLender() {
        require(msg.sender == lender, "ERR:LO"); // BL => Lender only
        _;
    }

    function payAtOnce() external payable onlyBorrower {
        DealDetials storage dealDetails = deal;
        require(dealDetails.noOfInstalments > 0, "ERR:NM"); // NM => No more installments
        require(
            dealDetails.amountPaidTotal < dealDetails.totalAmount,
            "ERR:NM"
        ); // NM => No more installments

        uint256 value = msg.value;
        uint256 amountLeftToPay = dealDetails.totalAmount -
            dealDetails.amountPaidTotal;
        require(value == amountLeftToPay, "ERR:WV"); // WV => Wrong value

        (bool success, ) = lender.call{value: value}("");
        require(success, "ERR:OT"); //OT => On Trnasfer

        dealDetails.amountPaidTotal += value;
    }

    function payInInstallment() external payable onlyBorrower {
        DealDetials storage dealDetails = deal;

        require(dealDetails.noOfInstalments <= 0, "ERR:NM"); // NM => No more installments

        uint256 value = msg.value;
        uint256 interestAmt = (dealDetails.instalmentAmt *
            dealDetails.interestRate);
        require(value == dealDetails.instalmentAmt + interestAmt, "ERR:WV"); // WV => Wrong value

        if (dealDetails.addedInstalments) {
            uint256 amtToLeder = dealDetails.instalmentAmt +
                (interestAmt * 95 * 10**16);
            uint256 amtToProtocol = interestAmt * 5 * 10**16;

            (bool successInLender, ) = lender.call{value: amtToLeder}("");
            require(successInLender, "ERR:OT"); //OT => On Transfer

            (bool successInBorrower, ) = deployer.call{value: amtToProtocol}(
                ""
            );
            require(successInBorrower, "ERR:OT"); //OT => On Transfer
        } else {
            uint256 amtToLenderOnly = dealDetails.instalmentAmt + interestAmt;

            (bool success, ) = lender.call{value: amtToLenderOnly}("");
            require(success, "ERR:OT"); //OT => On Transfer
        }

        dealDetails.amountPaidTotal += value;
        --dealDetails.noOfInstalments;
    }

    function requestNoOfInstalment(uint8 noOfAddInstalments)
        external
        onlyBorrower
    {
        require(noOfAddInstalments >= 3, "ERR:MR"); // MR => Minimum required no of instalments

        acceptRequestOfInstalment(noOfAddInstalments);
    }

    function acceptRequestOfInstalment(
        uint8 _noOfAddInstalments,
        uint8 _interestRate
    ) external onlyLender {
        DealDetials storage dealDetails = deal;

        dealDetails.noOfInstalments += _noOfAddInstalments;
        dealDetails.interestRate = _interestRate;

        deal.addedInstalments = true;
    }
}
