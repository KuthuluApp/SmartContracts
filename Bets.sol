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

    @title Bet
    v0.1

    BET : https://www.KUTHULU.xyz/?group=Bet
    A project by DOOM Labs (https://DOOMLabs.io)
    The first decentralized betting platform on KUTHULU
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IBetMetadata.sol";
import "./interfaces/IKuthulu.sol";
import "./KUTHULU.sol";

contract Bet is ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Trusted Contracts
    mapping (address => bool) public trustedContracts;

    // Vault address to receive funds to
    address public vaultAddress;

    // Bet address to place bets to for MATIC
    address public betAddress;

    // Bet owner address to place bets to for ERC20
    address public betOwnerAddress;

    // This contract (Bet) Group ID
    uint256 public betGroupID;

    // Keep track of the amount minted
    uint256 public betsMinted;

    // Set the house cut
    uint256 cut;

    struct BetDetails {
        string[] bets;          // The bet ["musk", "zuck"]
        mapping(string => uint256) BetIndex; // Where the bet is stored in the array
        uint256[] betWagers;    // Total amount of bets wagered
        uint256[] betsPlaced;   // Total amount of bets placed
        bool active;            // Is the bet active (taking bets)
        bool winnerPicked;            // Is the bet active (taking bets)
        address betType;        // Type of bet wagered (ERC-20 contract / 0x0 = MATIC)
        string betTypeName;     // The name of the token being wagered
        uint256 winnerIndex;    // The index of the winning bet
    }

    // Mapping for Bet => Bet Details ("muskvszuck" => BetDetails)
    mapping(string => BetDetails) public Bets;

    // List of active bets
    string[] public activeBets;

    // Record the users bet details
    struct PlacedBetsDetails {
        string bet;
        string betOn;
        uint256 betAmount;
        bool paidOut;
    }

    // Record all user bets (User Address => (Bet => What they Bet)
    mapping(uint256 => PlacedBetsDetails) public PlacedBets;

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
        uint256 paid;
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

    // OpenSea approval contract
    address public osAddress;

    // Link the KUtils contract
    IKUtils public KUtils;

    // Link the BetMetadata contract
    IBetMetadata public BetMetadata;

    // Link the BetMetadata contract
    IKuthulu public KuthuluApp;

    // Link the Tips contract
    ITips public Tips;

    // Setup to be able to call default DOOM ERC20 calls
    IERC20Upgradeable public paymentToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address kuthuluContract, address userProfiles, address _kutils, address _tips, address betMetadata, uint256 _cut) initializer public {
        __ERC721_init("Bets of KUTHULU", "BETS");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set the initial vault owner
        vaultAddress = msg.sender;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Setup link to KUtils
        Tips = ITips(_tips);

        // Setup link to KUTHULU
        KuthuluApp = IKuthulu(kuthuluContract);

        // Setup link to BetMetadata
        BetMetadata = IBetMetadata(betMetadata);

        // Initialize minted to 0
        betsMinted = 0;

        // Allow KUTHULU to call this contract
        trustedContracts[kuthuluContract] = true;

        // Allow the User Profiles KUTHULU contract to call to test hook
        trustedContracts[userProfiles] = true;

        // Set the house cut
        cut = _cut;

        // Set the initial address to OpenSea
        osAddress = address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE);
    }


    /*

    EVENTS

    */

    event logMintBetToken(address indexed sender, uint256 tokenId);
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

    function updateDetails(address _kutils, address _tips, address kuthuluContract, address betMetadata, uint256 _betGroupID, address _betAddress, address _betOwnerAddress, uint256 _cut, address _newVault) public onlyAdmins {
        // Update the User Profiles contract address
        KUtils = IKUtils(_kutils);

        // Update the User Profiles contract address
        Tips = ITips(_tips);

        // Setup link to KUTHULU
        KuthuluApp = IKuthulu(kuthuluContract);

        // Setup link to BetMetadata
        BetMetadata = IBetMetadata(betMetadata);

        // Update theBet Group ID
        betGroupID = _betGroupID;

        // Set the bet address to tag
        betAddress = _betAddress;

        // Set the bet address to tag
        betOwnerAddress = _betOwnerAddress;

        // Set the house cut
        cut = _cut;

        // Set the vault address
        vaultAddress = _newVault;
    }


    function createBet(string memory bet, string[] memory bets, address betType, string memory betTypeName) public onlyAdmins {

        // Lowercase the bet first
        bet = KUtils._toLower(bet);

        // Make sure it doesn't already exist
        require(Bets[bet].bets.length == 0, "Bet already exists");

        Bets[bet].bets = bets;
        Bets[bet].betType = betType;
        Bets[bet].betTypeName = betTypeName;

        // Store the index of the bets
        for (uint b=0; b < bets.length; b++) {
            Bets[bet].BetIndex[bets[b]] = b;
        }

        // Initialize the bet amounts and wagers
        Bets[bet].betsPlaced = new uint256[](bets.length);
        Bets[bet].betWagers = new uint256[](bets.length);
        Bets[bet].winnerIndex = 0;

        // Set active
        Bets[bet].active = true;
        Bets[bet].winnerPicked = false;

        // Post the message back to KUTHULU
        postResponse(address(0), bet, betTypeName, 0);

        // Add to active Bets
        activeBets.push(bet);
    }

    function pickWinner(string calldata _bet, uint256 winningIndex) public onlyAdmins {
        Bets[_bet].winnerIndex = winningIndex;
        Bets[_bet].active = false;
        Bets[_bet].winnerPicked = true;

        updateActiveBets(_bet, false);

        // Post the message back to KUTHULU
        postResponse(address(0), _bet, Bets[_bet].bets[winningIndex], 0);
    }

    function setBetStatus(string calldata _bet, bool _status) public onlyAdmins {
        Bets[_bet].active = _status;
        updateActiveBets(_bet, _status);
    }


    /*

    KUTHULU FUNCTIONS

    */

    function KuthuluHook(MsgData memory newMsg) public onlyTrustedContracts returns (bool) {

        // Do this if it's a real post
        if (newMsg.msgID != 0){

            // Get the amount they're betting
            if ((newMsg.msgStats.tipsReceived > 0 || newMsg.msgStats.tipERC20Amount > 0) && newMsg.hashtags.length == 2){

                // Lowercase the bet for lookup
                string memory bet = KUtils._toLower(newMsg.hashtags[0]);

                // Lowercase the betOn for lookup
                string memory betOn = KUtils._toLower(newMsg.hashtags[1]);

                // First check that the bet is active and no winner has been picked yet
                if (Bets[bet].active && !Bets[bet].winnerPicked){

                    // Now verify they're betting on something possible
                    bool validBet = false;
                    for (uint b=0; b < Bets[bet].bets.length; b++) {
                        if (KUtils.stringsEqual(Bets[bet].bets[b], betOn)){
                            validBet = true;
                        }
                    }

                    if (!validBet){
                        return false;
                    }

                    // Storing for gas optimization
                    uint256 betAmount = 0;
                    uint256 betAmountOriginal = 0;
                    uint256 taggedAccounts = newMsg.taggedAccounts.length;

                    /// If the bet is accepting MATIC and there's a MATIC tip, it's good
                    if (Bets[bet].betType == address(0) && newMsg.msgStats.tipsReceived > 0){
                        betAmount = newMsg.msgStats.tipsReceived;
                        betAmountOriginal = betAmount;

                        // Move the house cut to the vault
                        betAmount = calcHouseCut(betAmount);

                    } else if (taggedAccounts > 1){
                        // If there's more than 2 tagged account (1 for the ERC-20 token contract address) and it's the right token for the bet and there's ERC-20 token tips, it's good
                        if (Bets[bet].betType == newMsg.taggedAccounts[taggedAccounts - 1] && newMsg.msgStats.tipERC20Amount > 0){
                            betAmount = newMsg.msgStats.tipERC20Amount;
                            betAmountOriginal = betAmount;

                            // Move the house cut to the vault
                            betAmount = calcHouseCut(betAmount);
                        }
                    }

                    // Check if we're placing a valid bet
                    if (betAmount > 0){

                        // Loop through all tagged addresses to see if it matches us
                        for (uint t=0; t < taggedAccounts; t++) {
                            if (newMsg.taggedAccounts[t] == betAddress || newMsg.taggedAccounts[t] == betOwnerAddress){

                                // Kill the loop
                                t == taggedAccounts;

                                // Place the bet
                                placeBet(betAmount, bet, betOn, newMsg.postedBy[0], betAmountOriginal);
                            }
                        }
                    } else {
                        // Invalid Bet Amount
                        return false;
                    }
                } else {
                    // Bet not active
                    return false;
                }
            } else {
                // Invalid requirements
                return false;
            }
        }
        return true;
    }


    /*

    PUBLIC FUNCTIONS

    */


    /**
    * @dev Calculate house cut
    */
    function calcHouseCut(uint256 amount) public view whenNotPaused returns (uint256) {
        uint256 sf = 0;
        if (cut > 0){
            sf = amount - ((amount * (100 - cut)) / 100);
        }

        return (amount - sf);
    }

    /**
    * @dev Show bet options for a bet
    */
    function betChoices(string memory bet) public view whenNotPaused returns (string[] memory) {
        return Bets[bet].bets;
    }

    function getActiveBets() public view whenNotPaused returns (string[] memory) {
        return activeBets;
    }

    function calcWinnings(uint256 _tokenID) public view returns (uint256) {

        // Get the bet they placed
        string memory betPlaced = PlacedBets[_tokenID].bet;

        if (Bets[betPlaced].BetIndex[PlacedBets[_tokenID].betOn] != Bets[betPlaced].winnerIndex) {
            return 0;
        }

        uint256 wager = PlacedBets[_tokenID].betAmount;

        uint256 winningSide = Bets[betPlaced].betWagers[Bets[betPlaced].winnerIndex];

        uint256 percentWin = wager * 1e18 / winningSide;

        uint256 totalBets = Bets[betPlaced].betWagers.length;

        uint256 totalPool = 0;
        for (uint b=0; b < totalBets; b++) {
            totalPool+= Bets[betPlaced].betWagers[b];
        }

        // Calculate and return their winnings
        uint256 winnings = (totalPool * percentWin) / 1e18;
        return winnings;
    }


    /**
    * @dev Claim winnings from bets
    */
    function claimWinnings(uint256 _tokenID) public whenNotPaused nonReentrant {

        // Check to make sure they are the owner
        require(ownerOf(_tokenID) == msg.sender, "You don't own that bet");

        // Get the bet they placed
        string memory betPlaced = PlacedBets[_tokenID].bet;

        // Check that the bet is over
        require(Bets[betPlaced].winnerPicked, "Winner has not been chosen yet");

        // Check that we haven't paid them yet
        require(!PlacedBets[_tokenID].paidOut, "This bet has already been paid out");

        // Check that they won the bet
        require(Bets[betPlaced].winnerIndex == Bets[betPlaced].BetIndex[PlacedBets[_tokenID].betOn], "You didn't win");

        // Calculate the winnings
        uint256 winnings = calcWinnings(_tokenID);

        // Set token as paid
        PlacedBets[_tokenID].paidOut = true;

        if (Bets[betPlaced].betType == address(0)){
            // Transfer the MATIC
            Tips.payOut(msg.sender, winnings, address(0));
        } else {
            // Make the contract interface and transfer the tokens
            Tips.payOut(msg.sender, winnings, Bets[betPlaced].betType);
        }
    }

    /**
    * @dev Get the token metadata
    * @param _tokenID : the unique Group ID
    */
    function tokenURI(uint256 _tokenID) public view virtual override(ERC721Upgradeable) returns (string memory) {
        // Generate the metadata
        return BetMetadata.getMetadata(_tokenID, PlacedBets[_tokenID].bet, PlacedBets[_tokenID].betOn, PlacedBets[_tokenID].paidOut, PlacedBets[_tokenID].betAmount);
    }


    /*

    PRIVATE FUNCTIONS

    */

    function updateActiveBets(string calldata _bet, bool _status) private {
        uint256 activeLen = activeBets.length;
        if (!_status && activeLen > 0){
            // Remove the level from the list
            uint256 place = 0;
            for (uint i=0; i < activeLen; i++) {
                if (KUtils.stringsEqual(activeBets[i], _bet)){
                    place = i;
                    break;
                }
            }

            // Swap the last entry with this one
            activeBets[place] = activeBets[activeLen-1];

            // Remove the last element
            activeBets.pop();
        } else {
            activeBets.push(_bet);
        }
    }

    function placeBet(uint256 betAmount, string memory bet, string memory betOn, address mintTo, uint256 betAmountOriginal) private {

        // Increment
        betsMinted++;

        // Get the index of the bet they're placing for
        uint256 betIndex = Bets[bet].BetIndex[betOn];

        // Increase the total number of bets to this bet
        Bets[bet].betsPlaced[betIndex]++;

        // Add the total wager bet
        Bets[bet].betWagers[betIndex] += betAmount;

        // Record the users bet to the token
        PlacedBets[betsMinted].bet = bet;
        PlacedBets[betsMinted].betOn = betOn;
        PlacedBets[betsMinted].betAmount = betAmount;
        PlacedBets[betsMinted].paidOut = false;

        // Emit to the logs for external reference
        emit logMintBetToken(msg.sender, betsMinted);

        // Post the message back to KUTHULU
        postResponse(mintTo, bet, betOn, betAmountOriginal);

        // Mint the token
        _safeMint(mintTo, betsMinted);
    }

    /**
    * @dev Post a message back to KUTHULU
    */
    function postResponse(address posterAddress, string memory bet, string memory betOn, uint256 betAmount) private whenNotPaused {

        // Create a couple hashtags
        string[] memory hashtags = new string[](3);
        hashtags[0] = "bet";
        hashtags[1] = bet;
        hashtags[2] = betOn;

        // Initialize the message to send and tagged accounts
        string memory message = '';
        address[] memory taggedAccounts = new address[](0);

        // If this is a response to a bet placed, add the additional details
        if (betAmount > 0){
            // Tag the winners account
            taggedAccounts = new address[](1);
            taggedAccounts[0] = posterAddress;

            // Convert bet amount from wei
            betAmount = betAmount / 10**18;

            message = string(abi.encodePacked("@", KUtils.addressToString(posterAddress), " has #Bet ", KUtils.toString(betAmount), " ", Bets[bet].betTypeName, " on #", betOn));
            message = string(abi.encodePacked(message, " to win #", bet, "\n\nGood Luck!\n\nCurrent Stats:"));

            // Loop through all the available bets
            for (uint b=0; b < Bets[bet].bets.length; b++) {
                message = string(abi.encodePacked(message, "\n=&gt; ", Bets[bet].bets[b], " (", KUtils.toString(Bets[bet].betsPlaced[b]) , " bets for [[", KUtils.toString(Bets[bet].betWagers[b]), "]] ", Bets[bet].betTypeName, ")"));
            }

        } else if (Bets[bet].winnerPicked){
            // If the winner is picked, then we're posting a response of the chosen winner
            message = string(abi.encodePacked("We have a WINNER!\n\n#", Bets[bet].bets[Bets[bet].winnerIndex], " has won the #Bet on #", bet, "\n\n[[Claim Your Winnings]]"));
        } else {
            // Else this is a post response of a new bet that was just created
            message = string(abi.encodePacked("A new #Bet has just been created =&gt; #", bet, "\n\nWagers are in ", Bets[bet].betTypeName, "\n\nBet options are:\n"));

            // Loop through all the available bets
            for (uint b=0; b < Bets[bet].bets.length; b++) {
                message = string(abi.encodePacked(message, "=&gt; ", Bets[bet].bets[b], "\n"));
            }

            message = string(abi.encodePacked(message, "\nExample bet as a post, (add Tip in ", Bets[bet].betTypeName ," for wager):\n", "%Bets #", bet, " #", Bets[bet].bets[0], "\n\nPlace your Bets!"));
        }

        // Set the post attributes
        uint256 blockComments = 0;  // Block Comments (Comment Level: 0 = Allowed / 1 = Not Allowed)
        uint256 isCommentOf = 0;  // Is this a comment of another post? If so, add that message ID here
        uint256 isRepostOf = 0;  // Is this a repost of another post? If so, add that message ID here
        uint256 groupID = 49631434039692877301571795200980672380367951824757834049111173611858804356068;  // Are you posting on behalf of a group? If so, add the Spaces here (KUTHULU-Rewards)
        uint256 tipsERC20Amount = 0; // Amount of ERC20 token to tip in wei
        string memory uri = ''; // The URI of the image to add to the post

        // We're not posting to any Spaces / Groups
        uint256[] memory inGroups = new uint256[](0);

        // Make the post back to KUTHULU
        KuthuluApp.postMsg(message, hashtags, taggedAccounts, uri, [blockComments,isCommentOf,isRepostOf,groupID,tipsERC20Amount], inGroups);
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

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}


