// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {ISyncable} from "./interfaces/ISyncable.sol";
import {ITokenDistributor} from "./interfaces/ITokenDistributor.sol";

contract TokenDistributor is ITokenDistributor, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant DISTRIBUTE_ROLE = keccak256("DISTRIBUTE_ROLE");

    address public immutable override TOKEN;

    constructor(address token, address admin) {
        TOKEN = token;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function distribute(Distribution[] calldata distributions) external onlyRole(DISTRIBUTE_ROLE) {
        uint256 _totalDistributions = distributions.length;
        uint256 _totalAmount;
        for (uint256 i; i < _totalDistributions; i++) {
            Distribution calldata dist = distributions[i];
            IERC20(TOKEN).safeTransfer(dist.target, dist.amount);
            ISyncable(dist.target).sync(dist.amount);
            _totalAmount += dist.amount;
        }
        emit Distribute(msg.sender, _totalAmount, distributions);
    }
}
