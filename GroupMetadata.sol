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

    @title GroupTokenMetadata
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
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IUserProfiles.sol";
import "./interfaces/IGroups.sol";

contract GroupMetadata is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Link the KUtils contract
    IKUtils public KUtils;

    // Link the Groups contract
    IGroups public Groups;

    // Link the User Profiles contract
    IUserProfiles public UserProfiles;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);
    }


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

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function updateContracts(address _kutils, address _userProfiles, address _groups) public onlyAdmins {
        // Update the User Profiles contract address
        KUtils = IKUtils(_kutils);

        // Setup link to User Profiles
        UserProfiles = IUserProfiles(_userProfiles);

        // Setup link to Groups
        Groups = IGroups(_groups);
    }


    /*

    Public Functions

    */

    /**
    * @dev Return the metadata of a group NFT for a tokenURI
    * @param _tokenID : group ID of a token to get metadata for
    * @return string : the metadata of a token in JSON format base64 encoded
    */
    function getMetadata(uint256 _tokenID) public view returns (string memory){

        string memory groupName = Groups.getGroupNameFromID(_tokenID);
        uint256 groupNameLength = KUtils.strlen(groupName);
        string[3] memory colors = Groups.getGroupColorsFromID(_tokenID);
        string memory groupAddress = KUtils.addressToString(Groups.getGroupAddressFromID(_tokenID));

        string memory fontSize = '12px';

        if (groupNameLength <= 10){
            fontSize = '34px';
        } else if (groupNameLength <= 15){
            fontSize = '26px';
        } else if (groupNameLength <= 20){
            fontSize = '22px';
        } else if (groupNameLength <= 25){
            fontSize = '17px';
        }

        string memory theText = KUtils.append("<text x='130' y='246' font-size='", fontSize, "' fill='white' filter='url(#dropShadow)' id='k'>%", groupName, "</text>");

        bytes memory image = abi.encodePacked(
            "<svg width='270' height='270' viewBox='0 0 270 270' fill='none' xmlns='http://www.w3.org/2000/svg'><rect width='270' height='270' fill='url(#paint0_linear)'/><defs><filter id='dropShadow' color-interpolation-filters='sRGB' filterUnits='userSpaceOnUse' height='280' width='270'><feDropShadow dx='0' dy='1' stdDeviation='2' flood-opacity='0.425' width='200%' height='200%'/></filter></defs><g transform='translate(70,205) scale(0.25,-0.25)' fill='#FFFFFF' stroke='none'><path d='M190 472 c-51 -25 -68 -61 -87 -180 -3 -18 0 -39 7 -47 8 -10 9 -15 2 -15 -15 0 -22 13 -24 47 -3 33 -13 43 -50 43 -33 0 -32 2 -13 -44 11 -25 25 -41 46 -48 16 -5 34 -18 39 -28 15 -28 1 -30 -25 -4 -28 28 -47 30 -65 9 -10 -13 -10 -19 4 -33 20 -23 21 -75 1 -92 -8 -7 -15 -28 -15 -46 l0 -34 240 0 240 0 0 34 c0 18 -7 39 -15 46 -20 17 -19 69 1 92 14 14 14 20 4 33 -18 21 -37 19 -65 -10 -24 -23 -25 -23 -25 -4 0 13 11 25 34 34 33 14 48 29 52 50 1 6 5 18 9 27 6 15 2 18 -21 18 -35 0 -59 -14 -50 -28 8 -14 -11 -62 -25 -62 -8 0 -8 4 1 15 7 8 10 29 7 47 -3 18 -8 50 -11 72 -8 50 -41 95 -82 112 -44 18 -72 18 -114 -4z m147 -34 c12 -13 25 -38 29 -55 5 -28 3 -33 -11 -33 -21 0 -55 -27 -55 -43 0 -6 9 -1 20 11 25 26 33 27 54 6 23 -22 20 -60 -6 -79 -16 -12 -19 -19 -10 -22 16 -6 15 -50 -2 -56 -7 -3 -18 -1 -24 5 -20 20 -32 -4 -32 -62 0 -40 4 -59 14 -63 21 -8 26 2 26 48 0 44 13 65 42 65 22 0 24 -26 3 -34 -10 -3 -15 -19 -15 -45 0 -50 -34 -80 -69 -61 -22 11 -29 31 -33 95 -2 28 -8 40 -18 40 -10 0 -16 -12 -18 -40 -4 -64 -11 -84 -33 -95 -16 -9 -26 -8 -45 5 -19 12 -24 24 -24 59 0 30 -5 46 -15 50 -21 8 -19 26 3 26 29 0 42 -21 42 -65 0 -46 5 -56 26 -48 10 4 14 23 14 63 0 58 -12 82 -32 62 -6 -6 -17 -8 -24 -5 -17 6 -18 50 -1 56 8 3 5 10 -10 22 -27 19 -30 57 -7 79 21 21 29 20 54 -6 11 -12 20 -18 20 -13 0 16 -33 45 -52 45 -22 0 -23 21 -4 59 19 37 39 52 79 61 41 8 85 -4 114 -32z m-249 -302 c2 -25 7 -46 11 -46 5 0 12 -11 15 -24 3 -13 9 -32 12 -41 6 -14 -1 -16 -47 -13 -46 3 -54 6 -57 24 -4 29 21 49 38 29 7 -8 20 -15 28 -15 12 0 11 4 -6 16 -17 11 -22 25 -22 56 0 26 -6 45 -17 53 -25 19 -7 40 20 22 16 -11 23 -26 25 -61z m370 40 c-12 -9 -18 -27 -18 -54 0 -31 -5 -45 -22 -56 -14 -10 -17 -16 -9 -16 8 0 23 8 33 17 17 15 21 15 29 3 5 -8 8 -24 7 -35 -3 -17 -12 -20 -57 -23 -48 -3 -53 -1 -46 15 4 10 10 27 13 38 3 11 10 23 16 27 5 4 9 23 8 42 -3 42 32 87 52 66 8 -8 7 -15 -6 -24z'/><path d='M230 442 c0 -4 9 -8 20 -8 11 0 20 4 20 8 0 4 -9 8 -20 8 -11 0 -20 -4 -20 -8z'/><path d='M196 403 c-11 -12 -6 -19 14 -19 11 0 20 3 20 7 0 10 -27 19 -34 12z'/><path d='M283 403 c-20 -7 -15 -19 7 -19 11 0 20 4 20 8 0 10 -13 16 -27 11z'/><path d='M134 306 c-9 -23 0 -51 16 -51 10 0 15 10 15 29 0 32 -21 47 -31 22z'/><path d='M334 306 c-9 -23 0 -51 16 -51 10 0 15 10 15 29 0 32 -21 47 -31 22z'/></g><text x='135' y='65' font-size='56px' fill='white' filter='url(#dropShadow)' id='k'>KUTHULU</text>", theText, "<defs><style>text { font-family: Noto Color Emoji, Apple Color Emoji, sans-serif; font-weight: bold; font-family: sans-serif;text-anchor:middle} #k {font-family:Impact;}</style><linearGradient id='paint0_linear' x1='190.5' y1='302' x2='-64' y2='-172.5' gradientUnits='userSpaceOnUse'><stop stop-color='#", colors[2], "'/><stop offset='0.428185' stop-color='#", colors[1], "'/><stop offset='1' stop-color='#", colors[0], "'/></linearGradient></defs></svg>"
        );

        string memory attribs = string(abi.encodePacked(
            '{"trait_type": "Characters","value": "', KUtils.toString(groupNameLength), '"},'
            '{"trait_type": "Group Address","value": "', groupAddress, '"},'
            '{"trait_type": "Details","value": "', Groups.getGroupDetailsFromID(_tokenID), '"},'
            '{"trait_type": "URI","value": "', Groups.getGroupURIFromID(_tokenID), '"}'
        ));

        bytes memory dataURI = abi.encodePacked(
            '{"name": "KUTHULU Space: ',groupName , '",',
            '"image": "data:image/svg+xml;base64,', Base64Upgradeable.encode(image), '",',
            '"external_url": "https://www.KUTHULU.xyz/?address=', groupAddress, '",',
            '"description": "KUTHULU Space is a privately owned social group in the worlds first truly decentralized social platform that takes place 100% on blockchain. Free from censorship. Controlled by no one. Join the Madness! https://KUTHULU.xyz",',
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
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}


