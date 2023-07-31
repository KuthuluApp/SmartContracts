// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKuthulu {

    // Post a Message
    function postMsg(string calldata message, string[] memory _hashtags, address[] calldata taggedAccounts, string calldata uri, uint256[5] memory attribs, uint256[] memory inGroups) external payable;

    // Erase a Message You Posted
    function eraseMsg(uint256 msgID) external;

    // Toggle Liking a Message
    function toggleLike(uint256 msgID) external;

    // Follow a User or Space by Address
    function followUser(address addressToFollow) external;

    // Unfollow a User or Space by Address
    function unfollowUser(address addressToUnFollow) external;

    // Get message IDs posted by a User or Space
    function getMsgIDsByAddress(address usrAddress, uint256 startFrom, bool getUserComments, bool getUserReposts) external view returns (uint256[] memory);

    // Get Comments & Reposts of a message
    function getSubIDsByPost(uint256 msgID, uint256 startFrom, bool isRepost) external view returns (uint256[] memory);

    // Get Message IDs that have a given hashtag
    function getMsgIDsByHashtag(string memory hashtag, uint256 startFrom) external view returns (uint256[] memory);

    // Get Message IDs that have a given address tagged
    function getMsgIDsByTag(address taggedAddress, uint256 startFrom) external view returns (uint256[] memory);

    // Get the message details of a list of messages by ID
    function getMsgsByIDs(uint256[] calldata msgIDs) external view returns (string[][] memory);

    // Get stats from the app
    function getStats() external view returns (uint256[] memory);
}