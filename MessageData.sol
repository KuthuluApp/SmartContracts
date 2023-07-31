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

    @title MessageData
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
import "./interfaces/IHashtags.sol";
import "./interfaces/ITagged.sol";
import "./interfaces/IPosts.sol";
import "./interfaces/IGroupPosts.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/IMessageFormat.sol";
import "./interfaces/IFollowers.sol";
import "./interfaces/IBlocking.sol";

contract MessageData is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;

    // Set the Bucket Key and Count
    uint256[2] public buckets;

    // Message Stats
    struct MsgStats {
        int likes;
        int comments;
        uint256 totalInThread;
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
        uint256 paid;      // May not need this
        string[] hashtags;
        address[] taggedAccounts;
        uint256 asGroup;
        uint256[] inGroups;
        string uri;
        uint256 commentLevel;
        uint256 isCommentOf;
        uint256 isRepostOf;
        uint256 commentID;
        MsgStats msgStats;
    }


    // Map of all the message buckets (posts is static)
    // posts/msgID-0, posts/msgID-1, posts/msgID-2 ...
    mapping (string => uint256[]) public msgMap;
    mapping (string => mapping (uint256 => bool)) public msgMapMap;

    // Bucket Key => Msg ID => Msg Data
    mapping (string => mapping (uint256 => MsgData)) public msgData;

    // Link the KUtils contract
    IKUtils public KUtils;

    // Link to the Hashtags
    IHashtags public Hashtags;

    // Link to the Tagged Accounts
    ITagged public Tagged;

    // Link to the Posts Owners
    IPosts public Posts;

    // Link to the Group Posts
    IGroupPosts public GroupPosts;

    // Link to the Group Details
    IGroups public Groups;

    // Link to the Message Formatter
    IMessageFormat public MessageFormat;

    // Link to the Followers
    IFollowers public Followers;

    // Link to the Blocking
    IBlocking public Blocking;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxItemsPerBucket) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        maxItemsPerBucket = _maxItemsPerBucket;

        // Setup link to User Profiles
        KUtils = IKUtils(_kutils);

        // Initialize Buckets
        buckets = [0,0];
    }


    /*

    EVENTS

    */

    event logNewMsg(uint256 msgID, uint256 isCommentOf, uint256 isRepostOf, address[2] postedBy, MsgData newMsg, uint256 indexed asGroup, uint256[] inGroups);
    event logRemoveMsg(uint256 msgID);
    event logUpdateMsgStats(uint256 indexed statType, uint256 msgID, int256 statValue, uint256 tips);



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


    function updateContracts(address _kutils, address _hashtags, address _tagged, address _posts, address _messageFormat, address _followers, address _groupPosts, address _groups, address _blocking) public onlyAdmins {
        // Update the User Profiles contract address
        KUtils = IKUtils(_kutils);

        // Update the Hashtags address
        Hashtags = IHashtags(_hashtags);

        // Update the Tagged addresses
        Tagged = ITagged(_tagged);

        // Update the Posts addresses
        Posts = IPosts(_posts);

        // Update the Group Posts addresses
        GroupPosts = IGroupPosts(_groupPosts);

        // Update the Group Posts addresses
        Groups = IGroups(_groups);

        // Update the Message Formatting
        MessageFormat = IMessageFormat(_messageFormat);

        // Update the Followers addresses
        Followers = IFollowers(_followers);

        // Update the Blocking addresses
        Blocking = IBlocking(_blocking);
    }

    function saveMsg(MsgData memory newMsg) public onlyAdmins {

        // Check if this is a repost, and if so, update that messages updateStats
        if (newMsg.isRepostOf > 0){
            addStat(3, newMsg.isRepostOf, 1, 0);
        }

        // Get the bucket to store the message
        if (buckets[1] == maxItemsPerBucket){
            // If so, update the buckets and then return the next bucket ID
            buckets[0] += 1;
            buckets[1] = 0;
        }

        // Get the bucket key to save the message into
        string memory thisBucketKey = KUtils.append('posts-',KUtils.toString(buckets[0]),'','','');

        // if it's a comment, store the map to isCommentOf
        if (newMsg.isCommentOf > 0){

            // Update the message stats the comment is for
            addStat(2, newMsg.isCommentOf, 1, 0);

            // Add the comment ID to the message
            string memory commentOfBucketKey = getBucketKeyByID(newMsg.isCommentOf);
            newMsg.commentID = msgData[commentOfBucketKey][newMsg.isCommentOf].msgStats.totalInThread;
        }

        // Add to the messages bucket
        msgMap[thisBucketKey].push(newMsg.msgID);

        // Add to the messages bucket flag
        msgMapMap[thisBucketKey][newMsg.msgID] = true;

        // Save the Message MessageData
        msgData[thisBucketKey][newMsg.msgID] = newMsg;

        // Record the post to the poster
        Posts.addPost(newMsg.msgID, newMsg.postedBy[0], newMsg.isCommentOf, 0);

        // If this is a repost, also save the message as so for queries
        if (newMsg.isRepostOf > 0){
            Posts.addPost(newMsg.msgID, newMsg.postedBy[0], newMsg.isCommentOf, newMsg.isRepostOf);
        }

        // Save the message to the groups if there are any
        GroupPosts.addPost(newMsg.msgID, newMsg.inGroups);

        // Increase the bucket counter
        buckets[1] += 1;

        // Emit to the logs for external reference
        emit logNewMsg(newMsg.msgID, newMsg.isCommentOf, newMsg.isRepostOf, newMsg.postedBy, newMsg, newMsg.asGroup, newMsg.inGroups);
    }

    function removeMsg(uint256 msgID, address requester) public onlyAdmins {
        // Find the bucket containing the message
        string memory thisBucketKey = getBucketKeyByID(msgID);

        // Get the the data from the post
        MsgData memory thisMsgData = msgData[thisBucketKey][msgID];

        // Only the message poster can erase it
        require(thisMsgData.postedBy[0] == requester || Groups.isMemberOfGroupByID(thisMsgData.asGroup, requester), "Only the message owner or proxy can erase it");

        if (thisMsgData.isCommentOf > 0){

            // Remove a comment stat
            addStat(2, thisMsgData.isCommentOf, -1, 0);

        } else if (thisMsgData.isRepostOf > 0){

            // Remove a comment stat
            addStat(3, thisMsgData.isRepostOf, -1, 0);

        }

        // Remove the message bucket flag
        msgMapMap[thisBucketKey][thisMsgData.msgID] = false;


        // Remove the Hashtags
        if (thisMsgData.hashtags.length > 0){
            Hashtags.removeHashtags(msgID, thisMsgData.hashtags);
        }

        // Remove the Tagged accounts
        if (thisMsgData.taggedAccounts.length > 0){
            Tagged.removeTags(msgID, thisMsgData.taggedAccounts);
        }

        // Remove link to Groups
        GroupPosts.removePost(msgID, thisMsgData.inGroups);

        // Remove the post from the poster
        Posts.removePost(msgID, msgData[thisBucketKey][msgID].postedBy[0], thisMsgData.isCommentOf, 0);

        // If this is a repost, also remove the message from repost buckets (comment / repost must be removed separately)
        if (thisMsgData.isRepostOf > 0){
            Posts.removePost(msgID, msgData[thisBucketKey][msgID].postedBy[0], thisMsgData.isCommentOf, thisMsgData.isRepostOf);
        }

        msgData[thisBucketKey][msgID].message = "This message has been deleted by the poster.";
        msgData[thisBucketKey][msgID].uri = "";
        delete msgData[thisBucketKey][msgID].hashtags;
        delete msgData[thisBucketKey][msgID].taggedAccounts;

        // Emit to the logs for external reference
        emit logRemoveMsg(msgID);
    }

    function getMsgsByIDs(uint256[] memory msgIDs, bool onlyFollowers, address userToCheck) public whenNotPaused onlyAdmins view returns (string[][] memory){
        string[][] memory allData = new string[][](msgIDs.length);

        for (uint i=0; i < msgIDs.length; i++) {

            // Get the bucket key where this message is stored
            string memory thisBucketKey = getBucketKeyByID(msgIDs[i]);

            // Check to make sure the message exists
            require(bytes(thisBucketKey).length > 0, "Invalid Message ID");

             // Only get the valid messages
            if (msgMapMap[thisBucketKey][msgIDs[i]]){

                // Get the message data from the bucket
                MsgData storage thisMsgData = msgData[thisBucketKey][msgIDs[i]];

                bool validPost = true;

                // If only getting followers posts
                if (onlyFollowers && userToCheck != address(0)){

                    // If they are not following this user, skip returning the data
                    if (!Followers.isUserFollowing(userToCheck, thisMsgData.postedBy[0])){
                        validPost = false;
                    }
                }

                // Check to see if either account is being blocked by the other
                if (!Blocking.isAllowed(userToCheck, thisMsgData.postedBy[0]) || !Blocking.isAllowed(thisMsgData.postedBy[0], userToCheck)) {
                    // If so, skip showing the post
                    validPost = false;
                }

                // If it's still valid, show it
                if (validPost){

                    uint256[] memory thisData = new uint256[](15);

                    MsgStats storage stats = thisMsgData.msgStats;

                    thisData[0] = thisMsgData.msgID;
                    thisData[1] = stats.time;
                    thisData[2] = stats.block;
                    thisData[3] = stats.tipsReceived;
                    thisData[4] = thisMsgData.paid;
                    thisData[5] = stats.postByContract;
                    thisData[6] = uint(stats.likes);
                    thisData[7] = uint(stats.reposts);
                    thisData[8] = uint(stats.comments);
                    thisData[9] = thisMsgData.isCommentOf;
                    thisData[10] = thisMsgData.isRepostOf;
                    thisData[11] = uint(thisMsgData.commentLevel);
                    thisData[12] = thisMsgData.asGroup;
                    thisData[13] = stats.tipERC20Amount;
                    thisData[14] = thisMsgData.commentID;

                    // Get the formatted message
                    allData[i] = MessageFormat.buildMsg(thisData, thisMsgData.message, thisMsgData.postedBy, thisMsgData.hashtags, thisMsgData.taggedAccounts, thisMsgData.uri, thisMsgData.inGroups, stats.tipContract);
                }
            }
        }

        return allData;
    }

    // statType
    // 1 = like
    // 2 = comment
    // 3 = repost
    // 4 = tip

    function addStat(uint8 statType, uint256 msgID, int amount, uint256 tips) public onlyAdmins {
        // Find the bucket where this message is
        string memory thisBucketKey = getBucketKeyByID(msgID);

        // Update the respective stat
        if (statType == 1){
            msgData[thisBucketKey][msgID].msgStats.likes += amount;
        } else if (statType == 2){
            msgData[thisBucketKey][msgID].msgStats.comments += amount;
            if (amount > 0){
                msgData[thisBucketKey][msgID].msgStats.totalInThread += uint(amount);
            }
        } else if (statType == 3){
            msgData[thisBucketKey][msgID].msgStats.reposts += amount;
        }

        // update tips received
        msgData[thisBucketKey][msgID].msgStats.tipsReceived += tips;

        // Emit to the logs for external reference
        emit logUpdateMsgStats(statType, msgID, amount, tips);
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Get the address of the user or group that posted a message
    * @param msgID : The message ID to check for the posters address
    * @return address : the address of the member that posted the message
    */
    function getPoster(uint256 msgID) public view whenNotPaused returns (address){
        string memory topBucketKey = getBucketKeyByID(msgID);
        return msgData[topBucketKey][msgID].postedBy[0];
    }

    /**
    * @dev Get a list of group IDs that a message was posted in
    * @param msgID : The message ID to check for
    * @return uint256[] : an array of group IDs that the message was posted in
    */
    function getInGroups(uint256 msgID) public view whenNotPaused returns (uint256[] memory){
        string memory topBucketKey = getBucketKeyByID(msgID);
        return msgData[topBucketKey][msgID].inGroups;
    }

    /**
    * @dev Get the comment level of a post.
    * @dev 0 = Comments are open / 1 = Comments are closed
    * @param msgID : The message ID to check for
    * @return uint256 : the comment level of the message
    */
    function getMsgCommentLevel(uint256 msgID) public view whenNotPaused returns (uint256){
        // Find the bucket key for the message
        string memory thisBucketKey = getBucketKeyByID(msgID);

        // Return the message data from the bucket
        return msgData[thisBucketKey][msgID].commentLevel;
    }


    /*

    PRIVATE FUNCTIONS

    */

    function getBucketKeyByID(uint256 msgID) private view returns (string memory){
        // Initialize the bucket key
        string memory thisBucketKey = "";

        // Go through each bucket to see if it's there in reverse
        for (uint b=buckets[0]; b >= 0; b--) {
            // Get the next bucket key
            thisBucketKey = KUtils.append('posts-',KUtils.toString(b),'','','');

            // Get the poster address from the message for a post
            address poster = msgData[thisBucketKey][msgID].postedBy[0];
            
            if (poster != address(0)) {
                // We found the bucket with the message in it
                break;
            } else if (b == 0){
                thisBucketKey = '';
                break;
            }
        }

        return thisBucketKey;
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}


