// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IGroupMetadata {
    // Build a JSON string from the group data for the metadata
    function getMetadata(uint256 _tokenID) external view returns (string memory);
}