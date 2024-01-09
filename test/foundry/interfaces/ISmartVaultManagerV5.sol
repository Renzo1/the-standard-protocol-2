// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISmartVaultManagerV5 {
    struct Token { bytes32 symbol; address addr; uint8 dec; address clAddr; uint8 clDec; }

    struct Asset { Token token; uint256 amount; uint256 collateralValue; }

    struct Status { 
        address vaultAddress; uint256 minted; uint256 maxMintable; uint256 totalCollateralValue;
        Asset[] collateral; bool liquidated; uint8 version; bytes32 vaultType;
    }
        struct SmartVaultData { 
        uint256 tokenId; uint256 collateralRate; uint256 mintFeeRate;
        uint256 burnFeeRate; Status status;
    }

    function initialize(uint256, uint256, address, address, address, address, address, address) external;
    function HUNDRED_PC() external view returns (uint256);
    function protocol() external view returns (address);
    function liquidator() external view returns (address);
    function euros() external view returns (address);
    function collateralRate() external view returns (uint256);
    function tokenManager() external view returns (address);
    function smartVaultDeployer() external view returns (address);
    function nftMetadataGenerator() external view returns (address);
    function mintFeeRate() external view returns (uint256);
    function burnFeeRate() external view returns (uint256);
    function swapFeeRate() external view returns (uint256);
    function lastToken() external view returns (uint256);

    function vaults() external view returns (SmartVaultData[] memory);
    function mint() external returns (address, uint256);
    function liquidateVault(uint256) external;
    function totalSupply() external view returns (uint256);
    function setLiquidatorAddress(address) external;
    function setProtocolAddress(address) external;

    // function grantPoolBurnRole(address) external;
}