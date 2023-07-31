// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRaffleTix {

    // Get the type of amulate by ID
    function awardTix(address[] calldata users, uint256 quantity) external;
}