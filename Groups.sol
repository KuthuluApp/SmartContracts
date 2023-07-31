/*

                                   :-++++++++=:.
                                -++-.   ..   .-++-
                              -*=      *==*      -*-
                             ++.                   ++
                            +*     =++:    :+*=.    ++
                           :*.    .: .:    :: :.    .*-
                           =*                        *+
                           =**==+=:            .=*==**+
                .-----:.  =*..--..*=          =*:.--..*=  .:-----:
                 -******= *: *::* .+          +: *-:* :* =******=
                  -*****= *: *..*.              .*. *..* =*****=
                  -****** ++ =**=                =**= =* +*****-
                    :****= ++-:                    :-++ =****:
                   :--:.:+***:-.                  .-:+**+:.:--:.
                 -*-::-+= .**                        +*. =*-::-*-
                 -*-:   +*.+*.  .--            :-.   *+.++   .:*-
                   :*+  :*+--=*=*-=*    --.   *+:*++=--+*-  =*:
                    ++  -*:    +* :*  .*--*.  *- *+    :*=  =*
                    ++  -*=*+  :* :*  .*. *.  *- *:  +*=*=  +*
                    **  .+=*+  :*++*  .*++*.  *+=*:  +*=*.  +*.
                  =*-*=    +*  :*.-*  .*::*.  *-.*-  *+    =*-++.
                 *=   -++- =*  .*=++  .*..*:  ++-*.  *= -++-   =*.
                -*       .  *=   ::   ++  ++   ::   -*.         *=
                -*:..........**=:..:=*+....+*=-..:-**:.........:*=

   ▄█   ▄█▄ ███    █▄      ███        ▄█    █▄    ███    █▄   ▄█       ███    █▄
  ███ ▄███▀ ███    ███ ▀█████████▄   ███    ███   ███    ███ ███       ███    ███
  ███▐██▀   ███    ███    ▀███▀▀██   ███    ███   ███    ███ ███       ███    ███
 ▄█████▀    ███    ███     ███   ▀  ▄███▄▄▄▄███▄▄ ███    ███ ███       ███    ███
▀▀█████▄    ███    ███     ███     ▀▀███▀▀▀▀███▀  ███    ███ ███       ███    ███
  ███▐██▄   ███    ███     ███       ███    ███   ███    ███ ███       ███    ███
  ███ ▀███▄ ███    ███     ███       ███    ███   ███    ███ ███▌    ▄ ███    ███
  ███   ▀█▀ ████████▀     ▄████▀     ███    █▀    ████████▀  █████▄▄██ ████████▀
  ▀                                                          ▀

    @title Groups
    v0.3

    KUTHULU : https://www.KUTHULU.xyz
    A project by DOOM Labs (https://DOOMLabs.io)
    The first truly decentralized social framework.
    Built for others to build upon and share freedom of expression.
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IUserProfiles.sol";
import "./interfaces/IGroupTokens.sol";

contract Groups is Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Trusted Contracts
    mapping (address => bool) public trustedContracts;

    struct GroupDetails {
        address ownerAddress;
        address[] members;
        string groupName;
        address groupAddress;
        string details;
        string uri;
        string[3] colors;
    }

    // Max length of details to save
    uint256 public maxDetailsLength;

    // Mapping of Group ID to Group Details
    mapping (uint256 => GroupDetails) public groupDetails;

    // Group Address to Group ID mapping
    mapping(address => uint256) public groupAddressToID;

    // User Member Mapping to Groups
    mapping(address => uint256[]) public groupMemberships;

    // Member of groups (Address of member => Group Token ID => True/False is Member)
    mapping (address => mapping (uint256 => bool)) public isMemberOf;

    // Set the maximum number of members allowed in a group
    uint256 public maxMembersPerGroup;

    // Link the KUtils
    IKUtils public KUtils;

    // Link the User Profiles
    IUserProfiles public UserProfiles;

    // Link the Group Tokens
    IGroupTokens public GroupTokens;

    // Set the max length for URIs to store
    uint256 public maxURILength;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxMembersPerGroup, uint256 _maxDetailsLength, uint256 _maxURILength) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set max members per group
        maxMembersPerGroup = _maxMembersPerGroup;

        // Set max Details length
        maxDetailsLength = _maxDetailsLength;

        // Set max Details length
        maxURILength = _maxURILength;
    }


    /*

    EVENTS

    */

    event logLeaveGroup(uint256 indexed groupID, address indexed member);
    event logJoinGroup(uint256 indexed groupID, address indexed member);
    event logUpdateGroupNameFormat(uint256 indexed groupID, string groupName);


    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier onlyTrustedContracts() {
        require(trustedContracts[msg.sender], "Only trusted contracts can call this function.");
        _;
    }

    modifier onlyGroupOwners(uint256 groupID) {
        require(groupDetails[groupID].ownerAddress == msg.sender, "Only group owners can call this function.");
        _;
    }

    modifier onlyGroupMembers(uint256 groupID, address member) {
        require(isMemberOf[member][groupID], "They are not a member of this group");
        _;
    }


    /*

    ADMIN FUNCTIONS

    */

    function pause() public onlyAdmins {
        _pause();
    }

    function unpause() public onlyAdmins {
        _unpause();
    }

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function updateTrustedContract(address contractAddress, bool status) public onlyAdmins {
        trustedContracts[contractAddress] = status;
    }

    function updateContracts(address _kutils, address _userProfiles, address _groupTokens) public onlyAdmins {
        // Update the KUtils contract address
        KUtils = IKUtils(_kutils);

        // Update the User Profiles contract address
        UserProfiles = IUserProfiles(_userProfiles);

        // Update the Group Tokens contract address
        GroupTokens = IGroupTokens(_groupTokens);
    }

    function updateDetails(uint256 _maxMembers, uint256 _maxDetails, uint256 _maxURI) public onlyAdmins {
        maxMembersPerGroup = _maxMembers;
        maxDetailsLength = _maxDetails;
        maxURILength = _maxURI;
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Get the address of the owner of a group
    * @param groupID : the unique Group ID of the group to lookup
    * @return address : the address of the owner of a group
    */
    function getOwnerOfGroupByID(uint256 groupID) public view whenNotPaused returns (address){
        return groupDetails[groupID].ownerAddress;
    }

    /**
    * @dev Get the members of a group
    * @param groupID : the unique Group ID of the group to lookup
    * @return address[] : an array of addresses of members of a group
    */
    function getMembersOfGroupByID(uint256 groupID) public view whenNotPaused returns (address[] memory){
        return groupDetails[groupID].members;
    }

    /**
    * @dev Check if a user or group is a member of a group
    * @param groupID : the unique Group ID of the group to lookup
    * @param member : the address of the member you want to lookup
    * @return bool : True = they are a member / False = they are not a member
    */
    function isMemberOfGroupByID(uint256 groupID, address member) public view whenNotPaused returns (bool){
        return isMemberOf[member][groupID];
    }

    /**
    * @dev Get the Group ID of a group from the group name
    * @param groupName : the name of the group to lookup
    * @return uint256 : the unique group ID of the group
    */
    function getGroupID(string calldata groupName) public view whenNotPaused returns (uint256){
        bytes32 groupBytes = keccak256(bytes(KUtils._toLower(groupName)));
        return uint256(groupBytes);
    }

    /**
    * @dev Get the Group Address of a group from the group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return address : the address of the group
    */
    function getGroupAddressFromID(uint256 groupID) public view whenNotPaused returns (address){
        return groupDetails[groupID].groupAddress;
    }

    /**
    * @dev Get the Group ID of a group from the group address
    * @param groupAddress : the address of the group to lookup
    * @return uint256 : the unique Group ID of the group
    */
    function getGroupIDFromAddress(address groupAddress) public view whenNotPaused returns (uint256){
        return groupAddressToID[groupAddress];
    }

    /**
    * @dev Get the address of the owner of a group
    * @param groupAddress : the address of the group to lookup
    * @return address : the address of the owner of the group
    */
    function getOwnerOfGroupByAddress(address groupAddress) public view whenNotPaused returns (address){
        return groupDetails[groupAddressToID[groupAddress]].ownerAddress;
    }

    /**
    * @dev Get a list of groups that a user or group belongs to
    * @param lookupAddress : the address of the user or group to lookup
    * @return uint256[] : a list of group IDs that the user or group belongs to
    */
    function getGroupMemberships(address lookupAddress) public view whenNotPaused returns (uint256[] memory){
        return groupMemberships[lookupAddress];
    }

    /**
    * @dev Check to see if a group is available to mint
    * @param groupName : the name of the group to lookup
    * @return bool : True = the group is available to mint / False = the group has already been minted
    */
    function isGroupAvailable(string calldata groupName) public view whenNotPaused returns (bool){
        if (groupDetails[getGroupID(groupName)].groupAddress != address(0)){
            return false;
        }
        return true;
    }

    /**
    * @dev Get the Group Name of a group from the group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return string : the name of the group
    */
    // Get the group name from an ID
    function getGroupNameFromID(uint256 groupID) public view returns (string memory){
        return groupDetails[groupID].groupName;
    }

    /**
    * @dev Get the Group Details of a group from the group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return string : the details of the group
    */
    // Get the group details from an ID
    function getGroupDetailsFromID(uint256 groupID) public view returns (string memory){
        return groupDetails[groupID].details;
    }

    /**
    * @dev Get the Group URI of a group from the group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return string : the URI of the group
    */
    function getGroupURIFromID(uint256 groupID) public view returns (string memory){
        return groupDetails[groupID].uri;
    }

    /**
    * @dev Get the colors used as the backgroun of the NFT of a group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return string[3] : an array of the three colors in hex format used to make the background color of the group NFT
    */
    function getGroupColorsFromID(uint256 groupID) public view returns (string[3] memory){
        return groupDetails[groupID].colors;
    }

    /**
    * @dev Add a user as a member to a group
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group to add the user to
    * @param member : the address of the user or group to add as a user to the group
    */
    function addMemberToGroup(uint256 groupID, address member) public onlyGroupOwners(groupID) whenNotPaused nonReentrant{
        // Add them to the group
        addMember(groupID, member);
    }

    /**
    * @dev Remove a user from a group
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group to remove the user from
    * @param member : the address of the user to remove from the group
    */
    function removeMemberFromGroup(uint256 groupID, address member) public onlyGroupOwners(groupID) whenNotPaused {
        removeMember(groupID, member);
    }

    /**
    * @dev Leave a group (self)
    * @dev Can only be called by a user in the group provided
    * @param groupID : the unique Group ID of the group to leave from
    */
    function leaveGroup(uint256 groupID) public onlyGroupMembers(groupID, msg.sender) whenNotPaused nonReentrant{
        removeMember(groupID, msg.sender);
    }

    /**
    * @dev This allows owners to change the case of their group name (mygroup => MyGroup)
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group modify the case of the name
    * @param groupName : the formatting of the group name to change to
    */
    function updateGroupNameFormat(uint256 groupID, string calldata groupName) public onlyGroupOwners(groupID) whenNotPaused  {
        // Ensure the group name is not empty
        require(bytes(groupName).length > 0, "Group name cannot be empty");

        // Make sure the name is still the same
        require(groupID == getGroupID(groupName), "Can only change the case");

        // Set the group name
        groupDetails[groupID].groupName = groupName;

        // Update the stored metadata for the group profile
        GroupTokens.adminUpdateGroupMetadata(groupID);

        // Log the change
        emit logUpdateGroupNameFormat(groupID, groupName);
    }

    /**
    * @dev This allows users to change colors of their group image (Hex format)
    * @dev Can only be called by the owner of the group
    * @dev (000000 = Black / FFFFFF = White / b154f0 = Purple)
    * @param groupID : the unique Group ID of the group modify colors for
    * @param color1 : the first color in hex format to set the NFT background to
    * @param color2 : the second color in hex format to set the NFT background to
    * @param color3 : the third color in hex format to set the NFT background to
    */
    function updateGroupNFTColors(uint256 groupID, string calldata color1, string calldata color2, string calldata color3) public onlyGroupOwners(groupID) whenNotPaused {
        // Ensure valid hex length
        require(bytes(color1).length <= 6, "Invalid Hex color");
        require(bytes(color2).length <= 6, "Invalid Hex color");
        require(bytes(color3).length <= 6, "Invalid Hex color");

        groupDetails[groupID].colors[0] = color1;
        groupDetails[groupID].colors[1] = color2;
        groupDetails[groupID].colors[2] = color3;

        // Update the stored metadata for the group profile
        GroupTokens.adminUpdateGroupMetadata(groupID);
    }

    /**
    * @dev This allows owners to change details associated with their group. These are written to the NFT metadata
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group modify
    * @param details : the details of the group to be written to the metadata of the NFT
    */
    function updateGroupNFTDetails(uint256 groupID, string calldata details) public onlyGroupOwners(groupID) whenNotPaused {
        // Make sure the details are within length limits
        require(bytes(details).length <= maxDetailsLength, "Details too long");

        groupDetails[groupID].details = details;

        // Update the stored metadata for the group profile
        GroupTokens.adminUpdateGroupMetadata(groupID);
    }

    /**
    * @dev This allows owners to change details associated with their group. These are written to the NFT metadata
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group modify
    * @param uri : the URI of the group to be written to the metadata of the NFT
    */
    function updateGroupNFTURI(uint256 groupID, string calldata uri) public onlyGroupOwners(groupID) whenNotPaused {
        // Require a Avatar with RCF compliant characters only
        require(KUtils.isValidURI(uri), "Bad characters in URI");

        // Make sure the uri is within length limits
        require(bytes(uri).length <= maxURILength, "URI too long");

        groupDetails[groupID].uri = uri;

        // Update the stored metadata for the group profile
        GroupTokens.adminUpdateGroupMetadata(groupID);
    }


    /*

    PRIVATE FUNCTIONS

    */

    function addMember(uint256 groupID, address member) private {
        // Make sure there's room for membership in the group
        require(groupDetails[groupID].members.length < maxMembersPerGroup, "You have reached the max amount of members for this group");

        // Make sure they're not already a member
        require(!isMemberOf[member][groupID], "Already member of group");

        // Add them to the group
        isMemberOf[member][groupID] = true;

        // Add to the group member count
        groupDetails[groupID].members.push(member);

        // Add the group to their list of memberships
        groupMemberships[member].push(groupID);

        // Emit to the logs for external reference
        emit logJoinGroup(groupID, member);
    }

    function removeMember(uint256 groupID, address member) private {
        // Remove them from the group
        isMemberOf[member][groupID] = false;

        // Remove it from the group members array
        uint256 place = 0;
        string memory addressString = KUtils.addressToString(member);
        for (uint i=0; i < groupDetails[groupID].members.length; i++) {
            if (KUtils.stringsEqual(KUtils.addressToString(groupDetails[groupID].members[i]), addressString)){
                place = i;
                break;
            }
        }

        // Swap the last entry with this one
        groupDetails[groupID].members[place] = groupDetails[groupID].members[groupDetails[groupID].members.length-1];

        // Remove the last element
        groupDetails[groupID].members.pop();

        // Remove the groups from membership
        place = 0;
        for (uint i=0; i < groupMemberships[member].length; i++) {
            if (groupMemberships[member][i] == groupID){
                place = i;
                break;
            }
        }

        // Swap the last entry with this one
        groupMemberships[member][place] = groupMemberships[member][groupMemberships[member].length-1];

        // Remove the last element
        groupMemberships[member].pop();

        // Emit to the logs for external reference
        emit logLeaveGroup(groupID, member);
    }


    /*

    CONTRACT CALL FUNCTIONS

    */

    // Update token ownership only callable from the Token contract overrides
    function onTransfer(address from, address to, uint256 tokenId) public onlyTrustedContracts nonReentrant {
        // If transferred to new owner
        if (from != address(0)){
            // Add new owner to mapping
            groupDetails[tokenId].ownerAddress = to;
            groupAddressToID[to] = tokenId;
            removeMember(tokenId, from);
            addMember(tokenId, to);
        }

        // If Burned
        if (to == address(0)){
            // Remove old owner from mapping
            delete groupDetails[tokenId];

            // Reset the group address mapping
            delete groupAddressToID[to];
        }
    }

    function setInitialDetails(uint256 _groupID, address _thisOwner, string memory groupName, address tokenContractAddress) public onlyTrustedContracts {
        // Make it so that we can only do this on mint
        require(groupDetails[_groupID].ownerAddress == address(0), "Can't edit existing group");

        // Set the owner
        groupDetails[_groupID].ownerAddress = _thisOwner;

        // Set the owner as the first member of the group and add to member count
        isMemberOf[_thisOwner][_groupID] = true;

        // Add to the group member count
        groupDetails[_groupID].members.push(_thisOwner);

        // Set the group name
        groupDetails[_groupID].groupName = groupName;

        // Add the group to the owners list of memberships
        groupMemberships[_thisOwner].push(_groupID);

        // Set the default colors for the NFT
        groupDetails[_groupID].colors[0] = 'ad81fc';
        groupDetails[_groupID].colors[1] = '8855d5';
        groupDetails[_groupID].colors[2] = '5e13d1';

        // Generate and store an address for the group
        address groupAddress = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp)))));
        groupAddressToID[groupAddress] = _groupID;
        groupDetails[_groupID].groupAddress = groupAddress;

        // Update the group profile to the initial details
        UserProfiles.setupNewGroup(groupAddress, groupName, _groupID, tokenContractAddress);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}


