// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.19;

import "../../../library/KContract.sol";

import "../../Treasury/TreasuryLibrary.sol";

import "./IRewardReceiver.sol";

abstract contract RewardReceiver is IRewardReceiver, KContract {
    using TreasuryLibrary for ITreasury;

    // rewards are in k tokens
    uint256 private $totalRewards;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRewardReceiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function totalRewards() public view virtual override returns (uint256) {
        return $totalRewards;
    }

    function reward(uint256 amount) public virtual override returns (uint256) {
        address _rewardsAddress = K.rewards();
        uint256 _rewardsUnused = _reward(amount);
        uint256 _rewardsUsed = amount - _rewardsUnused;

        if (_rewardsAddress != _msgSender()) {
            IKEI.Core memory _k = _core();
            // if it is not the rewards contract then lets go ahead and deposit the difference into the treasury.
            uint256 _received = ITreasury(_k.treasury).deposit(_k.token, _msgSender(), _rewardsUsed);
            require(_received >= _rewardsUsed, "RewardReceiver: INSUFFICIENT_REWARDS");
        }

        return _rewardsUnused;
    }

    function _useRewards(uint256 amount) internal {
        uint256 _totalRewards = $totalRewards;
        require(amount <= _totalRewards, "RewardReceiver: INSUFFICIENT_REWARDS");
        unchecked {
            $totalRewards = _totalRewards - amount;
        }
        emit UseRewards(amount, _msgSender());
    }

    function _reward(uint256 _amount) internal virtual returns (uint256) {
        $totalRewards += _amount;
        emit ReceiveRewards(_amount, _msgSender());
        return 0;
    }
}
