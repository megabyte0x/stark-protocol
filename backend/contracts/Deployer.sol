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
    address private starkProtocolAddress;

    constructor() {
        owner = _msgSender();
    }

    function setStarkAddress(address _starkProtocolAddress) external {
        require(_msgSender() == owner, "ERR:NA"); // NA=> Not Allowed
        starkContract = Istark_protocol(_starkProtocolAddress);
        starkProtocolAddress = _starkProtocolAddress;
    }

    struct p2pRequest {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress; // * Address of the Deal Contract
        address tokenAddress;
        uint256 instalmentAmount; //* Amount to be paid in each instalment
        uint256 totalAmount; // * Total Amount borrowed
        uint256 interestRate; // * Interest Rate by the Lender
        uint16 noOfInstalments; // * No of Instalments
        bool requestAccepted; // * Request Raised by the lender accepted or not
    }

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
    function p2pDeploy(address _borrower) internal {
        p2pRequest memory requestDetails = p2pRequests[_borrower];

        dealContract = new deal_contract(
            requestDetails.borrower,
            requestDetails.lender,
            starkProtocolAddress,
            requestDetails.tokenAddress,
            requestDetails.instalmentAmount,
            requestDetails.totalAmount,
            requestDetails.interestRate,
            requestDetails.noOfInstalments
        );

        p2pRequests[requestDetails.borrower].dealAddress = address(dealContract);

        starkContract.addAllowContracts(address(dealContract));

        // emit Event to notify both lender and borrower
    }

    function guarantyDeploy(address _borrower) internal {
        guarantyRequest memory requestDetails = guarantyRequests[_borrower];

        guarantyContract = new guaranty_contract(
            requestDetails.borrower,
            requestDetails.lender,
            starkProtocolAddress,
            requestDetails.tokenAddress,
            requestDetails.totalAmount,
            requestDetails.timeRentedUntil
        );

        guarantyRequests[requestDetails.borrower].dealAddress = address(guarantyContract);

        starkContract.addAllowContracts(address(guarantyContract));

        // emit Event to notify both lender and borrower
    }

    // * FUNCTION: To raise the p2pRequest to borrow
    function p2pRaiseRequest(
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint16 _noOfInstalments,
        address _lender,
        address _tokenAddress
    ) external {
        require(!p2pRequests[_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted

        p2pRequest memory requestDetails;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.instalmentAmount = _instalmentAmount;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.interestRate = _interestRate;
        requestDetails.noOfInstalments = _noOfInstalments;
        requestDetails.tokenAddress = _tokenAddress;

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

        guarantyRequest memory requestDetails;

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
        p2pRequest memory requestDetails = p2pRequests[_borrower];

        require(!requestDetails.requestAccepted, "ERR:AA"); // AA =>Already Accepted
        uint256 tokenAmountinProtocol = starkContract.getSupplyBalance(
            requestDetails.tokenAddress,
            _msgSender()
        );
        require(requestDetails.totalAmount <= tokenAmountinProtocol, "ERR:NE"); // NA => Not Enough Amount

        starkContract.requestChange_LockBalance(
            requestDetails.tokenAddress,
            _msgSender(),
            _borrower,
            requestDetails.totalAmount
        );

        p2pRequests[_borrower].requestAccepted = true;

        p2pDeploy(_borrower);

        // emit event to notify borrower
    }

    // * FUNCTION: To accept the guarantyRequest made by the borrower
    function guarantyAcceptRequest(address _borrower) external {
        guarantyRequest memory requestDetails = guarantyRequests[_borrower];

        require(!requestDetails.requestAccepted, "ERR:AA"); // AA =>Already Accepted

        uint256 tokenAmountinProtocol = starkContract.getSupplyBalance(
            requestDetails.tokenAddress,
            _msgSender()
        );

        require(requestDetails.totalAmount <= tokenAmountinProtocol, "ERR:NE"); // NA => Not Enough Amount

        starkContract.requestChange_LockBalance(
            requestDetails.tokenAddress,
            _msgSender(),
            _borrower,
            requestDetails.totalAmount
        );

        guarantyRequests[_borrower].requestAccepted = true;

        guarantyDeploy(_borrower);
        // emit event to notify borrower
    }
}
