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

    @title Tagged
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

contract Tagged is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Maximum amount of tagged accounts
    uint256 public maxTaggedAccounts;

    // Maximum amount of records to return on query
    uint256 public maxItemsReturn;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;

    // Map the user address to a list of message IDs that tagged them
    // Address is a string for address "buckets" 0x123, 0x123-1, 0x123-2 ...
    mapping (string => uint256[]) public taggedMap;
    mapping (string => mapping (uint256 => bool)) public taggedMapMap;

    // Link the KUtils
    IKUtils public KUtils;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxItemsReturn, uint256 _maxItemsPerBucket, uint256 _maxTaggedAccounts) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        maxItemsReturn = _maxItemsReturn;
        maxItemsPerBucket = _maxItemsPerBucket;
        maxTaggedAccounts = _maxTaggedAccounts;

        require((maxItemsPerBucket + 1) >= maxItemsReturn, "Invalid Setup");

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);
    }


    /*

    EVENTS

    */

    event logAddTag(uint256 indexed msgID, address indexed taggedAccount);
    event logRemoveTag(uint256 indexed msgID, address indexed untaggedAccount);


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

    function updateDetails(address _kutils, uint256 _maxTaggedAccounts) public onlyAdmins {
        // Update the KUtils address
        KUtils = IKUtils(_kutils);

        // Update max tagged accounts allowed
        maxTaggedAccounts = _maxTaggedAccounts;
    }

    function addTags(uint256 msgID, address[] calldata addressesTagged) public onlyAdmins {
        // Make sure there are tags to add if this is called
        require(addressesTagged.length > 0, "No tags to add");

        // Make sure there aren't more than maximum tagged accounts
        require(addressesTagged.length <= maxTaggedAccounts, "Too many accounts tagged");

        for (uint h=0; h < addressesTagged.length; h++) {
            // Make sure it's a valid address
            require(addressesTagged[h] != address(0), "Can't tag null");

            // Stringify the address
            string memory addressTaggedStr = KUtils.addressToString(addressesTagged[h]);

            // Add them to the bucket of Tags
            uint256 bucketKeyID = getBucketKey(addressTaggedStr, true);
            string memory taggedBucketKey = KUtils.append(addressTaggedStr,'-',KUtils.toString(bucketKeyID),'','');

            // Update the Tagged Mapping with this user address
            taggedMap[taggedBucketKey].push(msgID);

            // Update the Tagged Map Map for quick removal
            taggedMapMap[taggedBucketKey][msgID] = true;

            // Emit to the logs for external reference
            emit logAddTag(msgID, addressesTagged[h]);
        }
    }

    function removeTags(uint256 msgID, address[] calldata addressesTagged) public onlyAdmins {
        // Make sure there are tags to remove if this is called
        require(addressesTagged.length > 0, "No tags to remove");

        // Make sure there aren't more than maximum tagged accounts
        require(addressesTagged.length <= maxTaggedAccounts, "Too many accounts tagged");

        for (uint h=0; h < addressesTagged.length; h++) {
            // Make sure it's a valid address
            require(addressesTagged[h] != address(0), "Can't remove tag null");

            // Stringify the address
            string memory addressTaggedStr = KUtils.addressToString(addressesTagged[h]);

            // Get the latest bucket on that user
            uint256 bucketKeyID = getBucketKey(addressTaggedStr, false);

            // Loop through each bucket and set the address to false
            for (uint i=0; i <= bucketKeyID; i++) {
                string memory taggedBucketKey = KUtils.append(addressTaggedStr,'-',KUtils.toString(i),'','');

                // Update the map map for quick removal
                taggedMapMap[taggedBucketKey][msgID] = false;
            }

            // Emit to the logs for external reference
            emit logRemoveTag(msgID, addressesTagged[h]);
        }
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Returns a list of message IDs that are tagged to a given user
    * @param usrAddress : the address of a user or group to retrieve the details for
    * @param startFrom : the number to start getting records from
    * @return uint256[] : an array of message IDs
    */
    function getTaggedMsgIDs(address usrAddress, uint256 startFrom) public view whenNotPaused returns(uint256[] memory) {

        // Check to make sure the message exists
        require(usrAddress != address(0), "Invalid address");

        // Lowercase the address
        string memory usrAddressStr = KUtils.addressToString(usrAddress);

        // We may need to change this
        uint256 _maxRecords = maxItemsReturn;

        // Get the latest bucket
        uint256 bucketKeyID = getBucketKey(usrAddressStr, false);

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = ((taggedMap[KUtils.append(usrAddressStr,'-',KUtils.toString(bucketKeyID),'','')].length) + (bucketKeyID * maxItemsPerBucket));
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
            string memory _bucketKey = KUtils.append(usrAddressStr,'-',KUtils.toString(bucketKeyID),'','');

            // if the starting point is greater than the beginning item and less than the max in this bucket, this is the correct bucket
            if (startFrom >= (i * maxItemsPerBucket) && startFrom < ((taggedMap[_bucketKey].length) + (i * maxItemsPerBucket))) {
                bucketKeyID = i;

                // Adjust the startFrom to work with this bucket
                if (i != 0){
                    startFrom = startFrom - (i * maxItemsPerBucket);
                }

            }
        }

        // Get the bucket key from where we will pull from
        string memory bucketKey = KUtils.append(usrAddressStr,'-',KUtils.toString(bucketKeyID),'','');

        // Initialize the remainder bucket
        string memory remainderBucketKey = bucketKey;

        // Check if there's less than max records in this bucket and only go to the end
        if (startFrom < _maxRecords){
            _maxRecords = startFrom + 1;
        }

        // Initialize the count as empty;
        uint256 taggedCount = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {

            // Check that the item is still enabled
            if (taggedMapMap[bucketKey][taggedMap[bucketKey][i - 1]]){
                taggedCount += 1;
            }
        }

        // Figure out the amount left to get from remainder bucket
        uint amountLeft = maxItemsReturn - taggedCount;

        // Add the remainder from the next bucket if there are any
        if (bucketKeyID != 0 && amountLeft > 0){

            // Get the new bucket key from where we will pull the remainder from (the previous one)
            remainderBucketKey = KUtils.append(usrAddressStr,'-',KUtils.toString((bucketKeyID - 1)),'','');

            // Get the amount of items in the bucket to prevent multiple calculations for gas savings
            uint256 remainderLen = taggedMap[remainderBucketKey].length;

            for (uint i=remainderLen; i > remainderLen - amountLeft; i--) {
                // Add it if the item is still enabled
                if (taggedMapMap[remainderBucketKey][taggedMap[remainderBucketKey][i - 1]]){
                    taggedCount += 1;
                } else {
                    // If it's disabled, we still have a slot, so reopen it as long as we're not at zero
                    if (remainderLen > amountLeft){
                        amountLeft ++;
                    }
                }
            }
        }

        // Start the array
        uint256[] memory msgIDs = new uint256[](taggedCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {
            if(taggedMapMap[bucketKey][taggedMap[bucketKey][i - 1]]){
                msgIDs[counter] = taggedMap[bucketKey][i - 1];
                counter += 1;
            }
        }

        // If there are more records to get from the next contract, check how many and KUtils.append them
        if (bucketKeyID != 0 && amountLeft > 0){
            // Loop through all items in the next bucket
            for (uint i=taggedMap[remainderBucketKey].length; i > taggedMap[remainderBucketKey].length - amountLeft; i--) {
                // Add it if the item is still enabled
                if (taggedMapMap[remainderBucketKey][taggedMap[remainderBucketKey][i - 1]]){
                    msgIDs[counter] = taggedMap[remainderBucketKey][i - 1];
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
            if (taggedMap[bucketToCheck].length > 0){
                // exists
                b++;
                prevBucketLen = taggedMap[bucketToCheck].length;
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