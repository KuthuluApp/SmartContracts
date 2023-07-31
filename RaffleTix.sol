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

    @title RaffleTix
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


contract RaffleTix is ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Cost to mint a new Token
    uint256 public costToMint;

    // Vault address to receive funds to
    address public vaultAddress;

    // Base URI for the Tix
    string public tixBaseURI;

    // Keep track of the amount minted
    uint256 public minted;

    // Set the max amount to claim at once
    uint256 maxToClaim;

    // Mapping of address to amount of Tix To Claim
    mapping (address => uint256) tixToClaim;

    // Used for whale watching on chain
    // Mapping of total amount owned to an array of address that own that amount
    mapping (uint256 => address[]) whaleWatcher;
    uint256[] public whaleSizes;

    // Details for Multi Sig Locking
    struct MultiSig {
        address lockedBy;
        bool isLocked;
    }

    // Mapping of NFTs to Multi Sig Lock Details
    mapping (uint256 => MultiSig) private multiSigLock;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 cost) initializer public {
        __ERC721_init("KUTHULU Raffle Tickets", "KTIX");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set the initial vault owner
        vaultAddress = msg.sender;

        // Set the cost to mint an amulet
        costToMint = cost;

        // Initialize minted to 0
        minted = 0;

        // Set max to claim to 100 to start
        maxToClaim = 100;

        tixBaseURI = 'ipfs://QmX3KSiTP7Jxd1o79KD1KvLwyKrPTFUdgdndDPJv9aJjnm';
    }


    /*

    EVENTS

    */

    event logMintToken(address indexed sender, uint256 tokenId);
    event logClaimToken(address indexed sender, uint256 tokenId);
    event logUpdateClaimable(address[] indexed users, uint256 indexed quantity);
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

    function setVaultAddress(address _newVault) public onlyOwner{
        vaultAddress = _newVault;
    }

    function updateDetails(uint256 tixCost, uint256 _maxToClaim, string calldata _tixBaseURI) public onlyAdmins {
        costToMint = tixCost;
        maxToClaim = _maxToClaim;
        tixBaseURI = _tixBaseURI;
    }

    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable(vaultAddress), address(this).balance);
    }

    function awardTix(address[] calldata users, uint256 quantity) public onlyAdmins whenNotPaused {

        for (uint i=0; i < users.length; i++) {
            tixToClaim[users[i]] += quantity;
        }

        // Emit to the logs for external reference
        emit logUpdateClaimable(users, quantity);
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Mint yourself Raffle Tix (up to 10 at a time)
    * @param quantity : The amount of Raffle Tix you want to acquire
    */
    function mintTix(uint256 quantity) public payable whenNotPaused nonReentrant {

        // No more than 10 at a time to prevent spamming
        require(quantity <= 10, "Can only mint 10 at a time");

        // Transfer the Payment Token to the contract
        AddressUpgradeable.sendValue(payable(vaultAddress), (costToMint * quantity));

        // Mint the token
        for (uint i=0; i < quantity; i++) {
            // Increment
            minted++;

            // Emit to the logs for external reference
            emit logMintToken(msg.sender, minted);

            // Mint the Tix
            _safeMint(msg.sender, minted);
        }
    }

    /**
    * @dev Claim up to 10 Raffle Tix that you have been awarded
    */
    function claimTix() public payable whenNotPaused nonReentrant {

        // Check to make sure they have tix to claim
        require(tixToClaim[msg.sender] > 0, "You don't have any Raffle Tix to claim");

        // Mint the token
        uint256 tixLeft = tixToClaim[msg.sender];
        for (uint i=0; i < tixLeft && i < maxToClaim; i++) {
            // Increment
            minted++;

            // Decrement
            tixToClaim[msg.sender]--;

            // Emit to the logs for external reference
            emit logClaimToken(msg.sender, minted);

            // Mint the Tix
            _safeMint(msg.sender, minted);
        }
    }


    /**
    * @dev Get the amount of Raffle Tix that a user can claim
    * @param : user : Address to check how many tix they have
    * @return uint256 : The number of Raffle tix that address can claim
    */
    function checkTix(address user) public view whenNotPaused returns (uint256) {
        return tixToClaim[user];
    }


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
                tixBaseURI
            )
        );
    }


    /*

    PRIVATE FUNCTIONS

    */


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
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
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


