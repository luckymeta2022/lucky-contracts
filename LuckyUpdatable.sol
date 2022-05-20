// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract LuckyUpdatable {
    uint256 constant digit = 1e18;
    uint256 constant ddigit = 100e18;
    uint256 constant qdigit = 10000e18;
    uint256[10] lmgIncomeForLog = [556, 1667, 4444, 5556, 19444, 33889, 57222, 91667, 143889, 222222];
    uint256[10] lmtIncomeForLog = [6,   17, 44, 56, 194, 339, 572, 917, 1439, 2222];
    uint256[10] lmgCostByLevel  = [5, 10, 30, 50, 85, 130, 210, 310, 470];
    uint256[10] lmtCostByLevel  = [5, 10, 30, 50, 85, 130, 210, 310, 470];


    function lmgForLevelup(uint256 _level) external view returns (uint256) {
        require(_level <= 9, "role level exceeds max limit.");
        uint256 lmg = lmgCostByLevel[_level - 1] * qdigit;
        return lmg;
    }

     
    function lmtForLevelup(uint256 _level) external view returns (uint256) {
        require(_level <= 9, "role level exceeds max limit.");
        uint256 lmt = lmtCostByLevel[_level - 1] * ddigit;
        return lmt;
    }



    function lmgForLogin(uint256 _level) external view returns (uint256) {
        require(_level <= 10, "role level exceeds max limit.");
        uint256 lmg = lmgIncomeForLog[_level - 1] * digit;
        return lmg;
    }
    function lmtForLogin(uint256 _level) external view returns (uint256) {
        require(_level <= 10, "role level exceeds max limit.");
        uint256 lmt = lmtIncomeForLog[_level - 1] * digit;
        return lmt;
    }
}
