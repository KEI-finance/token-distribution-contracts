// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.19;

import "../../../library/util/Percent.sol";
import "../../../library/KContract.sol";

import "../../Pricing/PricingLibrary.sol";
import "../../Oracle/IOracle.sol";
import "../../Token/IToken.sol";

import "../interfaces/ITokenDistributor.sol";

import "./IRewardDistributor.sol";

contract RewardDistributor is IRewardDistributor, KContract {
    bytes32 public constant override MANAGE_DISTRIBUTION_CONFIG_ROLE = keccak256("MANAGE_DISTRIBUTION_CONFIG_ROLE");

    bytes32 private $config;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRewardDistributor).interfaceId || super.supportsInterface(interfaceId);
    }

    function distributionConfig() public view override returns (bytes32) {
        return $config;
    }

    function updateDistributionConfig(bytes32 newConfig) external override onlyRole(MANAGE_DISTRIBUTION_CONFIG_ROLE) {
        uint256 val = uint256(newConfig);
        uint256 _totalPercent;

        for (uint256 i = 0; i < 16; i++) {
            _totalPercent += uint16(val << 16 * i);
        }

        require(_totalPercent <= Percent.BASE_PERCENT, "RewardDistributor: INVALID_TOTAL_PERCENTAGE");

        emit DistributionConfigUpdate($config, newConfig, _msgSender());
        $config = newConfig;
    }

    function _distributeProfit(uint256 totalProfit, IKEI.Core memory k) internal {
        _distributeProfit(totalProfit, 0, k);
    }

    function _distributeProfit(uint256 totalProfit, IKEI.Snapshot memory k) internal {
        _distributeProfit(totalProfit, 0, k);
    }

    function _distributeProfit(uint256 totalProfit, uint256 mintExtra, IKEI.Core memory k) internal {
        return _distributeProfit(totalProfit, mintExtra, IOracle(k.oracle).prices().floorPrice, k.token, k.rewards);
    }

    function _distributeProfit(uint256 totalProfit, uint256 mintExtra, IKEI.Snapshot memory k) internal {
        return _distributeProfit(totalProfit, mintExtra, IOracle(k.oracle).prices().floorPrice, k.token, k.rewards);
    }

    function _distributeProfit(uint256 totalProfit, uint256 floorPrice, address token, address rewards) internal {
        return _distributeProfit(totalProfit, 0, floorPrice, token, rewards);
    }

    function _distributeProfit(
        uint256 totalProfit,
        uint256 mintExtra,
        uint256 floorPrice,
        address token,
        address rewards
    ) internal {
        uint256 _totalTokens = PricingLibrary.baseToTokens(floorPrice, totalProfit);
        uint256 _toMint = _totalTokens + mintExtra;

        if (_toMint > 0) {
            IToken(token).mint(_toMint);
        }

        if (_totalTokens > 0) {
            ITokenDistributor(rewards).sync(_totalTokens, $config);
        }
    }

    function _distributeProfitTokens(uint256 totalTokens, IKEI.Core memory k) internal {
        ITokenDistributor(k.rewards).sync(totalTokens, $config);
    }
}
