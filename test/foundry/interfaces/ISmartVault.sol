// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../../../contracts/interfaces/ITokenManager.sol";

interface ISmartVault {
    struct Asset { ITokenManager.Token token; uint256 amount; uint256 collateralValue; }
    struct Status { 
        address vaultAddress; uint256 minted; uint256 maxMintable; uint256 totalCollateralValue;
        Asset[] collateral; bool liquidated; uint8 version; bytes32 vaultType;
    }

    function owner() external view returns (address);
    // function minted() external view returns (uint256);

    function status() external view returns (Status memory);
    function undercollateralised() external view returns (bool);
    function setOwner(address _newOwner) external;
    function liquidate() external;
    function removeCollateralNative(uint256, address payable) external;
    function removeCollateral(bytes32, uint256, address) external;
    function removeAsset(address, uint256, address) external;
    function mint(address, uint256) external;
    function burn(uint256) external;
}