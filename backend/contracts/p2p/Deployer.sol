//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Deal.sol";

contract deployer_contract is Context {
    deal_contract private dealContract;

    address private owner;

    constructor() {
        owner = _msgSender();
    }

    struct p2pRequest {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress; // * Address of the Deal Contract
        uint256 instalmentAmount; //* Amount to be paid in each instalment
        uint256 totalAmount; // * Total Amount borrowed
        uint256 interestRate; // * Interest Rate by the Lender
        uint16 noOfInstalments; // * No of Instalments
        bool requestAccepted; // * Request Raised by the lender or not
    }

    p2pRequest private p2pRequest;

    // * To store all the p2pRequests made in the protocol
    mapping(address => p2pRequest) private p2pRequests;

    function getRequests(address _borrower) external view returns (p2pRequest memory) {
        return p2pRequests[_borrower];
    }

    // * To deploy the Deal Contract
    function p2pDeploy() internal {
        p2pRequest storage requestDetails = p2pRequest;

        dealContract = new deal_contract(
            requestDetails.borrower,
            requestDetails.lender,
            requestDetails.instalmentAmount,
            requestDetails.totalAmount,
            requestDetails.interestRate,
            requestDetails.noOfInstalments
        );

        p2pRequests[requestDetails.borrower].dealAddress = address(dealContract);

        delete p2pRequest;

        // emit Event to notify both lender and borrower
    }

    // * To raise the p2pRequest to borrow
    function p2pRaiseRequest(
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint16 _noOfInstalments,
        address _lender
    ) external {
        require(!p2pRequests[_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted

        p2pRequest storage requestDetails = p2pRequest;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.instalmentAmount = _instalmentAmount;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.interestRate = _interestRate;
        requestDetails.noOfInstalments = _noOfInstalments;

        p2pRequests[_msgSender()] = requestDetails;

        // emit event to notify lender
    }

    // * To accept the p2pRequest made by the borrower
    function p2pAcceptRequest(address _borrower) external payable {
        require(!p2pRequests[_borrower].requestAccepted, "ERR:AA"); // AA =>Already Accepted

        uint256 value = msg.value;
        require(p2pRequests[_borrower].totalAmount == value, "ERR:WV"); // WV => Wrong Value

        p2pRequests[_borrower].requestAccepted = true;

        deploy();

        (bool success, ) = _borrower.call{value: value}("");
        require(success, "ERR:OT"); // OT => On Transfer

        // emit event to notify borrower
    }
}
