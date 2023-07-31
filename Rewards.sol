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

    @title Rewards
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
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


import "./interfaces/IKUtils.sol";
import "./interfaces/IRaffleTix.sol";
import "./interfaces/IKuthulu.sol";
import "./interfaces/IDOOM.sol";

contract Rewards is Initializable, PausableUpgradeable, OwnableUpgradeable, ERC20Upgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    address KuthuluContract;

    // Amount of posts per level per rewardID
    uint256[][] amountPerLevel;

    // Map the address to the highest tier they're at
    mapping (address => uint256[]) userRewardTier;

    // Link to the RaffleTix
    IRaffleTix public RaffleTix;

    // Link to the KuthuluApp
    IKuthulu public KuthuluApp;

    // Link to the DOOM Contracts
    IDOOM public DOOM;

    // Link the KUtils contract
    IKUtils public KUtils;

    // Setup to be able to call default DOOM ERC20 calls
    IERC20Upgradeable public token;

    // Current Reward ID to keep track of
    uint256 currentRewardID;

    // Map the address to the rewardID that's being tracked
    mapping (address => uint256) userRewardID;

    uint256 rewardsGroupID;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, address _kuthulu, address _doom, address _raffleTix, uint256[] calldata _amnts) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set the amount of posts to increment to reach next level for this ID;
        amountPerLevel.push(_amnts);

        // Setup link to RaffleTix
        RaffleTix = IRaffleTix(_raffleTix);

        // Setup link to KUTHULU
        KuthuluApp = IKuthulu(_kuthulu);
        KuthuluContract = _kuthulu;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Setup link to DOOM
        DOOM = IDOOM(_doom);
        token = IERC20Upgradeable(_doom);

        // Start out with 0
        currentRewardID = 0;

        // Set the initial Rewards Group IDOOM
        rewardsGroupID = 82901138019809681465386440910526222986491416502260907764523583795075734899591;
    }

    /*

    EVENTS

    */

    event logAward(address indexed usrAddress, string indexed handle);


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

    function updateGroupID(uint256 groupID) public onlyAdmins {
        rewardsGroupID = groupID;
    }


    // setting incrementRewardID=true effectively makes a new reward ID and sets it's amounts per level (level attribute ignored)
    // setting incrementRewardID=false will just update the amounts for the level provided
    function updateDetails(address _kutils, address _kuthulu, address _raffleTix, address _doom, uint256[] calldata _amounts, uint256 level,bool incrementRewardID) public onlyAdmins {
        // Update the User Profiles contract address
        KUtils = IKUtils(_kutils);

        // Update the KUTHULU contract address
        KuthuluApp = IKuthulu(_kuthulu);

        // Setup link to RaffleTix
        RaffleTix = IRaffleTix(_raffleTix);

        // Update the DOOM address
        DOOM = IDOOM(_doom);

        // Set the current Reward ID
        if (incrementRewardID){
            currentRewardID++;

            // Set the amount per level
            amountPerLevel[currentRewardID] = _amounts;
        } else {
            // Set the amount per level
            amountPerLevel[level] = _amounts;
        }


    }

    function mintDoom(uint256 quantity) public payable onlyAdmins {
        // Mint some DOOM as needed to the contract
        uint256 valueToSend = quantity * 10000000000000000;
        DOOM.publicMint{value: valueToSend}(quantity);

        // Approve KUTHULU to spend the DOOM tokens
        token.approve(KuthuluContract, valueToSend);
    }


    function checkRewards(uint256 msgID, uint256 postCount, address posterAddress) public onlyAdmins {

        // If the user doesn't have a reward Tier for this Reward ID
        if (userRewardTier[posterAddress].length < currentRewardID + 1){

            // Loop through until they get to it and initialize it to zero
            for (uint256 i=0; i <= currentRewardID; i++) {
                userRewardTier[posterAddress].push(0);
            }
        }

        // Make sure they're on the current reward ID to be tracked
        if (userRewardID[posterAddress] != currentRewardID){

            // If not, change it and reset their level
            userRewardID[posterAddress] = currentRewardID;
            userRewardTier[posterAddress][currentRewardID] = 0;
        }

        uint256 level = userRewardTier[posterAddress][currentRewardID];

        // If they're under the max reward level (
        if (level < amountPerLevel[currentRewardID].length) {

            // If hey have reached the reward tier for their current level
            if (postCount >= amountPerLevel[currentRewardID][level]){

                // Increase them to the next level
                userRewardTier[posterAddress][currentRewardID]++;

                // YAY! They win!
                // Have to make an array cuz awardTix expects it
                address[] memory winner = new address[](1);
                winner[0] = posterAddress;

                // Post a message to let them know
                postResponse(userRewardTier[posterAddress][currentRewardID], posterAddress);

                RaffleTix.awardTix(winner, 1);
            }
        }
    }




    /*

    PRIVATE FUNCTIONS

    */


    /**
    * @dev Post a message back to KUTHULU
    */
    function postResponse(uint256 level, address posterAddress) private whenNotPaused {

        // Create a couple hashtags
        string[] memory hashtags = new string[](2);

        hashtags[0] = "RaffleWinner";
        hashtags[1] = "Kultish";

        // Tag the winners account
        address[] memory taggedAccounts = new address[](1);
        taggedAccounts[0] = posterAddress;

        string memory message = string(abi.encodePacked("Congrats to @", KUtils.addressToString(posterAddress), "! They won a Raffle Ticket NFT and are now at level ", KUtils.toString(level)));
        message = string(abi.encodePacked(message, "! Raffle Ticket holders are entered to win a whitelist spot for the minting of the coveted Amulets! Only Amulet holders will be able to mint a Kultist! The more Raffle Tickets you have, the more chances you have to win!"));


        // Set the post attributes
        uint256 blockComments = 0;  // Block Comments (Comment Level: 0 = Allowed / 1 = Not Allowed)
        uint256 isCommentOf = 0;  // Is this a comment of another post? If so, add that message ID here
        uint256 isRepostOf = 0;  // Is this a repost of another post? If so, add that message ID here
        uint256 groupID = rewardsGroupID;  // Are you posting on behalf of a group? If so, add the GroupID here (KUTHULU-Rewards)
        uint256 tipsERC20Amount = 0; // Amount of ERC20 token to tip in wei
        string memory uri = 'ipfs://QmZpN1cCURBoQwFWMSZRYTktxcwqRcNsHvcjigZjNiLBLD'; // The URI of the image to add to the post

        // We're not posting to any Spaces / Groups
        uint256[] memory inGroups = new uint256[](0);

        // Make the post back to KUTHULU
        KuthuluApp.postMsg(message, hashtags, taggedAccounts, uri, [blockComments,isCommentOf,isRepostOf,groupID,tipsERC20Amount], inGroups);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}


