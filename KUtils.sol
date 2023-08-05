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

    KUtils.sol
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

contract KUtils is Initializable, PausableUpgradeable, OwnableUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function append(string memory a, string memory b, string memory c, string memory d, string memory e) public pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }

    function _toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function isValidURI(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if(b.length > 2000) return false;

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if(
                // Only allow valid ASCII characters as per RFC3986 URI Generic Syntax
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x2E) && //.
                !(char == 0x2F) && //"/"
                !(char == 0x3A) && //:
                !(char == 0x5F) && //_
                !(char == 0x7E) && //~
                !(char == 0x3F) && //?
                !(char == 0x23) && //#
                !(char == 0x5B) && //[
                !(char == 0x5D) && //]
                !(char == 0x26) && //&
                !(char == 0x21) && //!
                !(char == 0x40) && //@
                !(char == 0x24) && //$
                !(char == 0x28) && //(
                !(char == 0x29) && //)
                !(char == 0x2A) && //*
                !(char == 0x2B) && //+
                !(char == 0x2C) && //,
                !(char == 0x3B) && //;
                !(char == 0x25) && //%
                !(char == 0x3D) && //=
                !(char == 0x2D) //-
            )
                return false;
        }

        return true;
    }

    function isValidGroupString(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if(
            // Only allow valid ASCII characters as per RFC3986 URI Generic Syntax
                (char == 0x26) || //&
                (char == 0x21) || //!
                (char == 0x40) || //@
                (char == 0x24) || //$
                (char == 0x28) || //(
                (char == 0x29) || //)
                (char == 0x2A) || //*
                (char == 0x2B) || //+
                (char == 0x2C) || //,
                (char == 0x3B) || //;
                (char == 0x25) || //%
                (char == 0x3D) || //=
                (char == 0x2E) || //.
                (char == 0x2F) || //"/"
                (char == 0x3A) || //:
                (char == 0x5C) || //"\"
                (char == 0x7E) || //~
                (char == 0x3F) || //?
                (char == 0x23) || //#
                (char == 0x22) || //"
                (char == 0x5E) || //^
                (char == 0x7C) || //|
                (char == 0x7B) || //{
                (char == 0x7D) || //}
                (char == 0x5B) || //[
                (char == 0x5D) || //]
                (char == 0x27) || //'
                (char == 0x3C) || //<
                (char == 0x3E) || //>
                (char == 0x60) || //`
                (char == 0x20)
            )
            return false;
        }

        return true;
    }

    function isValidString(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if(
            // Only allow valid ASCII characters as per RFC3986 URI Generic Syntax
                !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x2E) && //.
            !(char == 0x5F) && //_
            !(char == 0x2D) //-
            )
                return false;
        }

        return true;
    }

    function isSafeString(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if(
            // As to not to allow scripts
                (char == 0x3C) || //<
                (char == 0x3E) //>
            )
                return false;
        }

        return true;
    }


    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    // THIS RETURNS ADDRESS IN LOWER CASE
    function addressToString(address addr) public pure returns (string memory){
        // Cast Address to byte array
        bytes memory addressBytes = abi.encodePacked(addr);

        // Byte array for the new string
        bytes memory stringBytes = new bytes(42);

        // Assign firs two bytes to '0x'
        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        // Iterate over every byte in the array
        // Each byte contains two hex digits that gets individually converted
        // into their ASCII representation and add to the string
        for (uint256 i = 0; i < 20; i++) {
            // Convert hex to decimal values
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            // Convert decimals to ASCII Values
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            // Add ASCII values to the string byte array
            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;
        }

        // Cast byte array to string and return
        return string(stringBytes);
    }

    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) public pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    function stringsEqual(string memory a, string memory b) public pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}