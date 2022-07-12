//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Deal.sol";

contract deployer_contract is Context {
    deal_contract private dealContract;

    address private owner;

    constructor() {
        owner = _msgSender();
    }

    struct Request {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress; // * Address of the Deal Contract
        uint256 instalmentAmount; //* Amount to be paid in each instalment
        uint256 totalAmount; // * Total Amount borrowed
        uint256 interestRate; // * Interest Rate by the Lender
        uint16 noOfInstalments; // * No of Instalments
        bool requestAccepted; // * Request Raised by the lender or not
    }

    Request private request;

    // * To store all the requests made in the protocol
    mapping(address => Request) private requests;

    function getRequests(address _borrower)
        external
        view
        returns (Request memory)
    {
        return requests[_borrower];
    }

    // * To deploy the Deal Contract
    function deploy() internal {
        Request storage requestDetails = request;

        dealContract = new deal_contract(
            requestDetails.borrower,
            requestDetails.lender,
            requestDetails.instalmentAmount,
            requestDetails.totalAmount,
            requestDetails.interestRate,
            requestDetails.noOfInstalments
        );

        requests[requestDetails.borrower].dealAddress = address(dealContract);

        delete request;

        // emit Event to notify both lender and borrower
    }

    // * To raise the request to borrow
    function raiseRequest(
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint16 _noOfInstalments,
        address _lender
    ) external {
        require(!requests[_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted

        Request storage requestDetails = request;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.instalmentAmount = _instalmentAmount;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.interestRate = _interestRate;
        requestDetails.noOfInstalments = _noOfInstalments;

        requests[_msgSender()] = requestDetails;

        // emit event to notify lender
    }

    // * To accept the request made by the borrower
    function acceptRequest(address _borrower) external payable {
        require(!requests[_borrower].requestAccepted, "ERR:AA"); // AA =>Already Accepted

        uint256 value = msg.value;
        require(requests[_borrower].totalAmount == value, "ERR:WV"); // WV => Wrong Value

        requests[_borrower].requestAccepted = true;

        deploy();

        (bool success, ) = _borrower.call{value: value}("");
        require(success, "ERR:OT"); // OT => On Transfer

        // emit event to notify borrower
    }
}
