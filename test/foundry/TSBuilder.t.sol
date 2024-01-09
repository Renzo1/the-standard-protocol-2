// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";

////// Import Interface //////
import { ISmartVaultManagerV5 } from "./interfaces/ISmartVaultManagerV5.sol";
import { ILiquidationPoolManager } from "./interfaces/ILiquidationPoolManager.sol";
import { AggregatorV3InterfaceForTest } from "./interfaces/AggregatorV3InterfaceForTest.sol";
import { ILiquidationPool } from "./interfaces/ILiquidationPool.sol";
import { ISmartVault } from "./interfaces/ISmartVault.sol";
import { IEUROs } from "../../contracts/interfaces/IEUROs.sol";
import { IERC20Mock } from "./interfaces/IERC20Mock.sol";
import { ITokenManager } from "../../contracts/interfaces/ITokenManager.sol";
import { ISmartVaultDeployer } from "../../contracts/interfaces/ISmartVaultDeployer.sol";
import { ISmartVaultIndex } from "../../contracts/interfaces/ISmartVaultIndex.sol";

////// Import Mock Contracts //////
import { EUROsMock } from "../../utils/EUROsMock.sol";
import { ERC20Mock } from "../../utils/ERC20Mock.sol";
import { TokenManagerMock } from "../../utils/TokenManagerMock.sol";
import { SmartVaultDeployerV3 } from "../../utils/SmartVaultDeployerV3.sol";
import { SmartVaultIndex } from "../../utils/SmartVaultIndex.sol";
import { ChainlinkMockForTest } from "../../utils/ChainlinkMockForTest.sol";

////// Import Scope Contracts //////
import { MockSmartVaultManagerV5 } from "../../contracts/MockSmartVaultManagerV5.sol";
import { LiquidationPoolManager } from "../../contracts/LiquidationPoolManager.sol";
import { LiquidationPool } from "../../contracts/LiquidationPool.sol";

contract TSBuilder is Test {
    ///                                                          ///
    ///                          BASE SETUP                      ///
    ///                                                          ///

    ////// Network Contracts //////
    ISmartVaultManagerV5 public SmartVaultManagerContract;
    ILiquidationPoolManager public liquidationPoolManagerContract;
    ILiquidationPool public liquidationPool;

    ITokenManager public tokenManagerContract;
    ISmartVaultIndex public smartVaultIndexContract;

    address public SmartVaultManager; // Also EUROs admin
    address public liquidationPoolManager;
    address public pool;

    address public tokenManager;
    address public smartVaultDeployer;
    address public smartVaultIndex;

    ////// Network Assets //////
    IEUROs public EUROs;
    IERC20Mock public TST;
    IERC20Mock public WBTC;
    IERC20Mock public PAXG;

    address public euros_;
    address public tst_;
    address public wbtc_;
    address public paxg_;

    ////// Network Actors //////
    address public owner; 
    address public protocol;
    address public liquidator;
    address payable public treasury;


    ////// Oracle Contracts //////
    AggregatorV3InterfaceForTest clNativeUsdPrice;
    AggregatorV3InterfaceForTest clEurUsdPrice;
    AggregatorV3InterfaceForTest clBtcUsdPrice;
    AggregatorV3InterfaceForTest clPaxgUsdPrice;

    address public clNativeUsd;
    address public clEurUsd;
    address public clBtcUsd;
    address public clPaxgUsd;


    ////// Other variables //////
    uint256 public collateralRate = 110000;
    uint256 public feeRate = 2000;
    uint32 public poolFeePercentage = 50000;
    bytes32 public native;

    struct Token { bytes32 symbol; address addr; uint8 dec; address clAddr; uint8 clDec; }

    struct Asset { Token token; uint256 amount; }

    // struct VaultForTest { address owner; address vaultAddr; uint256 id;}

    function setUp() public virtual {
        owner = vm.addr(420420);
        bytes32 _native = bytes32(abi.encodePacked("ETH"));
        native = _native;
        treasury = payable(vm.addr(11022033));
        // It wasn't clear whether protocol was pointing to treasury from the docs
        // but I took it so. Reason is in finding
        protocol = treasury;

        // deploy Network Assets
        vm.startPrank(owner);
        tst_ = address(new ERC20Mock("TST", "TST", 18));
        wbtc_ = address(new ERC20Mock("WBTC", "WBTC", 8));
        paxg_ = address(new ERC20Mock("PAXG", "PAXG", 18));

        TST = IERC20Mock(tst_);
        WBTC = IERC20Mock(wbtc_);
        PAXG = IERC20Mock(paxg_);

        // deploy Price Oracles for Assets
        clNativeUsd = address(new ChainlinkMockForTest("ETH / USD"));
        clEurUsd = address(new ChainlinkMockForTest("EUR / USD"));
        clBtcUsd = address(new ChainlinkMockForTest("WBTC / USD"));
        clPaxgUsd = address(new ChainlinkMockForTest("PAXG / USD"));

        clNativeUsdPrice = AggregatorV3InterfaceForTest(clNativeUsd);
        clEurUsdPrice = AggregatorV3InterfaceForTest(clEurUsd);
        clBtcUsdPrice = AggregatorV3InterfaceForTest(clBtcUsd);
        clPaxgUsdPrice = AggregatorV3InterfaceForTest(clPaxgUsd);

        // deploy tokenManager
        tokenManager = address(new TokenManagerMock(native, address(clNativeUsd)));
        tokenManagerContract = ITokenManager(tokenManager);

        // deploy smartVaultDeployer
        smartVaultDeployer = address(new SmartVaultDeployerV3(native, clEurUsd));

        // deploy smartVaultIndex
        smartVaultIndex = address(new SmartVaultIndex());
        smartVaultIndexContract = ISmartVaultIndex(smartVaultIndex);

        // deploy SmartVaultManager
        SmartVaultManager = address(new MockSmartVaultManagerV5());
        vm.stopPrank();

        vm.startPrank(SmartVaultManager);
        euros_ = address(new EUROsMock());
        EUROs = IEUROs(euros_);
        vm.stopPrank();

        vm.startPrank(owner);
        liquidator = address(0); // use random address cause liquidationPoolManager hasn't been deployed yet
        SmartVaultManagerContract = ISmartVaultManagerV5(SmartVaultManager);
        // initialize SmartVaultManager
        SmartVaultManagerContract.initialize(collateralRate, feeRate, euros_, protocol, liquidator, tokenManager, smartVaultDeployer, smartVaultIndex);
        //  _liquidator

        // deploy LiquidationPoolManager
        liquidationPoolManager = address(new LiquidationPoolManager(tst_, euros_, SmartVaultManager, clEurUsd, treasury, poolFeePercentage));
        // update liquidator to liquidationPoolManager once it's deployed
        liquidator = liquidationPoolManager;
        SmartVaultManagerContract.setLiquidatorAddress(liquidator);

        smartVaultIndexContract.setVaultManager(SmartVaultManager);

        // Set pool variable
        liquidationPoolManagerContract = ILiquidationPoolManager(liquidationPoolManager);
        pool = liquidationPoolManagerContract.pool();
        liquidationPool = ILiquidationPool(pool);
        vm.stopPrank();
    }

    ///                                                                                ///
    ///                          Contract Initial State Pramaters                      ///
    ///                                                                                ///
    // Set accepted colleteral assets
    function setAcceptedCollateral() private {
        vm.startPrank(owner);
        tokenManagerContract.addAcceptedToken(wbtc_, clBtcUsd);
        tokenManagerContract.addAcceptedToken(paxg_, clPaxgUsd);
        vm.stopPrank();
    }

    // set asset initial prices
    function setInitialTimeAndPrice() private {
        clNativeUsdPrice.setPrice(2200 * 1e8 ); // $2200
        clEurUsdPrice.setPrice(11037 * 1e4); // $1.1037
        clBtcUsdPrice.setPrice(42_000 * 1e8); // $42000
        clPaxgUsdPrice.setPrice(2000 * 1e8); // $2000
    }

    ///                                                             ///
    ///                          Deploy System                      ///
    ///                                                             ///
    function setUpNetwork() internal {
        setAcceptedCollateral();
        setInitialTimeAndPrice();
    }


    ///                                                                 ///
    ///                          Utility Functions                      ///
    ///                                                                 ///

    // Util functions to update token price everytime price changing function is called 
    // Update price within a given range:
    // ETHUSD: $700 - 7000; WBTCUSD: $14000 - 100000; PAXGUSD: $700 - 7000; EURUSD: $1.03 - 1.12
    // Use a fixed 1*1e8 price for TST price if needed
    function setPriceAndTime(uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) internal {
        int256 nativeUsd = int256(_nativeUsd * 1e8);
        int256 eurUsd = int256(_eurUsd * 1e4);
        int256 btcUsd = int256(_btcUsd * 1e8);
        int256 paxgUsd = int256(_paxgUsd * 1e8);

        // roll block time by 5 hours
        // If needed you can roll block number by corresponding time warp
        vm.warp(block.timestamp + 5 hours);
        uint256 blockTimestamp = block.timestamp;

        clNativeUsdPrice.addPriceRound(blockTimestamp, nativeUsd);
        clEurUsdPrice.addPriceRound(blockTimestamp, eurUsd);
        clBtcUsdPrice.addPriceRound(blockTimestamp, btcUsd);
        clPaxgUsdPrice.addPriceRound(blockTimestamp, paxgUsd);
    }

    function createUser(uint256 _id, uint256 _balance) internal returns(address){
        address user = vm.addr(_id + _balance);

        vm.deal(user, _balance * 1e18);
        TST.mint(user, _balance * 1e18);
        WBTC.mint(user, _balance * 1e8);
        PAXG.mint(user, _balance * 1e18);

        return user;
    }

    function createVaultOwners(uint256 _numOfOwners) public returns(ISmartVault[] memory) {
        address owner;
        address vaultAddr;
        uint256 tokenId;
        ISmartVault vault;

        ISmartVault[] memory vaults = new ISmartVault[](_numOfOwners);
        

        for (uint256 j = 0; j < _numOfOwners; j++) {
            owner = createUser(j, 100);
            vm.startPrank(owner);
            // mint a vault
            (address vaultAddr, uint256 tokenId)  = SmartVaultManagerContract.mint();
            vault = ISmartVault(vaultAddr);

            // transfer collateral (Native, WBTC, and PAXG) to vault
            // Transfer 10 ETH @ $2200, 1 BTC @ $42000, 10 PAXG @ $2000
            // Total initial collateral value: $84,000 or EUR76,107
            (bool sent,) = payable(vaultAddr).call{value: 10 * 1e18}("");
            require(sent,"Test ETH Tx failed");
            WBTC.transfer(vaultAddr, 1 * 1e8);
            PAXG.transfer(vaultAddr, 10 * 1e18);

            // Max mintable = euroCollateral() * HUNDRED_PC / collateralRate
            // Max mintable = 76,107 * 100000/110000 = 69,188 @ $1.1037 eurusd price

            vault.mint(owner, 55_350 * 1e18); //69,188 * 80%
            vm.stopPrank();

            vaults[j] = vault;
        }
        return vaults;
    }
    
    function setLiqPoolManagerAsset(uint256 _wbtcAmount, uint256 _paxgAmount) internal returns (ILiquidationPoolManager.Asset[] memory){
        // Create instances of the Token struct
        ITokenManager.Token memory wbtcToken;
        ITokenManager.Token memory paxgToken;

        wbtcToken.symbol = bytes32(abi.encodePacked("WBTC"));
        wbtcToken.addr = address(WBTC);
        wbtcToken.dec = 8;
        wbtcToken.clAddr = address(clBtcUsd);
        wbtcToken.clDec = 8;

        paxgToken.symbol = bytes32(abi.encodePacked("PAXG"));
        paxgToken.addr = address(PAXG);
        paxgToken.dec = 18;
        paxgToken.clAddr = address(clPaxgUsd);
        paxgToken.clDec = 8;

        ILiquidationPoolManager.Asset[] memory asset = new ILiquidationPoolManager.Asset[](2);

        asset[0] = ILiquidationPoolManager.Asset(wbtcToken, _wbtcAmount);
        asset[1] = ILiquidationPoolManager.Asset(paxgToken, _paxgAmount);

        return asset;
    }

    // Note to self
    // Remember to update asset price every time chainlink address is called
    // Remember to call LiquidationPoolManager::runLiquidation() after every function call
}
 