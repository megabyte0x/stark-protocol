pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "./p2p/deal.sol";
import "./p2p/Deal.sol";
import "./guaranty/guaranty.sol";
import "./interfaces/IStark.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract deployer_contract is Context {
contract CreditLogic is Context, Ownable {
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
    function setStarkAddress(address _starkProtocolAddress) external onlyOwner {
        starkContract = Istark_protocol(_starkProtocolAddress);
        starkProtocolAddress = _starkProtocolAddress;
    }

    struct p2pRequest {
    struct P2PRequest {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress; // * Address of the Deal Contract
@@ -36,12 +31,7 @@ contract deployer_contract is Context {
        bool requestAccepted; // * Request Raised by the lender accepted or not
    }

    p2pRequest private p2pRequestInstance;

    // * To store all the p2pRequests made in the protocol
    mapping(address => p2pRequest) private p2pRequests;

    struct guarantyRequest {
    struct GuarantyRequest {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress;
@@ -51,28 +41,21 @@ contract deployer_contract is Context {
        bool requestAccepted; // * Request Raised by the lender accepted or not
    }

    guarantyRequest private guarantyRequestInstance;

    // * To store all the guarantyRequest made in the protocol
    mapping(address => guarantyRequest) private guarantyRequests;
    // * To store all the GuarantyRequest made in the protocol
    // guarantyRequests[_lender][_borrower]
    mapping(address => mapping(address => GuarantyRequest)) private guarantyRequests;

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getP2PRequests(address _borrower) external view returns (p2pRequest memory) {
        return p2pRequests[_borrower];
    }
    // * To store all the p2pRequests made in the protocol
    // lender & borrower -> request
    mapping(address => mapping(address => P2PRequest)) private p2pRequests;

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getGuarantyRequests(address _borrower)
        external
        view
        returns (guarantyRequest memory)
    {
        return guarantyRequests[_borrower];
    }
    ///////////////////////
    //// p2p functions ///
    //////////////////////

    // * FUNCTION: To deploy the Deal Contract
    function p2pDeploy() internal {
        p2pRequest memory requestDetails = p2pRequestInstance;
    function p2pDeploy(address _lender, address _borrower) internal {
        P2PRequest memory requestDetails = p2pRequests[_lender][_borrower];

        dealContract = new deal_contract(
            requestDetails.borrower,
@@ -85,37 +68,16 @@ contract deployer_contract is Context {
            requestDetails.noOfInstalments
        );

        p2pRequests[requestDetails.borrower].dealAddress = address(dealContract);

        starkContract.addAllowContracts(address(dealContract));

        delete p2pRequestInstance;

        // emit Event to notify both lender and borrower
    }

    function guarantyDeploy() internal {
        guarantyRequest memory requestDetails = guarantyRequestInstance;

        guarantyContract = new guaranty_contract(
            requestDetails.borrower,
            requestDetails.lender,
            starkProtocolAddress,
            requestDetails.tokenAddress,
            requestDetails.totalAmount,
            requestDetails.timeRentedUntil
        p2pRequests[requestDetails.lender][requestDetails.borrower].dealAddress = address(
            dealContract
        );

        guarantyRequests[requestDetails.borrower].dealAddress = address(guarantyContract);

        starkContract.addAllowContracts(address(guarantyContract));

        delete guarantyRequestInstance;
        starkContract.addAllowContracts(address(dealContract));

        // emit Event to notify both lender and borrower
    }

    // * FUNCTION: To raise the p2pRequest to borrow
    // * FUNCTION: To raise the P2PRequest to borrow
    function p2pRaiseRequest(
        uint256 _instalmentAmount,
        uint256 _totalAmount,
@@ -124,9 +86,9 @@ contract deployer_contract is Context {
        address _lender,
        address _tokenAddress
    ) external {
        require(!p2pRequests[_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted
        require(!p2pRequests[_lender][_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted

        p2pRequest memory requestDetails = p2pRequestInstance;
        P2PRequest memory requestDetails;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
@@ -136,36 +98,14 @@ contract deployer_contract is Context {
        requestDetails.noOfInstalments = _noOfInstalments;
        requestDetails.tokenAddress = _tokenAddress;

        p2pRequests[_msgSender()] = requestDetails;
        p2pRequests[_lender][_msgSender()] = requestDetails;

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

        guarantyRequest memory requestDetails = guarantyRequestInstance;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.timeRentedUntil = _timeRentedUntil;
        requestDetails.tokenAddress = _tokenAddress;

        guarantyRequests[_msgSender()] = requestDetails;

        // emit event to notify lender
    }

    // * FUNCTION: To accept the p2pRequest made by the borrower
    // * FUNCTION: To accept the P2PRequest made by the borrower
    function p2pAcceptRequest(address _borrower) external payable {
        p2pRequest memory requestDetails = p2pRequests[_borrower];
        P2PRequest memory requestDetails = p2pRequests[_msgSender()][_borrower];

        require(!requestDetails.requestAccepted, "ERR:AA"); // AA =>Already Accepted
        uint256 tokenAmountinProtocol = starkContract.getSupplyBalance(
@@ -181,16 +121,65 @@ contract deployer_contract is Context {
            requestDetails.totalAmount
        );

        p2pRequests[_borrower].requestAccepted = true;
        p2pRequests[_msgSender()][_borrower].requestAccepted = true;

        p2pDeploy();
        p2pDeploy(_msgSender(), _borrower);

        // emit event to notify borrower
    }

    // * FUNCTION: To accept the guarantyRequest made by the borrower
    ////////////////////////////
    ///// guaranty functions ///
    ///////////////////////////

    function guarantyDeploy(address _lender, address _borrower) internal {
        GuarantyRequest memory requestDetails = guarantyRequests[_lender][_borrower];

        guarantyContract = new guaranty_contract(
            requestDetails.borrower,
            requestDetails.lender,
            starkProtocolAddress,
            requestDetails.tokenAddress,
            requestDetails.totalAmount,
            requestDetails.timeRentedUntil
        );

        guarantyRequests[requestDetails.lender][requestDetails.borrower].dealAddress = address(
            guarantyContract
        );

        starkContract.addAllowContracts(address(guarantyContract));

        // emit Event to notify both lender and borrower
    }

    // * FUNCTION: To raise the request for backing the loan from the protocol
    function guarantyRaiseRequest(
        address _lender,
        address _tokenAddress,
        uint256 _totalAmount,
        uint256 _timeRentedUntil
    ) external {
        require(!guarantyRequests[_lender][_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted
        GuarantyRequest storage requestDetails;

        // if(guarantyRequests[_lender][_msgSender()]){

        // }

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.timeRentedUntil = _timeRentedUntil;
        requestDetails.tokenAddress = _tokenAddress;

        guarantyRequests[_lender][_msgSender()] = requestDetails;
        // emit event to notify lender
    }

    // * FUNCTION: To accept the GuarantyRequest made by the borrower
    function guarantyAcceptRequest(address _borrower) external {
        guarantyRequest memory requestDetails = guarantyRequests[_borrower];
        GuarantyRequest memory requestDetails = guarantyRequests[_msgSender()][_borrower];

        require(!requestDetails.requestAccepted, "ERR:AA"); // AA =>Already Accepted

@@ -208,9 +197,31 @@ contract deployer_contract is Context {
            requestDetails.totalAmount
        );

        guarantyRequests[_borrower].requestAccepted = true;
        guarantyRequests[_msgSender()][_borrower].requestAccepted = true;

        guarantyDeploy();
        guarantyDeploy(_msgSender(), _borrower);
        // emit event to notify borrower
    }

    //////////////////////////
    ///// getter functions ///
    /////////////////////////

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getP2PRequests(address _lender, address _borrower)
        external
        view
        returns (P2PRequest memory)
    {
        return p2pRequests[_lender][_borrower];
    }

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getGuarantyRequests(address _lender, address _borrower)
        external
        view
        returns (GuarantyRequest memory)
    {
        return guarantyRequests[_lender][_borrower];
    }
}
