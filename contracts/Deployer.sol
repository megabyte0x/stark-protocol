//SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/utils/Context.sol";
import "contracts/Deal.sol";

contract Deployer is Context {
    Deal public dealContract;

    struct Request {
        address borrower;
        address lender;
        address dealAddress;
        uint256 instalmentAmount;
        uint256 totalAmount;
        uint256 interestRate;
        uint16 noOfInstalments;
        bool requestRaised;
    }

    Request private request;

    mapping(address => Request) requests;

    function deploy() internal {
        Request storage requestDetails = request;

        dealContract = new Deal(
            requestDetails.borrower,
            requestDetails.lender,
            requestDetails.instalmentAmount,
            requestDetails.totalAmount,
            requestDetails.interestRate,
            requestDetails.noOfInstalments
        );

        requestDetails.dealAddress = address(dealContract);

        // emit Event
    }

    function raiseRequest(
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint16 _noOfInstalments,
        address _lender
    ) external {
        require(!requests[_msgSender()].requestRaised, "ERR:AR"); // AR => Already raised

        Request storage requestDetails = request;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.instalmentAmount = _instalmentAmount;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.interestRate = _interestRate;
        requestDetails.noOfInstalments = _noOfInstalments;

        requests[_msgSender()].requestRaised = true;

        // emit event
    }

    function acceptRequest(address _lender) external payable {
        require(requests[_lender].requestRaised, "ERR:NR"); // NR => No request

        uint256 value = msg.value;
        require(requests[_lender].totalAmount == value, "ERR:WV"); // WV => Wrong Value

        deploy();

        (bool success, ) = _lender.call{value: value}("");
        require(success, "ERR:OT"); // OT => On Transfer
    }
}
