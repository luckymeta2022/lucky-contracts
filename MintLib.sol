// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./LuckyLib.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

library MintLib {

    struct MintData {
        uint tokenId;
        address owner;
        string tokenURI;
        LuckyLib.Lucky lucky;
        bytes signature;
    }


    bytes32 public constant MINT_TYPEHASH = keccak256("MintData(uint256 tokenId,address owner,string tokenURI,Unicorn unicorn)");

    function hash(MintData memory data) internal pure returns (bytes32) {

        return keccak256(abi.encode(
                MINT_TYPEHASH,
                data.tokenId,
                data.owner,
                keccak256(bytes(data.tokenURI)),
                LuckyLib.hash(data.lucky)
        ));
    }
    
    function validate(MintData memory mintData, address signer) internal view returns(bool) {
        return SignatureChecker.isValidSignatureNow(signer,hash(mintData),mintData.signature);
    }
}