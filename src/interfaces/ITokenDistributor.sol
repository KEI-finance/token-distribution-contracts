// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ITokenDistributor {
    event Distribute(address indexed sender, uint256 indexed totalAmount, Distribution[] distributions);

    struct Distribution {
        address target;
        uint256 amount;
    }

    function TOKEN() external view returns (address);

    function distribute(Distribution[] memory distributions) external;
}
