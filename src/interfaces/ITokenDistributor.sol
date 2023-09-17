// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface ITokenDistributor {
    event Request(uint256 indexed id, DistributionRequest request, address indexed sender);
    event ProcessRewards(
        uint256 indexed currentIndex,
        RewardDistributions distributions,
        uint256 totalProcessed,
        uint256 totalRewards,
        address indexed sender
    );

    struct DistributionConfig {
        uint16 debtPercent;
        uint16 adminPercent;
        uint16 stakingPercent;
        uint16 processorPercent;
        uint16 affiliatePercent;
    }

    struct DistributionRequest {
        bytes32 encodedConfig;
        uint128 totalRewards;
        uint128 __gap;
        address txOrigin;
        uint32 timestamp;
    }

    struct RewardDistributions {
        uint256 adminTokens;
        uint256 affiliateTokens;
        uint256 stakingTokens;
        uint256 processorTokens;
        uint256 debtTokens;
        uint256 treasuryTokens;
    }

    function currentRequestId() external view returns (uint256);
    function totalPendingRequests() external view returns (uint256);

    function sync(uint256 maxRewards, bytes32 encodedConfig) external returns (uint256 rewardId);
    function process(uint256 maxToProcess) external returns (uint256 totalRewardsDistributed);
}
