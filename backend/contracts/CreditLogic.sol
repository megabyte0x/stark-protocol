//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./p2p/Deal.sol";
import "./interfaces/IStark.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CreditLogic is Context, Ownable {
    Deal private dealContract;
    Istark_protocol starkContract;
    address private starkProtocolAddress;
    address[] private borrowers;
    address[] private lenders;

    function setStarkAddress(address _starkProtocolAddress) external onlyOwner {
        starkContract = Istark_protocol(_starkProtocolAddress);
        starkProtocolAddress = _starkProtocolAddress;
    }

    struct P2PRequest {
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

    struct GuarantyRequest {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress;
        address tokenAddress;
        uint256 totalAmount; // * Amount looking for the guaranty
        uint256 timeRentedUntil;
        uint256 timeRentedSince;
        bool requestAccepted; // * Request Raised by the lender accepted or not
    }

    // * To store all the GuarantyRequest made in the protocol
    // guarantyRequests[_lender][_borrower]
    mapping(address => mapping(address => GuarantyRequest)) private guarantyRequests;

    // * To store all the p2pRequests made in the protocol
    // lender & borrower -> request
    mapping(address => mapping(address => P2PRequest)) private p2pRequests;

    ///////////////////////
    //// p2p functions ///
    //////////////////////

    // * FUNCTION: To deploy the Deal Contract
    function p2pDeploy(address _lender, address _borrower) internal {
        P2PRequest memory requestDetails = p2pRequests[_lender][_borrower];

        dealContract = new Deal(
            requestDetails.borrower,
            requestDetails.lender,
            starkProtocolAddress,
            requestDetails.tokenAddress,
            requestDetails.instalmentAmount,
            requestDetails.totalAmount,
            requestDetails.interestRate,
            requestDetails.noOfInstalments
        );

        p2pRequests[requestDetails.lender][requestDetails.borrower].dealAddress = address(
            dealContract
        );

        // starkContract.addAllowContracts(address(dealContract));

        // emit Event to notify both lender and borrower
    }

    // * FUNCTION: To raise the P2PRequest to borrow
    function p2pRaiseRequest(
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint16 _noOfInstalments,
        address _lender,
        address _tokenAddress
    ) external {
        require(!p2pRequests[_lender][_msgSender()].requestAccepted, "Err: Already Raised");

        P2PRequest memory requestDetails;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.instalmentAmount = _instalmentAmount;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.interestRate = _interestRate;
        requestDetails.noOfInstalments = _noOfInstalments;
        requestDetails.tokenAddress = _tokenAddress;

        p2pRequests[_lender][_msgSender()] = requestDetails;

        // emit event to notify lender
    }

    // * FUNCTION: To accept the P2PRequest made by the borrower
    function p2pAcceptRequest(address _borrower) external payable {
        P2PRequest memory requestDetails = p2pRequests[_msgSender()][_borrower];

        require(!requestDetails.requestAccepted, "ERR: Already Accepted");
        uint256 tokenAmountinProtocol = starkContract.getSupplyBalance(
            requestDetails.tokenAddress,
            _msgSender()
        );
        require(requestDetails.totalAmount <= tokenAmountinProtocol, "ERR: Not Enough Amount");

        // starkContract.lockBalanceChanges(
        //     requestDetails.tokenAddress,
        //     _msgSender(),
        //     _borrower,
        //     requestDetails.totalAmount
        // );

        IERC20(requestDetails.tokenAddress).transferFrom(
            _msgSender(),
            _borrower,
            requestDetails.totalAmount
        );

        p2pRequests[_msgSender()][_borrower].requestAccepted = true;

        p2pDeploy(_msgSender(), _borrower);

        // emit event to notify borrower
    }

    ////////////////////////////
    ///// guaranty functions ///
    ////////////////////////////

    // * FUNCTION: To raise the request for backing the loan from the protocol
    function guarantyRaiseRequest(
        address _lender,
        address _tokenAddress,
        uint256 _totalAmount,
        uint256 _timeRentedUntil
    ) external {
        require(!guarantyRequests[_lender][_msgSender()].requestAccepted, "Err: Already Raised");

        GuarantyRequest memory requestDetails;
        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.timeRentedUntil = _timeRentedUntil;
        requestDetails.tokenAddress = _tokenAddress;
        borrowers.push(_msgSender());

        guarantyRequests[_lender][_msgSender()] = requestDetails;
        // emit event to notify lender
    }

    // * FUNCTION: To accept the GuarantyRequest made by the borrower
    function guarantyAcceptRequest(address _borrower) external {
        GuarantyRequest memory requestDetails = guarantyRequests[_msgSender()][_borrower];

        require(!requestDetails.requestAccepted, "ERR: Already Accepted"); // AA =>Already Accepted

        uint256 tokenAmountinProtocol = starkContract.getSupplyBalance(
            requestDetails.tokenAddress,
            _msgSender()
        );

        require(requestDetails.totalAmount <= tokenAmountinProtocol, "ERR: Not Enough Amount"); // NA => Not Enough Amount

        starkContract.lockBalanceChanges(
            requestDetails.tokenAddress,
            _msgSender(),
            _borrower,
            requestDetails.totalAmount
        );

        lenders.push(_msgSender());

        requestDetails.timeRentedSince = block.timestamp;

        guarantyRequests[_msgSender()][_borrower].requestAccepted = true;
        // emit event to notify borrower
    }

    //////////////////////////
    ///// getter functions ///
    /////////////////////////

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getP2PRequest(address _lender, address _borrower)
        external
        view
        returns (P2PRequest memory)
    {
        return p2pRequests[_lender][_borrower];
    }

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getGuarantyRequest(address _lender, address _borrower)
        external
        view
        returns (GuarantyRequest memory)
    {
        return guarantyRequests[_lender][_borrower];
    }

    function getBorrowers() external view returns (address[] memory) {
        return borrowers;
    }

    function getLenders() external view returns (address[] memory) {
        return lenders;
    }
}
