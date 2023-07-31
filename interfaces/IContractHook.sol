// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IContractHook {

    // Message Stats
    struct MsgStats {
        int likes;
        int comments;
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
        MsgStats msgStats;
    }

    // External Contract to call with message details
    function KuthuluHook(MsgData memory newMsg) external returns (bool);
}