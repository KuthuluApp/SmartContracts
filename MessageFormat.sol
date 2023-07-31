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

    @title MessageFormat
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
import "./interfaces/IUserProfiles.sol";
import "./interfaces/IGroups.sol";

contract MessageFormat is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;


    // Link the KUtils contract
    IKUtils public KUtils;

    // Link the Groups contract
    IGroups public Groups;

    // Link the User Profiles contract
    IUserProfiles public UserProfiles;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);
    }


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

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function updateContracts(address _kutils, address _userProfiles, address _groups) public onlyAdmins {
        // Update the User Profiles contract address
        KUtils = IKUtils(_kutils);

        // Setup link to User Profiles
        UserProfiles = IUserProfiles(_userProfiles);

        // Setup link to Groups
        Groups = IGroups(_groups);
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Build an array of message details by message ID
    * @param msgData : array of message data to format
    * @param message : the body of the message
    * @param postedBy : an array of who posted the message. [0] = Address of the poster / [1] = proxy poster address
    * @param hashtags : an array of hashtags in the message
    * @param taggedAccounts : an array of tagged accounts in the message
    * @param uri : the URI added to a message (also used for attachments)
    * @param inGroups : an array of group IDs that the message was posted into
    * @return uint256 : the comment level of the message
    * @dev msgData[]
    * 0 = msgID
    * 1 = time
    * 2 = block
    * 3 = tip
    * 4 = paid
    * 5 = postByContract
    * 6 = likes
    * 7 = reposts
    * 8 = comments
    * 9 = isCommentOf
    * 10 = isRepostOf
    * 11 = commentLevel
    * 12 = asGroup
    * 13 = ERC20 Tip Amount
    * 14 = Comment ID
    */
    function buildMsg(uint256[] memory msgData, string memory message, address[2] memory postedBy, string[] memory hashtags, address[] memory taggedAccounts, string memory uri, uint256[] memory inGroups, address tipContract) public view returns (string[] memory){

        string memory hashtagsStr = "";
        string memory taggedStr = "";
        string memory inGroupsStr = "";


        for (uint h=0; h < hashtags.length; h++) {
            if (h == 0){
                hashtagsStr = hashtags[h];
            } else {
                hashtagsStr = KUtils.append(hashtagsStr, ',', hashtags[h], '', '');
            }
        }


        for (uint h=0; h < taggedAccounts.length; h++) {
            if (h == 0){
                taggedStr = KUtils.addressToString(taggedAccounts[h]);
            } else {
                taggedStr = KUtils.append(taggedStr, ',', KUtils.addressToString(taggedAccounts[h]), '', '');
            }
        }

        for (uint h=0; h < inGroups.length; h++) {
            if (h == 0){
                inGroupsStr = KUtils.toString(inGroups[h]);
            } else {
                inGroupsStr = KUtils.append(inGroupsStr, ',', KUtils.toString(inGroups[h]), '', '');
            }
        }

        // userDetails[]
        /**
        * 0 = Handle
        * 1 = Post Count
        * 2 = Number of users they are following
        * 3 = Number of users that are following them
        * 4 = User Verification level
        * 5 = Avatar URI
        * 6 = Avatar Metadata
        * 7 = Avatar Contract Address
        * 8 = URI
        * 9 = Bio
        * 10 = Location
        * 11 = Block number when joined
        * 12 = Block timestamp when joined
        * 13 = Limit of number of users they can follow
        * 14 = Total Tips Received
        * 15 = Total Tips Sent
        */
        string[] memory userDetails = UserProfiles.getUserDetails(postedBy[0]);


        // Build Return Object
        /**
        *   index = attribute name (pseudo type)
        *
        *   0 = msgID (int)
        *   1 = postedBy (address)
        *   2 = handle (string)
        *   3 = verification level (int)
        *   4 = avatarURI (string)
        *   5 = avatarMetadata (string)
        *   6 = avatarContract (address)
        *   7 = message (string)
        *   8 = commentLevel (int)
        *   9 = hashtags (string[])
        *   10 = taggedAccounts (address[])
        *   11 = postByContract (bool)
        *   12 = likes (int)
        *   13 = comments (int)
        *   14 = reposts (int)
        *   15 = isCommentOf (int)
        *   16 = isRepostOf (int)
        *   17 = asGroup (int)
        *   18 = inGroups (int[])
        *   19 = uri (string)
        *   20 = tips (int)
        *   21 = paid (int)
        *   22 = block (int)
        *   23 = timestamp (int)
        *   24 = postProxy (address)
        *   25 = ERC20 token contract address for tips
        *   26 = Amount of ERC20 Token tipped
        *   27 = Comment ID in Thread
        */

        string[] memory messageDetails = new string[](28);

        messageDetails[0] = KUtils.toString(msgData[0]);
        messageDetails[1] = KUtils.addressToString(postedBy[0]);
        messageDetails[2] = userDetails[0];
        messageDetails[3] = userDetails[4];
        messageDetails[4] = userDetails[5];
        messageDetails[5] = userDetails[6];
        messageDetails[6] = userDetails[7];
        messageDetails[7] = message;
        messageDetails[8] = KUtils.toString(msgData[11]);
        messageDetails[9] = hashtagsStr;
        messageDetails[10] = taggedStr;
        messageDetails[11] = KUtils.toString(msgData[5]);
        messageDetails[12] = KUtils.toString(msgData[6]);
        messageDetails[13] = KUtils.toString(msgData[8]);
        messageDetails[14] = KUtils.toString(msgData[7]);
        messageDetails[15] = KUtils.toString(msgData[9]);
        messageDetails[16] = KUtils.toString(msgData[10]);
        messageDetails[17] = KUtils.toString(msgData[12]);
        messageDetails[18] = inGroupsStr;
        messageDetails[19] = uri;
        messageDetails[20] = KUtils.toString(msgData[3]);
        messageDetails[21] = KUtils.toString(msgData[4]);
        messageDetails[22] = KUtils.toString(msgData[2]);
        messageDetails[23] = KUtils.toString(msgData[1]);
        messageDetails[24] = KUtils.addressToString(postedBy[1]);
        messageDetails[25] = KUtils.addressToString(tipContract);
        messageDetails[26] = KUtils.toString((msgData[13]));
        messageDetails[27] = KUtils.toString((msgData[14]));


        return messageDetails;
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}


