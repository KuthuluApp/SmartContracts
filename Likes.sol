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

    @title Likes
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
import "./interfaces/IMessageData.sol";

contract Likes is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Maximum amount of records to return on query
    uint256 public maxItemsReturn;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;

    // Map the message ID to a list of addresses that liked the message
    // String is for msgID "buckets" 123-0, 123-1, 123-2 ...
    mapping (string => address[]) public likedByMap;
    mapping (string => mapping (address => bool)) public likedByMapMap;

    // Map the user address to a list of message IDs that are liked by them
    // Address is a string for address "buckets" 0x123, 0x123-1, 0x123-2 ...
    mapping (string => uint256[]) public likesMap;
    //TODO : integrate this
    mapping (string => mapping (uint256 => bool)) public likesMapMap;


    // Link to the Message Data
    IMessageData public messageData;

    // Link the KUtils
    IKUtils public KUtils;


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

    event logAddLike(uint256 indexed msgID, address indexed requester);
    event logRemoveLike(uint256 indexed msgID, address indexed requester);



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

    function updateContracts(address _kutils, address _messageData) public onlyAdmins {
        // Update the KUtils address
        KUtils = IKUtils(_kutils);

        // Update the User Message Data address
        messageData = IMessageData(_messageData);
    }

    function addLike(uint256 msgID, address likedBy) public onlyAdmins {
        // Stringify the ID
        string memory msgIDStr = KUtils.toString(msgID);

        // Stringify the address
        string memory likedByStr = KUtils.addressToString(likedBy);

        // Add them to the bucket of Likes
        uint256 bucketKeyID = getBucketKey(msgIDStr, true);
        string memory likeBucketKey = KUtils.append(msgIDStr,'-',KUtils.toString(bucketKeyID),'','');

        // Get the latest bucket key for likes by user
        uint256 bucketKeyIDForLikes = getLikesBucketKey(likedByStr, true);
        string memory likesByUserBucketKey = KUtils.append(likedByStr,'-',KUtils.toString(bucketKeyIDForLikes),'','');

        // Initialize adding the new record
        bool addIt = true;

        // Initialize out of the loop for gas savings
        string memory thisBucketKey;

        // Check through each bucket to see if they liked this previously
        for (uint b=bucketKeyID; b >= 0; b--) {
            // Get the next bucket key
            thisBucketKey = KUtils.append(msgIDStr, '-',KUtils.toString(b),'','');

            for (uint x; x < likedByMap[thisBucketKey].length; x++) {
                if (likedByMap[thisBucketKey][x] == likedBy) {
                    // Liked it previously, so no need to add to the map
                    addIt = false;
                    break;
                }
            }

            if (b == 0){
                break;
            }
        }

        // Only add to the mapping if not previously added (liked)
        if (addIt) {
            // Update the Likes Mapping with this user address
            likedByMap[likeBucketKey].push(likedBy);

            // Add the like to the likes by user bucket
            likesMap[likesByUserBucketKey].push(msgID);
        }

        // Update the Likes Map Map for quick removal
        likedByMapMap[likeBucketKey][likedBy] = true;

        // Update the User Likes Map Map for quick removal
        likesMapMap[likesByUserBucketKey][msgID] = true;

        // Add the like to the message
        messageData.addStat(1, msgID, 1, 0);

        // Emit to the logs for external reference
        emit logAddLike(msgID, likedBy);
    }

    function removeLike(uint256 msgID, address likedBy) public onlyAdmins {
        // Stringify the ID
        string memory msgIDStr = KUtils.toString(msgID);

        // Get the latest bucket on that message
        uint256 bucketKeyID = getBucketKey(msgIDStr, false);

        // Loop through each bucket and set the address to false
        for (uint i=0; i <= bucketKeyID; i++) {
            string memory likeBucketKey = KUtils.append(msgIDStr,'-',KUtils.toString(i),'','');

            // Update the map map for quick removal
            likedByMapMap[likeBucketKey][likedBy] = false;
        }

        // Stringify the address
        string memory likedByStr = KUtils.addressToString(likedBy);

        // Get the latest bucket key for likes by user
        uint256 bucketKeyIDForLikes = getLikesBucketKey(likedByStr, false);

        // Loop through each bucket and set the msgID to false
        for (uint i=0; i <= bucketKeyIDForLikes; i++) {
            string memory likesByUserBucketKey = KUtils.append(likedByStr,'-',KUtils.toString(i),'','');

            // Update the map map for quick removal
            likesMapMap[likesByUserBucketKey][msgID] = false;
        }

        // Remove the like from the message
        messageData.addStat(1, msgID, -1, 0);

        // Emit to the logs for external reference
        emit logRemoveLike(msgID, likedBy);
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Returns a list of users that liked a message
    * @param msgID : the message ID to get likes for
    * @param startFrom : the number to start getting records from
    * @return address[] : an array of addresses of users and groups that liked a message
    */
    function getLikesFromMsgID(uint256 msgID, uint256 startFrom) public view whenNotPaused returns(address[] memory) {
        // Stringify the ID for the mapping
        string memory msgIDStr = KUtils.toString(msgID);

        // We may need to change this
        uint256 _maxRecords = maxItemsReturn;

        // Get the latest bucket
        uint256 bucketKeyID = getBucketKey(msgIDStr, false);

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = ((likedByMap[KUtils.append(msgIDStr,'-',KUtils.toString(bucketKeyID),'','')].length) + (bucketKeyID * maxItemsPerBucket));
            if (startFrom != 0){
                startFrom -= 1;
            } else {
                // It's empty, so end
                address[] memory empty = new address[](0);
                return empty;
            }
        }

        // Figure out where the list should be pulled from
        for (uint i=0; i <= bucketKeyID; i++) {
            string memory _bucketKey = KUtils.append(msgIDStr,'-',KUtils.toString(bucketKeyID),'','');

            // if the starting point is greater than the beginning item and less than the max in this bucket, this is the correct bucket
            if (startFrom >= (i * maxItemsPerBucket) && startFrom < ((likedByMap[_bucketKey].length) + (i * maxItemsPerBucket))) {
                bucketKeyID = i;

                // Adjust the startFrom to work with this bucket
                if (i != 0){
                    startFrom = startFrom - (i * maxItemsPerBucket);
                }

            }
        }

        // Get the bucket key from where we will pull from
        string memory bucketKey = KUtils.append(msgIDStr,'-',KUtils.toString(bucketKeyID),'','');

        // Initialize the remainder bucket
        string memory remainderBucketKey = bucketKey;

        // Check if there's less than max records in this bucket and only go to the end
        if (startFrom < _maxRecords){
            _maxRecords = startFrom + 1;
        }

        // Initialize the count as empty;
        uint256 itemCount = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {

            // Check that the item is still enabled
            if (likedByMapMap[bucketKey][likedByMap[bucketKey][i - 1]]){
                itemCount += 1;
            }
        }

        // Figure out the amount left to get from remainder bucket
        uint amountLeft = maxItemsReturn - itemCount;

        // Add the remainder from the next bucket if there are any
        if (bucketKeyID != 0 && amountLeft > 0){

            // Get the new bucket key from where we will pull the remainder from (the previous one)
            remainderBucketKey = KUtils.append(msgIDStr,'-',KUtils.toString((bucketKeyID - 1)),'','');

            // Get the amount of items in the bucket to prevent multiple calculations for gas savings
            uint256 remainderLen = likedByMap[remainderBucketKey].length;

            for (uint i=remainderLen; i > remainderLen - amountLeft; i--) {
                // Add it if the item is still enabled
                if (likedByMapMap[remainderBucketKey][likedByMap[remainderBucketKey][i - 1]]){
                    itemCount += 1;
                } else {
                    // If it's disabled, we still have a slot, so reopen it as long as we're not at zero
                    if (remainderLen > amountLeft){
                        amountLeft ++;
                    }
                }
            }
        }

        // Start the array
        address[] memory likedBy = new address[](itemCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {
            if(likedByMapMap[bucketKey][likedByMap[bucketKey][i - 1]]){
                likedBy[counter] = likedByMap[bucketKey][i - 1];
                counter += 1;
            }
        }

        // If there are more records to get from the next bucket, check how many and KUtils.append them
        if (bucketKeyID != 0 && amountLeft > 0){
            // Loop through all items in the next bucket
            for (uint i=likedByMap[remainderBucketKey].length; i > likedByMap[remainderBucketKey].length - amountLeft; i--) {
                // Add it if the item is still enabled
                if (likedByMapMap[remainderBucketKey][likedByMap[remainderBucketKey][i - 1]]){
                    likedBy[counter] = likedByMap[remainderBucketKey][i - 1];
                    counter += 1;
                }
                // we don't have to redo the amount increase if disabled since we're using the derived value now
            }
        }

        return likedBy;
    }


    /**
    * @dev Returns a list of messages liked by a user
    * @param liker : the address to get likes from
    * @param startFrom : the number to start getting records from
    * @return uint256[] : an array of message IDs that were liked by the user
    */
    function getLikesByAddress(address liker, uint256 startFrom) public view whenNotPaused returns(uint256[] memory) {
        // Stringify the address for the mapping
        string memory likerStr = KUtils.addressToString(liker);

        // We may need to change this
        uint256 _maxRecords = maxItemsReturn;

        // Get the latest bucket
        uint256 bucketKeyID = getLikesBucketKey(likerStr, false);

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = ((likesMap[KUtils.append(likerStr,'-',KUtils.toString(bucketKeyID),'','')].length) + (bucketKeyID * maxItemsPerBucket));
            if (startFrom != 0){
                startFrom -= 1;
            } else {
                // It's empty, so end
                uint256[] memory empty = new uint256[](0);
                return empty;
            }
        }

        // Figure out where the list should be pulled from
        for (uint i=0; i <= bucketKeyID; i++) {
            string memory _bucketKey = KUtils.append(likerStr,'-',KUtils.toString(bucketKeyID),'','');

            // if the starting point is greater than the beginning item and less than the max in this bucket, this is the correct bucket
            if (startFrom >= (i * maxItemsPerBucket) && startFrom < ((likesMap[_bucketKey].length) + (i * maxItemsPerBucket))) {
                bucketKeyID = i;

                // Adjust the startFrom to work with this bucket
                if (i != 0){
                    startFrom = startFrom - (i * maxItemsPerBucket);
                }

            }
        }

        // Get the bucket key from where we will pull from
        string memory bucketKey = KUtils.append(likerStr,'-',KUtils.toString(bucketKeyID),'','');

        // Initialize the remainder bucket
        string memory remainderBucketKey = bucketKey;

        // Check if there's less than max records in this bucket and only go to the end
        if (startFrom < _maxRecords){
            _maxRecords = startFrom + 1;
        }

        // Initialize the count as empty;
        uint256 itemCount = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {

            // Check that the item is still enabled
            if (likesMapMap[bucketKey][likesMap[bucketKey][i - 1]]){
                itemCount += 1;
            }
        }

        // Figure out the amount left to get from remainder bucket
        uint amountLeft = maxItemsReturn - itemCount;

        // Add the remainder from the next bucket if there are any
        if (bucketKeyID != 0 && amountLeft > 0){

            // Get the new bucket key from where we will pull the remainder from (the previous one)
            remainderBucketKey = KUtils.append(likerStr,'-',KUtils.toString((bucketKeyID - 1)),'','');

            // Get the amount of items in the bucket to prevent multiple calculations for gas savings
            uint256 remainderLen = likesMap[remainderBucketKey].length;

            for (uint i=remainderLen; i > remainderLen - amountLeft; i--) {
                // Add it if the item is still enabled
                if (likesMapMap[remainderBucketKey][likesMap[remainderBucketKey][i - 1]]){
                    itemCount += 1;
                } else {
                    // If it's disabled, we still have a slot, so reopen it as long as we're not at zero
                    if (remainderLen > amountLeft){
                        amountLeft ++;
                    }
                }
            }
        }


        // Start the array
        uint256[] memory likedBy = new uint256[](itemCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {
            if(likesMapMap[bucketKey][likesMap[bucketKey][i - 1]]){
                likedBy[counter] = likesMap[bucketKey][i - 1];
                counter += 1;
            }
        }

        // If there are more records to get from the next bucket, check how many and KUtils.append them
        if (bucketKeyID != 0 && amountLeft > 0){
            // Loop through all items in the next bucket
            for (uint i=likesMap[remainderBucketKey].length; i > likesMap[remainderBucketKey].length - amountLeft; i--) {
                // Add it if the item is still enabled
                if (likesMapMap[remainderBucketKey][likesMap[remainderBucketKey][i - 1]]){
                    likedBy[counter] = likesMap[remainderBucketKey][i - 1];
                    counter += 1;
                }
                // we don't have to redo the amount increase if disabled since we're using the derived value now
            }
        }

        return likedBy;
    }


    /**
    * @dev Check if a user or group liked a message
    * @param addressToCheck : The user or group see if they liked the message
    * @param msgID : The message ID to check if they liked or not
    * @return bool : True = the address liked the message / False = the user did not like the message
    */
    function checkUserLikeMsg(address addressToCheck, uint256 msgID) public view whenNotPaused returns (bool) {
        string memory thisBucketKey;

        string memory msgIDStr = KUtils.toString(msgID);

        // Go through each bucket to see if it's there in reverse
        uint256 thisKey = getBucketKey(msgIDStr, false);

        for (uint b=thisKey; b >= 0; b--) {
            // Get the next bucket key
            thisBucketKey = KUtils.append(msgIDStr, '-',KUtils.toString(b),'','');

            if (likedByMapMap[thisBucketKey][addressToCheck]) {
                // This bucket has the msgID with the like from this user in it
                return true;
            }

            if (b == 0){
                break;
            }
        }

        return false;
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
            if (likedByMap[bucketToCheck].length > 0){
                // exists
                b++;
                prevBucketLen = likedByMap[bucketToCheck].length;
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

    function getLikesBucketKey(string memory mapKey, bool toInsert) private view returns (uint256){
        uint256 prevBucketLen = 0;
        uint256 b = 0;
        uint256 mapID = 99999999999999999999;

        while (mapID == 99999999999999999999){

            // Get the bucket key to check
            string memory bucketToCheck = KUtils.append(mapKey,'-',KUtils.toString(b),'','');
            if (likesMap[bucketToCheck].length > 0){
                // exists
                b++;
                prevBucketLen = likesMap[bucketToCheck].length;
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