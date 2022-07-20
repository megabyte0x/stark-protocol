// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface Istark_protocol {
    function getLockedBalance(address tokenAddress, address userAddress)
        external
        view
        returns (uint256);

    function requestChange_LockBalance(
        address _tokenAddress,
        address _lender,
        address _borrower,
        uint256 _tokenAmount
    ) external;

    function addAllowContracts(address _contractAddress) external;

    function changeBalances(
        address _tokenAddress,
        address _lender,
        address _borrower,
        uint256 _tokenAmount
    ) external;
}
