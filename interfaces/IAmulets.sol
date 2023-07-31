// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAmulets {

    // Get the type of amulet by ID
    function getAmuletType(uint256 amuletID) external view returns (uint256[] memory);
}