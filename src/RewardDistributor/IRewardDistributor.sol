// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IRewardDistributor {
    event DistributionConfigUpdate(bytes32 prevValue, bytes32 newValue, address indexed sender);

    function MANAGE_DISTRIBUTION_CONFIG_ROLE() external view returns (bytes32);

    function distributionConfig() external view returns (bytes32);
    function updateDistributionConfig(bytes32 newConfig) external;
}
