// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.15;

// import "@openzeppelin/contracts/utils/Context.sol";
// import "../interfaces/IStark.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "hardhat/console.sol";

// contract Guaranty is Context, ReentrancyGuard {
//     address private deployer;
//     address private borrower;
//     address private lender;
//     address private tokenAddress;
//     // address private starkAddress;

//     Istark_protocol starkContract;

//     struct GuarantyDetails {
//         uint256 totalAmount; // * Total amount borrowed by the borrower
//         uint256 totalAmountToPay; // * Total amount left to be paid
//         uint256 amountPaidTotal; // * Amount paid by the borrower in total
//         uint256 timeRentedSince; // * Time when the deal started
//         uint256 timeRentedUntil; // * Time when the deal will end
//     }

//     GuarantyDetails private deal;

//     address private stark;

//     constructor(
//         address _borrower,
//         address _lender,
//         address _starkAddress,
//         address _tokenAddress,
//         uint256 _totalAmount,
//         uint256 _timeRentedUntil
//     ) {
//         deployer = _msgSender();
//         borrower = _borrower;
//         lender = _lender;
//         starkContract = Istark_protocol(_starkAddress);
//         tokenAddress = _tokenAddress;

//         GuarantyDetails storage dealDetails = deal;
//         dealDetails.timeRentedSince = block.timestamp;
//         dealDetails.timeRentedUntil = block.timestamp + _timeRentedUntil;
//         dealDetails.totalAmount = _totalAmount;
//         stark = _starkAddress;
//     }

//     modifier onlyBorrower() {
//         require(msg.sender == borrower, "ERR:Borrower only"); // BO => Borrower only
//         _;
//     }

//     // * FUNCTION: To get the address of the borrower.
//     function getBorrower() public view returns (address) {
//         return borrower;
//     }

//     // * FUNCTION: To get the address of the lender.
//     function getLender() public view returns (address) {
//         return lender;
//     }

//     // * FUNCTION: To get the detials of the Deal.
//     function getDealDetails() public view returns (GuarantyDetails memory) {
//         return deal;
//     }

//     // * FUNCTION: To get the amount left to be paid
//     function getTotalAmountLeft() public view returns (uint256) {
//         return deal.totalAmountToPay;
//     }

//     function repay(uint256 value) external payable onlyBorrower nonReentrant {
//         GuarantyDetails memory dealDetails = deal;
//         require(
//             dealDetails.amountPaidTotal < dealDetails.totalAmount,
//             "ERR: No more installments"
//         ); // NM => No more installments

//         // uint256  = msg.value;
//         require(value > 0, "ERR: Minimum Amount should be greater than zero"); // MA => Minimum Amount should be greater than zero

//         // (bool success,) = lender.call{value: value}("");
//         // require(success, "ERR:OT"); //OT => On Transfer
//         IERC20(tokenAddress).transferFrom(msg.sender, address(this), value);
        
//         deal.amountPaidTotal += value;

//         starkContract.repayChanges(tokenAddress, lender, borrower, value);

//         // if (dealDetails.amountPaidTotal == dealDetails.totalAmount) {
//         //     // emit Event
//         // }
//     }
// }
