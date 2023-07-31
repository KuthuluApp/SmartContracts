// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPosts {

    // Get a list of a users posts or posts of a message
    function getMsgIDsByAddress(address usrAddress, uint256 startFrom, uint256[] calldata whatToGet) external view returns(uint256[] memory);

    // Remove a post from a user mapping
    function addPost(uint256 msgID, address addressPoster, uint256 isCommentOf, uint256 isRepostOf) external;

    // Add a post to a users mapping
    function removePost(uint256 msgID, address addressPoster, uint256 isCommentOf, uint256 isRepostOf) external;
}