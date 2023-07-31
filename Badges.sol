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

    @title Badges
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
import "./interfaces/INFT.sol";

contract Badges is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) private admins;

    struct BadgeDetails {
        string badgeName;
        uint256 badgeTypeID;
        string badgeURI;
        address allowedAddress;
        uint256 minimumReq;
        bool status;
        string desc;
        string otherURI;
    }

    // Mapping of all the badge details to a unique ID
    mapping (uint256 => BadgeDetails) badgeDetails;

    // The array to keep track of badges
    uint256[] public badgeIDs;

    // Badge count for indexing
    uint256 public badgeCount;

    // Mapping of all the badges to user address
    mapping (address => uint256[]) userBadges;


    // Link to the KUtils Contracts
    IKUtils public KUtils;



    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Initialize badgeCount to 0
        badgeCount = 0;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);
    }


    /*

    EVENTS

    */

    event addBadgeToApp(string indexed badgeName, string badgeURL, address indexed allowedAddress, string otherURI, string desc);
    event updateBadgeLog(uint256 indexed badgeID, string indexed badgeName, string badgeURL, address indexed allowedAddress, string otherURI);
    event removeBadgeFromApp(uint256 indexed badgeID);
    event enableBadgeLog(uint256 indexed badgeID);
    event disableBadgeLog(uint256 indexed badgeID);
    event addToUser(address indexed addedBy, uint256 indexed badgeID, address indexed userAddress);
    event removeFromUser(address indexed removedBy, uint256 indexed badgeID, address indexed userAddress);


    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
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

    function updateContracts(address _kutils) public onlyAdmins {
        // Update the KUtils address
        KUtils = IKUtils(_kutils);
    }

    /**
    * @dev Add a badge to the list of badges to be added to users
    * @param badgeName : Name of the badge to add
    * @param badgeURI : The badge image URI
    * @param allowedAddress : Address that is allowed to call to add the badge (0x0 = admin only)
    * @param minimumReq : A minimum amount of tokens required from allowedAddress contract for this badge to be added
    * @param badgeTypeID : A specific string that the contract will verify ownership of by address
    * @param otherURI : Typically a link to the project behind the badge
    * @param desc : General descriptive text about the badge
    */
    function addBadge(string calldata badgeName, string calldata badgeURI, address allowedAddress, uint256 minimumReq, uint256 badgeTypeID, string calldata otherURI, string calldata desc) public whenNotPaused onlyAdmins {

        // Increase badgeCount
        badgeCount++;

        // Add the badge to the list of available badges
        badgeIDs.push(badgeCount);

        // Add the badge details to the mapping
        badgeDetails[badgeCount].badgeName = badgeName;
        badgeDetails[badgeCount].badgeTypeID = badgeTypeID;
        badgeDetails[badgeCount].badgeURI = badgeURI;
        badgeDetails[badgeCount].otherURI = otherURI;
        badgeDetails[badgeCount].desc = desc;
        badgeDetails[badgeCount].allowedAddress = allowedAddress;
        badgeDetails[badgeCount].minimumReq = minimumReq;
        badgeDetails[badgeCount].status = true;

        // Log the adding of the badge
        emit addBadgeToApp(badgeName, badgeURI, allowedAddress, otherURI, desc);
    }


    /**
    * @dev Update a badge
    * @param badgeID : The ID of the badge to update
    * @param badgeName : Name of the badge to add
    * @param badgeURI : The badge image URI
    * @param allowedAddress : Address that is allowed to call to add the badge (0x0 = admin only)
    * @param minimumReq : A minimum amount of tokens required from allowedAddress contract for this badge to be added
    * @param badgeTypeID : A specific string that the contract will verify ownership of by address
    * @param otherURI : Typically a link to the project behind the badge
    * @param desc : General descriptive text about the badge
    */
    function updateBadge(uint256 badgeID, string calldata badgeName, string calldata badgeURI, address allowedAddress, uint256 minimumReq, uint256 badgeTypeID, string calldata otherURI, string calldata desc) public whenNotPaused onlyAdmins {

        // Add the badge details to the mapping
        badgeDetails[badgeID].badgeName = badgeName;
        badgeDetails[badgeID].badgeTypeID = badgeTypeID;
        badgeDetails[badgeID].badgeURI = badgeURI;
        badgeDetails[badgeID].otherURI = otherURI;
        badgeDetails[badgeID].desc = desc;
        badgeDetails[badgeID].allowedAddress = allowedAddress;
        badgeDetails[badgeID].minimumReq = minimumReq;

        // Log the updating of the badge
        emit updateBadgeLog(badgeID, badgeName, badgeURI, allowedAddress, otherURI);
    }




    /**
    * @dev Remove a badge from the list of badges to be added to users
    * @param badgeID : The ID of the badge to remove
    */
    function removeBadge(uint256 badgeID) public whenNotPaused onlyAdmins {

        // Get the index of the badgeID
        uint256 place = 0;
        bool ok = false;
        for (uint i=0; i < badgeIDs.length; i++) {
            if (badgeIDs[i] == badgeID){
                place = i;
                ok = true;
                break;
            }
        }

        // Make sure this badge exists
        require(ok, "User does not have badge");

        // Swap the last entry with this one
        badgeIDs[place] = badgeIDs[badgeIDs.length-1];

        // Remove the last element
        badgeIDs.pop();

        // Disable the badge details
        badgeDetails[badgeID].status = false;

        // Log the adding of the badge
        emit removeBadgeFromApp(badgeID);
    }

    /**
    * @dev Enable an existing badge
    * @param badgeID : The ID of the badge to enable
    */
    function enableBadge(uint256 badgeID) public whenNotPaused onlyAdmins {

        // Make sure this badge exists
        require(badgeDetails[badgeID].status == false, "Invalid badge ID or not disabled");

        // Enable the badge
        badgeDetails[badgeID].status = true;

        // Log the adding of the badge
        emit enableBadgeLog(badgeID);
    }

    /**
    * @dev Disable an existing badge
    * @param badgeID : The ID of the badge to disable
    */
    function disableBadge(uint256 badgeID) public whenNotPaused onlyAdmins {

        // Make sure this badge exists
        require(badgeDetails[badgeID].status == true, "Invalid badge ID or not enabled");

        // Enable the badge
        badgeDetails[badgeID].status = false;

        // Log the adding of the badge
        emit disableBadgeLog(badgeID);
    }


    /*

    EXTERNAL CONTRACT FUNCTIONS

    */

    /**
    * @dev Add a badge to a user from the allowed address of the badge or by an admin
    * @param userAddress : Wallet address of the user to add the badge to
    * @param badgeID : The badge ID
    */
    function addBadgeToUser(address userAddress, uint256 badgeID) public whenNotPaused {

        // Initialize that it's ok to add badge
        bool ok = true;

        // Check to see if if this user / contract is allowed to add this badge ID to users and it's active
        require((badgeDetails[badgeID].allowedAddress == msg.sender || admins[msg.sender]) && badgeDetails[badgeID].status, "Not adding.");

        // Check to make sure they don't already have this badge
        for (uint i=0; i < userBadges[userAddress].length; i++) {
            if (userBadges[userAddress][i] == badgeID){
                ok = false;
                break;
            }
        }

        // If they don't already have it (it's ok), then add it
        if (ok){

            // Add the badge to their profile
            userBadges[userAddress].push(badgeID);

            // Log the adding of the badge
            emit addToUser(msg.sender, badgeID, userAddress);
        }
    }

    /**
    * @dev Remove a badge from a user by the allowed address of the badge or by an admin
    * @param userAddress : Wallet address of the user to remove the badge from
    * @param badgeID : The badge ID
    */
    function removeBadgeFromUser(address userAddress, uint256 badgeID) public whenNotPaused {

        // Check to see if if this user / contract is allowed to remove this badge ID to users and it's active
        require(userAddress == msg.sender || badgeDetails[badgeID].allowedAddress == msg.sender || admins[msg.sender], "Nope.");

        // Get the index of the badgeID
        uint256 place = 0;
        bool ok = false;
        for (uint i=0; i < userBadges[userAddress].length; i++) {
            if (userBadges[userAddress][i] == badgeID){
                place = i;
                ok = true;
                break;
            }
        }

        // Make sure this badge exists
        if (ok) {

            // Swap the last entry with this one
            userBadges[userAddress][place] = userBadges[userAddress][userBadges[userAddress].length-1];

            // Remove the last element
            userBadges[userAddress].pop();

            // Log the adding of the badge
            emit removeFromUser(msg.sender, badgeID, userAddress);
        }
    }


    /*

    PUBLIC FUNCTIONS

    */


    /**
    * @dev Check to see if the requesting user qualifies for a badge
    * @param badgeID : The badge ID to check to see if they qualify to be added
    */
    function verifyBadge(uint256 badgeID) public whenNotPaused {

        // Get the address for this badge
        address badgeContract = badgeDetails[badgeID].allowedAddress;

        // Verify that this is a verifiable badge
        require(badgeContract != address(0), "Badge not verifiable");

        // Build interface to link to NFT contract
        INFT NFT;

        // Setup link to the NFT contract
        NFT = INFT(badgeContract);

        // Check that they have the minimum amount required if set
        require(NFT.balanceOf(msg.sender) >= badgeDetails[badgeID].minimumReq, "Not enough owned");

        // If they passed a badge type, check for it in the contract
        if (badgeDetails[badgeID].badgeTypeID > 0){
            require(NFT.kuthuluVerifyBadgeType(badgeDetails[badgeID].badgeTypeID, msg.sender), "You don't have that badge");
        }

        // They meet the requirements so add the badge to their profile
        userBadges[msg.sender].push(badgeID);
    }

    /**
    * @dev return a list of users badge IDs
    * @param userAddress : The address of the user to get badges for
    */
    function getUserBadges(address userAddress) public view whenNotPaused returns(uint256[] memory) {
        return userBadges[userAddress];
    }

    /**
    * @dev Get badge details
    * @param badgeID : The ID of the badge to get the details for
    * @dev 0 = Badge Name
    * @dev 1 = Badge URI for the thumbnail
    * @dev 2 = Contract address that is allowed to add and remove badges to members dynamically
    * @dev 3 = Minimum quantity of NFTs / tokens required to be owned to qualify for the badge
    * @dev 4 = Status (active / disabled)
    * @dev 5 = Badge Type ID
    * @dev 6 = Other URI : generally a URI to the location of the project behind it
    * @dev 7 = Description about the badge
    */
    function getBadgeDetails(uint256 badgeID) public view whenNotPaused returns(string[] memory) {
        // Initialize the return array of badge details
        string[] memory thisBadge = new string[](8);

        thisBadge[0] = badgeDetails[badgeID].badgeName;
        thisBadge[1] = badgeDetails[badgeID].badgeURI;
        thisBadge[2] = KUtils.addressToString(badgeDetails[badgeID].allowedAddress);
        thisBadge[3] = KUtils.toString(badgeDetails[badgeID].minimumReq);
        thisBadge[4] = badgeDetails[badgeID].status ? "active" : "disabled";
        thisBadge[5] = KUtils.toString(badgeDetails[badgeID].badgeTypeID);
        thisBadge[6] = badgeDetails[badgeID].otherURI;
        thisBadge[7] = badgeDetails[badgeID].desc;

        return thisBadge;
    }

    /**
    * @dev get a list of all the badge IDs
    */
    function getBadges() public view whenNotPaused returns(uint256[] memory) {
        return badgeIDs;
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}