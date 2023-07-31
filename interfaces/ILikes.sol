// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILikes {

    // Get a list of a users that liked a post
    function getLikesFromMsgID(uint256 msgID, uint256 startFrom) external view returns(address[] memory);

    // Add a like to a users post
    function removeLike(uint256 msgID, address likedBy) external;

    // Remove a like from a users post
    function addLike(uint256 msgID, address likedBy) external;

    // Check if a user liked a post
    function checkUserLikeMsg(address usrAddress, uint256 msgID) external view returns (bool);
}