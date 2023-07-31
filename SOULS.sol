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

    @title SOULS
    v0.2

    KUTHULU : https://www.KUTHULU.xyz
    A project by DOOM Labs (https://DOOMLabs.io)
    The first truly decentralized social framework.
    Built for others to build upon and share freedom of expression.
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import "./interfaces/IAmulets.sol";
import "./interfaces/IKultists.sol";

contract SOULS is Initializable, ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Keep track of the amount of SOULS an address has minted
    mapping (address => uint256) soulsMintedByOwner;
    
    // Save token URIs
    mapping (uint256 => string) tokenURIs;

    // Vault address to receive funds to
    address public vaultAddress;

    // Store total SOULS minted
    uint256 minted;
    
    // The amount of SOULS each Amulet Level can mint for free
    uint256[] amuletLevelMints;  

    // Link the Amulets
    IAmulets public AmuletTokens;

    // Link the Kultists
    IKultists public Kultists;

    // Link the Amulets
    IERC721Upgradeable public Amulets;
    IERC721EnumerableUpgradeable public AmuletsEnum;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kultists, address _amulets) initializer public {
        __ERC1155_init("SOULS");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set the initial vault owner
        vaultAddress = msg.sender;

        // Initialize the SOUL token URI
        tokenURIs[1] = "ipfs://Qmd2rpuevmd3BU2P4VwryrFNEiQnJXS2fWmMVYuP9epo6C";

        // Set the Kultists contract
        Kultists = IKultists(_kultists);

        // Set the Amulets contract
        AmuletTokens = IAmulets(_amulets);
        Amulets = IERC721Upgradeable(_amulets);
        AmuletsEnum = IERC721EnumerableUpgradeable(_amulets);
        
        // set the initial amulet minting levels
        amuletLevelMints = [0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,3,3,3,4,5,10];
    }

    /*

    EVENTS

    */

    event logMintToken(address indexed account, uint256 id, uint256 amount, bytes data);


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

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyAdmins {

        // Only mint souls if they've earned any
        require(remainingToMint(account) > 0, "You have not earned any SOULS to mint!");

        // Increment Owner amount
        soulsMintedByOwner[account]++;

        // Increment total amount
        minted++;

        // Emit to the logs for external reference
        emit logMintToken(account, id, amount, data);

        // Mint the token
        _mint(account, id, amount, data);

    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyAdmins {
        _mintBatch(to, ids, amounts, data);
    }

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable(vaultAddress), address(this).balance);
    }

    function setVaultAddress(address _newVault) public onlyAdmins{
        vaultAddress = _newVault;
    }

    function updateContracts(address _kultists, address _amulets) public onlyAdmins {
        // Set the Kultists contract
        Kultists = IKultists(_kultists);

        // Set the Amulets contract
        AmuletTokens = IAmulets(_amulets);
        Amulets = IERC721Upgradeable(_amulets);
        AmuletsEnum = IERC721EnumerableUpgradeable(_amulets);
    }

    function updateTokenURI(uint256 token, string calldata newUri) public onlyAdmins {
        // Set the Kultists contract
        tokenURIs[token] = newUri;
    }

    function updateAmuletMintingLevels(uint256 level, uint256 amount) public onlyAdmins {
        // Update the level
        amuletLevelMints[level] = amount;
    }


    /*

    PUBLIC FUNCTIONS

    */


    /**
    * @dev Get the top Level Amulet that is owned by a wallet
    * @param user : The address of the wallet to lookup
    * @return uint256 : The level of the top amulet the giver wallet owns
    */
    function getTopAmuletOwned(address user) public view returns (uint256){
        // Get the balance of the user
        uint256 balance = Amulets.balanceOf(user);

        // Set the base value of Amulet owned to zero
        uint256 topAmulet = 0;

        if (balance > 0){
            for (uint i=0; i < balance; i++) {
                // Get the token number that they own
                uint256 tokenNumber = AmuletsEnum.tokenOfOwnerByIndex(user, i);

                // Now get the type of token from the number
                uint256 amuletType = AmuletTokens.getAmuletType(tokenNumber)[1];

                // If the amulet type is greater than the previous
                if (amuletType > topAmulet){
                    //set it to the top (King of the Hill bitches!)
                    topAmulet = amuletType;
                }
            }
        }

        return topAmulet;
    }


    /**
    * @dev Get the amount of SOULS that a user can mint based on their top amulet owned
    * @param user : The address of the wallet to lookup
    * @return uint256 : The amount of SOULS left that they can mint
    */
    function remainingToMint(address user) public view returns (uint256) {
        // Get amount of mints they can do based on amulet ownership
        uint256 howManyCanMint = amuletLevelMints[getTopAmuletOwned(user)];

        if (howManyCanMint > soulsMintedByOwner[user]){
            return howManyCanMint - soulsMintedByOwner[user];
        } else {
            return 0;
        }
    }


    /**
    * @dev Burn a SOUL token. This will add 1 re-roll when minting a Kultist
    * @param amount : The number of SOULS they want to burn in exchange for re-rolls
    */
    function burnSoul(uint256 amount) public nonReentrant {

        // Update their reRoll count for a Kultist
        Kultists.addReRoll(msg.sender, amount);

        // Burn the SOUL
        _burn(msg.sender, 1, amount);
    }


    /*

    OVERRIDE FUNCTIONS

    */

    function uri(uint256 _tokenid) override public view returns (string memory) {
        return tokenURIs[_tokenid];
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
    
    /*
    
                     00                  
                    0000                 
                   000000                
        00         000000          00    
         0000      000000      00000     
         000000    0000000   0000000     
          000000   0000000 0000000       
           0000000 000000 0000000        
             000000 00000 000000         
     0000     000000 000 0000  000000000 
      000000000  0000 0 000 000000000    
         000000000  0 0 0 000000000      
             0000000000000000            
                  000 0 0000             
                00000 0  00000           
               00     0      00

    */
}
