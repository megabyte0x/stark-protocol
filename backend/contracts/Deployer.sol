//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "./p2p/Deal.sol";
import "./guarantee/guarantee.sol";

contract deployer_contract is Context {
    deal_contract private dealContract;
    guarantee_contract private guaranteeContract;

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
        bool requestAccepted; // * Request Raised by the lender accepted or not
    }

    p2pRequest private p2pRequestInstance;

    // * To store all the p2pRequests made in the protocol
    mapping(address => p2pRequest) private p2pRequests;

    struct guranteeRequest {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress;
        uint256 totalAmount; // * Amount looking for the gurantee
        uint256 _timeRentedUntil;
        bool requestAccepted; // * Request Raised by the lender accepted or not
    }

    guranteeRequest private guranteeRequestInstance;

    // * To store all the guranteeRequest made in the protocol
    mapping(address => guranteeRequest) private guranteeRequests;

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getP2PRequests(address _borrower) external view returns (p2pRequest memory) {
        return p2pRequests[_borrower];
    }

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getGuranteeRequests(address _borrower) external view returns (p2pRequest memory) {
        return guranteeRequests[_borrower];
    }

    // * FUNCTION: To deploy the Deal Contract
    function p2pDeploy() internal {
        p2pRequest storage requestDetails = p2pRequestInstance;

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

    function guranteeDeploy() internal {
        guranteeRequest storage requestDetails = guranteeRequestInstance;

        guaranteeContract = new guarantee_contract(
            requestDetails.borrower,
            requestDetails.lender,
            requestDetails.totalAmount,
            requestDetails.timeRentedUntil
        );

        guranteeRequests[requestDetails.borrower].dealAddress = address(guaranteeContract);

        delete guranteeRequest;
    }

    // * FUNCTION: To raise the p2pRequest to borrow
    function p2pRaiseRequest(
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint16 _noOfInstalments,
        address _lender
    ) external {
        require(!p2pRequests[_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted

        p2pRequest storage requestDetails = p2pRequestInstance;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.instalmentAmount = _instalmentAmount;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.interestRate = _interestRate;
        requestDetails.noOfInstalments = _noOfInstalments;

        p2pRequests[_msgSender()] = requestDetails;

        // emit event to notify lender
    }

    // * FUNCTION: To raise the request for backing the loan from the protocol
    function guaranteeRaiseRequest(
        uint256 _totalAmount,
        address _lender,
        uint256 _timeRentedUntil
    ) external {
        require(!guranteeRequests[_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted

        guranteeRequest storage requestDetails = guranteeRequestInstance;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.timeRentedUntil = _timeRentedUntil;

        guranteeRequests[_msgSender()] = requestDetails;

        // emit event to notify lender
    }

    // * FUNCTION: To accept the p2pRequest made by the borrower
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

    // * FUNCTION: To accept the guranteeRequest made by the borrower
    function guranteeAcceptRequest(address _borrower) external {
        require(!guranteeRequests[_borrower].requestAccepted, "ERR:AA"); // AA =>Already Accepted

        p2pRequests[_borrower].requestAccepted = true;

        guranteeDeploy();
        // emit event to notify borrower
    }
}
