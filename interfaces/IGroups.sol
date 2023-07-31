// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGroups {

    struct GroupDetails {
        address ownerAddress;
        address[] members;
        string groupName;
        address groupAddress;
        string details;
        string uri;
        string[3] colors;
    }

    // Function to set group details on initial mint
    function setInitialDetails(uint256 _groupID, address owner, string memory groupName, address setInitialDetails) external;

    // Get group owner address by Group ID
    function getOwnerOfGroupByID(uint256 groupID) external view returns (address);

    // Get a list of members of a group
    function getMembersOfGroupByID(uint256 groupID) external view returns (address[] memory);

    // Check if a user is a member of a group
    function isMemberOfGroupByID(uint256 groupID, address member) external view returns (bool);

    // Get a Group ID from the Group Name
    function getGroupID(string calldata groupName) external view returns (uint256);

    // Get a generated Group Address from a Group ID
    function getGroupAddressFromID(uint256 groupID) external view returns (address);

    // Get Group Name from a Group ID
    function getGroupNameFromID(uint256 groupID) external view returns (string memory);

    // Get Group Details from a Group ID
    function getGroupDetailsFromID(uint256 groupID) external view returns (string memory);

    // Get Group URI from a Group ID
    function getGroupURIFromID(uint256 groupID) external view returns (string memory);

    // Get Avatar Colors from a Group ID
    function getGroupColorsFromID(uint256 groupID) external view returns (string[3] memory);

    // Get a group ID from their generated address
    function getGroupIDFromAddress(address groupAddress) external view returns (uint256);

    // Get the owner address of a group by the group address
    function getOwnerOfGroupByAddress(address groupAddress) external view returns (address);

    // Check if a group is available
    function isGroupAvailable(string calldata groupName) external view returns (bool);

    // Get Group Details
    function groupDetails(uint256 groupID) external view returns (GroupDetails memory);

    // Update Group Ownership on Token transfer (only callable from Token contract overrides)
    function onTransfer(address from, address to, uint256 tokenId) external;
}