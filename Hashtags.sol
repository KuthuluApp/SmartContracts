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

    @title Hashtags
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

contract Hashtags is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Maximum amount of records to return on query
    uint256 public maxItemsReturn;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;

    // Map the hashtags to a list of message IDs they are used in
    // awesome-0, awesome-1, awesome-2 ...
    mapping (string => uint256[]) public hashtagMap;
    // This map is the hashtag bucket ID to the mapping of the message ID and if it's still valid or not
    mapping (string => mapping (uint256 => bool)) public hashtagMapMap;

    // Max amount of hashtags per post
    uint256 public maxHashtags;

    // Max characters for each hashtag
    uint256 public maxHashtagLength;

    // Min characters required for a hashtag
    uint256 public minHashtagLength;
    
    // Link the KUtils
    IKUtils public KUtils;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxItemsReturn, uint256 _maxItemsPerBucket, uint256 _maxHashtagLength, uint256 _minHashtagLength, uint256 _maxHashtags) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        maxItemsReturn = _maxItemsReturn;
        maxItemsPerBucket = _maxItemsPerBucket;
        maxHashtagLength = _maxHashtagLength;
        minHashtagLength = _minHashtagLength;
        maxHashtags = _maxHashtags;

        require((maxItemsPerBucket + 1) >= maxItemsReturn, "Invalid Setup");

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);
    }


    /*

    EVENTS

    */

    event logAddHashtag(string indexed hashtags, uint256 indexed msgID);
    event logRemoveHashtag(string indexed hashtags, uint256 indexed msgID);


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

    function updateDetails(address _kutils, uint256 _maxHashtags) public onlyAdmins {
        // Update the User Profiles contract address
        KUtils = IKUtils(_kutils);

        // Update max hashtags
        maxHashtags = _maxHashtags;
    }

    function addHashtags(uint256 msgID, string[] memory hashtagsToToggle) public onlyAdmins {
        // Make sure there are hashtags to add if we're calling this
        require(hashtagsToToggle.length > 0, "No hashtags to add");

        // Make sure there not more than max hashtags
        require(hashtagsToToggle.length <= maxHashtags, "Too many hashtags");

        // Initialize outside of the loop for gas savings
        string memory hashtagToToggle;

        for (uint h=0; h < hashtagsToToggle.length; h++) {
            require(bytes(hashtagsToToggle[h]).length <= maxHashtagLength && bytes(hashtagsToToggle[h]).length >= minHashtagLength, "Hashtag character count exceeds max length");

            require(KUtils.isValidString(hashtagsToToggle[h]), "Invalid characters in hashtag");

            // Lowercase the hashtag first
            hashtagToToggle = KUtils._toLower(hashtagsToToggle[h]);

            // Adding the hashtag to the message
            uint256 bucketKeyID = getBucketKey(hashtagToToggle, true);
            string memory hashtagBucketKey = KUtils.append(hashtagToToggle,'-',KUtils.toString(bucketKeyID),'','');

            if (!hashtagMapMap[hashtagBucketKey][msgID]){
                // Update the Hashtag Mapping with this user address
                hashtagMap[hashtagBucketKey].push(msgID);

                // Update the Hashtag Map Map for quick check and removal later
                hashtagMapMap[hashtagBucketKey][msgID] = true;
            }

            // Emit to the logs for external reference
            emit logAddHashtag(hashtagToToggle, msgID);
        }
    }

    function removeHashtags(uint256 msgID, string[] calldata hashtagsToToggle) public onlyAdmins {
        // Make sure there are hashtags to remove if we're calling this
        require(hashtagsToToggle.length > 0, "No hashtags to remove");

        // Initialize outside of the loop for gas savings
        string memory hashtagToToggle;

        for (uint h=0; h < hashtagsToToggle.length; h++) {
            require(bytes(hashtagsToToggle[h]).length <= maxHashtagLength && bytes(hashtagsToToggle[h]).length >= minHashtagLength, "Hashtag character count exceeds max length");

            require(KUtils.isValidString(hashtagsToToggle[h]), "Invalid characters in hashtag");

            // Lowercase the hashtag first
            hashtagToToggle = KUtils._toLower(hashtagsToToggle[h]);

            // Get the latest bucket on that hashtag
            uint256 bucketKeyID = getBucketKey(hashtagToToggle, false);

            string memory hashtagBucketKey;

            // Loop through each bucket and set the hashtag to false for this message
            for (uint i=0; i <= bucketKeyID; i++) {
                hashtagBucketKey = KUtils.append(hashtagToToggle,'-',KUtils.toString(i),'','');

                // Update the map map for quick removal
                hashtagMapMap[hashtagBucketKey][msgID] = false;
            }

            // Emit to the logs for external reference
            emit logRemoveHashtag(hashtagToToggle, msgID);
        }
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Returns a list of message IDs that used a given hashtag
    * @param hashtag : the hashtag to pull messages from
    * @param startFrom : the number to start getting records from
    * @return uint256[] : an array of message IDs that have a specific hashtag
    */
    function getMsgIDsFromHashtag(string memory hashtag, uint256 startFrom) public view whenNotPaused returns(uint256[] memory) {
        // Lowercase the hashtag first
        hashtag = KUtils._toLower(hashtag);

        // We may need to change this
        uint256 _maxRecords = maxItemsReturn;

        // Get the latest bucket
        uint256 bucketKeyID = getBucketKey(hashtag, false);

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = ((hashtagMap[KUtils.append(hashtag,'-',KUtils.toString(bucketKeyID),'','')].length) + (bucketKeyID * maxItemsPerBucket));
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
            string memory _bucketKey = KUtils.append(hashtag,'-',KUtils.toString(bucketKeyID),'','');

            // if the starting point is greater than the beginning item and less than the max in this bucket, this is the correct bucket
            if (startFrom >= (i * maxItemsPerBucket) && startFrom < ((hashtagMap[_bucketKey].length) + (i * maxItemsPerBucket))) {
                bucketKeyID = i;

                // Adjust the startFrom to work with this bucket
                if (i != 0){
                    startFrom = startFrom - (i * maxItemsPerBucket);
                }

            }
        }

        // Get the bucket key from where we will pull from
        string memory bucketKey = KUtils.append(hashtag,'-',KUtils.toString(bucketKeyID),'','');

        // Initialize the remainder bucket
        string memory remainderBucketKey = bucketKey;

        // Check if there's less than max records in this bucket and only go to the first item in the bucket
        if (startFrom < _maxRecords){
            _maxRecords = startFrom + 1;
        }

        // Initialize the count as empty;
        uint256 msgCount = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {

            // Check that the item is still enabled
            if (hashtagMapMap[bucketKey][hashtagMap[bucketKey][i - 1]]){
                msgCount += 1;
            }

        }

        // Figure out the amount left to get from remainder bucket
        uint amountLeft = maxItemsReturn - msgCount;

        // Add the remainder from the next bucket if there are any
        if (bucketKeyID != 0 && amountLeft > 0){

            // Get the new bucket key from where we will pull the remainder from (the previous one)
            remainderBucketKey = KUtils.append(hashtag,'-',KUtils.toString((bucketKeyID - 1)),'','');

            // Get the amount of items in the bucket to prevent multiple calculations for gas savings
            uint256 remainderLen = hashtagMap[remainderBucketKey].length;

            for (uint i=remainderLen; i > remainderLen - amountLeft; i--) {
                // Add it if the item is still enabled
                if (hashtagMapMap[remainderBucketKey][hashtagMap[remainderBucketKey][i - 1]]){
                    msgCount += 1;
                } else {
                    // If it's disabled, we still have a slot, so reopen it as long as we're not at zero
                    if (remainderLen > amountLeft){
                        amountLeft ++;
                    }
                }
            }
        }

        // Start the array
        uint256[] memory msgIDs = new uint256[](msgCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {
            // Check that the item is still enabled
            if (hashtagMapMap[bucketKey][hashtagMap[bucketKey][i - 1]]){
                msgIDs[counter] = hashtagMap[bucketKey][i - 1];
                counter += 1;
            }
        }

        // If there are more records to get from the next contract, check how many and KUtils.append them
        if (bucketKeyID != 0 && amountLeft > 0){
            // Loop through all items in the next bucket
            for (uint i=hashtagMap[remainderBucketKey].length; i > hashtagMap[remainderBucketKey].length - amountLeft; i--) {
                // Add it if the item is still enabled
                if (hashtagMapMap[remainderBucketKey][hashtagMap[remainderBucketKey][i - 1]]){
                    msgIDs[counter] = hashtagMap[remainderBucketKey][i - 1];
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
            if (hashtagMap[bucketToCheck].length > 0){
                // exists
                b++;
                prevBucketLen = hashtagMap[bucketToCheck].length;
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