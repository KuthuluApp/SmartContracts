// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IKUtils {
    // Append a string
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) external pure returns (string memory);

    // Convert an address to a string
    function addressToString(address addr) external pure returns (string memory);

    // Is a valid URI
    function isValidURI(string memory str) external pure returns (bool);

    // Is a valid string
    function isValidString(string memory str) external pure returns (bool);

    // Is a safe string
    function isSafeString(string memory str) external pure returns (bool);

    // Is a valid string for group names
    function isValidGroupString(string memory str) external pure returns (bool);

    // Convert a uint to string
    function toString(uint256 value) external pure returns (string memory);

    // Returns a lowercase version of the string provided
    function _toLower(string memory str) external pure returns (string memory);

    // Check if 2 strings are the same
    function stringsEqual(string memory a, string memory b) external pure returns (bool);

    // Check literal string length (10x gas cost)
    function strlen(string memory s) external pure returns (uint256);
}