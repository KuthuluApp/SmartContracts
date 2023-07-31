// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDOOM {

    // Cost to Mint 1 DOOM Token
    function costToMint() external returns (uint256);

    // Burn tokens
    function burnTokens(address from, uint256 amount) external returns (bool);

    // Mint Tokens
    function publicMint(uint256 amount) external payable;

    // Admin Mint Tokens
    function preMint(address to, uint256 amount) external;
}