// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFollowers {

    // Get a list of a users followers
    function getFollowers(address usrAddress, uint256 startFrom) external view returns(string[] memory);

    // Add a follower to a users mapping
    function addFollower(address addressRequester, address addressTarget) external;

    // Remove a follower from a user mapping
    function removeFollower(address addressRequester, address addressTarget) external;

    // Check if a user (requester) is following another user (target)
    function isUserFollowing(address addressRequester, address addressTargetStr) external view returns (bool);
}