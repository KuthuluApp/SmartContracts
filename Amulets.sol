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

    @title Amulets
    v0.2

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

import "./interfaces/IBadges.sol";


contract Amulets is ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Trusted Contracts
    mapping (address => bool) public trustedContracts;

    // Cost to mint a new Token
    uint256 public costToMint;

    // Quantity to mint of Token
    uint256 public maxSupply;

    // Quantity allowed to mint by whitelist whales
    uint256 public maxWhaleList;

    // Quantity allowed to mint by whitelist
    uint256 public maxWhiteList;

    // Vault address to receive funds to
    address public vaultAddress;

    // Base URI for the Amulets
    string public amuletsBaseURI;

    // Keep track of the amount minted
    uint256 public minted;

    struct AmuletDetails {
        uint256 amuletType;
        uint256 badgeID;
    }

    // Mapping for Amulet ID => Amulet Type post-reveal
    mapping(uint256 => AmuletDetails) amuletDetails;

    // Whitelist details
    struct WhiteList {
        bool isOnList;
        bool isOnWhaleList;
        uint256 amountMinted;
    }

    // Mapping of whitelist for Pre-Sale
    mapping (address => WhiteList) whiteList;

    // Used for whale watching on chain
    // Mapping of total amount owned to an array of address that own that amount
    mapping (uint256 => address[]) whaleWatcher;
    uint256[] public whaleSizes;

    // openMint Levels
    // 0 = Closed
    // 1 = Whale White List
    // 2 = White List
    // 3 = Open Mint
    uint256 public openMint;

    // Details for Multi Sig Locking
    struct MultiSig {
        address lockedBy;
        bool isLocked;
    }

    // Mapping of NFTs to Multi Sig Lock Details
    mapping (uint256 => MultiSig) private multiSigLock;


    // Message Stats
    struct MsgStats {
        int likes;
        int comments;
        int reposts;
        uint256 tipsReceived;
        address tipContract;
        uint256 tipERC20Amount;
        uint postByContract;
        uint256 time;
        uint256 block;
    }

    // The Message data struct
    struct MsgData {
        uint msgID;
        address[2] postedBy;
        string message;
        uint256 paid;      // May not need this
        string[] hashtags;
        address[] taggedAccounts;
        uint256 asGroup;
        uint256[] inGroups;
        string uri;
        uint256 commentLevel;
        uint256 isCommentOf;
        uint256 isRepostOf;
        MsgStats msgStats;
    }

    // Link to the Badges Contracts
    IBadges public Badges;

    // OpenSea approval contract
    address public osAddress;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 cost, uint256 max, uint256 maxWhale, uint256 maxWL, address kuthuluContract, address userProfiles) initializer public {
        __ERC721_init("Amulets of KUTHULU", "AMULET");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set the initial vault owner
        vaultAddress = msg.sender;

        // Set the cost to mint an amulet
        costToMint = cost;

        // Set the quantity available to mint
        maxSupply = max;

        // Quantity allowed to mint by whitelist whales
        maxWhaleList = maxWhale;

        // Quantity allowed to mint by whitelist
        maxWhiteList = maxWL;

        // Initialize minted to 0
        minted = 0;

        // Set openMint to closed.
        openMint = 0;

        // Allow KUTHULU to call this contract
        trustedContracts[kuthuluContract] = true;

        // Allow the User Profiles KUTHULU contract to call to test hook
        trustedContracts[userProfiles] = true;

        // Set the initial address to OpenSea
        osAddress = address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE);
    }


    /*

    EVENTS

    */

    event logMintToken(address indexed sender, uint256 tokenId);
    event logWhiteList(address[] indexed users, bool indexed isWhale);
    event logTokenLocked(address indexed multiSig, uint256 indexed tokenId);
    event logTokenUnlocked(address indexed sender, uint256 indexed tokenId);


    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier onlyTrustedContracts() {
        require(trustedContracts[msg.sender], "Only trusted contracts can call this function.");
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

    function updateTrustedContract(address contractAddress, bool status) public onlyAdmins {
        trustedContracts[contractAddress] = status;
    }

    function updateContracts(address _badges) public onlyAdmins {
        // Update the Badges address
        Badges = IBadges(_badges);
    }

    function setVaultAddress(address _newVault) public onlyAdmins{
        vaultAddress = _newVault;
    }

    // openMint Levels
    // 0 = Closed
    // 1 = Whale White List
    // 2 = White List
    // 3 = Open Mint
    function updateDetails(uint256 amuletCost, uint256 max, uint256 _openMint, string calldata _amuletsBaseURI, address _osAddress) public onlyAdmins {
        costToMint = amuletCost;
        maxSupply = max;
        openMint = _openMint;
        amuletsBaseURI = _amuletsBaseURI;

        // Update the OpenSea address
        osAddress = _osAddress;
    }

    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable(vaultAddress), address(this).balance);
    }

    function addToWhiteList(address[] calldata users, bool isWhale) public onlyAdmins whenNotPaused {

        for (uint i=0; i < users.length; i++) {
            if (isWhale){
                whiteList[users[i]].isOnWhaleList = true;
            } else {
                whiteList[users[i]].isOnList = true;
            }
        }

        // Emit to the logs for external reference
        emit logWhiteList(users, isWhale);
    }

    function setAmuletType(uint256 amuletID, uint256 amuletType, uint256 badgeID) public onlyAdmins {
        amuletDetails[amuletID].amuletType = amuletType;
        amuletDetails[amuletID].badgeID = badgeID;
    }


    /*

    KUTHULU FUNCTIONS

    */

    function KuthuluHook(MsgData memory newMsg) public onlyTrustedContracts returns (bool) {

        // Do this if it's a real post
        if (newMsg.msgID != 0){
            if (newMsg.taggedAccounts.length == 1 || (newMsg.taggedAccounts.length == 2 && newMsg.msgStats.tipERC20Amount > 0)){
                if (newMsg.taggedAccounts[0] == vaultAddress && newMsg.msgStats.tipsReceived == costToMint){
                    // Mint the NFT to the original sender
                    mintAmulet(newMsg.postedBy[0]);
                }
            }
        }

        return true;
    }


    /*

    PUBLIC FUNCTIONS

    */


    /**
    * @dev Get Whale Sizes List
    * @return address[] : List of token amounts that are owned by an address
    */
    function getWhaleSizes() public view whenNotPaused returns (uint256[] memory) {
        return whaleSizes;
    }


    /**
    * @dev Get Whale Address(es) by level
    * @param level : The amount of tokens owned by a single address
    * @return address[] : List of addresses that own that many tokens
    */
    function getWhales(uint256 level) public view whenNotPaused returns (address[] memory) {
        return whaleWatcher[level];
    }


    /**
    * @dev Get the token metadata
    * @param _tokenID : the unique Group ID
    * @return uint256 : the unique ID of the group
    */
    function tokenURI(uint256 _tokenID) public view virtual override(ERC721Upgradeable) returns (string memory) {
        return string(
            abi.encodePacked(
                amuletsBaseURI,
                StringsUpgradeable.toString(_tokenID),
                ".json"
            )
        );
    }

    /**
    * @dev Get the type of amulet a token is by ID
    * @param amuletID : the amulet token ID
    * @return uint256 : the amulet type
    */
    function getAmuletType(uint256 amuletID) public view returns (uint256[] memory) {
        uint256[] memory badgeDetails = new uint256[](2);

        badgeDetails[0] = amuletDetails[amuletID].badgeID;
        badgeDetails[1] = amuletDetails[amuletID].amuletType;

        return badgeDetails;
    }


    function kuthuluVerifyBadgeType(uint256 badgeTypeID, address owner) public view returns (bool) {
        for (uint i=0; i < balanceOf(owner); i++) {
            if (getAmuletType(tokenOfOwnerByIndex(owner, i))[1] == badgeTypeID){
                return true;
            }
        }
        return false;
    }


    /*

    PRIVATE FUNCTIONS

    */

    /**
    * @dev Mint an Amulet with a specific ID
    * @dev openMint Levels
    * @dev 0 = Closed
    * @dev 1 = Whale White List
    * @dev 2 = White List
    * @dev 3 = Open Mint
    */
    function mintAmulet(address mintTo) private whenNotPaused nonReentrant {

        if (openMint == 1){
            require(whiteList[mintTo].isOnWhaleList == true, "Open to Whitelists Whales Only");
            require(whiteList[mintTo].amountMinted < maxWhaleList, "Max mint for Whitelist Whales");
        } else if (openMint == 2){
            require(whiteList[mintTo].isOnList == true || whiteList[mintTo].isOnWhaleList == true, "Open to All Whitelisters");
            require(
                (whiteList[mintTo].amountMinted < maxWhaleList && whiteList[mintTo].isOnWhaleList) ||
                (whiteList[mintTo].amountMinted < maxWhiteList && whiteList[mintTo].isOnList)
                , "Max mint for whitelist");
        } else {
            require(openMint == 3, "Public Minting Not Open");
        }

        // All tokens minted
        require(minted + 1 <= maxSupply, "All tokens minted");

        // Increment
        minted++;
        whiteList[mintTo].amountMinted++;

        // Emit to the logs for external reference
        emit logMintToken(mintTo, minted);

        // Mint the token
        _safeMint(mintTo, minted);
    }



    // Update the whales mapping and array for top holders
    function updateWhales(address tokenOwner, uint256 tokensOwned, uint256 tokensOwnedBefore) private whenNotPaused {

        // Remove them from previous slot if they had a more than zero
        if (tokensOwnedBefore > 0){

            // Remove the address from level
            uint256 place = 0;
            for (uint i=0; i < whaleWatcher[tokensOwnedBefore].length; i++) {
                if (whaleWatcher[tokensOwnedBefore][i] == tokenOwner){
                    place = i;
                    break;
                }
            }

            // Swap the last entry with this one
            whaleWatcher[tokensOwnedBefore][place] = whaleWatcher[tokensOwnedBefore][whaleWatcher[tokensOwnedBefore].length-1];

            // Remove the last element
            whaleWatcher[tokensOwnedBefore].pop();

            // If we just wiped out a level, remove it from the whaleSizes
            if (whaleWatcher[tokensOwnedBefore].length == 0){
                // Remove the level from the list
                place = 0;
                uint256 whaleSizeLen = whaleSizes.length;
                for (uint i=0; i < whaleSizeLen; i++) {
                    if (whaleSizes[i] == tokensOwnedBefore){
                        place = i;
                        break;
                    }
                }

                // Swap the last entry with this one
                whaleSizes[place] = whaleSizes[whaleSizeLen-1];

                // Remove the last element
                whaleSizes.pop();
            }
        }

        // Add them to their new slot
        whaleWatcher[tokensOwned].push(tokenOwner);

        // If they have created a new level, add it to the list
        if (whaleWatcher[tokensOwned].length == 1){
            whaleSizes.push(tokensOwned);
        }
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

    OVERRIDE FUNCTIONS

    */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchAmount) internal whenNotPaused override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {

        // Make sure MultiSig Lock is off. Will be able to be set by new owner
        require(multiSigLock[tokenId].isLocked == false, "Token Locked with MultiSig");

        super._beforeTokenTransfer(from, to, tokenId, batchAmount);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchAmount) internal whenNotPaused override(ERC721Upgradeable) {

        uint256 tokensOwned = 0;
        uint256 badgeID = amuletDetails[tokenId].badgeID;
        bool lastBadgeType = true;

        // If it's not a mint call
        if (from != address(0)){
            // Update whale list for previous owner
            tokensOwned = balanceOf(from);
            updateWhales(from, tokensOwned, tokensOwned + 1);

            // See if this is the last badge of that type that they own
            for (uint i=0; i < tokensOwned; i++) {
                if (amuletDetails[tokenOfOwnerByIndex(from, i)].badgeID == badgeID){
                    lastBadgeType = false;
                }
            }

            // Remove the badge from the previous owner
            if (lastBadgeType){
                Badges.removeBadgeFromUser(from, badgeID);
            }
        }

        // If it's not a burn call
        if (to != address(0)){
            // Update whale list for current owner
            tokensOwned = balanceOf(to);
            updateWhales(to, tokensOwned, tokensOwned - 1);

            // Add the badge to the new owner
            Badges.addBadgeToUser(to, badgeID);
        }

        super._afterTokenTransfer(from, to, tokenId, batchAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override(IERC721Upgradeable, ERC721Upgradeable) view returns (bool isOperator) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == osAddress) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721Upgradeable.isApprovedForAll(_owner, _operator);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}


