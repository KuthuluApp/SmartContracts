// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRewards {

    // External Contract to call with message details
    function checkRewards(uint256 msgID, uint256 postCount, address posterAddress) external;
}