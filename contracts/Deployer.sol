//SPDX-License-Identifier: Unlicense

// import "@openzeppelin/contracts/utils/Create2.sol";
import "contracts/Deal.sol";

contract Deployer {
    event Deploy(address addr);

    Deal public dealContract;

   struct Request {
        address borrower;
        address lender;
        uint256 instalmentAmount;
        uint256 totalAmount;
        uint256 interestRate;
        uint16 noOfInstalments;
    }   

    Request private request;

    function deploy() external returns (Deal) {

        Request storage requestDetails = request; 

        dealContract = new Deal(
            requestDetails.borrower,
            requestDetails.lender,
            requestDetails.instalmentAmount,
            requestDetails.totalAmount,
            requestDetails.interestRate,
            requestDetails.noOfInstalments
        );
        return (dealContract);
    }

}
