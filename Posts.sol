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

    @title Posts
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

contract Posts is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Maximum amount of records to return on query
    uint256 public maxItemsReturn;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;

    // Map the user address to a list of message IDs
    // Address is a string for address "buckets" 0x123, 0x123-1, 0x123-2 ...
    mapping (string => uint256[]) public postsMap;
    mapping (string => mapping (uint256 => bool)) public postsMapMap;
    
    // Link the KUtils
    IKUtils public KUtils;

    // Link the User Profiles contract
    IUserProfiles public userProfiles;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxItemsReturn, uint256 _maxItemsPerBucket) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        maxItemsReturn = _maxItemsReturn;
        maxItemsPerBucket = _maxItemsPerBucket;

        require((maxItemsPerBucket + 1) >= maxItemsReturn, "Invalid Setup");

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);
    }


    /*

    EVENTS

    */

    event logAddPost(uint256 msgID, address indexed addressPoster, uint256 indexed isCommentOf, uint256 indexed isRepostOf);
    event logRemovePost(uint256 msgID, address indexed addressPoster, uint256 indexed isCommentOf, uint256 indexed isRepostOf);


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

    function updateContracts(address _kutils, address _userProfiles) public onlyAdmins {
        // Update the KUtils address
        KUtils = IKUtils(_kutils);

        // Update the User Profiles contract address
        userProfiles = IUserProfiles(_userProfiles);
    }

    function addPost(uint256 msgID, address addressPoster, uint256 isCommentOf, uint256 isRepostOf) public whenNotPaused onlyAdmins {

        // Check if the message is a comment or not to make the bucket key
        string memory comments = isCommentOf > 0 ? '-c' : '';

        // Check if the message is a repost or not to make the bucket key
        string memory reposts = isRepostOf > 0 ? '-r' : '';

        // Stringify the address
        string memory prefix = KUtils.append(KUtils.addressToString(addressPoster), comments, reposts, '', '');

        // Add the post to the bucket for the poster
        uint256 bucketKeyID = getBucketKey(prefix, true);
        string memory postBucketKey = KUtils.append(prefix,'-',KUtils.toString(bucketKeyID),'','');

        // Update the Posts Mapping with this user address
        postsMap[postBucketKey].push(msgID);

        // Update the Posts Map Map for quick removal
        postsMapMap[postBucketKey][msgID] = true;

        if (isCommentOf > 0){
            // Create the prefix to save the comment
            prefix = KUtils.append(KUtils.toString(isCommentOf), comments, '', '', '');
        }

        if (isRepostOf > 0){
            // Create the prefix to save the repost
            prefix = KUtils.append(KUtils.toString(isRepostOf), '', reposts, '', '');
        }

        if (isCommentOf > 0 || isRepostOf > 0){
            // Add the post to the bucket for the poster
            bucketKeyID = getBucketKey(prefix, true);
            postBucketKey = KUtils.append(prefix,'-',KUtils.toString(bucketKeyID),'','');

            // Update the Posts Mapping with this user address
            postsMap[postBucketKey].push(msgID);

            // Update the Posts Map Map for quick removal
            postsMapMap[postBucketKey][msgID] = true;
        }

        // Emit log for external use
        emit logAddPost(msgID, addressPoster, isCommentOf, isRepostOf);
    }

    function removePost(uint256 msgID, address addressPoster, uint256 isCommentOf, uint256 isRepostOf) public whenNotPaused onlyAdmins {

        // Check if the message is a comments or not to make the bucket key
        string memory comments = isCommentOf > 0 ? '-c' : '';

        // Check if the message is a comments or not to make the bucket key
        string memory reposts = isRepostOf > 0 ? '-r' : '';

        // Stringify the address
        string memory prefix = KUtils.append(KUtils.addressToString(addressPoster), comments, reposts, '', '');

        // Get the latest bucket on that user
        uint256 bucketKeyID = getBucketKey(prefix, false);

        string memory postBucketKey;

        // Loop through each bucket and set the address to false
        for (uint i=0; i <= bucketKeyID; i++) {
            postBucketKey = KUtils.append(prefix,'-',KUtils.toString(i),'','');

            // Update the map map for quick removal
            postsMapMap[postBucketKey][msgID] = false;
        }

        if (isCommentOf > 0){
            // Create the prefix to get the comments
            prefix = KUtils.append(KUtils.toString(isCommentOf), comments, '', '', '');
        }

        if (isRepostOf > 0){
            // Create the prefix to get the reposts
            prefix = KUtils.append(KUtils.toString(isRepostOf), '', reposts, '', '');
        }

        if (isCommentOf > 0 || isRepostOf > 0){
            // Get the latest bucket on that user
            bucketKeyID = getBucketKey(prefix, false);

            // Loop through each bucket and set the address to false
            for (uint i=0; i <= bucketKeyID; i++) {
                postBucketKey = KUtils.append(prefix,'-',KUtils.toString(i),'','');

                // Update the map map for quick removal
                postsMapMap[postBucketKey][msgID] = false;
            }
        }

        // Update their total post count
        userProfiles.updatePostCount(addressPoster, false);

        // Emit log for external use
        emit logAddPost(msgID, addressPoster, isCommentOf, isRepostOf);
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Returns a list of messages that are posted by a given user or group
    * @param usrAddress : the address to retrieve message IDs for
    * @param startFrom : the number to start getting records from
    * @param whatToGet : an array of parameters
    * @dev Parameter[0] : 0 = posts that are not comments / 1 = get Comments of user / 2 = get comments of post
    * @dev Parameter[1] : isCommentOf message ID
    * @dev Parameter[2] : repostType[0, 1, 2 (same as comments)]
    */
    function getMsgIDsByAddress(address usrAddress, uint256 startFrom, uint256[] calldata whatToGet) public view whenNotPaused returns(uint256[] memory) {

        // Get the prefix for by address
        string memory fullPrefix = KUtils.append(KUtils.addressToString(usrAddress), whatToGet[0] > 0 ? '-c' : '', whatToGet[2] > 0 ? '-r' : '', '', '');

        // Check if this is a for comments / reposts
        bool isComRep = ((whatToGet[0] == 2 || whatToGet[2] == 2) && whatToGet[1] > 0) ? true : false;

        // If a message ID was sent, then change the prefix to ID
        if (isComRep) {
            fullPrefix = KUtils.append(KUtils.toString(whatToGet[1]), whatToGet[0] > 0 ? '-c' : '', whatToGet[2] > 0 ? '-r' : '', '', '');
        }

        // We may need to change this
        uint256 _maxRecords = maxItemsReturn;

        // Get the latest bucket
        uint256 bucketKeyID = getBucketKey(fullPrefix, false);

        if (isComRep) {
            // Divide before multiply ok here as we're relying on the truncation
            uint256 olderBucketKeyID = (startFrom / (_maxRecords + 1));
            if (startFrom > 0 && olderBucketKeyID != bucketKeyID){
                bucketKeyID = olderBucketKeyID;
            }
        }

        // Get the bucket key from where we will pull from
        string memory bucketKey = KUtils.append(fullPrefix,'-',KUtils.toString(bucketKeyID),'','');

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = ((postsMap[bucketKey].length) + (bucketKeyID * maxItemsPerBucket));
            if (startFrom != 0){
                // Change the startFrom for comments / reposts to get them all
                if (!isComRep) {
                    startFrom -= 1;
                }
            } else {
                // It's empty, so end
                uint256[] memory empty = new uint256[](0);
                return empty;
            }
        }

        // Figure out where the list should be pulled from
        uint256 i = 0;
        for (i=0; i <= bucketKeyID; i++) {

            // if the starting point is greater than the beginning item and less than the max in this bucket, this is the correct bucket
            if (startFrom >= (i * maxItemsPerBucket) && startFrom <= ((postsMap[bucketKey].length) + (i * maxItemsPerBucket))) {
                bucketKeyID = i;

                // Adjust the startFrom to work with this bucket
                if (i != 0){
                    startFrom = startFrom - (i * maxItemsPerBucket);
                }

            }
        }

        // If this is a comment, we need to reduce by 1 for an array pointer
        if (isComRep && startFrom > 0) {
            startFrom--;
        }

        // Initialize the remainder bucket
        string memory remainderBucketKey = bucketKey;

        // Check if there's less than max records in this bucket and only go to the end
        if (startFrom < _maxRecords){
            _maxRecords = startFrom + 1;
        }

        // Initialize the count as empty;
        uint256 postCount = 0;

        // Loop through all items in the first bucket up to max return amount
        i = (startFrom + 1);
        while (i > (startFrom + 1 - _maxRecords)) {
            if (postsMapMap[bucketKey][postsMap[bucketKey][i - 1]]){
                postCount += 1;
            }
            i--;
        }

        // Figure out the amount left to get from remainder bucket
        uint256 amountLeft = maxItemsReturn - postCount;

        // Add the remainder from the next bucket if there are any
        if (bucketKeyID != 0 && amountLeft > 0){

            // Get the new bucket key from where we will pull the remainder from (the previous one)
            remainderBucketKey = KUtils.append(fullPrefix,'-',KUtils.toString((bucketKeyID - 1)),'','');

            // Get the amount of items in the bucket to prevent multiple calculations for gas savings
            uint256 remainderLen = postsMap[remainderBucketKey].length;

            for (i=remainderLen; i > remainderLen - amountLeft; i--) {
                // Add it if the item is still enabled
                if (postsMapMap[remainderBucketKey][postsMap[remainderBucketKey][i - 1]]){
                    postCount += 1;
                } else {
                    // If it's disabled, we still have a slot, so reopen it as long as we're not at zero
                    if (remainderLen > amountLeft){
                        amountLeft ++;
                    }
                }
            }
        }

        // Start the array
        uint256[] memory msgIDs = new uint256[](postCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the first bucket up to max return amount
        for (i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {
            if(postsMapMap[bucketKey][postsMap[bucketKey][i - 1]]){
                msgIDs[counter] = postsMap[bucketKey][i - 1];
                counter += 1;
            }
        }

        // If there are more records to get from the next contract, check how many and KUtils.append them
        if (bucketKeyID != 0 && amountLeft > 0){
            // Loop through all items in the next bucket
            for (i=postsMap[remainderBucketKey].length; i > postsMap[remainderBucketKey].length - amountLeft; i--) {
                // Add it if the item is still enabled
                if (postsMapMap[remainderBucketKey][postsMap[remainderBucketKey][i - 1]]){
                    msgIDs[counter] = postsMap[remainderBucketKey][i - 1];
                    counter += 1;
                }
                // we don't have to redo the amount increase if disabled since we're using the derived value now
            }
        }

        return msgIDs;
    }


    /*

    PRIVATE FUNCTIONS

    */

    function getBucketKey(string memory mapKey, bool toInsert) private view returns (uint256){
        uint256 prevBucketLen = 0;
        uint256 b = 0;
        uint256 mapID = 99999999999999999999;

        while (mapID == 99999999999999999999){
            // Get the bucket key to check
            string memory bucketToCheck = KUtils.append(mapKey,'-',KUtils.toString(b),'','');
            if (postsMap[bucketToCheck].length > 0){
                // exists
                b++;
                prevBucketLen = postsMap[bucketToCheck].length;
            } else if (b == 0) {
                // Doesn't exist at all, so set it to 0
                mapID = b;
            } else {
                // It's the previous one
                mapID = b - 1;

                // If we're inserting, check to see if the previous bucket is full and we should insert to a new one
                if (prevBucketLen >= maxItemsPerBucket && toInsert == true){
                    // We've reached the max items per bucket so return the next key (which is this one)
                    mapID = b;
                }
            }
        }

        return mapID;
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}