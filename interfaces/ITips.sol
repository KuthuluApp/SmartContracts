// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITips {
    // Add tips to a users post
    function addTip(uint256 msgID, address tippedBy, uint256 tips) external;

    // Add tips to tagged accounts
    function addTaggedTips(address[] memory taggedAccounts, uint256 tipPerTag, address tipContract, address posterAddress) external payable;
}