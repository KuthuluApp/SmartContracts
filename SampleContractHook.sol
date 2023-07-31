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

    @title SampleContractHook
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
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


import "./interfaces/IKUtils.sol";
import "./interfaces/IKuthulu.sol";
import "./interfaces/IDOOM.sol";

//import "hardhat/console.sol";

contract SampleContractHook is Initializable, PausableUpgradeable, OwnableUpgradeable, ERC20Upgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Message Stats
    struct MsgStats {
        int likes;
        int comments;
        int reposts;
        uint256 tipsReceived;
        address tipContract;
        uint256 tipERC20Amount;
        uint postByContract;
        uint256 time;
        uint256 block;
    }

    // The Message data struct
    struct MsgData {
        uint msgID;
        address[2] postedBy;
        string message;
        uint256 paid;
        string[] hashtags;
        address[] taggedAccounts;
        uint256 asGroup;
        uint256[] inGroups;
        string uri;
        uint256 commentLevel;
        uint256 isCommentOf;
        uint256 isRepostOf;
        MsgStats msgStats;
    }

    // To call back to KUTHULU
    address public KuthuluContract;

    // Link to the KuthuluApp
    IKuthulu public KuthuluApp;

    // Link to the KUtils Contracts
    IKUtils public KUtils;

    // Link to the KUtils Contracts
    IDOOM public DOOM;

    // Setup to be able to call default DOOM ERC20 calls
    IERC20Upgradeable public token;

    // Trusted Contracts
    mapping (address => bool) public kuthuluContracts;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kuthulu, address[2] calldata _kuthuluTrusted, address _kutils,  address _doom) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Setup link to KUTHULU
        KuthuluApp = IKuthulu(_kuthulu);
        KuthuluContract = _kuthulu;

        // KUTHULU Contracts (Main app + UserProfiles non-proxy addresses) for allowed entry
        kuthuluContracts[_kuthuluTrusted[0]] = true;
        kuthuluContracts[_kuthuluTrusted[1]] = true;


        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Setup link to DOOM
        DOOM = IDOOM(_doom);
        token = IERC20Upgradeable(_doom);
    }


    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier onlyKUTHULUContracts() {
        require(kuthuluContracts[msg.sender], KUtils.append("Only KUTHULU contracts can call this function. Not Allowed: ", KUtils.addressToString(msg.sender),"","",""));
        _;
    }


    /*

    ADMIN FUNCTIONS

    */

    receive() external payable {}

    function pause() public onlyAdmins {
        _pause();
    }

    function unpause() public onlyAdmins {
        _unpause();
    }

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function updateKUTHULUContracts(address contractAddress, bool status) public onlyAdmins {
        // You must add the KUTHULU and UserProfiles contract addresses (not the proxies) for this to work
        kuthuluContracts[contractAddress] = status;
    }

    function updateContracts(address _kuthulu, address _kutils, address _doom) public onlyAdmins {
        // Update the KUTHULU contract address
        KuthuluApp = IKuthulu(_kuthulu);

        // Update the KUtils address
        KUtils = IKUtils(_kutils);

        // Update the DOOM address
        DOOM = IDOOM(_doom);
    }

    function mintDoom(uint256 quantity) public payable onlyAdmins {
        uint256 valueToSend = quantity * DOOM.costToMint();
        DOOM.publicMint{value: valueToSend}(quantity);

        // Approve KUTHULU to spend the DOOM tokens
        token.approve(KuthuluContract, quantity * 1 ether);
    }


    function KuthuluHook(MsgData memory newMsg) public onlyKUTHULUContracts returns (bool) {

//        console.log();
//
//        console.log(">>> Contract Hook Received");
//        console.log("--------");
//
//        // Log everything out for testing
//        console.log("Message ID Received:", newMsg.msgID);
//        console.log("Posted By:", KUtils.addressToString(newMsg.postedBy[0]));
//        console.log("Posted Proxy By:", KUtils.addressToString(newMsg.postedBy[1]));
//        console.log("Message Received:", newMsg.message);
//        console.log("Paid:", newMsg.paid);
//        console.log("Number of Hashtags:", newMsg.hashtags.length);
//        console.log("Number of Tagged Accounts:", newMsg.taggedAccounts.length);
//        console.log("Posted By Group ID:", newMsg.asGroup);
//        console.log("Number of Groups Posted Into:", newMsg.inGroups.length);
//        console.log("URI:", newMsg.uri);
//        console.log("Comment Level:", newMsg.commentLevel);
//        console.log("Is Comment Of Message ID:", newMsg.isCommentOf);
//        console.log("Is Repost Of Message ID:", newMsg.isRepostOf);
//        console.log("Posted By Contract:", newMsg.msgStats.postByContract);
//        console.log("Message Timestamp:", newMsg.msgStats.time);
//        console.log("Message Posted at Block:", newMsg.msgStats.block);
//        console.log("Total Tips Received To Split Among All Tagged Accounts:", newMsg.msgStats.tipsReceived);
//        console.log("Total ERC20 Token Tips Received:", newMsg.msgStats.tipERC20Amount);
//        console.log("--------");

        // Do this if it's a real post
        if (newMsg.msgID != 0){
//            console.log();
            postTestMessage(KUtils.append("Thanks for the message @",KUtils.addressToString(newMsg.postedBy[0]),"!","",""), newMsg.postedBy[0]);
//            console.log();
//            console.log("<<<< End Contract Hook");
        }

        return true;
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Get the number of messages posted in KUTHULU to test the interface
    * @return uint256 : the number of messages in the KUTHULU app
    */
    function getKuthuluMsgCount() public view whenNotPaused returns (uint256){

        // Initialize the array
        uint256[] memory stats = new uint256[](9);

        // Get all the stats from KUTHULU
        stats = KuthuluApp.getStats();

        // Return total post count
        return stats[0];
    }


    /**
    * @dev Toggle the liking of a message
    */
    function toggleLike(uint256 msgID) private {

//        console.log("> Toggling Like for message ID:", msgID);

        KuthuluApp.toggleLike(msgID);

//        console.log("< Toggled Like");
    }


    /**
    * @dev Post a sample message back to KUTHULU
    */
    function postTestMessage(string memory message, address taggedAccount) private whenNotPaused {

//        console.log("> Posting Test Message");

        // Create a couple hashtags
        string[] memory hashtags = new string[](2);

        hashtags[0] = "DOOMLabs";
        hashtags[1] = "boom";


        // Tag a sample tagged account
        // If tipping an ERC20 token, the last tagged address must be the token contract address
        address[] memory taggedAccounts = new address[](1);

        taggedAccounts[0] = taggedAccount;

        // Set URI
        string memory uri = "https://www.DOOMLabs.io";

        // Set the post attributes
        uint256 allowComments = 0;  // Allow Comments (Comment Level: 0 = Allowed / 1 = Not Allowed)
        uint256 isCommentOf = 0;  // Is this a comment of another post? If so, add that message ID here
        uint256 isRepostOf = 0;  // Is this a repost of another post? If so, add that message ID here
        uint256 groupID = 0;  // Are you posting on behalf of a group? If so, add the GroupID here
        uint256 tipsERC20Amount = 0; // Amount of ERC20 token to tip in wei

        // We're not posting to any Spaces / Groups
        uint256[] memory inGroups = new uint256[](0);

        // Make the test post back to KUTHULU
        KuthuluApp.postMsg(message, hashtags, taggedAccounts, uri, [allowComments,isCommentOf,isRepostOf,groupID,tipsERC20Amount], inGroups);

//        console.log("< Test Message Posted");
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}


