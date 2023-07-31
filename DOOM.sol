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

    @title DOOM
    v0.3

    KUTHULU : https://www.KUTHULU.xyz
    A project by DOOM Labs (https://DOOMLabs.io)
    The first truly decentralized social framework.
    Built for others to build upon and share freedom of expression.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract DOOM is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    address public vaultAddress;

    // Address of the KUTHULU contract
    address public appAddress;

    // Address of the Handles contract
    address public handlesAddress;

    // Setup the cost to mint 1 token
    uint256 public costToMint;

    // Set max token allowance for when minting
    uint256 maxAllowance;

    // Address of the Tips contract
    address public tipsAddress;

    // Mapping of address to last mint block
    mapping (address => uint256) public lastMintBlock;

    // Set the amount of blocks to have to wait for preMinting
    uint256 public preMinBlockCheck;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("DOOM", "DOOM");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("DOOM");
        __ERC20Votes_init();

        // Set cost to mint DOOM to be 0.01 MATIC / DOOM
        costToMint = 1 ether / 100;

        // Send 1,000,000 DOOM to admin
        _mint(msg.sender, 1000000 * 10 ** decimals());

        // Set max DOOM to 10 billion
        maxAllowance = 10000000000 ether;

        // Set deploy address as admin
        admins[msg.sender] = true;

        // Set the initial vault owner
        vaultAddress = msg.sender;

        // Set block wait time to about 4 Hours
        preMinBlockCheck = 6000;
    }


    /*

    EVENTS

    */

    event logMintTokens(address indexed purchaser, uint256 amount);


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

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function mint(address to, uint256 amount) public onlyAdmins {
        _privMint(to, amount);
    }

    function preMint(address to, uint256 amount) public onlyAdmins {

        // Only allow preMint every X Blocks for a wait time
        if (lastMintBlock[to] == 0 || block.number - lastMintBlock[to] >= preMinBlockCheck){

            // Record this block for cool-down
            lastMintBlock[to] = block.number;

            // Auto-approve main contract to spend tokens
            _approve(to, appAddress, maxAllowance);

            // Auto-approve UserHandles contract to spend tokens
            _approve(to, handlesAddress, maxAllowance);

            // Auto-approve UserHandles contract to spend tokens
            _approve(to, tipsAddress, maxAllowance);

            // Log it
            emit logMintTokens(to, amount);

            // Send it
            _mint(to, amount);
        }
    }

    function setVaultAddress(address _newVault) public onlyAdmins{
        vaultAddress = _newVault;
    }

    function setAddresses(address _app, address _handles, address _tips) public onlyAdmins{
        appAddress = _app;
        handlesAddress = _handles;
        tipsAddress = _tips;
    }

    function updateTokenCost(uint256 _newCost) public onlyAdmins{
        costToMint = _newCost;
    }

    function updatePreMintWaitTime(uint256 _preMintBlocks) public onlyAdmins{
        preMinBlockCheck = _preMintBlocks;
    }

    function burnTokens(address from, uint256 amount) public onlyAdmins returns (bool) {
        burnFrom(from, amount);
        return true;
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Mint the amount of DOOM you want
    * @param amount : the number of DOOM you want in ether
    */
    function publicMint(uint256 amount) public whenNotPaused nonReentrant payable {
        // Make sure they've sent enough MATIC to cover the cost of the tokens
        require(msg.value == (costToMint * amount), "Incorrect payment amount minting");

        // Transfer the tokens
        _privMint(msg.sender, (amount * 1 ether));
    }


    /*

    PRIVATE FUNCTIONS

    */

    function _privMint(address to, uint256 amount) private {

        // Auto-approve main contract to spend tokens
        approve(appAddress, maxAllowance);

        // Auto-approve UserHandles contract to spend tokens
        approve(handlesAddress, maxAllowance);

        // Auto-approve UserHandles contract to spend tokens
        approve(tipsAddress, maxAllowance);

        // Log it
        emit logMintTokens(to, amount);

        // Transfer MATIC to the vault
        AddressUpgradeable.sendValue(payable(vaultAddress), address(this).balance);

        // Send it
        _mint(to, amount);
    }


    /*

    OVERRIDE FUNCTIONS

    */

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
    internal
    override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
    internal
    override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}