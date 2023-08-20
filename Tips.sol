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

    @title Tips
    v0.3

    KUTHULU : https://www.KUTHULU.xyz
    A project by DOOM Labs (https://DOOMLabs.io)
    The first truly decentralized social framework.
    Built for others to build upon and share freedom of expression.
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/IMessageData.sol";
import "./interfaces/IUserProfiles.sol";

contract Tips is Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Maximum amount of records to return on query
    uint256 public maxItemsReturn;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;

    // Map the user msgID to a list of addresses that them
    // Address is a string for address "buckets" 123, 123-1, 123-2 ...
    mapping (string => address[]) public tipsMap;
    mapping (string => uint256[]) public tipsAmountMap;
    mapping (string => mapping (address => bool)) public tipsMapMap;

    // Keep a ledger of all tips owed for claiming
    mapping (address => uint256) tipsOwed;

    // Percentage cut of tips for service costs
    uint256 cut;

    // Vault address for cut
    address vaultAddress;

    // Link to the Groups
    IGroups public Groups;

    // Link to the Message Data
    IMessageData public MessageData;

    // Link to the Message Data
    IUserProfiles public UserProfile;

    // Link the KUtils
    IKUtils public KUtils;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxItemsReturn, uint256 _maxItemsPerBucket, uint256 _cut) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        maxItemsReturn = _maxItemsReturn;
        maxItemsPerBucket = _maxItemsPerBucket;
        cut = _cut;

        require((maxItemsPerBucket + 1) >= maxItemsReturn, "Invalid Setup");

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);
    }


    /*

    EVENTS

    */

    event logAddTip(uint256 indexed msgID, address indexed requester, uint256 tips);
    event logClaimTips(address indexed poster, uint256 balance, uint256 groupID);
    event logTaggedTip(address indexed taggedAccount, uint256 tip);
    event logTaggedTipERC20(address indexed taggedAccount, uint256 tip, address tipContract);


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

    function setVaultAddress(address _newVault) public onlyAdmins{
        vaultAddress = _newVault;
    }

    function updateContracts(address _kutils, address _messageData, address _userProfile, address _groups) public onlyAdmins {
        // Update the KUtils address
        KUtils = IKUtils(_kutils);

        // Update the User Message Data address
        MessageData = IMessageData(_messageData);

        // Update the User Message Data address
        UserProfile = IUserProfiles(_userProfile);

        // Update the User Message Data address
        Groups = IGroups(_groups);
    }

    function addTip(uint256 msgID, address tippedBy, uint256 tips) public onlyAdmins {
        // Make sure we're not tagging a 0x0 address
        require(tippedBy != address(0), "Input address cannot be the zero address");

        addTipInt(msgID, tippedBy, tips);
    }

    function addTaggedTips(address[] memory taggedAccounts, uint256 erc20Tips, address tipContract, address posterAddress) public onlyAdmins whenNotPaused payable {

        // Get the amount of accounts that were tagged
        uint256 accountLength = taggedAccounts.length;

        // Make sure we have tagged accounts
        require(accountLength > 0, "Need Tagged Accounts");

        if (erc20Tips > 0){

            require((accountLength - 1) > 0, "Need Tagged Accounts");

            // ERC20 Receiver for tips via ERC20
            IERC20Upgradeable tipsToken = IERC20Upgradeable(tipContract);

            // Calculate the amount of tip per tage if split among multiple accounts
            uint256 tipPerTag = erc20Tips / (accountLength - 1);

            // If we have an uneven number, KUTHULU takes the remainder as a tip =)
            uint256 remainder = erc20Tips - (tipPerTag * (accountLength - 1));

            if (remainder > 0){
                // Send remainder to vault
                require(tipsToken.transferFrom(posterAddress, vaultAddress, remainder), "Failed remainder");
            }

            for (uint t=0; t < accountLength - 1; t++) {
                // Make sure we're not tagging a 0x0 address
                require(taggedAccounts[t] != address(0), "Input address cannot be the zero address");

                // Check to make sure the tagged address is not a group
                require(Groups.getOwnerOfGroupByAddress(taggedAccounts[t]) == address(0), "Cannot tip Groups ERC-20 Tokens");

                // Send the tips
                require(tipsToken.transferFrom(posterAddress,taggedAccounts[t], tipPerTag), "Failed tip transfer");

                emit logTaggedTipERC20(taggedAccounts[t], tipPerTag, tipContract);
            }
        }

        if (msg.value > 0){

            if (erc20Tips > 0){
                accountLength--;
            }

            // Calculate the amount of tip per tage if split among multiple accounts
            uint256 tipPerTag = msg.value / accountLength;

            // If we have an uneven number, KUTHULU takes the remainder as a tip =)
            uint256 remainder = msg.value - (tipPerTag * (accountLength - 1));

            if (remainder > 0){
                // Send remainder to vault
                tipsOwed[vaultAddress] += remainder;
            }

            // Give credit to each address tagged to claim payment
            for (uint t=0; t < accountLength; t++) {

                // Don't do the last address if ERC20 tips were added, as that's the contract address
                if (erc20Tips > 0 && t == accountLength){
                    break;
                }

                // Log the tip
                emit logTaggedTip(taggedAccounts[t], tipPerTag);

                // Update the balance owed to the address tipped
                tipsOwed[taggedAccounts[t]] += tipPerTag;
            }
        }
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Returns a list of addresses that tipped a post and how much they tipped
    * @param msgID : the message ID to get tips from
    * @param startFrom : the number to start getting records from
    * @return string[2][] : a multi-dimensional array of addresses that tipped a post and how much they tipped
    */
    function getTippersFromMsgID(uint256 msgID, uint256 startFrom) public view whenNotPaused returns(string[2][] memory) {
        // Stringify the message ID for the mapping
        string memory msgIDStr = KUtils.toString(msgID);

        // We may need to change this
        uint256 _maxRecords = maxItemsReturn;

        // Get the latest bucket
        uint256 bucketKeyID = getBucketKey(msgIDStr, false);

        string memory bucketPrefix = KUtils.append(msgIDStr,'-',KUtils.toString(bucketKeyID), '', '');

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = ((tipsMap[bucketPrefix].length) + (bucketKeyID * maxItemsPerBucket));
            if (startFrom != 0){
                startFrom -= 1;
            } else {
                // It's empty, so end
                string[2][] memory empty = new string[2][](0);
                return empty;
            }
        }

        // Figure out where the list should be pulled from
        for (uint i=0; i <= bucketKeyID; i++) {

            // if the starting point is greater than the beginning item and less than the max in this bucket, this is the correct bucket
            if (startFrom >= (i * maxItemsPerBucket) && startFrom < ((tipsMap[bucketPrefix].length) + (i * maxItemsPerBucket))) {
                bucketKeyID = i;

                // Adjust the startFrom to work with this bucket
                if (i != 0){
                    startFrom = startFrom - (i * maxItemsPerBucket);
                }

            }
        }

        // Initialize the remainder bucket
        string memory remainderBucketKey = bucketPrefix;

        // Check if there's less than max records in this bucket and only go to the end
        if (startFrom < _maxRecords){
            _maxRecords = startFrom + 1;
        }

        // Initialize the count as empty;
        uint256 itemCount = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {

            // Check that the item is still enabled
            if (tipsMapMap[bucketPrefix][tipsMap[bucketPrefix][i - 1]]){
                itemCount += 1;
            }
        }

        // Figure out the amount left to get from remainder bucket
        uint amountLeft = maxItemsReturn - itemCount;

        // Add the remainder from the next bucket if there are any
        if (bucketKeyID != 0 && amountLeft > 0){

            // Get the new bucket key from where we will pull the remainder from (the previous one)
            remainderBucketKey = KUtils.append(msgIDStr,'-',KUtils.toString((bucketKeyID - 1)), '', '');

            // Get the amount of items in the bucket to prevent multiple calculations for gas savings
            uint256 remainderLen = tipsMap[remainderBucketKey].length;

            for (uint i=remainderLen; i > remainderLen - amountLeft; i--) {
                // Add it if the item is still enabled
                if (tipsMapMap[remainderBucketKey][tipsMap[remainderBucketKey][i - 1]]){
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
        string[2][] memory tippedBy = new string[2][](itemCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the first bucket up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - _maxRecords); i--) {
            if(tipsMapMap[bucketPrefix][tipsMap[bucketPrefix][i - 1]]){
                tippedBy[counter] = [KUtils.addressToString(tipsMap[bucketPrefix][i - 1]), KUtils.toString(tipsAmountMap[bucketPrefix][i - 1])];
                counter += 1;
            }
        }

        // If there are more records to get from the next bucket, check how many and KUtils.append them
        if (bucketKeyID != 0 && amountLeft > 0){
            // Loop through all items in the next bucket
            for (uint i=tipsMap[remainderBucketKey].length; i > tipsMap[remainderBucketKey].length - amountLeft; i--) {
                // Add it if the item is still enabled
                if (tipsMapMap[remainderBucketKey][tipsMap[remainderBucketKey][i - 1]]){
                    tippedBy[counter] = [KUtils.addressToString(tipsMap[remainderBucketKey][i - 1]), KUtils.toString(tipsAmountMap[bucketPrefix][i - 1])];
                    counter += 1;
                }
                // we don't have to redo the amount increase if disabled since we're using the derived value now
            }
        }

        return tippedBy;
    }

    /**
    * @dev Check to see how much in tips are owed to an address of a user or group
    * @param addr : the address to check for tips owed to
    * @return uint256 : the amount of tips owed to the address
    */
    function checkTips(address addr) public view whenNotPaused returns (uint256){
        return tipsOwed[addr];
    }

    /**
    * @dev Claim tips owed to an address (user or group)
    * @dev If you pass a group ID, then you must be the owner of the group to claim the tips
    * @param groupID : (optional) the group ID to claim tips for. 0 = user address
    */
    function claimTips(uint256 groupID) public whenNotPaused nonReentrant {
        address account = msg.sender;

        if (groupID > 0){
            // If they're claiming on behalf of a group, make sure they're the owner
            require(Groups.getOwnerOfGroupByID(groupID) == account, "Not group owner");

            account = Groups.getGroupAddressFromID(groupID);
        }

        // Check how much they're owed
        uint256 balance = checkTips(account);

        // Only run if they're owed anything
        require(balance > 0, "No Tips");

        // Emit logs for external use
        emit logClaimTips(msg.sender, balance, groupID);

        // Close out what's owed before sending
        tipsOwed[account] = 0;

        // Transfer tips to their account
        AddressUpgradeable.sendValue(payable(msg.sender), balance);
    }

    /**
    * @dev Add tips to a post
    * @dev Tips are calculated from the value sent to this function
    * @param msgID : the message ID you want to add the tips to
    */
    function addTipFromPost(uint256 msgID) public whenNotPaused payable nonReentrant {

        // Calculate tips and sf
        uint256 sf = 0;
        if (cut > 0){
            sf = msg.value - ((msg.value * (100 - cut)) / 100)  ;
            tipsOwed[vaultAddress] += sf;
        }

        uint256 tip = msg.value - sf;

        // Add the tip to their owed balance
        tipsOwed[MessageData.getPoster(msgID)] += tip;

        // Record the tip
        addTipInt(msgID, msg.sender, tip);
    }


    /*

    PRIVATE FUNCTIONS

    */

    function payOut(address addr, uint256 amount, address paymentContract) public whenNotPaused onlyAdmins {
        if (paymentContract == address(0)){
            AddressUpgradeable.sendValue(payable(addr), amount);
        } else {
            // ERC20 Receiver for tips via ERC20
            IERC20Upgradeable tipsToken = IERC20Upgradeable(paymentContract);

            // Pay the ERC-20 tokens
            tipsToken.transferFrom(vaultAddress, addr, amount);
        }
    }

    function getBucketKey(string memory mapKey, bool toInsert) private view returns (uint256){
        uint256 prevBucketLen = 0;
        uint256 b = 0;
        uint256 mapID = 99999999999999999999;

        while (mapID == 99999999999999999999){
            // Get the bucket key to check
            string memory bucketToCheck = KUtils.append(mapKey,'-',KUtils.toString(b),'','');
            if (tipsMap[bucketToCheck].length > 0){
                // exists
                b++;
                prevBucketLen = tipsMap[bucketToCheck].length;
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

    function addTipInt(uint256 msgID, address tippedBy, uint256 tips) private {

        // Emit to the logs for external reference
        emit logAddTip(msgID, tippedBy, tips);

        // Stringify the ID
        string memory msgIDStr = KUtils.toString(msgID);

        // Add them to the bucket of Tips
        uint256 bucketKeyID = getBucketKey(msgIDStr, true);
        string memory tipBucketKey = KUtils.append(msgIDStr,'-',KUtils.toString(bucketKeyID),'','');

        // Update the Tips Mapping with this user address
        tipsMap[tipBucketKey].push(tippedBy);

        // Add the amount tipped to the map for lookup later
        tipsAmountMap[tipBucketKey].push(tips);

        // Update the Tips Map Map for quick removal
        tipsMapMap[tipBucketKey][tippedBy] = true;

        // Add the tip to the message
        MessageData.addStat(4, msgID, 0, tips);

        // Log the tips sent from sender
        UserProfile.updateUserTips(tippedBy, 0, tips);

        // Log tips received by poster
        UserProfile.updateUserTips(MessageData.getPoster(msgID), tips, 0);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}