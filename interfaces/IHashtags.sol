// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHashtags {

    // Get Message IDs from a hashtag
    function getMsgIDsFromHashtag(string memory hashtag, uint256 startFrom) external view returns(uint256[] memory);

    // Remove a hashtag from a message
    function removeHashtags(uint256 msgID, string[] calldata hashtagsToToggle) external;

    // Add a hashtag to a message
    function addHashtags(uint256 msgID, string[] memory hashtagsToToggle) external;
}