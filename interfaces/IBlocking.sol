// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlocking {

    // Update the whitelist
    function updateWhitelist(address toToggle) external;

    // Update the blacklist
    function updateBlacklist(address toToggle) external;

    // Check if a requester is allowed to interact with target
    function isAllowed(address requesterAddress, address targetAddress) external view returns (bool);

    // Enable or disable whitelist functionality for self
    function toggleWhiteList() external;

    // Clear our a whitelist or blacklist with a single call
    function clearList(bool clearWhitelist) external;
}