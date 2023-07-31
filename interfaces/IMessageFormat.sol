// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMessageFormat {
    // Build a JSON string from the message data
    // msgData[]
    // 0 = msgID
    // 1 = time
    // 2 = block
    // 3 = tip
    // 4 = paid
    // 5 = postByContract
    // 6 = likes
    // 7 = reposts
    // 8 = comments
    // 9 = isCommentOf
    // 10 = isRepostOf
    // 11 = commentLevel
    // 12 = asGroup
    // 13 = ERC20 Tip Amount
    // 14 = Comment ID
    function buildMsg(uint256[] memory msgData, string memory message, address[2] memory postedBy, string[] memory hashtags, address[] memory taggedAccounts,string memory uri, uint256[] memory inGroups, address tipContract) external view returns (string[] memory);
}