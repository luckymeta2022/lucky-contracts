// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Random {

    function _seedUint64(uint256 _seed) internal pure returns (uint256) {
        uint256 seed = uint256(uint64(_seed));
        uint256 rand = ((seed ** 2) / (10e4)) % (10e8);
        return rand;
    }

    function genSeedsUint64(uint256 _seed, uint256 _num) internal pure returns (uint256[] memory) {
        uint256 temp = _seed;
        uint256[] memory randArray = new uint256[](_num);
        for (uint256 i = 0; i < _num; i++){
            temp = _seedUint64(temp);
            randArray[i] = temp % _num;    
        }
        return randArray;
    }

}