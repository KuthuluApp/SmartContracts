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

    @title Kultists
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

import "./interfaces/INFT.sol";


contract Kultists is ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Trusted Contracts
    mapping (address => bool) public trustedContracts;

    // Max ReRolls allowed
    uint256 public maxReRolls;

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
    string public kultistBaseURI;

    // Keep track of the amount minted
    uint256 public minted;

    // Token details for metadata updates
    struct TokenDetails {
        string baseURI;
        string tokenName;
        bool summoned;
        bool revealed;
        uint256 reRolls;
    }

    // Metadata for all tokens (tokenID => Metadata)
    mapping (uint256 => TokenDetails) tokenMetadata;

    // Whitelist details
    struct WhiteList {
        bool isOnList;
        bool isOnWhaleList;
        uint256 amountMinted;
    }

    // Mapping of whitelist for Pre-Sale
    mapping (address => WhiteList) whiteList;

    // Mapping of user address to re-rolls left
    mapping (address => uint256) reRolls;

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

    // Build interface to link to NFT contract
    INFT NFT;

    // OpenSea approval contract
    address public osAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 cost, uint256 max, uint256 maxWhale, uint256 maxWL, address kuthuluContract, address userProfiles, address amuletsContract, string calldata _startBaseURI) initializer public {
        __ERC721_init("Kultists of KUTHULU", "KULT");
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

        // Set max ReRolls
        maxReRolls = 5;

        // Allow KUTHULU to call this contract
        trustedContracts[kuthuluContract] = true;

        // Allow the User Profiles KUTHULU contract to call to test hook
        trustedContracts[userProfiles] = true;

        // Setup link to the NFT contract
        NFT = INFT(amuletsContract);

        // Set the initial address to OpenSea
        osAddress = address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE);

        // Set the Kultists Initial Base URI
        kultistBaseURI = _startBaseURI;
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

    function setVaultAddress(address _newVault) public onlyAdmins{
        vaultAddress = _newVault;
    }

    // openMint Levels
    // 0 = Closed
    // 1 = Whale White List
    // 2 = White List
    // 3 = Open Mint
    function updateDetails(uint256 amuletCost, uint256 max, uint256 _openMint, uint256 _maxReRolls, address _osAddress, string calldata _kultistBaseURI) public onlyAdmins {
        costToMint = amuletCost;
        maxSupply = max;
        openMint = _openMint;
        maxReRolls = _maxReRolls;

        // Update the OpenSea address
        osAddress = _osAddress;

        // Update the BASE URI for Kultists
        kultistBaseURI = _kultistBaseURI;
    }

    function updateMetadata(uint256 tokenID, string calldata baseURI, string calldata name, bool summoned, bool revealed) public onlyAdmins {
        // Update to the new base URI
        tokenMetadata[tokenID].baseURI = baseURI;

        // Set the name of the token
        tokenMetadata[tokenID].tokenName = name;

        // Set the status of summoned
        tokenMetadata[tokenID].summoned = summoned;

        // Set the status of revealed
        tokenMetadata[tokenID].revealed = revealed;
    }

    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable(vaultAddress), address(this).balance);
    }

    function addReRoll(address user, uint256 amount) public onlyAdmins {
        reRolls[user] += amount;
    }

    function addToWhiteList(address[] calldata users, bool isWhale) public onlyAdmins {

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

    /**
    * @dev Use a re-roll to reveal a different Kultist and take away one re-roll
    */
    function useReRoll(address _thisOwner, uint256 tokenID) public onlyAdmins whenNotPaused {

        // Ensure they have reRolls to use
        require(reRolls[_thisOwner] > 0, "They don't have any re-rolls left");

        // Check we're under the limit of reRolls for this token
        require(tokenMetadata[tokenID].reRolls < maxReRolls, "Token at max ReRoll");

        // Subtract a reRoll from the owner
        reRolls[_thisOwner]--;

        // Update the amount of reRolls this token has had
        tokenMetadata[tokenID].reRolls++;
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
                    mintKultist(newMsg.postedBy[0]);
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
    * @dev Lookup the number of re-rolls that a user has
    * @param user : The wallet address of the user to lookup
    * @return uint256 : The number of re-rolls a wallet has when minting a Kultist
    */
    function getReRollCount(address user) public view whenNotPaused returns (uint256) {
        return reRolls[user];
    }

    /**
    * @dev Get the token data on it's reveal process
    * @param tokenID : The ID of the token to lookup
    * @return uint256[] : Will return the details of the token
    * @dev 0 = Is Summoned
    * @dev 0 = Is Revealed
    * @dev 0 = ReRoll Count
    */
    function getTokenDetails(uint256 tokenID) public view whenNotPaused returns (uint256[] memory) {

        // Initialize the return array of badge details
        uint256[] memory tokenDetails = new uint256[](3);

        tokenDetails[0] = tokenMetadata[tokenID].summoned ? 1 : 0;
        tokenDetails[1] = tokenMetadata[tokenID].revealed ? 1 : 0;
        tokenDetails[2] = tokenMetadata[tokenID].reRolls;

        return tokenDetails;
    }


    /**
    * @dev Get the token metadata
    * @param _tokenID : the unique Group ID
    * @return uint256 : the unique ID of the group
    */
    function tokenURI(uint256 _tokenID) public view virtual override(ERC721Upgradeable) returns (string memory) {

        // Check for revealed status to determine which metadata to show
        if (tokenMetadata[_tokenID].revealed || tokenMetadata[_tokenID].summoned){
            // Return metadata for revealed token
            return string(
                abi.encodePacked(
                    tokenMetadata[_tokenID].baseURI,
                    tokenMetadata[_tokenID].tokenName,
                    ".json"
                )
            );
        } else {
            // Return metadata for unrevealed token
            return string(
                abi.encodePacked(
                    tokenMetadata[_tokenID].baseURI,
                    StringsUpgradeable.toString(_tokenID),
                    ".json"
                )
            );
        }
    }


    /*

    PRIVATE FUNCTIONS

    */


    /**
    * @dev Mint an Kultist
    * @dev openMint Levels
    * @dev 0 = Closed
    * @dev 1 = Whale White List
    * @dev 2 = White List
    * @dev 3 = Open Mint
    */
    function mintKultist(address mintTo) private whenNotPaused nonReentrant {

        // Check that they have at least one Amulet
        require(NFT.balanceOf(mintTo) > 0, "You must own an Amulet to mint a Kultist");

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

        // Set the tokenMetadata
        tokenMetadata[minted].baseURI = kultistBaseURI;

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
            uint256 whalesLen = whaleWatcher[tokensOwnedBefore].length;
            for (uint i=0; i < whalesLen; i++) {
                if (whaleWatcher[tokensOwnedBefore][i] == tokenOwner){
                    place = i;
                    break;
                }
            }

            // Swap the last entry with this one
            whaleWatcher[tokensOwnedBefore][place] = whaleWatcher[tokensOwnedBefore][whalesLen-1];

            // Remove the last element
            whaleWatcher[tokensOwnedBefore].pop();

            // If we just wiped out a level, remove it from the whaleSizes
            if (whalesLen == 0){
                // Remove the level from the list
                place = 0;
                for (uint i=0; i < whaleSizes.length; i++) {
                    if (whaleSizes[i] == tokensOwnedBefore){
                        place = i;
                        break;
                    }
                }

                // Swap the last entry with this one
                whaleSizes[place] = whaleSizes[whaleSizes.length-1];

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

        // If it's not a mint call
        if (from != address(0)){
            // Update whale list for previous owner
            tokensOwned = balanceOf(from);
            updateWhales(from, tokensOwned, tokensOwned + 1);
        }

        // If it's not a burn call
        if (to != address(0)){
            // Update whale list for current owner
            tokensOwned = balanceOf(to);
            updateWhales(to, tokensOwned, tokensOwned - 1);
        }

        super._afterTokenTransfer(from, to, tokenId, batchAmount);
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


