//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IStark.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deal is Context {
    using SafeMath for uint256;

    address private deployer;
    address private borrower;
    address private lender;
    address private starkAddress;

    Istark_protocol starkContract;

    struct DealDetials {
        address tokenAddress;
        uint256 totalAmount; // * Total amount borrowed by the borrower
        uint256 totalAmountToPay; // * Total amount including interest left to be paid
        uint256 amountPaidTotal; // * Amount paid by the borrower in total
        uint256 instalmentAmt; // * Amount to be paid per insalment
        uint256 timeRentedSince; // * Time when the deal started
        uint256 interestRate; // * Interest rate decided by the lender.
        uint256 addedInterestRate; // * Additional Interest Rate for additional no. of instalments.
        uint16 noOfInstalments; // * No of instalments in which borrower will pay amount
        bool addedInstalments; // * If borrower got more instalments after request.
    }

    DealDetials private deal;

    struct AdditionalRequest {
        uint16 noOfInstalments; // * No of additional instalments
        uint256 interestRate; // * Interest Rate
        bool isAccepted; // * Request Accepted or Not
    }

    mapping(address => AdditionalRequest) additionRequest;

    constructor(
        address _borrower,
        address _lender,
        address _starkAddress,
        address _tokenAddress,
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint16 _noOfInstalments
    ) {
        deployer = _msgSender();
        borrower = _borrower;
        lender = _lender;
        starkContract = Istark_protocol(_starkAddress);
        starkAddress = _starkAddress;

        DealDetials storage dealDetails = deal;

        dealDetails.noOfInstalments = _noOfInstalments;
        dealDetails.totalAmount = _totalAmount;
        dealDetails.interestRate = _interestRate;
        dealDetails.timeRentedSince = uint256(block.timestamp);
        dealDetails.instalmentAmt = getInstalmentAmount(_instalmentAmount);
        dealDetails.totalAmountToPay = _totalAmount;
        dealDetails.tokenAddress = _tokenAddress;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "ERR:BO"); // BO => Borrower only
        _;
    }

    modifier onlyLender() {
        require(msg.sender == lender, "ERR:LO"); // BL => Lender only
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
    function getDealDetails() public view returns (DealDetials memory) {
        return deal;
    }

    // * FUNCTION: To get the Instalment Amount
    function getInstalmentAmount(uint256 _instalmentAmount) public view returns (uint256) {
        DealDetials memory dealDetails = deal;
        uint256 interestAmount = (_instalmentAmount * dealDetails.interestRate) / 100;

        uint256 instalmentAmount = _instalmentAmount + interestAmount;
        return instalmentAmount;
    }

    // * FUNCTION: To get the number of instalments
    function getNoOfInstalments() public view returns (uint16) {
        return deal.noOfInstalments;
    }

    // * FUNCTION: To get the total amount owed
    function getTotalAmountOwed() public view returns (uint256) {
        return deal.totalAmount;
    }

    // * FUNCTION: To get the amount left to be paid
    function getTotalAmountLeft() public view returns (uint256) {
        return deal.totalAmountToPay;
    }

    // * FUNCTION: To get the interest rate
    function getInterestRate() public view returns (uint256) {
        return deal.interestRate;
    }

    // * FUNCTION: Pay the amount left at once
    function payAtOnce() external onlyBorrower {
        DealDetials memory dealDetails = deal;
        require(dealDetails.noOfInstalments > 0, "ERR:NM"); // NM => No more installments
        require(dealDetails.amountPaidTotal < dealDetails.totalAmount, "ERR:NM"); // NM => No more installments

        // uint256 value = msg.value;
        uint256 amountLeftToPay = getTotalAmountLeft();
        // require(value == amountLeftToPay, "ERR:WV"); // WV => Wrong value

        IERC20(dealDetails.tokenAddress).transferFrom(borrower, lender, amountLeftToPay);

        // starkContract.repayChanges(dealDetails.tokenAddress, lender, borrower, amountLeftToPay);

        deal.amountPaidTotal += amountLeftToPay;
        deal.totalAmountToPay -= amountLeftToPay;
    }

    // * FUNCTION: Pay the pre-defined amount in instalments not necessarily periodically.
    function payInInstalment() external payable onlyBorrower {
        DealDetials memory dealDetails = deal;

        require(dealDetails.noOfInstalments > 0, "ERR:NM"); // NM => No more installments
        require(dealDetails.amountPaidTotal < dealDetails.totalAmount, "ERR:NM"); // NM => No more installments

        // * amtToLenderOnly: Amount with standard interest
        uint256 amtToLenderOnly = dealDetails.instalmentAmt;

        if (dealDetails.addedInstalments) {
            // * totalInterestedAmount: Amount after additional interest is added
            uint256 totalInterestedAmount = amtToLenderOnly +
                (dealDetails.addedInterestRate * dealDetails.instalmentAmt);

            // require(value == totalInterestedAmount, "ERR:WV"); // WV => Wrong value

            // * amtToLender: Amount after with 95% of additional interest is added
            uint256 amtToLender = amtToLenderOnly +
                ((dealDetails.instalmentAmt * 95) / 100) *
                (dealDetails.addedInterestRate);

            // * amtToProtocol: Amount after with 5% of additional interest is added
            uint256 amtToProtocol = ((dealDetails.instalmentAmt * 5) / 100) *
                dealDetails.addedInterestRate;

            // (bool successInLender, ) = lender.call{value: amtToLender}("");
            // require(successInLender, "ERR:OT"); //OT => On Transfer

            // starkContract.repayChanges(dealDetails.tokenAddress, lender, borrower, amtToLender);

            IERC20(dealDetails.tokenAddress).transferFrom(borrower, lender, amtToLender);
            IERC20(dealDetails.tokenAddress).transferFrom(borrower, starkAddress, amtToProtocol);

            // (bool successInBorrower, ) = deployer.call{value: amtToProtocol}("");
            // require(successInBorrower, "ERR:OT"); //OT => On Transfer
            deal.amountPaidTotal += amtToLender;
            deal.totalAmountToPay -= amtToLender;
            //! TODO: Function to pass the value to the protocol
        } else {
            // starkContract.repayChanges(
            //     dealDetails.tokenAddress,
            //     lender,
            //     borrower,
            //     amtToLenderOnly
            // );

            IERC20(dealDetails.tokenAddress).transferFrom(borrower, lender, amtToLenderOnly);

            deal.amountPaidTotal += amtToLenderOnly;
            deal.totalAmountToPay -= amtToLenderOnly;
        }
        --deal.noOfInstalments;
    }

    // * FUNCTION: Request the Lender for more instalments
    function requestNoOfInstalment(uint16 noOfAddInstalments, uint256 _interestRate)
        external
        onlyBorrower
    {
        require(noOfAddInstalments >= 3, "ERR: Minimum required no of instalments");

        additionRequest[_msgSender()] = AdditionalRequest(
            noOfAddInstalments,
            _interestRate,
            false
        );

        // emit event
    }

    // * FUNCTION: Accept the request made the Lender for more instalments
    function acceptRequestOfInstalment(
        address _borrower,
        uint16 _noOfAddInstalments,
        uint256 _interestRate
    ) external onlyLender {
        require(!additionRequest[_borrower].isAccepted, "ERR: Already Accepted");

        additionRequest[_borrower].isAccepted = true;

        deal.noOfInstalments += _noOfAddInstalments;
        deal.addedInterestRate = _interestRate;
        deal.addedInstalments = true;
    }
}
