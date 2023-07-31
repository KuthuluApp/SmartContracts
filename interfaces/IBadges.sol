// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBadges {

    // Add a badge to a user
    function addBadgeToUser(address userAddress, uint256 badgeID) external;

    // Remove a badge from a user
    function removeBadgeFromUser(address userAddress, uint256 badgeID) external;
}