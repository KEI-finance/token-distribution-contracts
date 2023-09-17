// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.19;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../library/util/Percent.sol";
import "../../library/KContract.sol";

import "../Affiliate/IAffiliate.sol";
import "../Treasury/ITreasury.sol";
import "../Token/IToken.sol";

import "./RewardReceiver/IRewardReceiver.sol";

import "./interfaces/ITokenDistributor.sol";

contract TokenDistributor is ITokenDistributor, KContract {
    using SafeCast for uint256;
    using Percent for uint256;

    mapping(uint256 => DistributionRequest) private $requests;
    uint256 private $totalRequestsCreated;
    uint256 private $currentRequestId;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ITokenDistributor).interfaceId || super.supportsInterface(interfaceId);
    }

    function currentRequestId() external view override returns (uint256) {
        return $currentRequestId;
    }

    function distributionRequest(uint256 id) external view returns (DistributionRequest memory) {
        return $requests[id];
    }

    function totalPendingRequests() external view override returns (uint256) {
        unchecked {
            return $totalRequestsCreated - $currentRequestId;
        }
    }

    function decodeConfig(bytes32 encodedConfig) public pure returns (DistributionConfig memory config) {
        uint256 _value = uint256(encodedConfig);

        config.debtPercent = uint16(_value);
        config.adminPercent = uint16(_value << 16);
        config.stakingPercent = uint16(_value << 32);
        config.processorPercent = uint16(_value << 48);
        config.affiliatePercent = uint16(_value << 64);
    }

    function sync(uint256 maxRewards, bytes32 encodedConfig) external override whenNotPaused returns (uint256 id) {
        IKEI.Core memory _k = _core();

        uint256 _rewardAmount = ITreasury(_k.treasury).sync(_k.token, maxRewards);
        require(_rewardAmount > 0, "Rewards: NO_REWARDS");

        id = $totalRequestsCreated;

        DistributionRequest memory _request;

        _request.encodedConfig = encodedConfig;
        _request.totalRewards = _rewardAmount.toUint128();
        _request.timestamp = uint32(block.timestamp % 2 ** 32);
        _request.txOrigin = tx.origin;

        $requests[id] = _request;

        unchecked {
            // this is ok to wrap around
            $totalRequestsCreated = id + 1;
        }

        emit Request(id, _request, _msgSender());
    }

    function process(uint256 maxToProcess) external override whenNotPaused returns (uint256 totalRewardsDistributed) {
        IKEI.Snapshot memory _k = _snapshot();
        uint256 _totalToProcess;
        uint256 _totalRequestsCreated = $totalRequestsCreated;
        uint256 _currentId = $currentRequestId;

        RewardDistributions memory _dist;

        unchecked {
            _totalToProcess = maxToProcess + _currentId > _totalRequestsCreated || maxToProcess == 0
                ? _totalRequestsCreated - _currentId
                : maxToProcess;
        }

        if (_totalToProcess == 0) {
            return 0;
        }

        $currentRequestId = _currentId + _totalToProcess;

        IAffiliate.RewardData[] memory _affiliateData = new IAffiliate.RewardData[](_totalToProcess);
        for (uint256 i; i < _totalToProcess; ++i) {
            uint256 _id = i + _currentId;
            DistributionRequest memory _request = $requests[_id];
            RewardDistributions memory _currentDist;

            delete $requests[_id];

            unchecked {
                totalRewardsDistributed += _request.totalRewards;

                _currentDist = _getRewardDistribution(_request);

                _dist.treasuryTokens += _currentDist.treasuryTokens;
                _dist.stakingTokens += _currentDist.stakingTokens;
                _dist.debtTokens += _currentDist.debtTokens;
                _dist.adminTokens += _currentDist.adminTokens;
                _dist.processorTokens += _currentDist.processorTokens;
                _dist.affiliateTokens += _currentDist.affiliateTokens;
            }

            if (_currentDist.affiliateTokens > 0) {
                _affiliateData[i] = IAffiliate.RewardData({
                    totalTokens: _currentDist.affiliateTokens,
                    sender: _request.txOrigin,
                    rewardId: _id
                });
            }
        }

        // we need to distribute the affiliate each time because it will potentially have a different origin address
        if (_dist.affiliateTokens > 0) {
            // distribute to affiliate network, and give any remainder to the admin contract
            uint256 _remaining = IAffiliate(_k.affiliate).reward(_affiliateData);
            if (_remaining > 0) {
                _dist.affiliateTokens -= _remaining;
                _dist.treasuryTokens += _remaining;
            }
        }

        _distributeRewards(_dist, _k);

        emit ProcessRewards(_currentId, _dist, _totalToProcess, totalRewardsDistributed, _msgSender());
    }

    function _getRewardDistribution(DistributionRequest memory _request)
        private
        pure
        returns (RewardDistributions memory dist)
    {
        uint256 _totalRewards = _request.totalRewards;

        DistributionConfig memory _config = decodeConfig(_request.encodedConfig);

        dist.adminTokens = _totalRewards.applyPercent(_config.adminPercent);
        dist.debtTokens = _totalRewards.applyPercent(_config.debtPercent);
        dist.processorTokens = _totalRewards.applyPercent(_config.processorPercent);
        dist.stakingTokens = _totalRewards.applyPercent(_config.stakingPercent);
        dist.affiliateTokens = _totalRewards.applyPercent(_config.affiliatePercent);

        dist.treasuryTokens = _totalRewards - dist.adminTokens - dist.debtTokens - dist.affiliateTokens
            - dist.processorTokens - dist.stakingTokens;
    }

    // All tokens are held by the treasury
    function _distributeRewards(RewardDistributions memory dist, IKEI.Snapshot memory k) private {
        if (dist.debtTokens > 0) {
            uint256 leftover = IRewardReceiver(k.debt).reward(dist.debtTokens);
            if (leftover > 0) {
                dist.debtTokens -= leftover;
                unchecked {
                    dist.treasuryTokens += leftover;
                }
            }
        }

        if (dist.adminTokens > 0) {
            uint256 leftover = IRewardReceiver(k.admin).reward(dist.adminTokens);
            if (leftover > 0) {
                dist.adminTokens -= leftover;
                unchecked {
                    dist.treasuryTokens += leftover;
                }
            }
        }

        if (dist.processorTokens > 0) {
            uint256 leftover = IRewardReceiver(k.processor).reward(dist.processorTokens);
            if (leftover > 0) {
                dist.processorTokens -= leftover;
                unchecked {
                    dist.treasuryTokens += leftover;
                }
            }
        }

        if (dist.stakingTokens > 0) {
            uint256 leftover = IRewardReceiver(k.staking).reward(dist.stakingTokens);
            if (leftover > 0) {
                dist.stakingTokens -= leftover;
                unchecked {
                    dist.treasuryTokens += leftover;
                }
            }
        }

        if (dist.treasuryTokens > 0) {
            ITreasury(k.treasury).withdraw(k.token, address(this), dist.treasuryTokens);
            IToken(k.token).burn(dist.treasuryTokens);
        }
    }
}
