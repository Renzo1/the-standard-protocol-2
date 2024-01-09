// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ILiquidationPoolManager.sol";

interface ILiquidationPool {
    struct Position {  address holder; uint256 TST; uint256 EUROs; }
    struct Reward { bytes32 symbol; uint256 amount; uint8 dec; }
    
    function manager() external view returns (address);

    function tokenManager() external view returns (address);

    function position(address) external view returns(Position memory, Reward[] memory);

    function increasePosition(uint256, uint256) external;


    function decreasePosition(uint256, uint256) external;


    function claimRewards() external;

    function distributeAssets(ILiquidationPoolManager.Asset[] memory, uint256, uint256) external payable;

    function getTstTotal() external view returns (uint256);

    // For test 
    function consolidatePendingStakes() external;

    // function findRewards(address) external view returns (Reward[] memory);
}