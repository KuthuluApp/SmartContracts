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

    @title GroupTokens
    v0.3

    KUTHULU : https://www.KUTHULU.xyz
    A project by DOOM Labs (https://DOOMLabs.io)
    The first truly decentralized social framework.
    Built for others to build upon and share freedom of expression.
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/IUserProfiles.sol";
import "./interfaces/IGroupMetadata.sol";

contract GroupTokens is ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    uint256 public lastMintBlock;

    // Cost to mint a new group
    uint256[4] public costToMintTier;

    address public vaultAddress;

    // Maximum length for a group name
    uint256 public maxGroupNameSize;

    // Details for Multi Sig Locking
    struct MultiSig {
        address lockedBy;
        bool isLocked;
    }

    // Mapping of NFTs to Multi Sig Lock Details
    mapping (uint256 => MultiSig) private multiSigLock;

    // Link the KUtils
    IKUtils public KUtils;

    // Link the Groups
    IGroups public Groups;

    // Link the UserProfiles
    IUserProfiles public UserProfiles;

    // Link the GroupMetadata
    IGroupMetadata public GroupMetadata;

    // OpenSea approval contract
    address public osAddress;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _cost1, uint256 _cost2, uint256 _cost3, uint256 _cost4, uint256 _maxGroupNameSize) initializer public {
        __ERC721_init("KUTHULU Spaces", "SPACE");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set the initial vault owner
        vaultAddress = msg.sender;

        // Set the cost to mint a group per tier
        costToMintTier = [_cost1, _cost2, _cost3, _cost4];

        lastMintBlock = 0;

        maxGroupNameSize = _maxGroupNameSize;

        osAddress = address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE);
    }



    /*

    EVENTS

    */

    event logMintGroup(uint256 indexed groupID, string indexed groupName, address indexed owner);
    event logTokenLocked(address indexed multiSig, uint256 indexed tokenId);
    event logTokenUnlocked(address indexed sender, uint256 indexed tokenId);


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

    function updateContracts(address _kutils, address _groupMemberships, address _userProfiles, address _groupMetadata) public onlyAdmins {
        // Update the KUtils contract address
        KUtils = IKUtils(_kutils);

        // Update the Groups contract address
        Groups = IGroups(_groupMemberships);

        // Update the UserProfiles contract address
        UserProfiles = IUserProfiles(_userProfiles);

        // Update the GroupTokenMetadata contract address
        GroupMetadata = IGroupMetadata(_groupMetadata);
    }

    function updateDetails(uint256 tier1, uint256 tier2, uint256 tier3, uint256 tier4, uint256 _maxGroupNameSize, address _osAddress) public onlyAdmins {
        costToMintTier = [tier1, tier2, tier3, tier4];
        maxGroupNameSize = _maxGroupNameSize;

        // Update the OpenSea address
        osAddress = _osAddress;
    }

    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable(vaultAddress), address(this).balance);
    }

    /**
    * @dev Update the stored group metadata in the userprofile
    * @param groupID : the unique Group ID
    */
    function adminUpdateGroupMetadata(uint256 groupID) public whenNotPaused onlyAdmins {
        updateGroupMetadata(groupID);
    }



    /*

    Public Functions

    */

    /**
    * @dev Get a group ID from a group name.
    * @param groupName : Name of the group
    * @return uint256 : the unique ID of the group
    */
    function getGroupID(string calldata groupName) public view whenNotPaused returns (uint256){
        bytes32 groupBytes = keccak256(bytes(KUtils._toLower(groupName)));
        return uint256(groupBytes);
    }

    /**
    * @dev Checks the Groups contra
    ct to see if a group is available to mint
    * @param groupName : Name of the group
    * @return bool : True = Group is available to mint / False = Group is already minted
    */
    function isGroupAvailable(string calldata groupName) public view whenNotPaused returns (bool){
        return Groups.isGroupAvailable(groupName);
    }

    /**
    * @dev Mint a group / Space
    * @param groupName : Name of the group
    */
    function mintGroup(string calldata groupName) public payable whenNotPaused nonReentrant {

        // Get the character count for reuse (uses high gas version for exact count)
        uint256 groupNameLen = KUtils.strlen(groupName);

        if (groupNameLen >= 7) {
            // Don't allow KUTHULU prefixes as a security measure unless minted by admins
            require(!KUtils.stringsEqual("kuthulu", substring(KUtils._toLower(groupName), 0, 7)) || admins[msg.sender], "KUTHULU Prefix not allowed");
        }

        // Check format of the group name
        require(groupNameLen >= 3 && groupNameLen <= 100, "Group name must be between 3 and 100 characters");

        // Check that it only has allowed characters or admin override
        require(KUtils.isValidGroupString(groupName), "Group name has invalid characters.");

        // Check that the group name is available
        require(Groups.isGroupAvailable(groupName), "That group name already exists");

        // Transfer the Payment Token to the contract
        uint256 requiredPayment;
        if (groupNameLen == 3) {
            requiredPayment = costToMintTier[0];
        } else if (groupNameLen <= 5) {
            requiredPayment = costToMintTier[1];
        } else if (groupNameLen <= 8) {
            requiredPayment = costToMintTier[2];
        } else {
            requiredPayment = costToMintTier[3];
        }

        // Admins mint
        if (admins[msg.sender]){
            requiredPayment = 0;
        }

        // Check that only 1 group minted per block to ensure uniqueness of generated address
        require(block.number != lastMintBlock, "Name is good, but need to wait a block for uniqueness");

        // Update the last block minted at
        lastMintBlock = block.number;

        // Generate the group ID from the name
        uint256 groupID = getGroupID(groupName);

        // Set them to the owner & first member
        Groups.setInitialDetails(groupID, msg.sender, groupName, address(this));

        // Save the group metadata to the group profile
        updateGroupMetadata(groupID);

        // Emit to the logs for external reference
        emit logMintGroup(groupID, groupName, msg.sender);

        // Send the funds to the vault for minting if not an admin
        if (!admins[msg.sender]){
            AddressUpgradeable.sendValue(payable(vaultAddress), requiredPayment);
        }

        // Mint the token
        _safeMint(msg.sender, groupID);
    }


    /**
    * @dev Get the token metadata
    * @param _tokenID : the unique Group ID
    * @return uint256 : the unique ID of the group
    */
    function tokenURI(uint256 _tokenID) public view virtual override(ERC721Upgradeable) returns (string memory) {
        return GroupMetadata.getMetadata(_tokenID);
    }


    /*

    MULTI-SIG FUNCTIONS

    */

    /**
    * @dev Add MultiSig Address Locking for Transfers
    * @dev After adding, the address used for multi-sig must call activateMultiSigLock() to activate it
    * @param tokenID : The token ID to lock with the multi-sig address
    * @param multiSigAddress : The wallet address to be used to lock the token with
    */
    function addMultiSigLock(uint256 tokenID, address multiSigAddress) public {

        // Make sure they're the owner
        require(ownerOf(tokenID) == msg.sender, "Not owner");

        // Make sure it's not locked yet
        require(multiSigLock[tokenID].isLocked == false, "Error Locking");

        // Lock the token
        multiSigLock[tokenID].lockedBy = multiSigAddress;
    }


    /**
    * @dev Activate Multi Sig lock from address added to token
    * @dev This is done to ensure Multi Sig Address is correct before locking
    * @param tokenID : The token ID to lock with the multi-sig address
    */
    function activateMultiSigLock(uint256 tokenID) public {
        // Make sure only the locking address can activate
        require(multiSigLock[tokenID].lockedBy == msg.sender && !multiSigLock[tokenID].isLocked, "Not Multi-Sig Locking Address or already locked");

        // Lock the token
        multiSigLock[tokenID].isLocked = true;

        // Emit to the logs for external reference
        emit logTokenLocked(msg.sender, tokenID);
    }


    /**
    * @dev Remove MultiSig Lock From Token Transfer. Must be called by the address that was setup to lock the token
    * @param tokenID : The token ID to unlock with the multi-sig address
    */
    function removeMultiSigLock(uint256 tokenID) public {

        // Make sure they're the owner
        require(multiSigLock[tokenID].lockedBy == msg.sender && multiSigLock[tokenID].isLocked, "Not MultiSig owner or not locked");

        // Unlock the token
        multiSigLock[tokenID].isLocked = false;
        multiSigLock[tokenID].lockedBy = address(0);

        // Emit to the logs for external reference
        emit logTokenUnlocked(msg.sender, tokenID);
    }


    /**
    * @dev Check if token is locked. Returns 0x0 if not locked.
    * @param tokenID : The token ID to return the multi-sig address for
    * @return address : The wallet address used to lock the token from transfer
    */
    function getMultiSigAddress(uint256 tokenID) public view returns (address) {
        // Show the Multi-Sig Address
        return multiSigLock[tokenID].lockedBy;
    }

    /**
    * @dev Check if token is locked.
    * @param tokenID : The token ID to return the multi-sig address for
    * @return bool[2]
    * @dev 0 = True / False if locked
    * @dev 1 = True / False if Locking Address Added
    */
    function isMultiSigLocked(uint256 tokenID) public view returns (bool[2] memory) {
        bool isAddrAdded = false;
        if (multiSigLock[tokenID].lockedBy != address(0)){
            isAddrAdded = true;
        }
        return [multiSigLock[tokenID].isLocked, isAddrAdded];
    }


    /*

    PRIVATE FUNCTIONS

    */

    function updateGroupMetadata(uint256 groupID) private {

        // Get the address of the new group
        address groupAddress = Groups.getGroupAddressFromID(groupID);

        // Update group token metadata
        UserProfiles.updateMetadata(groupAddress, tokenURI(groupID));
    }

    function substring(string memory str, uint startIndex, uint endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }


    /*

    OVERRIDE FUNCTIONS

    */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchAmount) internal whenNotPaused override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {

        // Make sure MultiSig Lock is off. Will be able to be set by new owner
        require(multiSigLock[tokenId].isLocked == false, "Token Locked with MultiSig");

        super._beforeTokenTransfer(from, to, tokenId, batchAmount);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchAmount) internal whenNotPaused override(ERC721Upgradeable) {
        super._afterTokenTransfer(from, to, tokenId, batchAmount);

        // Update the group ownership
        Groups.onTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(
        address _thisOwner,
        address _operator
    ) public override(IERC721Upgradeable, ERC721Upgradeable) view returns (bool isOperator) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == osAddress) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721Upgradeable.isApprovedForAll(_thisOwner, _operator);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}


