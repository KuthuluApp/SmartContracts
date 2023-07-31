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

    @title Blocking
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
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/IUserProfiles.sol";
import "./interfaces/INFT.sol";


contract Blocking is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Maximum amount of records to return on query
    uint256 public maxItemsReturn;

    // Contract Proof struct
    struct ContractProof {
        address contractAddress;
        uint256 minimumReq;
    }

    // The User data struct
    struct UserData {
        mapping (address => bool) whitelist;
        mapping (address => bool) blacklist;
        address[] whitelistDetails;
        address[] blacklistDetails;
        bool usingWhitelist;
        ContractProof contractProof;

        //TODO : add contract blocking / exclusivity
    }

    // Map the User Address => User Data
    mapping (address => UserData) public usrBlockingMap;

    // Link the User Profiles contract
    IUserProfiles public userProfiles;

    // Link the Groups contract
    IGroups public Groups;

    // Link the KUtils contract
    IKUtils public KUtils;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxItemsReturn) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set max items to return on query
        maxItemsReturn = _maxItemsReturn;

        // Setup link to User Profiles
        KUtils = IKUtils(_kutils);
    }


    /*

    EVENTS

    */

    event toggleWhiteListLog(address indexed usrAddress, bool flipped, uint256 indexed groupID);
    event logWhitelistUpdate(address indexed profileAddress, address indexed toggleAddress, bool update, uint256 indexed groupID);
    event logBlacklistUpdate(address indexed profileAddress, address indexed toggleAddress, bool update, uint256 indexed groupID);
    event logNFTReqUpdate(address indexed contractAddress, uint256 minimumReq, uint256 indexedgroupID);


    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier checkForGroupOwnership(uint256 groupID) {
        // If this is a group validate that they are the owner
        if (groupID > 0){
            // Validate that they are the owner
            require(msg.sender == Groups.getOwnerOfGroupByID(groupID), "You are not the owner of this group");
        }
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

    function updateContracts(address _kutils, address _userProfiles, address _groups) public onlyAdmins {
        // Update the Groups contract address
        KUtils = IKUtils(_kutils);

        // Update the User Profiles contract address
        userProfiles = IUserProfiles(_userProfiles);

        // Update the Groups contract address
        Groups = IGroups(_groups);
    }


    /*

    BLACK & WHITE LISTS

    */

    /**
    * @dev Checks to see if the the group is using NFT whitelisting
    * @dev and if so, do they have the minimum required to be allowed to post into the group
    * @param requesterAddress : user or group address requesting to post into the group
    * @param groupAddress : the group that the requester wants to post into
    * @return bool: True = is allowed to perform action / False = is not allowed to perform action
    */
    function isAllowedByNFT(address requesterAddress, address groupAddress) public view whenNotPaused returns (bool){

        // First check if contract proofing is in place
        if (usrBlockingMap[groupAddress].contractProof.contractAddress != address(0)){
            // Build interface to link to NFT contract
            INFT NFT;

            // Setup link to the NFT contract
            NFT = INFT(usrBlockingMap[groupAddress].contractProof.contractAddress);

            // Check that they have the minimum amount required
            if (NFT.balanceOf(requesterAddress) < usrBlockingMap[groupAddress].contractProof.minimumReq) {
                return false;
            }
        }

        return true;
    }

    /**
    * @dev Checks to see if the requesterAddress is allowed to perform actions against targetAddress
    * @param requesterAddress : user or group address requesting to perform an action to a user or group
    * @param targetAddress : user or group address that the requester wants to perform an action against
    * @return bool: True = is allowed to perform action / False = is not allowed to perform action
    */
    function isAllowed(address requesterAddress, address targetAddress) public view whenNotPaused returns (bool){

        // First check if they're blocked by NFT
        if (isAllowedByNFT(requesterAddress, targetAddress)){

            // If they're using the whitelist
            if (usrBlockingMap[targetAddress].usingWhitelist) {
                // Check to make sure they're allowed
                if (usrBlockingMap[targetAddress].whitelist[requesterAddress]){
                    return true;
                }
            } else {
                // or not blacklisted if not using the whitelist
                if (!usrBlockingMap[targetAddress].blacklist[requesterAddress]){
                    return true;
                }
            }

        }

        return false;
    }


    /**
    * @dev Get a list of user addresses that are either blocked (blacklist) or allowed (whitelist)
    * @param usrAddress : the address of the user to get the black or whitelist of users from
    * @param blackList : true = black list / false = white list
    * @param startFrom : used or paginating through the results
    * @return address[]: an array of addresses in the list queried
    */
    function getList(address usrAddress, bool blackList, uint256 startFrom) public view whenNotPaused returns(address[] memory) {
        
        uint256 listTotal = blackList ? usrBlockingMap[usrAddress].blacklistDetails.length : usrBlockingMap[usrAddress].whitelistDetails.length;

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = listTotal;
            if (startFrom != 0){
                startFrom -= 1;
            } else {
                // It's empty, so end
                address[] memory empty = new address[](0);
                return empty;
            }
        }

        // Initialize the count as empty;
        uint256 returnCount = maxItemsReturn;

        if (startFrom < maxItemsReturn){
            returnCount = startFrom + 1;
        }

        // Start the array
        address[] memory blockList = new address[](returnCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the array up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - returnCount); i--) {
            blockList[counter] = blackList ? usrBlockingMap[usrAddress].blacklistDetails[i - 1] : usrBlockingMap[usrAddress].whitelistDetails[i - 1];
            counter += 1;
        }

        return blockList;
    }


    /**
    * @dev Toggle the using of a whitelist on / off. If a groupID is passed, only the group owner can perform this function.
    * @param groupID (optional) : Can pass in if this is a group being managed, otherwise pass in 0 for a user
    */
    function toggleWhiteList(uint256 groupID) public checkForGroupOwnership(groupID) whenNotPaused {

        address profileAddress = msg.sender;

        // If this is a group validate that they are the owner
        if (groupID > 0){
            profileAddress = Groups.getGroupAddressFromID(groupID);
        }

        // If they're using the whitelist
        if (usrBlockingMap[profileAddress].usingWhitelist) {
            // Disable it
            usrBlockingMap[profileAddress].usingWhitelist = false;

            // Log it
            emit toggleWhiteListLog(profileAddress, false, groupID);
        } else {
            // enable it
            usrBlockingMap[profileAddress].usingWhitelist = true;

            // Log it
            emit toggleWhiteListLog(profileAddress, true, groupID);
        }
    }


    /**
    * @dev Require a poster to own a minimum amount of NFTs (721 / 1155) to be able to post in your group
    * @param contractAddress : address of the NFT contract (0x0 disables requirement)
    * @param minimumReq : Minimum amount of NFTs owned by wallet from contractAddress to be allowed to post in group
    * @param groupID : Group ID to Apply to
    */
    function updateNFTReq(address contractAddress, uint256 minimumReq, uint256 groupID) public checkForGroupOwnership(groupID) whenNotPaused {

        // Get the group address from the group ID
        address profileAddress = _getProfileAddress(groupID);

        // Set the groups contract address for NFT requirements
        usrBlockingMap[profileAddress].contractProof.contractAddress = contractAddress;

        // Set the groups minimum required NFT owned amount
        usrBlockingMap[profileAddress].contractProof.minimumReq = minimumReq;

        // Log it
        emit logNFTReqUpdate(contractAddress, minimumReq, groupID);

    }


    /**
    * @dev Whitelist = NO ONE can message owner EXCEPT for addresses explicitly allowed here by the owner.
    * @dev Toggle an address to be on / off the whitelist
    * @dev If a groupID is passed, only the group owner can perform this function.
    * @param toToggle : address of user or group
    * @param groupID (optional) : Can pass in if this is a group being managed, otherwise pass in 0 for a user
    */
    function updateWhitelist(address toToggle, uint256 groupID) public checkForGroupOwnership(groupID) whenNotPaused {

        address profileAddress = _getProfileAddress(groupID);
        
        // Stringify the address
        string memory addressString = KUtils._toLower(KUtils.addressToString(toToggle));

        // If it's added, remove it
        if(usrBlockingMap[profileAddress].whitelist[toToggle] == true){
            // Set to false
            usrBlockingMap[profileAddress].whitelist[toToggle] = false;

            // Remove it from the array
            uint256 place = 0;
            for (uint i=0; i < usrBlockingMap[profileAddress].whitelistDetails.length; i++) {
                if (KUtils.stringsEqual(KUtils.addressToString(usrBlockingMap[profileAddress].whitelistDetails[i]), addressString)){
                    place = i;
                    break;
                }
            }

            // Swap the last entry with this one
            usrBlockingMap[profileAddress].whitelistDetails[place] = usrBlockingMap[profileAddress].whitelistDetails[usrBlockingMap[profileAddress].whitelistDetails.length-1];

            // Remove the last element
            usrBlockingMap[profileAddress].whitelistDetails.pop();

            // Log it
            emit logWhitelistUpdate(profileAddress, toToggle, false, groupID);
        } else {
            // Else it's not added so add it
            usrBlockingMap[profileAddress].whitelist[toToggle] = true;
            usrBlockingMap[profileAddress].whitelistDetails.push(toToggle);

            // Log it
            emit logWhitelistUpdate(profileAddress, toToggle, true, groupID);
        }
    }


    /**
    * @dev Blacklist = EVERYONE can message owner EXCEPT for addresses explicitly denied here by the owner
    * @dev Toggle an address to be on / off the blacklist
    * @dev If a groupID is passed, only the group owner can perform this function.
    * @param toToggle : address of user or group
    * @param groupID (optional) : Can pass in if this is a group being managed, otherwise pass in 0 for a user
    */
    function updateBlacklist(address toToggle, uint256 groupID) public checkForGroupOwnership(groupID) whenNotPaused {

        address profileAddress = _getProfileAddress(groupID);
        
        // Stringify the address
        string memory addressString = KUtils.addressToString(toToggle);

        // If it's added, remove it
        if(usrBlockingMap[profileAddress].blacklist[toToggle] == true){
            // Set to false
            usrBlockingMap[profileAddress].blacklist[toToggle] = false;

            // Remove it from the array
            uint256 place = 0;
            for (uint i=0; i < usrBlockingMap[profileAddress].blacklistDetails.length; i++) {
                if (KUtils.stringsEqual(KUtils.addressToString(usrBlockingMap[profileAddress].blacklistDetails[i]), addressString)){
                    place = i;
                    break;
                }
            }

            // Swap the last entry with this one
            usrBlockingMap[profileAddress].blacklistDetails[place] = usrBlockingMap[profileAddress].blacklistDetails[usrBlockingMap[profileAddress].blacklistDetails.length-1];

            // Remove the last element
            usrBlockingMap[profileAddress].blacklistDetails.pop();

            // Log it
            emit logBlacklistUpdate(profileAddress, toToggle, true, groupID);
        } else {
            // Else it's not added so add it
            usrBlockingMap[profileAddress].blacklist[toToggle] = true;
            usrBlockingMap[profileAddress].blacklistDetails.push(toToggle);

            // Log it
            emit logBlacklistUpdate(profileAddress, toToggle, true, groupID);
        }
    }


    /*

    PRIVATE FUNCTIONS

    */

    // Used to return either the group address or user address from a group ID
    function _getProfileAddress(uint256 groupID) private view whenNotPaused returns (address) {
        // If this is a group validate that they are the owner
        if (groupID > 0){
            return Groups.getGroupAddressFromID(groupID);
        } else {
            return msg.sender;
        }
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}