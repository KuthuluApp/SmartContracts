// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMessageData {

    // Message Stats
    struct MsgStats {
        int likes;
        int comments;
        uint256 totalInThread;
        int reposts;
        uint256 tipsReceived;
        address tipContract;
        uint256 tipERC20Amount;
        uint postByContract;
        uint256 time;
        uint256 block;
    }

    // The Message data struct
    struct MsgData {
        uint msgID;
        address[2] postedBy;
        string message;
        uint256 paid;
        string[] hashtags;
        address[] taggedAccounts;
        uint256 asGroup;
        uint256[] inGroups;
        string uri;
        uint256 commentLevel;
        uint256 isCommentOf;
        uint256 isRepostOf;
        uint256 commentID;
        MsgStats msgStats;
    }

    // Get a list of a users posts
    function getMsgsByIDs(uint256[] calldata msgIDs, bool onlyFollowers, address addrFollowing) external view returns (string[][] memory);

    // Add a post to a users mapping
    function removeMsg(uint256 msgID, address requester) external;

    // Remove a post from a user mapping
    function saveMsg(MsgData memory msgData) external;

    // Add Stats to a message
    function addStat(uint8 statType, uint256 msgID, int amount, uint256 tips) external;

    // Get the comment level of a message
    function getMsgCommentLevel(uint256 msgID) external view returns (uint256);

    // Get the address of the poster of a message
    function getPoster(uint256 msgID) external view returns (address);

    // Get a list of groups a message was posted into
    function getInGroups(uint256 msgID) external view returns (uint256[] memory);
}
