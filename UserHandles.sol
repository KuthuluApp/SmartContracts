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

    @title UserHandles
    v0.3

    KUTHULU : https://www.KUTHULU.xyz
    A project by DOOM Labs (https://DOOMLabs.io)
    The first truly decentralized social framework.
    Built for others to build upon and share freedom of expression.
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IUserProfiles.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/IDOOM.sol";

contract UserHandles is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Approved Wallets
    mapping (address => bool) public approved;

    // Map the Handle => User Address for uniqueness (stored in lowercase)
    mapping (string => address) public usrHandleMap;

    // Set token cost for name change
    uint256 public costForNameChange;

    // Set max length for handle
    uint256 maxHandleLength;

    // Link to the KUtils Contracts
    IKUtils public KUtils;

    // Link to Random NFT Contract
    IUserProfiles public UserProfiles;

    // Link to the DOOM Token
    IGroups public Groups;

    // Link to the DOOM Token
    IDOOM public DOOM;

    // ERC20 Receiver for payment via ERC20
    IERC20Upgradeable public paymentToken;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IERC20Upgradeable _paymentToken, address _kutils, uint256 _costForNameChange, uint256 _maxHandleLength) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the payment token
        paymentToken = IERC20Upgradeable(_paymentToken);

        // Setup the default Admin
        admins[msg.sender] = true;

        // Setup default approved wallet
        approved[msg.sender] = true;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Setup initial cost to update handle
        costForNameChange = _costForNameChange;

        // Setup initial max handle length
        maxHandleLength = _maxHandleLength;
    }


    /*

    EVENTS

    */

    event updateHandle(address indexed usrAddress, string indexed handle);


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

    function updateLimits(uint256 _costToChangeName, uint256 _maxHandleLength) public onlyAdmins {
        costForNameChange = _costToChangeName;
        maxHandleLength = _maxHandleLength;
    }

    function updateContracts(IERC20Upgradeable _payments, address _userProfiles, address _kutils, address _doom, address _groups) public onlyAdmins {
        // Update the contract address of the ERC20 token to be used as payment
        paymentToken = IERC20Upgradeable(_payments);

        // Update the Followers contract address
        UserProfiles = IUserProfiles(_userProfiles);

        // Update the KUtils address
        KUtils = IKUtils(_kutils);

        // Update the DOOM Token address
        DOOM = IDOOM(_doom);

        // Update the Groups address
        Groups = IGroups(_groups);
    }

    // Update a users handle to something custom (like ENS name)
    function updateUserHandleAdmin(address userAddress, string calldata handle, uint256 verified) public whenNotPaused onlyAdmins {

        // Convert the handle to lower case for comparison
        string memory handleLower = KUtils._toLower(handle);

        // Check if anyone already registered that handle and remove it from them if so
        if (usrHandleMap[handleLower] != address(0)) {
            UserProfiles.updateHandleVerify(usrHandleMap[handleLower], "", 0);
        }

        // Release their old handle
        delete usrHandleMap[KUtils._toLower(UserProfiles.getUserDetails(userAddress)[0])];

        // Update the Handle in the users profile
        UserProfiles.updateHandleVerify(userAddress, handle, verified);

        // Update the handle mapping to address to block it
        usrHandleMap[handleLower] = userAddress;

        emit updateHandle(userAddress, handle);
    }



    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Update a users own handle
    * @dev Handle must be less than maxHandleLength characters
    * @dev it costs costForNameChange DOOM to update a handle
    * @param handle : The handle they want to change to
    */
    function updateUserHandle(string calldata handle) public whenNotPaused {

        // Convert the handle to lower case for comparison
        string memory handleLower = KUtils._toLower(handle);

        if (KUtils.strlen(handle) >= 7){
            // Don't allow KUTHULU prefixes as a security measure unless minted by admins
            require(!KUtils.stringsEqual("kuthulu", substring(handleLower, 0, 7)) || admins[msg.sender], "KUTHULU Prefix not allowed");
        }

        // Transfer the Payment Token to the contract
        require(DOOM.burnTokens(msg.sender, costForNameChange), "Didn't burn DOOM");

        // Make sure the Handle length is within limits
        require(KUtils.strlen(handle) <= maxHandleLength, "Your Handle is too long");

        // Require basic characters only
        require(KUtils.isValidString(handle), "Bad characters in Handle");

        // Check if anyone already registered that handle
        require(usrHandleMap[handleLower] == address(0), "Handle already taken");

        // Release old handle
        delete usrHandleMap[KUtils._toLower(UserProfiles.getUserDetails(msg.sender)[0])];

        // Update the Handle in the users profile
        UserProfiles.updateHandleVerify(msg.sender, handle, 0);

        // Update the handle mapping to address to block it
        usrHandleMap[handleLower] = msg.sender;

        emit updateHandle(msg.sender, handle);
    }


    /**
    * @dev Check if a handle is available to be used
    * @param handle : The handle they want to change to
    * @return bool : True = Handle is available / False = Handle is already taken
    */
    function checkIfAvailable(string calldata handle) public view whenNotPaused returns (bool) {
        if (usrHandleMap[KUtils._toLower(handle)] == address(0)) {
            return true;
        } else {
            return false;
        }
    }


    /*

    PRIVATE FUNCTIONS

    */

    function substring(string memory str, uint startIndex, uint endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}