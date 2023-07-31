// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGroupPosts {

    // Get a list of a posts in a group
    function getMsgIDsByGroupID(uint256 groupID, uint256 startFrom) external view returns(uint256[] memory);

    // Remove a post from a group mapping
    function addPost(uint256 msgID, uint256[] calldata groupIDs) external;

    // Add a post to a groups mapping
    function removePost(uint256 msgID, uint256[] calldata groupIDs) external;
}