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

    @title Followers
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

contract Followers is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Maximum amount of records to return on query
    uint256 public maxItemsReturn;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;

    // Map the user address to a list of addresses that are following them
    // Address is a string for address "buckets" 0x123, 0x123-1, 0x123-2 ...
    mapping (string => address[]) public followerMap;
    mapping (string => mapping (address => bool)) public followerMapMap;

    // Records of who users are following (follower => following)
    mapping (address => address[]) public followingMap;
    // Quick lookup with follower => following => bool
    mapping (address => mapping (address => bool)) public followingMapMap;

    // Link the User Profiles
    IUserProfiles public userProfiles;

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

    event logAddFollower(address indexed requester, address indexed target);
    event logRemoveFollower(address indexed requester, address indexed target);



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
        // Update KUtils
        KUtils = IKUtils(_kutils);

        // Update the User User Profiles address
        userProfiles = IUserProfiles(_userProfiles);
    }

    // Add a follower to a user or group
    // addressRequester - the user or group address that wants to follow the addressTarget
    // addressTarget - the user or group address that the addressRequester wants to follow
    function addFollower(address addressRequester, address addressTarget) public whenNotPaused onlyAdmins {
        // Stringify the address
        string memory addressTargetStr = KUtils.addressToString(addressTarget);

        // Check if user already being followed
        require(!followingMapMap[addressRequester][addressTarget], "Already following that user");

        // Add them to the bucket of Followers
        uint256 bucketKeyID = getBucketKey(addressTargetStr, true);
        string memory followingBucketKey = KUtils.append(addressTargetStr,'-',KUtils.toString(bucketKeyID),'','');


        // Initialize adding the new record
        bool addIt = true;

        // Initialize out of the loop for gas savings
        string memory thisBucketKey;

        // Check through each bucket to see if they followed them previously
        for (uint b=bucketKeyID; b >= 0; b--) {
            // Get the next bucket key
            thisBucketKey = KUtils.append(addressTargetStr, '-',KUtils.toString(b),'','');

            for (uint x; x < followerMap[thisBucketKey].length; x++) {
                if (followerMap[thisBucketKey][x] == addressRequester) {
                    // Followed them previously, so no need to add to the map
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
            // Update the follower Mapping with this user address
            followerMap[followingBucketKey].push(addressRequester);
        }

        // Update the Follower Map Map for quick removal
        followerMapMap[followingBucketKey][addressRequester] = true;

        // Add them to the array
        followingMap[addressRequester].push(addressTarget);

        // Update the following map
        followingMapMap[addressRequester][addressTarget] = true;

        // Emit to the logs for external reference
        emit logAddFollower(addressRequester, addressTarget);
    }


    // Remove a follower to a user or group
    // addressRequester - the user or group address that wants to unfollow the addressTarget
    // addressTarget - the user or group address that the addressRequester wants to follow
    function removeFollower(address addressRequester, address addressTarget) public onlyAdmins {
        // Stringify the address
        string memory addressTargetStr = KUtils.addressToString(addressTarget);

        // Make sure it's not themselves
        require(addressRequester != addressTarget, "Not a thing");

        // Check if they're following the user
        require(followingMapMap[addressRequester][addressTarget], "Not following that user");

        // Get the latest bucket on that user
        uint256 bucketKeyID = getBucketKey(addressTargetStr, false);

        // Loop through each bucket and set the address to false
        for (uint i=0; i <= bucketKeyID; i++) {
            string memory followingBucketKey = KUtils.append(addressTargetStr,'-',KUtils.toString(i),'','');

            // Update the map map for quick removal
            followerMapMap[followingBucketKey][addressRequester] = false;
        }

        // Set to false or quick lookups
        followingMapMap[addressRequester][addressTarget] = false;

        // Remove it from the follower array
        uint256 place = 0;
        for (uint i=0; i < followingMap[addressRequester].length; i++) {
            if (followingMap[addressRequester][i] == addressTarget){
                place = i;
                break;
            }
        }

        // Swap the last entry with this one
        followingMap[addressRequester][place] = followingMap[addressRequester][followingMap[addressRequester].length-1];

        // Remove the last element
        followingMap[addressRequester].pop();

        // Emit to the logs for external reference
        emit logRemoveFollower(addressRequester, addressTarget);
    }



    /*

    PUBLIC FUNCTIONS

    */

    /**
    * Returns a list of users and groups are following a given user or group
    * @param usrAddress : the address to retrieve the details for (user or group)
    * @param startFrom : the number to start getting records from
    * @return address[] : an array of addresses of accounts following usrAddress
    */
    function getFollowers(address usrAddress, uint256 startFrom) public view whenNotPaused returns(address[] memory) {
        // Lowercase the address
        string memory usrAddressStr = KUtils.addressToString(usrAddress);

        // We may need to change this
        uint256 _maxRecords = maxItemsReturn;

        // Get the latest bucket
        uint256 bucketKeyID = getBucketKey(usrAddressStr, false);

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = ((followerMap[KUtils.append(usrAddressStr,'-',KUtils.toString(bucketKeyID),'','')].length) + (bucketKeyID * maxItemsPerBucket));
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
            string memory _bucketKey = KUtils.append(usrAddressStr,'-',KUtils.toString(bucketKeyID),'','');

            // if the starting point is greater than the beginning item and less than the max in this bucket, this is the correct bucket
            if (startFrom >= (i * maxItemsPerBucket) && startFrom < ((followerMap[_bucketKey].length) + (i * maxItemsPerBucket))) {
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
        uint256 followerCount = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {

            // Check that the item is still enabled
            if (followerMapMap[bucketKey][followerMap[bucketKey][i - 1]]){
                followerCount += 1;
            }
        }

        // Figure out the amount left to get from remainder bucket
        uint amountLeft = maxItemsReturn - followerCount;

        // Add the remainder from the next bucket if there are any
        if (bucketKeyID != 0 && amountLeft > 0){

            // Get the new bucket key from where we will pull the remainder from (the previous one)
            remainderBucketKey = KUtils.append(usrAddressStr,'-',KUtils.toString((bucketKeyID - 1)),'','');

            // Get the amount of items in the bucket to prevent multiple calculations for gas savings
            uint256 remainderLen = followerMap[remainderBucketKey].length;

            for (uint i=remainderLen; i > remainderLen - amountLeft; i--) {
                // Add it if the item is still enabled
                if (followerMapMap[remainderBucketKey][followerMap[remainderBucketKey][i - 1]]){
                    followerCount += 1;
                } else {
                    // If it's disabled, we still have a slot, so reopen it as long as we're not at zero
                    if (remainderLen > amountLeft){
                        amountLeft ++;
                    }
                }
            }
        }

        // Start the array
        address[] memory followers = new address[](followerCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {
            if(followerMapMap[bucketKey][followerMap[bucketKey][i - 1]]){
                followers[counter] = followerMap[bucketKey][i - 1];
                counter += 1;
            }
        }

        // If there are more records to get from the next contract, check how many and KUtils.append them
        if (bucketKeyID != 0 && amountLeft > 0){
            // Loop through all items in the next bucket
            for (uint i=followerMap[remainderBucketKey].length; i > followerMap[remainderBucketKey].length - amountLeft; i--) {
                // Add it if the item is still enabled
                if (followerMapMap[remainderBucketKey][followerMap[remainderBucketKey][i - 1]]){
                    followers[counter] = followerMap[remainderBucketKey][i - 1];
                    counter += 1;
                }
                // we don't have to redo the amount increase if disabled since we're using the derived value now
            }
        }

        return followers;
    }

    /**
    * @dev Returns a list of users a given user is following
    * @param usrAddress : the address to retrieve the details for
    * @param startFrom : the number to start getting records from
    * @return address[] : a list of addresses that usrAddress is following
    */
    function getFollowing(address usrAddress, uint256 startFrom) public view whenNotPaused returns(address[] memory) {

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = followingMap[usrAddress].length;
            if (startFrom != 0){
                startFrom -= 1;
            } else {
                // It's empty, so end
                address[] memory empty = new address[](0);
                return empty;
            }
        }

        // Initialize the count as empty;
        uint256 returnCount = maxItemsReturn;

        if (startFrom < maxItemsReturn){
            returnCount = startFrom;
        }

        // Start the array
        address[] memory followings = new address[](returnCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the array up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - returnCount); i--) {
            followings[counter] = followingMap[usrAddress][i - 1];
            counter += 1;
        }

        return followings;
    }


    /**
    * @dev Tells if a a user or group is following another user or group.
    * @dev Is addressTarget following addressRequester
    * @param addressRequester : the user or group checking if they are following addressTarget
    * @param addressTarget : the user or group checking if followed
    * @return bool : a list of addresses that usrAddress is following
    */
    function isUserFollowing(address addressRequester, address addressTarget) public view whenNotPaused returns (bool){
        return followingMapMap[addressRequester][addressTarget];
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
            if (followerMap[bucketToCheck].length > 0){
                // exists
                b++;
                prevBucketLen = followerMap[bucketToCheck].length;
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