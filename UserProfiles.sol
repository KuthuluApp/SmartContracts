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

    @title UserProfiles
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
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IFollowers.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/INFT.sol";
import "./interfaces/IContractHook.sol";
import "./interfaces/IRewards.sol";

contract UserProfiles is Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) private admins;

    // Approved Wallets
    mapping (address => bool) private approved;

    // Mapping of userAddress => ERC20 Contract Address => value
    mapping(address => mapping(address => uint256)) private mapERC20TipsReceived;
    mapping(address => mapping(address => uint256)) private mapERC20TipsSent;

    // User Stats
    struct UserStats {
        uint256 postCount;
        uint256 commentCount;
        uint256 followerCount;
        uint256 followingCount;
        uint256 tipsReceived;
        uint256 tipsSent;
    }

    // User Avatar
    struct UserAvatar {
        string avatar;
        string metadata;
        address contractAddress;
        uint256 tokenID;
        uint256 networkID;
    }

    // The User data struct
    struct UserData {
        string handle;
        string location;
        uint256 joinBlock;
        uint256 joinTime;
        UserAvatar userAvatar;
        string uri;
        string bio;
        uint256 followLimit;
        uint256 verified;
        uint256 groupID;
        address contractHook;
        UserStats userStats;
    }

    // Map the User Address => User Data
    mapping (address => UserData) private usrProfileMap;

    // Set Max URI Length
    uint256 public maxURILength;

    // Set Max Bio Length
    uint256 public maxBioLength;

    // Set the Max Location Length;
    uint256 public maxLocationLength;

    // Set Following Limit
    uint256 public maxFollowing;

    // Set the network ID to lookup NFT
    uint256 public networkID;

    // Keep track of the number of users that have joined
    uint256 public joinedUserCount;

    // Link to the KUtils Contracts
    IKUtils public KUtils;

    // Link to the Followers Contract
    IFollowers public Followers;

    // Link to the Groups Contract
    IGroups public Groups;

    // Link to Random NFT Contract
    INFT public NFT;

    // Link to the ContractHook
    IContractHook public ContractHook;

    // Link to the ContractHook
    IRewards public Rewards;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxURILength, uint256 _maxBioLength, uint256 _maxFollowing, uint256 _maxLocationLength, uint256 _networkID) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;
        approved[msg.sender] = true;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        maxURILength = _maxURILength;
        maxBioLength = _maxBioLength;
        maxFollowing = _maxFollowing;
        maxLocationLength = _maxLocationLength;
        networkID = _networkID;
    }


    /*

    EVENTS

    */

    event logProfileUpdated(address indexed requester, string uri, string avatar, string location, string bio);
    event logNewUser(address indexed requester);
    event hashtagToVerify(address indexed userAddress, string indexed handle);
    event logSaveNFTAvatar(address indexed profileAddress, string metadata, address indexed nftContract, uint256 tokenId, uint256 indexed _networkID);


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

    function updateApproved(address _address, bool status) public onlyAdmins {
        approved[_address] = status;
    }

    function updateProfileVars(uint256 _bioLen, uint256 _uriLen, uint256 _locLen, uint256 _networkID) public onlyAdmins {
        // Set the maximum length for the Biography attribute of a profile
        maxBioLength = _bioLen;

        // Set the maximum length for the URI attribute of a profile
        maxURILength = _uriLen;

        // Set the maximum length for the location attribute of a profile
        maxLocationLength = _locLen;

        // Set the network ID we're running on
        networkID = _networkID;
    }

    function updateContracts(address _followers, address _kutils, address _groups, address _rewards) public onlyAdmins {
        // Update the Followers contract address
        Followers = IFollowers(_followers);

        // Update the KUtils address
        KUtils = IKUtils(_kutils);

        // Update the Groups address
        Groups = IGroups(_groups);

        // Update the Rewards address
        Rewards = IRewards(_rewards);
    }

    // Updates the profile by decrementing post count
    function updatePostCount(address posterAddress, bool isComment) public onlyAdmins {
        // Make sure we have a valid address
        require(posterAddress != address(0), "Can't update 0 address");

        if (isComment){
            // Post count must be a number > 0
            require(usrProfileMap[posterAddress].userStats.commentCount > 0, "Invalid Comment Count");

            usrProfileMap[posterAddress].userStats.commentCount -= 1;
        } else {
            // Post count must be a number > 0
            require(usrProfileMap[posterAddress].userStats.postCount > 0, "Invalid Post Count");

            usrProfileMap[posterAddress].userStats.postCount -= 1;
        }
    }

    // Updates the profile with contracts posted in
    function recordPost(address posterAddress, uint256 tipPerTag, address[] calldata tipReceivers, uint256 isCommentOf, address tipContract, uint256 erc20Tips, uint256 msgID) public onlyAdmins {

        // If this poster doesn't have a profile setup yet, start it
        if (usrProfileMap[posterAddress].joinBlock == 0){
            joinUser(posterAddress);
        }

        // Add the post to their total count
        if (isCommentOf > 0){
            usrProfileMap[posterAddress].userStats.commentCount += 1;
        } else {
            usrProfileMap[posterAddress].userStats.postCount += 1;
        }

        // If ERC20 Token tips were provided
        if (erc20Tips > 0){
            // Add the total tips sent to their count
            mapERC20TipsSent[posterAddress][tipContract] += erc20Tips;

            // Update the tips received to each account tagged
            uint256 ercTipPerTag = erc20Tips / (tipReceivers.length - 1);
            for (uint i=0; i < tipReceivers.length - 1; i++) {
                mapERC20TipsReceived[tipReceivers[i]][tipContract] += ercTipPerTag;
            }
        }

        // Add the total tips sent to their count
        updateUserTips(posterAddress, 0, (tipPerTag * tipReceivers.length));

        // Update the tips received to each account tagged
        for (uint i=0; i < tipReceivers.length; i++) {
            if (erc20Tips > 0 && i == tipReceivers.length - 1){
                break;
            }
            updateUserTips(tipReceivers[i], tipPerTag, 0);
        }

        // Only allow rewards for non-contract posts
        if (tx.origin == posterAddress){
            // Check to see if they won any rewards and process as necessary
            Rewards.checkRewards(msgID, usrProfileMap[posterAddress].userStats.postCount, posterAddress);
        }
    }

    // Update a users tips sent / received
    function updateUserTips(address targetAddress, uint256 tipsReceived, uint256 tipsSent) public onlyAdmins {
        usrProfileMap[targetAddress].userStats.tipsSent += tipsSent;
        usrProfileMap[targetAddress].userStats.tipsReceived += tipsReceived;
    }

    // Set an NFT as your profile photo (only for users / not groups)
    function setAvatar(address profileAddress, string calldata imageURI, address _nftContract, uint256 tokenId, string memory metadata, uint256 _networkID) public whenNotPaused {
        // Only approved wallets can force an NFT avatar
        require(approved[msg.sender], "Only approved wallets can call this function.");

        // Make sure the URI is legit
        require(KUtils.isValidURI(imageURI), "Invalid URI");

        // Save image URI
        usrProfileMap[profileAddress].userAvatar.avatar = imageURI;

        // Save the NFT parts
        setNFTAvatarPriv(profileAddress, metadata, _nftContract, tokenId, _networkID);
    }

    // Setup a new groups details for the metadata
    function setupNewGroup(address groupAddress, string memory groupName, uint256 groupID, address _nftContract) public onlyAdmins {
        // Setup link to the NFT contract
        NFT = INFT(_nftContract);

        // Save the token contract
        usrProfileMap[groupAddress].userAvatar.contractAddress = _nftContract;

        // Save the token ID
        usrProfileMap[groupAddress].userAvatar.tokenID = groupID;

        // Save the group name to the profile
        usrProfileMap[groupAddress].handle = groupName;

        // Save the Group ID to the group profile
        usrProfileMap[groupAddress].groupID = groupID;

        // Save the Network ID to the group profile
        usrProfileMap[groupAddress].userAvatar.networkID = networkID;

        // Setup initial profile details for joining
        joinUser(groupAddress);
    }

    // Update a users handle and verification level (called from UserHandles.sol)
    // Verification Levels
    // 0 = Normal User
    // 1 = ENS Name Verified
    // 2 = Tyr Verified
    function updateHandleVerify(address userAddress, string calldata handle, uint256 verified) public onlyAdmins {

        // Update their verified level
        usrProfileMap[userAddress].verified = verified;

        // Update their handle
        usrProfileMap[userAddress].handle = handle;

        // Emit to the logs for external reference
        emit hashtagToVerify(userAddress, handle);
    }

    function followUser(address addressRequester, address addressToFollow) public onlyAdmins {
        // If this poster doesn't have a profile setup yet, start it
        if (usrProfileMap[addressRequester].joinBlock == 0){
            joinUser(addressRequester);
        }

        // Check to make sure they're under their max follow count
        require(usrProfileMap[addressToFollow].userStats.followerCount < usrProfileMap[addressRequester].followLimit, "You are following the maximum amount of accounts");

        // Add the follower to the followers lists
        Followers.addFollower(addressRequester, addressToFollow);

        // Add a follower to the users profile follower count
        usrProfileMap[addressToFollow].userStats.followerCount += 1;

        // Update following count by one
        usrProfileMap[addressRequester].userStats.followingCount += 1;
    }


    function unfollowUser(address addressRequester, address addressToUnfollow) public onlyAdmins {

        // Remove the follower from the followers lists
        Followers.removeFollower(addressRequester, addressToUnfollow);

        // Subtract a follower count from the dropped user
        usrProfileMap[addressToUnfollow].userStats.followerCount -= 1;

        // Remove following count by one
        usrProfileMap[addressRequester].userStats.followingCount -= 1;
    }

    function updateMetadata(address _address, string memory _metadata) public onlyAdmins {
        // Save the token metadata
        usrProfileMap[_address].userAvatar.metadata = _metadata;
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Update a user or group profile details
    * @dev When updating a group profile, only the owner has access to make updates
    * @param location : The user or groups location. Must be less than maxLocationLength characters in length
    * @param avatar : a URI for the user or groups avatar picture. Must be less than maxURILength characters in length
    * @param _uri : a URI to publicly share for the user or groups profile. Must be less than maxURILength characters in length
    * @param _bio : a bio of the user or group. Must be less than maxBioLength characters in length
    * @param groupID : (optional) the Group ID to update the profile for. 0 = user profile.
    */
    function updateProfile(string calldata location, string calldata avatar, string calldata _uri, string calldata _bio, uint256 groupID) public whenNotPaused {

        address profileAddress = msg.sender;

        // Make sure the location, avatar, uri, abd bio are valid strings
        require(KUtils.isSafeString(location) && KUtils.isValidURI(avatar) && KUtils.isValidURI(_uri) && KUtils.isSafeString(_bio), "Unsafe characters");

        // If this is a group validate that they are the owner
        if (groupID > 0){
            // Validate that they are the owner
            require(msg.sender == Groups.getOwnerOfGroupByID(groupID), "You are not the owner of this group");

            profileAddress = Groups.getGroupAddressFromID(groupID);
        }

        // If it's a new user, setup their initial profile
        if (usrProfileMap[profileAddress].joinBlock == 0){
            joinUser(profileAddress);
        }

        // Make sure the Location length is within limits
        require(bytes(location).length <= maxLocationLength, "Your Location is too long");

        // Make sure the Avatar length is within limits
        require(bytes(avatar).length <= maxURILength, "Your Avatar is too long");

        // Require a Avatar with RCF compliant characters only
        require(KUtils.isValidURI(avatar), "Bad characters in Avatar");

        // Make sure the URI length is within limits
        require(bytes(_uri).length <= maxURILength, "Your URI is too long");

        // Require a URI with RCF compliant characters only
        require(KUtils.isValidURI(_uri), "Bad characters in URI");

        // Make sure the Bio length is within limits
        require(bytes(_bio).length <= maxBioLength, "Your Bio is too long");

        // If they're updating their Avatar to a URI, erase the NFT data
        if (bytes(avatar).length > 4){
            setNFTAvatarPriv(profileAddress, '', address(0), 0, 0);
        }

        // Update the URI
        usrProfileMap[profileAddress].uri = _uri;

        // Update the Avatar
        usrProfileMap[profileAddress].userAvatar.avatar = avatar;

        // Update the Location
        usrProfileMap[profileAddress].location = location;

        // Update the Bio
        usrProfileMap[profileAddress].bio = _bio;

        // Emit to the logs for external reference
        emit logProfileUpdated(profileAddress, _uri, avatar, location, _bio);
    }


    /**
    * @dev Set an NFT as your profile photo
    * @dev When updating a group avatar, only the owner has access to make updates
    * @dev the wallet making this update must own the NFT on the contract provided
    * @dev not all contracts will work. They must follow metadata standards
    * @param _nftContract : the contract address on this network that you own the NFT for
    * @param tokenId : the NFT token ID of the NFT you own that is part of _nftContract
    * @param groupID : (optional) the Group ID to update the avatar for. 0 = user profile.
    */
    function setNFTAsAvatar(address _nftContract, uint256 tokenId, uint256 groupID) public whenNotPaused nonReentrant {
        // Make sure we get a valid address
        require(_nftContract != address(0), "Need the contract address that minted the NFT");

        // Setup link to the NFT contract
        NFT = INFT(_nftContract);

        // Check that they're the owner of the NFT
        require(NFT.ownerOf(tokenId) == msg.sender, "Not the owner of that NFT");

        address profileAddress = groupID > 0 ? Groups.groupDetails(groupID).groupAddress : msg.sender;

        // Save the NFT parts
        setNFTAvatarPriv(profileAddress, NFT.tokenURI(tokenId), _nftContract, tokenId, networkID);
    }


    /**
    * @dev Returns the user details by address in JSON string
    * @param usrAddress : the address to retrieve the details for
    * @return string[] : an array of user or group details
    * 0 = Handle
    * 1 = Post Count
    * 2 = Number of users they are following
    * 3 = Number of users that are following them
    * 4 = User Verification level
    * 5 = Avatar URI
    * 6 = Avatar Metadata
    * 7 = Avatar Contract Address
    * 8 = Avatar Network ID
    * 9 = token ID
    * 10 = URI
    * 11 = Bio
    * 12 = Location
    * 13 = Block number when joined
    * 14 = Block timestamp when joined
    * 15 = Limit of number of users they can follow
    * 16 = Total Tips Received
    * 17 = Total Tips Sent
    * 18 = Group ID (0 = user)
    */
    function getUserDetails(address usrAddress) public view whenNotPaused returns(string[] memory){

        // Initialize the return array of users details
        string[] memory userDetails = new string[](19);

        // Load the user profile once and store it in memory
        UserData storage profile = usrProfileMap[usrAddress];
        UserAvatar storage avatar = profile.userAvatar;
        UserStats storage stats = profile.userStats;

        userDetails[0] = profile.handle;
        userDetails[1] = KUtils.toString(stats.postCount);
        userDetails[2] = KUtils.toString(stats.followingCount);
        userDetails[3] = KUtils.toString(stats.followerCount);
        userDetails[4] = KUtils.toString(uint256(profile.verified));
        userDetails[5] = avatar.avatar;
        userDetails[6] = avatar.metadata;
        userDetails[7] = KUtils.addressToString(avatar.contractAddress);
        userDetails[8] = KUtils.toString(avatar.networkID);
        userDetails[9] = KUtils.toString(avatar.tokenID);
        userDetails[10] = profile.uri;
        userDetails[11] = profile.bio;
        userDetails[12] = profile.location;
        userDetails[13] = KUtils.toString(profile.joinBlock);
        userDetails[14] = KUtils.toString(profile.joinTime);
        userDetails[15] = KUtils.toString(profile.followLimit);
        userDetails[16] = KUtils.toString(stats.tipsReceived);
        userDetails[17] = KUtils.toString(stats.tipsSent);
        userDetails[18] = KUtils.toString(profile.groupID);

        return userDetails;
    }

    /**
    * @dev Returns a contract hook address that a user setup
    * @param usrAddress : the address to retrieve the contract hook address for
    * @return address: a contract address to call in hook (0x0 for empty)
    */
    function getContractHook(address usrAddress) public view whenNotPaused returns(address){
        return usrProfileMap[usrAddress].contractHook;
    }

    /**
    * @dev Sets a contract address for a contractHook to all posts that you are tagged in
    * @param contractAddress : the address to set the contract hook address for. Send 0x0 to erase it.
    * @param groupID : Group to attached the Contract Hook to. 0 = attach to msg.sender
    */
    function setContractHook(address contractAddress, uint256 groupID) public whenNotPaused nonReentrant {

        // Set the address to attach the contract hook to
        address hookTo = msg.sender;

        // See if we're attaching the hook to a group
        if (groupID > 0){
            // Update the address to hook to group address
            hookTo = Groups.getGroupAddressFromID(groupID);

            // Make sure the requester is the owner of the group
            require(Groups.getOwnerOfGroupByAddress(hookTo) == msg.sender, "You are not the owner of the group");
        }

        // If we have an address, run a quick sanity check before saving
        require (contractAddress != address(0), "Invalid contract address");

        // Hook up the interface to the contract
        ContractHook = IContractHook(contractAddress);

        IContractHook.MsgData memory newMsgCH;

        newMsgCH.msgID = 0;
        newMsgCH.postedBy = [msg.sender, address(0)];
        newMsgCH.message = "Test";
        newMsgCH.paid = 0;
        newMsgCH.hashtags = new string[](0);
        newMsgCH.taggedAccounts = new address[](0);
        newMsgCH.asGroup = 0;
        newMsgCH.inGroups = new uint256[](0);
        newMsgCH.uri = "http://www.KUTHULU.xyz";
        newMsgCH.commentLevel = 0;
        newMsgCH.isCommentOf = 0;
        newMsgCH.isRepostOf = 0;
        newMsgCH.msgStats.postByContract = 0;
        newMsgCH.msgStats.time = block.timestamp;
        newMsgCH.msgStats.block = block.number;
        newMsgCH.msgStats.tipsReceived = 0;

        // Make sure we have a valid address
        require(ContractHook.KuthuluHook(newMsgCH) == true, "Contract not setup for hook properly");

        // Reset
        delete ContractHook;

        // Save the contract address
        usrProfileMap[hookTo].contractHook = contractAddress;
    }


    /*

    PRIVATE FUNCTIONS

    */

    // Save all the NFT data for an avatar
    function setNFTAvatarPriv(address profileAddress, string memory metadata, address _nftContract, uint256 tokenId, uint256 _networkID) private {
        // Save the token metadata
        usrProfileMap[profileAddress].userAvatar.metadata = metadata;

        // Save the token contract
        usrProfileMap[profileAddress].userAvatar.contractAddress = _nftContract;

        // Save the token ID
        usrProfileMap[profileAddress].userAvatar.tokenID = tokenId;

        // Save contract network
        usrProfileMap[profileAddress].userAvatar.networkID = _networkID;

        // If setting an NFT as the avatar, wipe out the URI for it
        if (tokenId > 0){
            usrProfileMap[profileAddress].userAvatar.avatar = '';
        }

        // Emit to logs for external use
        emit logSaveNFTAvatar(profileAddress, metadata, _nftContract, tokenId, _networkID);
    }

    // Setup a new user profile
    function joinUser(address newUser) private {
        usrProfileMap[newUser].followLimit = maxFollowing;
        usrProfileMap[newUser].joinBlock = block.number;
        usrProfileMap[newUser].joinTime = block.timestamp;

        // Update the joined user count
        joinedUserCount++;

        // Emit to the logs for external reference
        emit logNewUser(msg.sender);

        // Add them to the bucket
        Followers.addFollower(newUser, newUser);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}