// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

////// Foundry cheats //////
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

import "./TSBuilder.t.sol";

////// Scope interfaces //////
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


contract Handler is CommonBase, StdCheats, StdUtils, DSTest {

    ////// Scope Contracts //////
    ISmartVaultManagerV5 smartVaultManager;
    ILiquidationPoolManager liquidationPoolManager;
    ILiquidationPool liquidationPool;

    ////// Network Assets //////
    IEUROs public EUROs;
    IERC20Mock public TST;
    IERC20Mock public WBTC;
    IERC20Mock public PAXG;

    ////// Network Actors //////
    address public owner; 
    address public protocol;
    address public liquidator;
    address payable public treasury;

    ////// Oracle Contracts //////
    AggregatorV3InterfaceForTest public clNativeUsd;
    AggregatorV3InterfaceForTest public clEurUsd;
    AggregatorV3InterfaceForTest public clBtcUsd;
    AggregatorV3InterfaceForTest public clPaxgUsd;


    ////// Other variables //////
    uint256 public collateralRate = 110000;
    uint256 public feeRate = 2000;
    uint32 public poolFeePercentage = 50000;

    struct SmartVaultData { 
        uint256 tokenId; uint256 collateralRate; uint256 mintFeeRate;
        uint256 burnFeeRate; ISmartVault.Status status;
    }


    constructor(ISmartVaultManagerV5 _smartVaultManager,
        ILiquidationPoolManager _liquidationPoolManager,
        ILiquidationPool _pool,
        IEUROs _euros,
        IERC20Mock _tst,
        IERC20Mock _wbtc,
        IERC20Mock _paxg,
        AggregatorV3InterfaceForTest _clNativeUsd,
        AggregatorV3InterfaceForTest _clEurUsd,
        AggregatorV3InterfaceForTest _clBtcUsd,
        AggregatorV3InterfaceForTest _clPaxgUsd
        ){
            smartVaultManager = _smartVaultManager;
            liquidationPoolManager = _liquidationPoolManager;
            liquidationPool = _pool;
            EUROs = _euros;
            TST = _tst;
            WBTC = _wbtc;
            PAXG = _paxg;
            clNativeUsd = _clNativeUsd;
            clEurUsd = _clEurUsd;
            clBtcUsd = _clBtcUsd;
            clPaxgUsd = _clPaxgUsd;

            owner = vm.addr(420420);
            protocol = address(liquidationPoolManager);
            liquidator = address(liquidationPoolManager);
            treasury = payable(vm.addr(11022033));

            // CultureIndex Util Set Up
            createCommunity(100, 1_000_000);
            createVaultOwners(9);
    }
    
    // Sanity checks
    // function testForDebugging() public{
    //         createVaultOwners(9);
    // }

    /////////////////////////////////////
    ////// Utility Functions Tests //////
    /////////////////////////////////////
    address[] public communityMembers;
    address[] public vaultOwners;

    address public currentActor;

    mapping(address => ISmartVault) public ownerToVault;
    mapping(ISmartVault => uint256)  public vaultId;

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = communityMembers[bound(actorIndexSeed, 0, communityMembers.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    modifier useOwner(uint256 actorIndexSeed) {
        currentActor = vaultOwners[bound(actorIndexSeed, 0, vaultOwners.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    // Create users (creators and sponsors) context. They'll also serve as potential voters
    function createCommunity(uint256 _numOfMembers, uint256 _balance) public {

        communityMembers = new address[](_numOfMembers);
        for (uint256 i = 0; i < _numOfMembers; i++) {
            address user = vm.addr(_numOfMembers + i);

            vm.deal(user, _balance * 1e18);
            TST.mint(user, _balance * 1e18);
            WBTC.mint(user, _balance * 1e8);
            PAXG.mint(user, _balance * 1e18);

            communityMembers[i] = user;
        }
    }

    // function mint(uint256 _actorIndexSeed) external useActor(_actorIndexSeed){
    //     (address _vault, uint256 _tokenId)  = smartVaultManager.mint();
    //     ISmartVault vault = ISmartVault(_vault);

    //     vaultOwners.push(msg.sender);
    //     ownerToVault[msg.sender] = vault;
    //     vaultId[vault] = _tokenId;
    // }

    // Create different groups of vault owners
    // Grouped by collateral to minted ratio i.e. closeness to liquidation
    // Group of 10 address from communityMembers[]
    function createVaultOwners(uint256 _cohorts) public {
        require(_cohorts < communityMembers.length, "must be less than community");
        address owner;
        ISmartVault vault;
        uint256 membersPerCohort = communityMembers.length / _cohorts;
        
        // Leave the last cohort as is
        for (uint256 i = 0; i < _cohorts - 1; i++) {

            uint256 j = i * membersPerCohort;
            uint256 lastMember = j + membersPerCohort;

            for (j; j < lastMember; j++) {
                owner = communityMembers[j];
                vm.startPrank(owner);
                // mint a vault
                (address vaultAddr, uint256 _tokenId)  = smartVaultManager.mint();
                vault = ISmartVault(vaultAddr);
                vaultOwners.push(owner);
                ownerToVault[owner] = vault;
                vaultId[vault] = _tokenId;

                // transfer collateral (Native, WBTC, and PAXG) to vault
                // Transfer 10 ETH @ $2200, 1 BTC @ $42000, 10 PAXG @ $2000
                // Total initial collateral value: $84,000 or EUR76,107
                vaultAddr.call{value: 10 * 1e18}("");
                WBTC.transfer(vaultAddr, 1 * 1e8);
                PAXG.transfer(vaultAddr, 10 * 1e18);

                // Max mintable = euroCollateral() * HUNDRED_PC / collateralRate
                // Max mintable = 76,107 * 100000/110000 = 69,188 @ $1.1037 eurusd price
                // Cohort mint EUROs in increment of 10%
                // The last cohort to mint, will mint close to liquidation threshold
                uint256 amount = 76_000 * lastMember / 10; 
                vault.mint(owner, amount * 1e18);
                vm.stopPrank();
            }
        }
    }

    // runLiquidation  function is called after every wrapper function call
    function runLiquidation() internal {
        // Get all the minted vaults
        uint256 vaultsMinted = smartVaultManager.lastToken();

        // call liquidate on all vaults
        for(uint256 i = 0; i < vaultsMinted; i++){
            liquidationPoolManager.runLiquidation(i);
        }
    }

    // Util functions to update token price everytime price changing function is called 
    // Update price within a given range:
    // ETHUSD: $700 - 7000; WBTCUSD: $14000 - 100000; PAXGUSD: $700 - 7000; EURUSD: $1.03 - 1.12
    // Use a fixed 1*1e8 price for TST price if needed
    function setPriceAndTime(uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) internal {
        int256 eurUsd = int256(_eurUsd * 1e4);
        int256 nativeUsd = int256(_nativeUsd * 1e8);
        int256 btcUsd = int256(_btcUsd * 1e8);
        int256 paxgUsd = int256(_paxgUsd * 1e8);

        // roll block time by 5 hours
        // If needed you can roll block number by corresponding time warp
        vm.warp(block.timestamp + 5 hours);
        uint256 blockTimestamp = block.timestamp;

        clNativeUsd.addPriceRound(blockTimestamp, nativeUsd);
        clEurUsd.addPriceRound(blockTimestamp, eurUsd);
        clBtcUsd.addPriceRound(blockTimestamp, btcUsd);
        clPaxgUsd.addPriceRound(blockTimestamp, paxgUsd);
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

    /////////////////////////////////////////////////
    ////// SmartVaultManager Wrapper Functions //////
    /////////////////////////////////////////////////


    // function mint(uint256 _actorIndexSeed) external useActor(_actorIndexSeed){
    //     (address _vault, uint256 _tokenId)  = smartVaultManager.mint();
    //     ISmartVault vault = ISmartVault(_vault);

    //     vaultOwners.push(msg.sender);
    //     ownerToVault[msg.sender] = vault;
    //     vaultId[vault] = _tokenId;
    // }

    ////////////////////////////////////////////
    ////// SmartVault Wrapper Functions ////////
    ////////////////////////////////////////////
    function addCollateral(uint256 _nativeAmount, uint256 _wbtcAmount, uint256 _paxgAmount, uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useOwner(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000
        
        _nativeAmount = bound(_nativeAmount, 0, 1000);
        _wbtcAmount = bound(_wbtcAmount, 0, 1000);
        _paxgAmount = bound(_paxgAmount, 0, 1000);

        address vaultAddr = address(ownerToVault[msg.sender]);

        uint256 originalNativeBalance = vaultAddr.balance;
        uint256 originalWbtBalance = WBTC.balanceOf(msg.sender);
        uint256 originalPaxgBalance = PAXG.balanceOf(msg.sender);

        vaultAddr.call{value: _nativeAmount * 1e18}("");
        WBTC.transfer(vaultAddr, _wbtcAmount * 1e8);
        PAXG.transfer(vaultAddr, _paxgAmount * 1e18);

        uint256 newNativeBalance = vaultAddr.balance;
        uint256 newWbtBalance = WBTC.balanceOf(msg.sender);
        uint256 newPaxgBalance = PAXG.balanceOf(msg.sender);

        // assert assets were sent
        assertEq(newNativeBalance, originalNativeBalance - _nativeAmount);
        assertEq(newWbtBalance, originalNativeBalance - _wbtcAmount);
        assertEq(newPaxgBalance, originalNativeBalance - _paxgAmount);


        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    function removeCollateralNativeWrap(uint256 _nativeAmount, uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useOwner(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000

        ISmartVault vault = ownerToVault[msg.sender];

        _nativeAmount = bound(_nativeAmount, 0, address(vault).balance);


        uint256 originalNativeBalance = address(vault).balance;
        vault.removeCollateralNative(_nativeAmount, payable(msg.sender));
        uint256 newNativeBalance = address(vault).balance;

        // assert assets were sent
        assertEq(newNativeBalance, originalNativeBalance - _nativeAmount);

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    function removeCollateralWrap(uint256 chooseToken, uint256 _amount, uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useOwner(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000

        bytes32 symbol;
        IERC20Mock token;

        ISmartVault vault = ownerToVault[msg.sender];
        chooseToken = bound(chooseToken, 0, 1);

        if(chooseToken == 0){
            symbol = bytes32(abi.encodePacked("WBTC"));
            token = WBTC;
        }else{
            symbol = bytes32(abi.encodePacked("PAXG"));
            token = PAXG;
        }

        _amount = bound(_amount, 0, token.balanceOf(msg.sender));

        uint256 originalBalance = token.balanceOf(address(vault));
        vault.removeCollateral(symbol, _amount, msg.sender);
        uint256 newBalance = token.balanceOf(address(vault));

        // assert assets were sent
        assertEq(newBalance, originalBalance - _amount);

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    function removeAssetWrap(uint256 chooseToken, uint256 _amount, uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useOwner(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000

        address tokenAddr;
        IERC20Mock token;

        ISmartVault vault = ownerToVault[msg.sender];
        chooseToken = bound(chooseToken, 0, 1);

        if(chooseToken == 0){
            tokenAddr = address(WBTC);
            token = WBTC;
        }else{
            tokenAddr = address(PAXG);
            token = PAXG;
        }

        _amount = bound(_amount, 0, token.balanceOf(msg.sender));


        uint256 originalBalance = token.balanceOf(address(vault));
        vault.removeAsset(tokenAddr, _amount, msg.sender);
        uint256 newBalance = token.balanceOf(address(vault));

        // assert assets were sent
        assertEq(newBalance, originalBalance - _amount);

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    function mintWrap(uint256 _amount, uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useOwner(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000
        _amount = bound(_amount, 0, 200);

        ISmartVault vault = ownerToVault[msg.sender];
        vault.mint(msg.sender, _amount);

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    function burnWrap(uint256 _amount, uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useOwner(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000
        _amount = bound(_amount, 0, 200);

        ISmartVault vault = ownerToVault[msg.sender];
        vault.burn(_amount);

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    //////////////////////////////////////////////////////
    ////// liquidationPoolManager Wrapper Functions //////
    //////////////////////////////////////////////////////

    function distributeFeesWrap(uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external {
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000

        liquidationPoolManager.distributeFees();

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    ///////////////////////////////////////////////
    ////// liquidationPool Wrapper Functions //////
    ///////////////////////////////////////////////

    function increasePositionWrap(uint256 _tstVal, uint256 _eurosVal, uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useActor(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000

        _tstVal = bound(_tstVal, 0, 1000);
        _eurosVal = bound(_eurosVal, 0, 1000);

        uint256 originalTstBalance = TST.balanceOf(address(liquidationPool));
        // uint256 originalEurosBalance = EUROs.balanceOf(address(liquidationPool));

        liquidationPool.increasePosition(_tstVal, _eurosVal);

        uint256 newTstBalance = TST.balanceOf(address(liquidationPool));
        // uint256 newEurosBalance = EUROs.balanceOf(address(liquidationPool));

        // assert assets were sent
        assertEq(newTstBalance, originalTstBalance + _tstVal);
        // assertEq(newEurosBalance, originalEurosBalance + _eurosVal);

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    function decreasePositionWrap(uint256 _tstVal, uint256 _eurosVal, uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useActor(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000

        bound(_tstVal, 0, 1000);
        bound(_eurosVal, 0, 1000);

        uint256 originalTstBalance = TST.balanceOf(address(liquidationPool));
        // uint256 originalEurosBalance = EUROs.balanceOf(address(liquidationPool));

        liquidationPool.decreasePosition(_tstVal, _eurosVal);

        uint256 newTstBalance = TST.balanceOf(address(liquidationPool));
        // uint256 newEurosBalance = EUROs.balanceOf(address(liquidationPool));

        // assert assets were sent
        // assertEq(newTstBalance, originalTstBalance - _tstVal);
        // assertEq(newEurosBalance, originalEurosBalance - _eurosVal);

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    function claimRewardWrap(uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useActor(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000

        liquidationPool.claimRewards();

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }

    function distributeAssetsWrap(uint256 _wbtcAmount, uint256 _paxgAmount, uint256 _collateralRate, uint256 _hundredPC, uint256 _actorIndexSeed, uint256 _eurUsd, uint256 _nativeUsd, uint256 _btcUsd, uint256 _paxgUsd) external useActor(_actorIndexSeed){
        // Price movement
        _eurUsd = bound(_eurUsd, 10300, 11200); // $1.03 - 1.12
        _nativeUsd = bound(_nativeUsd, 700, 7000); // $700 - 7000
        _btcUsd = bound(_btcUsd, 14000, 100000); // $14000 - 100000
        _paxgUsd = bound(_paxgUsd, 700, 5000); // $700 - 5000

        _wbtcAmount = bound(_wbtcAmount, 0, 10000);
        _paxgAmount = bound(_paxgAmount, 0, 10000);

        ILiquidationPoolManager.Asset[] memory assets = setLiqPoolManagerAsset(_wbtcAmount, _paxgAmount);

        liquidationPool.distributeAssets(assets, _collateralRate, _hundredPC);

        setPriceAndTime(_eurUsd, _nativeUsd, _btcUsd, _paxgUsd);
        runLiquidation();
    }
}