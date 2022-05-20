
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LuckyLib {

    struct Lucky {
        uint volume;
        uint weight;
        Trait trait;
        Birth birth;
    }
    
    struct Trait {
        uint strength;
        uint stamina;
        uint speed;
    }
    
    struct Birth {
        uint birthTime;
        uint matronId;
        uint generation;
        uint race;
    }

    function add(mapping(uint256=>Lucky) storage luckys,Lucky memory lucky,uint tokenId) internal {
        require(!isExist(luckys,tokenId),"existed");
        lucky.birth.birthTime = block.timestamp;
        luckys[tokenId] = lucky;
    }

    function remove(mapping(uint256=>Lucky) storage luckys,uint tokenId) internal returns(Lucky memory lucky) {
        lucky = luckys[tokenId];
        delete luckys[tokenId];
    }
    
    function isExist(mapping(uint256=>Lucky) storage luckys,uint tokenId) internal view returns(bool _exist) {
        _exist = luckys[tokenId].birth.birthTime>0;
    }
    
    bytes32 constant TRAIT_TYPEHASH = keccak256(
        "Trait(uint strength,uint stamina,uint speed)"
    );
    
    bytes32 constant BIRTH_TYPEHASH = keccak256(
        "Birth(uint birthTime,uint matronId,uint generation,uint race)"
    );
    
     bytes32 constant UNICORN_TYPEHASH = keccak256(
        "Unicorn(uint volume,unit weight,Trait trait,Birth birth)"
    );


    function hash(Trait memory trait) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TRAIT_TYPEHASH,
                trait.strength,
                trait.stamina,
                trait.speed
            )
        );
    }
    
    function hash(Birth memory birth) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                BIRTH_TYPEHASH,
                birth.matronId,
                birth.generation,
                birth.race
            )
        );
    }
    
    function hash(Lucky memory lucky) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                UNICORN_TYPEHASH,
                lucky.volume,
                lucky.weight,
                hash(lucky.trait),
                hash(lucky.birth)
            )
        );
    }
  
    

}