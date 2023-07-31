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

    @title KUTHULU
    v0.10

    KUTHULU : https://www.KUTHULU.xyz
    A project by DOOM Labs (https://DOOMLabs.io)
    The first truly decentralized social framework.
    Built for others to build upon and share freedom of expression.
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IUserProfiles.sol";
import "./interfaces/IKUtils.sol";
import "./interfaces/IHashtags.sol";
import "./interfaces/ITagged.sol";
import "./interfaces/IPosts.sol";
import "./interfaces/ILikes.sol";
import "./interfaces/IMessageData.sol";
import "./interfaces/IDOOM.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/ITips.sol";
import "./interfaces/IBlocking.sol";
import "./interfaces/IContractHook.sol";

contract KUTHULU is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) private admins;

    // ERC20 Contract Counters
    mapping(address => uint256) contractCounters;

    struct Counters {
        uint256 messages;   // Total messages posted ever
        uint256 comments;   // Total comments posted ever
        uint256 groupPosts; // Total group posts posted ever
        uint256 reposts;    // Total reposts posted ever
        uint256 hashtags;   // Total hashtags posted ever
        uint256 tags;       // Total tags posted ever
        uint256 likes;      // Total likes posted ever
        uint256 tips;       // Total tips posted ever
        uint256 follows;    // Total follows posted ever
    }
    
    Counters counters;

    // Max length of messages to save (UTF-8 single byte characters only)
    uint256[2] public maxMessageLength;

    // ERC20 Receiver for payment via ERC20
    IERC20Upgradeable public paymentToken;

    // Cost to post a message
    uint256 public costToPost;

    // Cost to like aa post
    uint256 public cutToPoster;

    // The max number of messages that can be returned at once
    uint256 public maxMsgReturnCount;

    // Link the User Profiles contract
    IUserProfiles public userProfiles;

    // Link to the KUtils
    IKUtils public KUtils;

    // Link to the Hashtags
    IHashtags public Hashtags;

    // Link to the Tagged Accounts
    ITagged public Tagged;

    // Link to the Posts
    IPosts public Posts;

    // Link to the Likes
    ILikes public Likes;

    // Link to the Message Data
    IMessageData public MessageData;

    // Link to the DOOM Token
    IDOOM public DOOM;

    // Link to the Groups
    IGroups public Groups;

    // Link to the Tips
    ITips public Tips;

    // Link to the Blocking
    IBlocking public Blocking;

    // Link to the ContractHook
    IContractHook public ContractHook;

    /*

    This is what may be the first of it's kind, a warrant canary for a smart contract
    This value should always return "safe" or "test" (on a temp basis)

    A warrant canary is a statement that declares that an organization has not taken certain actions or received
    certain requests for information from government or law enforcement authorities. Many services use warrant
    canaries to let users know how private their data is.

    Some types of law enforcement and intelligence requests come with orders prohibiting organizations from
    disclosing that they have been received. However, by removing the corresponding warrant canary statement from
    their website (or wherever it is posted), organizations can indicate that they have received such a request.

    Since contract deployment, KUTHULU has the following warrant canaries posted:

    1. KUTHULU has never turned over our encryption or authentication keys to anyone.

    2. KUTHULU has never installed any law enforcement software or code in any smart contract

    3. KUTHULU has never modified the intended destination of DNS responses at the request of law enforcement
    or another third party.

    */
    string public canary;

    // Max Groups to post in at once
    uint256 public maxGroups;

    // Private Reentrancy Guard with contract Whitelist
    bool private privateEnter;
    
    // Whitelist of contract addresses allowed for reentrancy
    mapping(address => bool) public privateEnterWhitelist;

    // The message count to reach when the DOOM faucet turns off
    uint256 public postToEarnCap;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IERC20Upgradeable _paymentToken, address _userProfiles, address _kutils, uint256 _costToPost, uint256[2] calldata _maxMessageLength, uint256 _maxMsgReturnCount, uint256 _cutToPoster, uint256 _maxGroups, uint256 _postToEarnCap) initializer public {
        //    constructor(uint256 _maxHashtagLength) {
        __Pausable_init();
        __Ownable_init();

        // Setup the payment token
        paymentToken = IERC20Upgradeable(_paymentToken);

        // Setup link to User Profiles
        userProfiles = IUserProfiles(_userProfiles);

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Setup the default Admin
        admins[msg.sender] = true;

        // Initialize the stats
        counters.messages = 0;
        counters.comments = 0;
        counters.groupPosts = 0;
        counters.reposts = 0;
        counters.hashtags = 0;
        counters.tags = 0;
        counters.likes = 0;
        counters.tips = 0;
        counters.follows = 0;

        // Initialize the state variables
        costToPost = _costToPost;
        maxMessageLength = _maxMessageLength;
        maxMsgReturnCount = _maxMsgReturnCount;
        cutToPoster = _cutToPoster;
        maxGroups = _maxGroups;
        privateEnter = true;
        postToEarnCap = _postToEarnCap;

        // Initialize the canary
        canary = "safe";
    }



    /*

    EVENTS

    */

    event logMsgPostMsg1(uint256 indexed msgID, address indexed postedBy, string message, string[] hashtags, address[] taggedAccounts);
    event logMsgPostMsg2(uint256 indexed msgID, address indexed proxy, string uri, uint256[5] attribs, uint256[] inGroups);
    event logEraseMsg(uint256 indexed msgID, address indexed poster);
    event logCanary(string canary);



    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Admins Only");
        _;
    }

    modifier nonReentrant() {

        // If msg.sender is on the whitelist, they can reenter
        if (!privateEnterWhitelist[msg.sender]){

            // On the first call to nonReentrant, _notEntered will be true
            require(privateEnter, "No Reentry Allowed");

            // Any calls to nonReentrant after this point will fail
            privateEnter = false;
        }

        _;

        privateEnter = true;
    }


    /*

    ADMIN FUNCTIONS

    */

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function pause() public onlyAdmins {
        _pause();
    }

    function unpause() public onlyAdmins {
        _unpause();
    }

    function setParams(uint256 _maxMsgReturnCount, uint256[2] calldata _maxMessageLength, uint256 _maxGroups, uint256 _postToEarnCap) public onlyAdmins {
        maxMsgReturnCount = _maxMsgReturnCount;
        maxMessageLength = _maxMessageLength;
        maxGroups = _maxGroups;
        postToEarnCap = _postToEarnCap;
    }

    function updateCosts(uint256 _costToPost, uint256 _cutToPoster) public onlyAdmins {
        //  Update the cost of DOOM in wei to post a new message
        costToPost = _costToPost;

        //  Update the cost of DOOM in wei to like a message
        cutToPoster = _cutToPoster;
    }

    function updateCanary(string memory _canary) public onlyAdmins{
        // Update the canary
        canary = _canary;

        // Log it in case anyone is listening
        emit logCanary(_canary);
    }

    function updatePrivateWhitelist(address wl, bool status) public onlyAdmins{
        // Update the whitelist
        privateEnterWhitelist[wl] = status;
    }

    // Contract Addresses
    // 0 = _userProfiles
    // 1 = _hashtags
    // 2 = _tagged
    // 3 = _posts
    // 4 = _likes
    // 5 = _messageData
    // 6 = _doom
    // 7 = _groups
    // 8 = _tips
    // 9 = _blocking
    function updateContracts(IERC20Upgradeable _payments, address[] calldata contracts) public onlyAdmins {
        // Update the contract address of the ERC20 token to be used as payment
        paymentToken = IERC20Upgradeable(_payments);

        // Update the User Profiles contract address
        userProfiles = IUserProfiles(contracts[0]);

        // Update the Hashtags address
        Hashtags = IHashtags(contracts[1]);

        // Update the Tagged addresses
        Tagged = ITagged(contracts[2]);

        // Update the Posts addresses
        Posts = IPosts(contracts[3]);

        // Update the Likes addresses
        Likes = ILikes(contracts[4]);

        // Update the Message Data addresses
        MessageData = IMessageData(contracts[5]);

        // Update the DOOM Token address
        DOOM = IDOOM(contracts[6]);

        // Update the Comments
        Groups = IGroups(contracts[7]);

        // Update the Tips
        Tips = ITips(contracts[8]);

        // Update Blocking
        Blocking = IBlocking(contracts[9]);
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Post a new message into KUTHULU
    * @param message : The message you want to post
    * @param _hashtags : (optional) an array of hashtags to associate with the post. Limit to maxHashtags
    * @param taggedAccounts : (optional) an array of addresses to tag with the post. Limit to maxTaggedAccounts
    * @param uri : (optional) a URI to attach to the post. Can be used to attach images / movies / etc
    * @param attribs : an array of post attributes (comment level / comment to / repost of / group ID)
    * @param inGroups : (optional) an array of group ID that this message is being posted into. Must be member of groups
    * @dev Comment Attributes Array (attribs)
    * @dev 0 = Comment Level Allowed (0 = No comments Allowed, 1 = Comments Allowed)
    * @dev 1 = Message ID of the post it is a comment to
    * @dev 2 = Message ID of post if it's a repost of another post
    * @dev 3 = Group ID to be posted as
    * @dev 4 = 0 = MATIC tips / >0 = Tips from ERC20 Contract (Contract Address is last address in taggedAccount array posted)
    */
    function postMsg(string calldata message, string[] memory _hashtags, address[] calldata taggedAccounts, string calldata uri, uint256[5] calldata attribs, uint256[] memory inGroups) public payable whenNotPaused nonReentrant {

        // Check if blocked from posting in a group if not an admin
        if(!admins[msg.sender]){
            for (uint g=0; g < inGroups.length; g++) {
                if (inGroups[g] > 0){
                    require(Blocking.isAllowed(msg.sender, Groups.getGroupAddressFromID(inGroups[g])), "Group Blocked-0");
                }
            }
        }

        // Burn DOOM Payment to make post if not an admin
        if(!admins[msg.sender] && counters.messages > postToEarnCap){
            require(DOOM.burnTokens(msg.sender, costToPost), "No DOOM");
        }

        // Only allow to post into a maximum amount of groups at once
        require(inGroups.length <= maxGroups, "Too many groups");

        // Initialize the poster address
        address posterAddress = msg.sender;

        // Check for valid comment levels
        require(attribs[0] < 2, "Bad Comment Level");

        // If this is a comment ensure the post exists first (no comment = 0)
        require(attribs[1] <= counters.messages, "Bad Comment Post ID");

        // If this is a repost ensure the post exists first (regular post = 0)
        require(attribs[2] <= counters.messages, "Bad Repost ID");

        // Check for group membership
        if (attribs[3] > 0){
            require(Groups.isMemberOfGroupByID(attribs[3], msg.sender), "Not Member of Group");

            // Make sure the message is within length limits or that it's a repost
            require(bytes(message).length <= maxMessageLength[1] && (bytes(message).length > 0 || attribs[2] > 0), "Message too long");

            // Set the poster address to be the group
            posterAddress = Groups.getGroupAddressFromID(attribs[3]);
        } else {
            // Make sure the message is within length limits or that it's a repost
            require(bytes(message).length <= maxMessageLength[0] && (bytes(message).length > 0 || attribs[2] > 0), "Message too long");
        }

        // Initialize tip contract address to null
        address tipContract = address(0);

        // If there are tips in ERC20, set the contract address of the token
        if (attribs[4] > 0){
            // Set the contract address for tips (from the posted taggedAccounts)
            tipContract = taggedAccounts[taggedAccounts.length - 1];
        }

        // If the new message is a comment
        if (attribs[1] > 0){
            // Get the OG poster of this thread
            address origPoster = MessageData.getPoster(attribs[1]);

            // check if the original message is allowing comments
            require(MessageData.getMsgCommentLevel(attribs[1]) == 1, "Comments not allowed");

            // Make sure they're not banned from any groups the original post is part of
            require(Blocking.isAllowed(msg.sender, origPoster) , "Group Blocked-1");

            // Check if blocked from posting in a group that's in the message being commented on
            uint256[] memory origInGroups = MessageData.getInGroups(attribs[1]);
            for (uint g=0; g < origInGroups.length; g++) {
                require(Blocking.isAllowed(msg.sender, Groups.getGroupAddressFromID(origInGroups[g])), "Group Blocked-2");
            }

            // If this is a comment, then we don't need the inGroups as it's inheriting it from the post it's a comment to
            inGroups = new uint256[](0);

            // Cut the poster in on the token
            if (costToPost > 0){
                require(paymentToken.transferFrom(msg.sender, origPoster, cutToPoster), "No Payment Token");
            }
        }

        // Increment the amount of messages we have posted
        counters.messages++;

        // If they tipped, send it
        if (msg.value > 0 || attribs[4] > 0){
            // Add the tagged tips
            Tips.addTaggedTips{value: msg.value}(taggedAccounts, attribs[4], tipContract, msg.sender);

            // Add the tips to the post
            Tips.addTip(counters.messages, posterAddress, msg.value);
        }

        // Update the hashtag Mapping with this message ID and hashtag
        if (_hashtags.length > 0){
            Hashtags.addHashtags(counters.messages, _hashtags);
        }

        // See if this message is posted via a proxy
        address postProxy = msg.sender == posterAddress ? address(0) : msg.sender;

        IMessageData.MsgData memory newMsg;

        newMsg.msgID = counters.messages;
        newMsg.postedBy = [posterAddress, postProxy];
        newMsg.message = message;
        newMsg.paid = costToPost;
        newMsg.hashtags = _hashtags;
        newMsg.taggedAccounts = taggedAccounts;
        newMsg.asGroup = attribs[3];
        newMsg.inGroups = inGroups;
        newMsg.uri = uri;
        newMsg.commentLevel = attribs[0];
        newMsg.isCommentOf = attribs[1];
        newMsg.isRepostOf = attribs[2];
        newMsg.msgStats.postByContract = tx.origin == msg.sender ? 0 : 1;
        newMsg.msgStats.time = block.timestamp;
        newMsg.msgStats.block = block.number;
        newMsg.msgStats.tipsReceived = msg.value;
        newMsg.msgStats.tipERC20Amount = attribs[4];
        newMsg.msgStats.tipContract = tipContract;

        MessageData.saveMsg(newMsg);

        // Record the message post
        if (taggedAccounts.length > 0 && msg.value > 0){
            userProfiles.recordPost(posterAddress, msg.value / taggedAccounts.length, taggedAccounts, attribs[1], tipContract, attribs[4], counters.messages);
        } else {
            userProfiles.recordPost(posterAddress, 0, taggedAccounts, attribs[1], tipContract, attribs[4], counters.messages);
        }

        // Update Stats
        updateStats(attribs, msg.value, _hashtags.length, taggedAccounts.length, tipContract, attribs[4]);

        // Log it
        emit logMsgPostMsg1(counters.messages, posterAddress, message, _hashtags, taggedAccounts);
        emit logMsgPostMsg2(counters.messages, postProxy, uri, attribs, inGroups);

        // Update the tagged accounts with this message ID and tagged user address
        // Doing this after saving the message so the hook can interact with this post
        if (taggedAccounts.length > 0){

            Tagged.addTags(counters.messages, taggedAccounts);

            for (uint t=0; t < taggedAccounts.length; t++) {
                // Check if they're being blocked from tagging a user
                require(Blocking.isAllowed(msg.sender, taggedAccounts[t]), "Tag Blocked");

                // Don't do the last address if ERC20 tips were added, as that's the contract address
                if (attribs[4] > 0 && t == taggedAccounts.length){
                    break;
                }

                // Get the Contract Hook for the tagged user if they have one
                address contractHook = userProfiles.getContractHook(taggedAccounts[t]);

                // If they have a contract in place, call it (unless it's back to itself)
                if (contractHook != address(0) && contractHook != msg.sender){
                    // Hook up the interface to the contract
                    ContractHook = IContractHook(contractHook);

                    IContractHook.MsgData memory newMsgCH;

                    newMsgCH.msgID = counters.messages;
                    newMsgCH.postedBy = [posterAddress, postProxy];
                    newMsgCH.message = message;
                    newMsgCH.paid = costToPost;
                    newMsgCH.hashtags = _hashtags;
                    newMsgCH.taggedAccounts = taggedAccounts;
                    newMsgCH.asGroup = attribs[3];
                    newMsgCH.inGroups = inGroups;
                    newMsgCH.uri = uri;
                    newMsgCH.commentLevel = attribs[0];
                    newMsgCH.isCommentOf = attribs[1];
                    newMsgCH.isRepostOf = attribs[2];
                    newMsgCH.msgStats.postByContract = newMsg.msgStats.postByContract;
                    newMsgCH.msgStats.time = block.timestamp;
                    newMsgCH.msgStats.block = block.number;
                    newMsgCH.msgStats.tipsReceived = msg.value;
                    newMsgCH.msgStats.tipERC20Amount = attribs[4];
                    newMsgCH.msgStats.tipContract = tipContract;

                    // Users Contract Hook must return true otherwise we fail the entire post and let the poster know
                    require(ContractHook.KuthuluHook(newMsgCH) == true, string(abi.encodePacked('Contract Hook failed for user: ', KUtils.addressToString(taggedAccounts[t]))));
                }
            }
        }

        // Wrapping with costToPost check to reduce gas costs on posts once threshold is reached
        if (counters.messages <= postToEarnCap){
            // If we're under postToEarnCap message count posted, mint them some DOOM
            if (counters.messages < (postToEarnCap / 100)){
                DOOM.preMint(msg.sender, 100 ether);
            } else if (counters.messages < (postToEarnCap / 10)){
                DOOM.preMint(msg.sender, 50 ether);
            } else {
                DOOM.preMint(msg.sender, 10 ether);
            }
        }
    }

    /**
    * @dev Erase a message that a user posted
    * @dev Can only erase your own messages
    * @param msgID : The message ID you want to erase
    */
    function eraseMsg(uint256 msgID) public whenNotPaused {

        // Erase the message
        MessageData.removeMsg(msgID, msg.sender);

        emit logEraseMsg(msgID, msg.sender);

    }

    /**
    * @dev Toggle liking a message. Like / Unlike
    * @param msgID : The message ID you want to toggle the like for
    */
    function toggleLike(uint256 msgID) public whenNotPaused nonReentrant {

        // Make sure it's a valid post
        require(msgID <= counters.messages, "Bad Post ID");

        // Check if this user already liked the post
        if (Likes.checkUserLikeMsg(msg.sender, msgID)) {
            // Unlike a post if so
            Likes.removeLike(msgID, msg.sender);
        } else {
            // Like a post
            Likes.addLike(msgID, msg.sender);

            // Increment the amount of likes we have posted
            counters.likes++;

            // Transfer the Payment Token to the contract
            if (costToPost > 0) {
                require(paymentToken.transferFrom(msg.sender, MessageData.getPoster(msgID), cutToPoster), "No Payment Token");
            }
        }
    }

    /**
    * @dev Follow a user or group
    * @param addressToFollow : The user or group address to follow
    */
    function followUser(address addressToFollow) public whenNotPaused nonReentrant {
        // Increment the amount of likes we have posted
        counters.follows++;

        // Follow the user
        userProfiles.followUser(msg.sender,addressToFollow);
    }

    /**
    * @dev Unfollow a user or group
    * @param addressToUnFollow : The user or group address to unfollow
    */
    function unfollowUser(address addressToUnFollow) public whenNotPaused nonReentrant {
        // Follow the user
        userProfiles.unfollowUser(msg.sender, addressToUnFollow);
    }

    /**
    * @dev Get the message IDs posted by a specific user or group
    * @param usrAddress : The user or group address to get message IDs for
    * @param startFrom : The place to start from for paginating
    * @param getUserComments : (optional) true = get only the comments of a user
    * @param getUserReposts : (optional) true = get only the reposts of a user
    * @return uint256[] : an array of message IDs
    */
    function getMsgIDsByAddress(address usrAddress, uint256 startFrom, bool getUserComments, bool getUserReposts) public view whenNotPaused returns (uint256[] memory) {

        // Initialize the array as 256 to sent to Posts
        uint256[] memory whatToGet = new uint256[](3);

        // If we're getting posts from a user for a specific post, swap the flag
        if (getUserComments){
            whatToGet[0] = 1;
        } else if (getUserReposts){
            whatToGet[2] = 1;
        }

        return Posts.getMsgIDsByAddress(usrAddress, startFrom, whatToGet);
    }


    /**
    * @dev Returns a list of comment IDs or repost IDs of a given message ID
    * @param msgID : The message ID to get comments or reposts for
    * @param startFrom : The place to start from for paginating
    * @param isRepost : (optional) true = get only the reposts of the message
    * @return uint256[] : an array of message IDs
    */
    function getSubIDsByPost(uint256 msgID, uint256 startFrom, bool isRepost) public view whenNotPaused returns (uint256[] memory) {
        // Initialize the array as 256 to sent to Posts
        uint256[] memory whatToGet = new uint256[](3);

        // Set the vars
        if (isRepost){
            // Get Reposts
            whatToGet[2] = 2;
        } else {
            // Get Comments
            whatToGet[0] = 2;
        }
        whatToGet[1] = msgID;

        return Posts.getMsgIDsByAddress(address(0), startFrom, whatToGet);
    }

    /**
    * @dev Returns a list of message IDs that have a hashtag
    * @param hashtag : The hashtag to get messages for
    * @param startFrom : The place to start from for paginating
    * @return uint256[] : an array of message IDs
    */
    function getMsgIDsByHashtag(string memory hashtag, uint256 startFrom) public view whenNotPaused returns (uint256[] memory) {
        return Hashtags.getMsgIDsFromHashtag(hashtag, startFrom);
    }

    /**
    * @dev Returns a list of message IDs that have a certain user or group tagged in them
    * @param taggedAddress : The user or group to get messages for that they are tagged in
    * @param startFrom : The place to start from for paginating
    * @return uint256[] : an array of message IDs
    */
    function getMsgIDsByTag(address taggedAddress, uint256 startFrom) public view whenNotPaused returns (uint256[] memory) {
        return Tagged.getTaggedMsgIDs(taggedAddress, startFrom);
    }

    /**
    * @dev Returns a multi-dimensional array of message data from a given list of message IDs
    * @dev See the MessageData contract for data structure
    * @dev The amount of IDs must be less than maxMsgReturnCount
    * @param msgIDs : The user or group to get messages for that they are tagged in
    * @param onlyFollowers : Return only messages of accounts the provided address follows
    * @param userToCheck : The address of the user account to get a filtered response of only those following
    * @return string[][] : multi-dimensional array of message data
    */
    function getMsgsByIDs(uint256[] calldata msgIDs, bool onlyFollowers, address userToCheck) public view whenNotPaused returns (string[][] memory) {
        require(msgIDs.length <= maxMsgReturnCount , "Too many requested");

        return MessageData.getMsgsByIDs(msgIDs, onlyFollowers, userToCheck);
    }

    /**
    * @dev Returns an array of all the stats for the app
    * @dev messages, comments, groupPosts, reposts, hashtags, tags, likes, tips, follows
    * @return uint256[] : an array of stats
    */
    function getStats() public view whenNotPaused returns (uint256[] memory) {
        // Initialize the array
        uint256[] memory stats = new uint256[](9);

        stats[0] = counters.messages;
        stats[1] = counters.comments;
        stats[2] = counters.groupPosts;
        stats[3] = counters.reposts;
        stats[4] = counters.hashtags;
        stats[5] = counters.tags;
        stats[6] = counters.likes;
        stats[7] = counters.tips;
        stats[8] = counters.follows;

        return stats;
    }


    /*

    PRIVATE  FUNCTIONS

    */

    function updateStats(uint256[5] calldata attribs, uint256 msgVal, uint256 totalHashTags, uint256 totalTaggedAccounts, address tipContract,  uint256 tipsInERC20) private {
        // Increment the amount of comments we have posted
        if (attribs[1] > 0){
            counters.comments++;
        }

        // Increment the amount of reposts we have posted
        if (attribs[2] > 0){
            counters.reposts++;
        }

        // Increment the amount of group posts we have posted
        if (attribs[3] > 0){
            counters.groupPosts++;
        }

        // Increment the amount of group posts we have posted
        counters.hashtags += totalHashTags;

        // Increment the amount of tips we have posted
        counters.tips += msgVal;

        // Increment the amount of tips received in ERC20 tokens
        if (tipContract != address(0)){
            contractCounters[tipContract] += tipsInERC20;
        }

        // Increment the amount of group posts we have posted
        counters.tags += totalTaggedAccounts;
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}