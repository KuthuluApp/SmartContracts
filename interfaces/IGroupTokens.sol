// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGroupTokens {

    // Get a Group ID from a name
    function getGroupID(string calldata groupName) external view returns (uint256);

    // Check if a group is available to mint
    function isGroupAvailable(string calldata groupName) external view returns (bool);

    // Mint a new group
    function mintGroup(string calldata groupName) external payable;

    // Update the Group Token Metadata
    function adminUpdateGroupMetadata(uint256 groupID) external;
}