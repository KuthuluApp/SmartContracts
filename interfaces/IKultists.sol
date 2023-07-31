// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKultists {

    // Add a ReRoll to a user
    function addReRoll(address user, uint256 amount) external;
}