//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

contract Lend is Context {
    
    address private deployer;
    address private borrower;
    address private lender;

    struct DealDetials {
        uint256 amountDueTotal;
        uint256 amountPaidTotal;
        uint256 instalmentAmt;
        uint64 timeRentedSince;
        uint64 timeRentedUntil;
        uint8 noOfInstalments;
        uint8 interestRate;
    }

    DealDetials private deal;

    constructor(
        address _borrower,
        address _lender,
        uint256 _amountDueTotal,
        uint64 _timeRentedSince,
        uint64 _timeRentedUntil,
        uint8 _noOfInstalments
    ) {
        deployer = _msgSender();
        borrower = _borrower;
        lender = _lender;
        uint256 _instalmentAmt = _amountDueTotal / _noOfInstalments;
        deal = DealDetials(
            _amountDueTotal,
            _instalmentAmt,
            _timeRentedSince,
            _timeRentedUntil,
            _noOfInstalments
        );
        deal.amountPaidTotal = 0;
        deal.interestRate = 0;
    }

    function payAtOnce() external onlyBorrowee {
        require(deal.amountDueTotal > 0, "ERR:NM"); // NM => No more installments
        require(deal.noOfInstalments > 0, "ERR:NM"); // NM => No more installments
        require (deal.timeRentedUntil< block.timestamp, "ERR:TM"); // TM => Timeout

        uint256 value = msg.value;
        require(value == deal.amountDueTotal, "ERR:WV"); // WV => Wrong value

        (bool success, ) = lender.call{value: value}("");
        require(success, "ERR:OT"); //OT => On Trnasfer

        deal.amountPaidTotal += value;
        deal.amountDueTotal -= value;
    }

    function payInInstallment() external onlyBorrower {
        require(deal.amountDueTotal > 0, "ERR:NM"); // NM => No more installments
        require(deal.noOfInstalments > 0, "ERR:NM"); // NM => No more installments
        require (deal.timeRentedUntil< block.timestamp, "ERR:TM"); // TM => Timeout

        uint256 value = msg.value;
        uint256 interestAmt  =  (deal.instalmentAmt * deal.interestRate);
        require(value == deal.instalmentAmt + interestAmt, "ERR:WV"); // WV => Wrong value
        
        uint256 amtToLeder = deal.instalmentAmt + (interest * 95 * 10**17);
        uint256 amtToProtocol = interestAmt * 5 * 10**16;

        (bool success, ) = lender.call{value: amtToLeder}("");
        require(success, "ERR:OT"); //OT => On Trnasfer

        (bool success, ) = deployer.call{value: amtToProtocol}("");
        require(success, "ERR:OT"); //OT => On Trnasfer

        deal.amountPaidTotal += value;
        deal.amountDueTotal -= value;
    }

    function requestNoOfInstalment(unit8 noOfAddInstalments ) external onlyBorrower {
        require (noOfAddInstalments>=3, "ERR:MR"); // MR => Minimum required no of instalments

        acceptRequestOfInstalment(noOfAddInstalments); 
    }

    function acceptRequestOfInstalment(uint8 _noOfAddInstalments, uint8 _interestRate) external onlyLender {
        
        deal.noOfInstalments += _noOfAddInstalments;
        deal.interestRate =  _interestRate;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "ERR:BO"); // BO => Borrower only
        _;
    }

    modifier onlyLender () {
        require(msg.sender == lender, "ERR:BL"); // BL => Lender only
        _;
    }

}
