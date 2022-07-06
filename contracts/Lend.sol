//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

contract Lend is Context{

    address private deployer;
    address private borrower;
    address private lender;

        struct DealDetials {
        uint256 amountDueTotal;
        uint256 amountPaidTotal;
        uint64 timeRentedSince;
        uint64 timeRentedUntil;
        uint8 noOfInstallments;
    }

    DealDetials private deal;

    constructor(
        address _borrower,
        address _lender,
        uint256 _amountDueTotal,
        uint256 _amountPaidTotal,
        uint64 _timeRentedSince,
        uint64 _timeRentedUntil,
        uint8 _noOfInstallments
    ) {
        borrower = _borrower;
        lender = _lender;
        deal = DealDetials(
            _amountDueTotal,
            _amountPaidTotal,
            _timeRentedSince,
            _timeRentedUntil,
            _noOfInstallments
        );
        deployer = _msgSender();
    }

    function payInstallment () external{

    }

   
}
