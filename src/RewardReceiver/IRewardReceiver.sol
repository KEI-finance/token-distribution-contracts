// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IRewardReceiver {
    event ReceiveRewards(uint256 amount, address indexed sender);
    event UseRewards(uint256 amount, address indexed sender);

    function totalRewards() external view returns (uint256);

    function reward(uint256 amount) external returns (uint256);
}
