// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface INFT {

    // Get the amount of tokens they own
    function balanceOf(address owner) external view returns (uint256);

    // Get the owner of a token
    function ownerOf(uint256 tokenId) external view returns (address);

    // Get the owner of a token
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // Return if a user owns a specific badge type
    function kuthuluVerifyBadgeType(uint256 badgeTypeID, address owner) external view returns (bool);
}