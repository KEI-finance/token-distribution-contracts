// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface ISyncTokens {

    function sync(uint256 maxRewards) external returns (uint256 id);
}
