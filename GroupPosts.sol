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

    @title GroupPosts
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

contract GroupPosts is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Maximum amount of records to return on query
    uint256 public maxItemsReturn;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;

    // Map the group ID to a list of message IDs
    // Address is a string for group ID "buckets" 123..., 132...-1, 123...-2 ...
    mapping (string => uint256[]) public groupPostsMap;
    mapping (string => mapping (uint256 => bool)) public groupPostsMapMap;
    
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

    event logAddPost(uint256 indexed msgID, uint256[] groupIDs);
    event logRemovePost(uint256 indexed msgID, uint256[] groupIDs);



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

    function addPost(uint256 msgID, uint256[] calldata groupIDs) public whenNotPaused onlyAdmins {

        // Initialize outside of the loop for gas savings
        string memory groupIDStr;
        string memory postBucketKey;

        for (uint g=0; g < groupIDs.length; g++) {
            // Convert the group ID to a string
            groupIDStr = KUtils.toString(groupIDs[g]);

            // Add the post to the bucket for the poster
            postBucketKey= KUtils.append(groupIDStr,'-',KUtils.toString(getBucketKey(groupIDStr, true)),'','');

            // Update the Posts Mapping with this user address
            groupPostsMap[postBucketKey].push(msgID);

            // Update the Posts Map Map for quick removal
            groupPostsMapMap[postBucketKey][msgID] = true;
        }

        // Log it
        emit logAddPost(msgID, groupIDs);
    }

    function removePost(uint256 msgID, uint256[] calldata groupIDs) public whenNotPaused onlyAdmins {

        // Initialize outside of the loop for gas savings
        string memory groupIDStr;
        string memory postBucketKey;

        for (uint g=0; g < groupIDs.length; g++) {
            // Convert the group ID to a string
            groupIDStr = KUtils.toString(groupIDs[g]);

            // Get the latest bucket on that user
            uint256 bucketKeyID = getBucketKey(groupIDStr, false);

            // Loop through each bucket and set the address to false
            for (uint i=0; i <= bucketKeyID; i++) {
                postBucketKey = KUtils.append(groupIDStr,'-',KUtils.toString(i),'','');

                // Update the map map for quick removal
                groupPostsMapMap[postBucketKey][msgID] = false;
            }
        }

        // Log it
        emit logRemovePost(msgID, groupIDs);
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Returns a list of messages are posted in a group
    * @param groupID : group ID to get a list of posts for
    * @param startFrom : the number to start getting records from
    * @return uint256[] : an array of message IDs
    */
    function getMsgIDsByGroupID(uint256 groupID, uint256 startFrom) public view whenNotPaused returns(uint256[] memory) {

        // We may need to change this
        uint256 _maxRecords = maxItemsReturn;

        // Convert the group ID to a string
        string memory groupIDStr = KUtils.toString(groupID);

        // Get the latest bucket
        uint256 bucketKeyID = getBucketKey(groupIDStr, false);

        // Get the bucket key from where we will pull from
        string memory bucketKey = KUtils.append(groupIDStr,'-',KUtils.toString(bucketKeyID),'','');

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = ((groupPostsMap[bucketKey].length) + (bucketKeyID * maxItemsPerBucket));
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

            // if the starting point is greater than the beginning item and less than the max in this bucket, this is the correct bucket
            if (startFrom >= (i * maxItemsPerBucket) && startFrom <= ((groupPostsMap[bucketKey].length) + (i * maxItemsPerBucket))) {
                bucketKeyID = i;

                // Adjust the startFrom to work with this bucket
                if (i != 0){
                    startFrom = startFrom - (i * maxItemsPerBucket);
                }

            }
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
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {

            // Check that the item is still enabled
            if (groupPostsMapMap[bucketKey][groupPostsMap[bucketKey][i - 1]]){
                postCount += 1;
            }

        }

        // Figure out the amount left to get from remainder bucket
        uint amountLeft = maxItemsReturn - postCount;

        // Add the remainder from the next bucket if there are any
        if (bucketKeyID != 0 && amountLeft > 0){

            // Get the new bucket key from where we will pull the remainder from (the previous one)
            remainderBucketKey = KUtils.append(groupIDStr,'-',KUtils.toString((bucketKeyID - 1)),'','');

            // Get the amount of items in the bucket to prevent multiple calculations for gas savings
            uint256 remainderLen = groupPostsMap[remainderBucketKey].length;

            for (uint i=remainderLen; i > remainderLen - amountLeft; i--) {
                // Add it if the item is still enabled
                if (groupPostsMapMap[remainderBucketKey][groupPostsMap[remainderBucketKey][i - 1]]){
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
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {
            if(groupPostsMapMap[bucketKey][groupPostsMap[bucketKey][i - 1]]){
                msgIDs[counter] = groupPostsMap[bucketKey][i - 1];
                counter += 1;
            }
        }

        // If there are more records to get from the next contract, check how many and KUtils.append them
        if (bucketKeyID != 0 && amountLeft > 0){
            // Loop through all items in the next bucket
            for (uint i=groupPostsMap[remainderBucketKey].length; i > groupPostsMap[remainderBucketKey].length - amountLeft; i--) {
                // Add it if the item is still enabled
                if (groupPostsMapMap[remainderBucketKey][groupPostsMap[remainderBucketKey][i - 1]]){
                    msgIDs[counter] = groupPostsMap[remainderBucketKey][i - 1];
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
            if (groupPostsMap[bucketToCheck].length > 0){
                // exists
                b++;
                prevBucketLen = groupPostsMap[bucketToCheck].length;
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