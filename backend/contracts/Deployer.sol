//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "./p2p/deal.sol";
import "./guaranty/guaranty.sol";
import "./interfaces/IStark.sol";

contract deployer_contract is Context {
    deal_contract private dealContract;
    guaranty_contract private guarantyContract;
    Istark_protocol starkContract;

    address private owner;

    constructor() {
        owner = _msgSender();
    }

    function setStarkAddress(address starkProtocolAddress) external {
        require(_msgSender() == owner, "ERR:NA"); // NA=> Not Allowed
        starkContract = Istark_protocol(starkProtocolAddress);
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

    struct guarantyRequest {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress;
        address tokenAddress;
        uint256 totalAmount; // * Amount looking for the guaranty
        uint256 timeRentedUntil;
        bool requestAccepted; // * Request Raised by the lender accepted or not
    }

    guarantyRequest private guarantyRequestInstance;

    // * To store all the guarantyRequest made in the protocol
    mapping(address => guarantyRequest) private guarantyRequests;

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getP2PRequests(address _borrower) external view returns (p2pRequest memory) {
        return p2pRequests[_borrower];
    }

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getGuarantyRequests(address _borrower)
        external
        view
        returns (guarantyRequest memory)
    {
        return guarantyRequests[_borrower];
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

        delete p2pRequestInstance;

        // emit Event to notify both lender and borrower
    }

    function guarantyDeploy() internal {
        guarantyRequest storage requestDetails = guarantyRequestInstance;

        guarantyContract = new guaranty_contract(
            requestDetails.borrower,
            requestDetails.lender,
            requestDetails.totalAmount,
            requestDetails.timeRentedUntil
        );

        guarantyRequests[requestDetails.borrower].dealAddress = address(guarantyContract);

        starkContract.addAllowContracts(address(guarantyContract));

        delete guarantyRequestInstance;
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
    function guarantyRaiseRequest(
        address _lender,
        address _tokenAddress,
        uint256 _totalAmount,
        uint256 _timeRentedUntil
    ) external {
        require(!guarantyRequests[_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted

        guarantyRequest storage requestDetails = guarantyRequestInstance;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.timeRentedUntil = _timeRentedUntil;
        requestDetails.tokenAddress = _tokenAddress;

        guarantyRequests[_msgSender()] = requestDetails;

        // emit event to notify lender
    }

    // * FUNCTION: To accept the p2pRequest made by the borrower
    function p2pAcceptRequest(address _borrower) external payable {
        require(!p2pRequests[_borrower].requestAccepted, "ERR:AA"); // AA =>Already Accepted

        uint256 value = msg.value;
        require(p2pRequests[_borrower].totalAmount == value, "ERR:WV"); // WV => Wrong Value

        p2pRequests[_borrower].requestAccepted = true;

        p2pDeploy();

        (bool success, ) = _borrower.call{value: value}("");
        require(success, "ERR:OT"); // OT => On Transfer

        // emit event to notify borrower
    }

    // * FUNCTION: To accept the guarantyRequest made by the borrower
    function guarantyAcceptRequest(
        address _borrower,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external {
        require(!guarantyRequests[_borrower].requestAccepted, "ERR:AA"); // AA =>Already Accepted

        uint256 tokenAmountinProtocol = starkContract.getLockedBalance(
            _tokenAddress,
            _msgSender()
        );

        require(_tokenAmount <= tokenAmountinProtocol, "ERR:NE"); // NA => Not Enough Amount

        starkContract.requestChange_LockBalance(
            _tokenAddress,
            _msgSender(),
            _borrower,
            _tokenAmount
        );

        guarantyRequests[_borrower].requestAccepted = true;

        guarantyDeploy();
        // emit event to notify borrower
    }
}
