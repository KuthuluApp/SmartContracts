// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IBetMetadata {
    // Build a JSON string from the group data for the metadata
    function getMetadata(uint256 _tokenID, string memory bet, string memory betOn, bool paidOut, uint256 betAmount) external view returns (string memory);
}