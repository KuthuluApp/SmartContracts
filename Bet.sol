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
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";



import "./interfaces/IKUtils.sol";


contract Bet is ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Trusted Contracts
    mapping (address => bool) public trustedContracts;

    // Vault address to receive funds to
    address public vaultAddress;

    // Bet address to place bets to
    address public betAddress;

    // ERC20 Token address to take wagers with
    address erc20TokenAddress;

    // Base URI for the Amulets
    string public tokenBaseURI;

    // Keep track of the amount minted
    uint256 public minted;

    struct BetDetails {
        string[] bets;      // The bet ["musk", "zuck"]
        mapping(string => uint256) BetIndex; // Where the bet is stored in the array
        uint256[] betWagers;    // Total amount of bets wagered
        uint256[] betsPlaced;    // Total amount of bets placed
        bool active;    // Is the bet active (taking bets)
        address betType;     // Type of bet wagered (ERC-20 contract / 0x0 = MATIC)
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

    // OpenSea approval contract
    address public osAddress;

    // Link the KUtils contract
    IKUtils public KUtils;

    // Setup to be able to call default DOOM ERC20 calls
    IERC20Upgradeable public paymentToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address kuthuluContract, address userProfiles, address _kutils) initializer public {
        __ERC721_init("Amulets of KUTHULU", "AMULET");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set the initial vault owner
        vaultAddress = msg.sender;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Initialize minted to 0
        minted = 0;

        // Set the bet address to tag to this address
        betAddress = address(this);

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

    function updateDetails(address _kutils) public onlyAdmins {
        // Update the User Profiles contract address
        KUtils = IKUtils(_kutils);
    }

    function setVaultAddress(address _newVault) public onlyAdmins{
        vaultAddress = _newVault;
    }

    function createBet(string calldata bet, string[] calldata bets, address betType) public onlyAdmins{
        // Make sure it doesn't already exist
        require(Bets[bet].bets.length == 0, "Bet already exists");

        Bets[bet].bets = bets;
        Bets[bet].betType = betType;

        // Store the index of the bets
        for (uint b=0; b < bets.length; b++) {
            Bets[bet].BetIndex[bets[b]] = b;
        }

        // Set active
        Bets[bet].active = true;

        // Add to active Bets
        activeBets.push(bet);
    }

    function pickWinner(string calldata _bet, uint256 winningIndex) public onlyAdmins {
        Bets[_bet].winnerIndex = winningIndex;
        Bets[_bet].active = false;
    }

    // openMint Levels
    // 0 = Closed
    // 1 = Whale White List
    // 2 = White List
    // 3 = Open Mint
    function updateDetails(string calldata _tokenBaseURI, address _osAddress) public onlyAdmins {
        // Set the BaseURI
        tokenBaseURI = _tokenBaseURI;

        // Update the OpenSea address
        osAddress = _osAddress;
    }

    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable(vaultAddress), address(this).balance);
    }


    /*

    KUTHULU FUNCTIONS

    */

    function KuthuluHook(MsgData memory newMsg) public onlyTrustedContracts nonReentrant returns (bool) {

        // Do this if it's a real post
        if (newMsg.msgID != 0){

            // If they've tagged us for a bet
            uint256 taggedAccounts = newMsg.taggedAccounts.length;

            // Get the amount they're betting
            if ((newMsg.msgStats.tipsReceived > 0 || newMsg.msgStats.tipERC20Amount > 0) && newMsg.hashtags.length == 2){

                string memory bet = newMsg.hashtags[0];

                // First check that the bet is active
                if (Bets[bet].active){

                    uint256 amountBet = 0;

                    /// If the bet is accepting MATIC and there's a MATIC tip, it's good
                    if (Bets[bet].betType == address(0) && newMsg.msgStats.tipsReceived > 0){
                        amountBet = newMsg.msgStats.tipsReceived;
                    } else if (taggedAccounts > 1){
                        // If there's more than 2 tagged account (1 for the ERC-20 token contract address) and it's the right token for the bet and there's ERC-20 token tips, it's good
                        if (Bets[bet].betType == newMsg.taggedAccounts[taggedAccounts - 1] && newMsg.msgStats.tipERC20Amount > 0){
                            amountBet = newMsg.msgStats.tipERC20Amount;
                        }
                    }

                    // Check if we're placing a valid bet
                    if (amountBet > 0){

                        // Loop through all tagged addresses to see if it matches us
                        for (uint t=0; t < taggedAccounts; t++) {
                            if (newMsg.taggedAccounts[t] == betAddress){
                                // Kill the loop
                                t == taggedAccounts;

                                // Place the bet
                                placeBet(newMsg, amountBet);
                            }
                        }
                    }
                }
            }
        }

        return true;
    }


    /*

    PUBLIC FUNCTIONS

    */


    /**
    * @dev Claim winnings from bets
    */
    function claimWinnings(uint256 _tokenID) public whenNotPaused nonReentrant {

        // Check to make sure they are the owner
        require(ownerOf(_tokenID) == msg.sender, "You don't own that bet");

        string memory betPlaced = PlacedBets[_tokenID].bet;

        // Check that the bet is over
        require(Bets[betPlaced].active == false, "Winner has not been chosen yet");

        // Check that they won the bet
        require(Bets[betPlaced].winnerIndex == Bets[betPlaced].BetIndex[PlacedBets[_tokenID].betOn], "Winner has not been chosen yet");

        uint256 totalPool = 0;

        uint256 wager = PlacedBets[_tokenID].betAmount;

        uint256 winningSide = Bets[betPlaced].betWagers[Bets[betPlaced].winnerIndex];

        uint256 percentWin = wager * 1e18 / winningSide;

        uint256 totalBets = Bets[betPlaced].betWagers.length;

        for (uint b=0; b < totalBets; b++) {
            totalPool+= Bets[betPlaced].betWagers[b];
        }

        // Calculate their winnings
        uint256 winnings = (totalPool * percentWin) / 1e18;

        // Set token as paid
        PlacedBets[_tokenID].paidOut = true;

        if ( Bets[betPlaced].betType == address(0)){
            // Transfer the MATIC
            AddressUpgradeable.sendValue(payable(msg.sender), winnings);
        } else {
            // Make the contract interface and transfer the tokens
            paymentToken.transferFrom(address(this), msg.sender, winnings);
        }
    }



    /**
   * @dev Return the metadata of a group NFT for a tokenURI
    * @param _tokenID : group ID of a token to get metadata for
    * @return string : the metadata of a token in JSON format base64 encoded
    */
    function getMetadata(uint256 _tokenID) public view returns (string memory){

        string memory bet = PlacedBets[_tokenID].bet;
        uint256 betLength = KUtils.strlen(bet);

        string memory betFontSize = '12px';

        if (betLength <= 10){
            betFontSize = '34px';
        } else if (betLength <= 15){
            betFontSize = '26px';
        } else if (betLength <= 20){
            betFontSize = '22px';
        } else if (betLength <= 25){
            betFontSize = '17px';
        }

        string memory betOn = PlacedBets[_tokenID].betOn;
        uint256 betOnLength = KUtils.strlen(betOn);

        string memory fontSize = '12px';

        if (betOnLength <= 10){
            fontSize = '34px';
        } else if (betOnLength <= 15){
            fontSize = '26px';
        } else if (betOnLength <= 20){
            fontSize = '22px';
        } else if (betOnLength <= 25){
            fontSize = '17px';
        }

        string memory theText = KUtils.append("<text x='130' y='246' font-size='", fontSize, "' fill='white' filter='url(#dropShadow)' id='k'>", betOn, "</text>");
        string memory betText = KUtils.append("<text x='135' y='65' font-size='", betFontSize, "' fill='white' filter='url(#dropShadow)' id='k'>", bet, "</text>");

        bytes memory image = abi.encodePacked(
            "<svg width='270' height='270' viewBox='0 0 270 270' fill='none' xmlns='http://www.w3.org/2000/svg'><rect width='270' height='270' fill='url(#paint0_linear)'/><defs><filter id='dropShadow' color-interpolation-filters='sRGB' filterUnits='userSpaceOnUse' height='280' width='270'><feDropShadow dx='0' dy='1' stdDeviation='2' flood-opacity='0.425' width='200%' height='200%'/></filter></defs><g transform='translate(70,205) scale(0.25,-0.25)' fill='#FFFFFF' stroke='none'><path d='M190 472 c-51 -25 -68 -61 -87 -180 -3 -18 0 -39 7 -47 8 -10 9 -15 2 -15 -15 0 -22 13 -24 47 -3 33 -13 43 -50 43 -33 0 -32 2 -13 -44 11 -25 25 -41 46 -48 16 -5 34 -18 39 -28 15 -28 1 -30 -25 -4 -28 28 -47 30 -65 9 -10 -13 -10 -19 4 -33 20 -23 21 -75 1 -92 -8 -7 -15 -28 -15 -46 l0 -34 240 0 240 0 0 34 c0 18 -7 39 -15 46 -20 17 -19 69 1 92 14 14 14 20 4 33 -18 21 -37 19 -65 -10 -24 -23 -25 -23 -25 -4 0 13 11 25 34 34 33 14 48 29 52 50 1 6 5 18 9 27 6 15 2 18 -21 18 -35 0 -59 -14 -50 -28 8 -14 -11 -62 -25 -62 -8 0 -8 4 1 15 7 8 10 29 7 47 -3 18 -8 50 -11 72 -8 50 -41 95 -82 112 -44 18 -72 18 -114 -4z m147 -34 c12 -13 25 -38 29 -55 5 -28 3 -33 -11 -33 -21 0 -55 -27 -55 -43 0 -6 9 -1 20 11 25 26 33 27 54 6 23 -22 20 -60 -6 -79 -16 -12 -19 -19 -10 -22 16 -6 15 -50 -2 -56 -7 -3 -18 -1 -24 5 -20 20 -32 -4 -32 -62 0 -40 4 -59 14 -63 21 -8 26 2 26 48 0 44 13 65 42 65 22 0 24 -26 3 -34 -10 -3 -15 -19 -15 -45 0 -50 -34 -80 -69 -61 -22 11 -29 31 -33 95 -2 28 -8 40 -18 40 -10 0 -16 -12 -18 -40 -4 -64 -11 -84 -33 -95 -16 -9 -26 -8 -45 5 -19 12 -24 24 -24 59 0 30 -5 46 -15 50 -21 8 -19 26 3 26 29 0 42 -21 42 -65 0 -46 5 -56 26 -48 10 4 14 23 14 63 0 58 -12 82 -32 62 -6 -6 -17 -8 -24 -5 -17 6 -18 50 -1 56 8 3 5 10 -10 22 -27 19 -30 57 -7 79 21 21 29 20 54 -6 11 -12 20 -18 20 -13 0 16 -33 45 -52 45 -22 0 -23 21 -4 59 19 37 39 52 79 61 41 8 85 -4 114 -32z m-249 -302 c2 -25 7 -46 11 -46 5 0 12 -11 15 -24 3 -13 9 -32 12 -41 6 -14 -1 -16 -47 -13 -46 3 -54 6 -57 24 -4 29 21 49 38 29 7 -8 20 -15 28 -15 12 0 11 4 -6 16 -17 11 -22 25 -22 56 0 26 -6 45 -17 53 -25 19 -7 40 20 22 16 -11 23 -26 25 -61z m370 40 c-12 -9 -18 -27 -18 -54 0 -31 -5 -45 -22 -56 -14 -10 -17 -16 -9 -16 8 0 23 8 33 17 17 15 21 15 29 3 5 -8 8 -24 7 -35 -3 -17 -12 -20 -57 -23 -48 -3 -53 -1 -46 15 4 10 10 27 13 38 3 11 10 23 16 27 5 4 9 23 8 42 -3 42 32 87 52 66 8 -8 7 -15 -6 -24z'/><path d='M230 442 c0 -4 9 -8 20 -8 11 0 20 4 20 8 0 4 -9 8 -20 8 -11 0 -20 -4 -20 -8z'/><path d='M196 403 c-11 -12 -6 -19 14 -19 11 0 20 3 20 7 0 10 -27 19 -34 12z'/><path d='M283 403 c-20 -7 -15 -19 7 -19 11 0 20 4 20 8 0 10 -13 16 -27 11z'/><path d='M134 306 c-9 -23 0 -51 16 -51 10 0 15 10 15 29 0 32 -21 47 -31 22z'/><path d='M334 306 c-9 -23 0 -51 16 -51 10 0 15 10 15 29 0 32 -21 47 -31 22z'/></g>", betText, theText, "<defs><style>text { font-family: Noto Color Emoji, Apple Color Emoji, sans-serif; font-weight: bold; font-family: sans-serif;text-anchor:middle} #k {font-family:Impact;}</style><linearGradient id='paint0_linear' x1='190.5' y1='302' x2='-64' y2='-172.5' gradientUnits='userSpaceOnUse'><stop stop-color='#ad81fc'/><stop offset='0.428185' stop-color='#8855d5'/><stop offset='1' stop-color='#5e13d1'/></linearGradient></defs></svg>"
        );

        string memory gotPaid = "False";
        if (PlacedBets[_tokenID].paidOut){
            gotPaid = "True";
        }

        string memory attribs = string(abi.encodePacked(
            '{"trait_type": "Bet","value": "', bet, '"},'
        '{"trait_type": "Bet On","value": "', betOn, '"},'
        '{"trait_type": "Wager Amount","value": "', PlacedBets[_tokenID].betAmount, '"},'
        '{"trait_type": "Winnings Claimed","value": "', gotPaid, '"}'
        ));

        bytes memory dataURI = abi.encodePacked(
            '{"name": "KUTHULU Bet: ',betOn , '",',
            '"image": "data:image/svg+xml;base64,', Base64Upgradeable.encode(image), '",',
            '"external_url": "https://www.KUTHULU.xyz/?group=Bet",',
            '"description": "KUTHULU Bet is a social wagering app built into KUTHULU. Place a bet just by making a social media post! Join the Madness! https://KUTHULU.xyz",',
            '"attributes": [', attribs, ']}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64Upgradeable.encode(dataURI)
            )
        );
    }


    /**
    * @dev Get the token metadata
    * @param _tokenID : the unique Group ID
    */
    function tokenURI(uint256 _tokenID) public view virtual override(ERC721Upgradeable) returns (string memory) {
        return getMetadata(_tokenID);
    }


    /*

    PRIVATE FUNCTIONS

    */


    function placeBet(MsgData memory newMsg, uint256 amountBet) private nonReentrant {

        // Increment
        minted++;

        string memory bet = newMsg.hashtags[0];
        string memory betOn = newMsg.hashtags[1];

        // Get the index of the bet they're placing for
        uint256 betIndex = Bets[bet].BetIndex[betOn];

        // Increase the total number of bets to this bet
        Bets[bet].betsPlaced[betIndex]++;

        // Add the total wager bet
        Bets[bet].betWagers[betIndex] += amountBet;

        // Record the users bet to the token
        PlacedBets[minted].bet = betOn;
        PlacedBets[minted].betOn = betOn;
        PlacedBets[minted].betAmount = amountBet;
        PlacedBets[minted].paidOut = false;

        // Emit to the logs for external reference
        emit logMintToken(msg.sender, minted);

        // Mint the token
        _safeMint(msg.sender, minted);
    }

    /**
    * @dev Post a message back to KUTHULU
    */
//    function postResponse(uint256 level, address posterAddress) private whenNotPaused {
//
//        // Create a couple hashtags
//        string[] memory hashtags = new string[](2);
//
//        hashtags[0] = "RaffleWinner";
//        hashtags[1] = "Kultish";
//
//        // Tag the winners account
//        address[] memory taggedAccounts = new address[](1);
//        taggedAccounts[0] = posterAddress;
//
//        string memory message = string(abi.encodePacked("Congrats to @", KUtils.addressToString(posterAddress), "! They won a Raffle Ticket NFT and are now at level ", KUtils.toString(level)));
//        message = string(abi.encodePacked(message, "! Raffle Ticket holders are entered to win a whitelist spot for the minting of the coveted Amulets! Only Amulet holders will be able to mint a Kultist! The more Raffle Tickets you have, the more chances you have to win!"));
//
//
//        // Set the post attributes
//        uint256 blockComments = 0;  // Block Comments (Comment Level: 0 = Allowed / 1 = Not Allowed)
//        uint256 isCommentOf = 0;  // Is this a comment of another post? If so, add that message ID here
//        uint256 isRepostOf = 0;  // Is this a repost of another post? If so, add that message ID here
//        uint256 groupID = rewardsGroupID;  // Are you posting on behalf of a group? If so, add the GroupID here (KUTHULU-Rewards)
//        uint256 tipsERC20Amount = 0; // Amount of ERC20 token to tip in wei
//        string memory uri = 'ipfs://QmZpN1cCURBoQwFWMSZRYTktxcwqRcNsHvcjigZjNiLBLD'; // The URI of the image to add to the post
//
//        // We're not posting to any Spaces / Groups
//        uint256[] memory inGroups = new uint256[](0);
//
//        // Make the post back to KUTHULU
//        KuthuluApp.postMsg(message, hashtags, taggedAccounts, uri, [blockComments,isCommentOf,isRepostOf,groupID,tipsERC20Amount], inGroups);
//    }


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


