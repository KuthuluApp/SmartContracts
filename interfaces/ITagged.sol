// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITagged {

    // Get a list of a messages a user is tagged in
    function getTaggedMsgIDs(address usrAddress, uint256 startFrom) external view returns(uint256[] memory);

    // Add a tag to a users post
    function removeTags(uint256 msgID, address[] memory addressesTagged) external;

    // Remove a tag from a users post
    function addTags(uint256 msgID, address[] memory addressTagged) external;
}