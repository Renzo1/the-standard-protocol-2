// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./TSBuilder.t.sol";
import "./Handler.t.sol";

contract LiquidationPoolTests is TSBuilder {
    address user;
    ISmartVault vault;

    function setUp() public override {
        super.setUp();
        super.setUpNetwork();
    }

    // feel free to ignore all sanity checks. They are merely debugging tools
    // Note: Ideally all assertions should have their own tests. 
    // I have cramped up multiple tests into this function to save time
    function testIncreasePosition(
        uint256 _owner1TstAmount,  
        uint256 _owner1EurAmount,  
        uint256 _owner2TstAmount,  
        uint256 _owner2EurAmount  
        ) public {
        ISmartVault[] memory vaults = new ISmartVault[](2);
        vaults = createVaultOwners(2);

        //////// Owner 1 variables ////////
        ISmartVault vault1 = vaults[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);

        // Ensure owner has EUROs and TST
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners isactiviated
        // However the value does match that with TSBuilder::createVaultOwners
        // Because this uses the corrected mint() function.
        assertEq(tstBalance1, 100 * 1e18);
        assertEq(euroBalance1, 54_243 * 1e18);

        //////// Owner 2 variables ////////
        ISmartVault vault2 = vaults[1];
        address owner2 = vault2.owner();
        uint256 tstBalance2 = TST.balanceOf(owner2);
        uint256 euroBalance2 = EUROs.balanceOf(owner2);

        // Ensure owner has EUROs and TST
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners isactiviated
        assertEq(tstBalance2, 100 * 1e18);
        assertEq(euroBalance2, 54_243 * 1e18);

        // // Sanity checks
        // console.log("Owner1 TST balance: ", tstBalance1);
        // console.log("Owner1 EUROs balance: ", euroBalance1);
        // console.log("Owner2 TST balance: ", tstBalance2);
        // console.log("Owner2 EUROs balance: ", euroBalance2);

        //////// Stake Tokens ////////
        vm.warp(block.timestamp + 2 days);



        _owner1TstAmount = bound(_owner1TstAmount, 0, tstBalance1);
        _owner1EurAmount = bound(_owner1EurAmount, 0, euroBalance1);
        if(_owner1TstAmount == 0) vm.assume( _owner1EurAmount != 0);

        uint256 poolTstBalance0 = TST.balanceOf(address(liquidationPool));
        uint256 poolEurBalance0 = EUROs.balanceOf(address(liquidationPool));

        vm.startPrank(owner1);
        TST.approve(address(liquidationPool), _owner1TstAmount);
        EUROs.approve(address(liquidationPool), _owner1EurAmount);
        liquidationPool.increasePosition( _owner1TstAmount, _owner1EurAmount);
        vm.stopPrank();

        // Test Stake Increases Pending Stakes
        assertEq(liquidationPool.getTstTotal(), _owner1TstAmount);

        uint256 poolTstBalance1 = TST.balanceOf(address(liquidationPool));
        uint256 poolEurBalance1 = EUROs.balanceOf(address(liquidationPool));

        // Test Transfer of TST and EUROs Amount Correctness
        assertEq(poolTstBalance1, _owner1TstAmount + poolTstBalance0);
        assertEq(poolEurBalance1, _owner1EurAmount + poolEurBalance0);

        vm.warp(block.timestamp + 2 days);

        _owner2TstAmount = bound(_owner2TstAmount, 0, tstBalance2);
        _owner2EurAmount = bound(_owner2EurAmount, 0, euroBalance2);
        if(_owner2TstAmount == 0) vm.assume( _owner2EurAmount > 0);

        vm.startPrank(owner2);
        TST.approve(address(liquidationPool), _owner2TstAmount);
        EUROs.approve(address(liquidationPool), _owner2EurAmount);
        liquidationPool.increasePosition( _owner2TstAmount, _owner2EurAmount);
        vm.stopPrank();

        // Test Holder Is Added to Holders Array


        // Test Consolidation of Pending Stakes


        // Test Consolidation of Pending Stakes


        // Test Transfer of TST and EUROs Amount Correctness


        // Test Correctness of New Pending Stake Entry



        // Sanity checks
        // console.log("Deadline: ", block.timestamp);
        // console.log("Owner2 EUROs balance: ", 1 days);
        // console.log("Owner1 TST balance: ", tstBalance1);
        // console.log("Owner1 EUROs balance: ", euroBalance1);
        // console.log("Contracts TST allowance: ",TST.allowance(owner1, address(liquidationPool)));
        // console.log("Contracts EUR allowance: ",EUROs.allowance(owner1, address(liquidationPool)));

        //////// Owners' Positions ////////

        // struct Position {  address holder; uint256 TST; uint256 EUROs; }
        // struct Reward { bytes32 symbol; uint256 amount; uint8 dec; }
        // function position(address) external view returns(Position memory, Reward[] memory);

        // Position position1 = liquidationPool.

    }

    function testDecreasePosition(
        uint256 _owner1TstAmount,  
        uint256 _owner1EurAmount,  
        uint256 _owner2TstAmount,  
        uint256 _owner2EurAmount,  
        uint256 _unstakeTstAmount,  
        uint256 _unstakeEurAmount
        ) public {

        ISmartVault[] memory vaults = new ISmartVault[](2);
        vaults = createVaultOwners(2);

        //////// Owner 1 variables ////////
        ISmartVault vault1 = vaults[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);

        // Ensure owner has EUROs and TST
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners isactiviated
        // However the value does match that with TSBuilder::createVaultOwners
        // Because this uses the corrected mint() function.
        assertEq(tstBalance1, 100 * 1e18);
        assertEq(euroBalance1, 54_243 * 1e18);

        //////// Owner 2 variables ////////
        ISmartVault vault2 = vaults[1];
        address owner2 = vault2.owner();
        uint256 tstBalance2 = TST.balanceOf(owner2);
        uint256 euroBalance2 = EUROs.balanceOf(owner2);

        // Ensure owner has EUROs and TST
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners isactiviated
        assertEq(tstBalance2, 100 * 1e18);
        assertEq(euroBalance2, 54_243 * 1e18);

        // // Sanity checks
        // console.log("Owner1 TST balance: ", tstBalance1);
        // console.log("Owner1 EUROs balance: ", euroBalance1);
        // console.log("Owner2 TST balance: ", tstBalance2);
        // console.log("Owner2 EUROs balance: ", euroBalance2);

        //////// Stake Tokens ////////
        vm.warp(block.timestamp + 2 days);



        _owner1TstAmount = bound(_owner1TstAmount, 0, tstBalance1);
        _owner1EurAmount = bound(_owner1EurAmount, 0, euroBalance1);
        if(_owner1TstAmount == 0) vm.assume( _owner1EurAmount != 0);

        uint256 poolTstBalance0 = TST.balanceOf(address(liquidationPool));
        uint256 poolEurBalance0 = EUROs.balanceOf(address(liquidationPool));

        vm.startPrank(owner1);
        TST.approve(address(liquidationPool), _owner1TstAmount);
        EUROs.approve(address(liquidationPool), _owner1EurAmount);
        liquidationPool.increasePosition( _owner1TstAmount, _owner1EurAmount);
        vm.stopPrank();

        // Test Stake Increases Pending Stakes
        assertEq(liquidationPool.getTstTotal(), _owner1TstAmount);

        uint256 poolTstBalance1 = TST.balanceOf(address(liquidationPool));
        uint256 poolEurBalance1 = EUROs.balanceOf(address(liquidationPool));

        // Test Transfer of TST and EUROs Amount Correctness
        assertEq(poolTstBalance1, _owner1TstAmount + poolTstBalance0);
        assertEq(poolEurBalance1, _owner1EurAmount + poolEurBalance0);

        vm.warp(block.timestamp + 2 days);

        // _owner2TstAmount = bound(_owner2TstAmount, 0, tstBalance2);
        // _owner2EurAmount = bound(_owner2EurAmount, 0, euroBalance2);
        // if(_owner2TstAmount == 0) vm.assume( _owner2EurAmount != 0);

        // vm.startPrank(owner2);
        // TST.approve(address(liquidationPool), _owner2TstAmount);
        // EUROs.approve(address(liquidationPool), _owner2EurAmount);
        // liquidationPool.increasePosition( _owner2TstAmount, _owner2EurAmount);
        // vm.stopPrank();

        //////// Unstake Tokens ////////
        _unstakeTstAmount = bound(_unstakeTstAmount, 0, _owner1TstAmount);
        _unstakeEurAmount = bound(_unstakeEurAmount, 0, _owner1EurAmount);

        vm.startPrank(owner1);
        liquidationPool.decreasePosition( _unstakeTstAmount, _unstakeEurAmount);
        vm.stopPrank();

        // Test Decrease Reduces Position
        uint256 poolTstBalance2 = TST.balanceOf(address(liquidationPool));
        uint256 poolEurBalance2 = EUROs.balanceOf(address(liquidationPool));
        
        assertEq(poolTstBalance2, poolTstBalance1 - _unstakeTstAmount);
        assertEq(poolEurBalance2, poolEurBalance1 - _unstakeEurAmount);

        // Test Transfer of TST and EUROs to Holder

        // Test Holder Removal on Empty Position

        // Test Fee Distribution Call

        // Test Consolidation of Pending Stakes

        // Test Position Not Deleted Prematurely

        // Test Correctness of Position After Partial Decrease


    }

    function testAssetsDistribution(
        uint256 _owner1TstAmount,  
        uint256 _owner1EurAmount,
        uint256 _distributionFactor
        ) public {

        ISmartVault[] memory vaults = new ISmartVault[](1);
        vaults = createVaultOwners(1);

        //////// Owner variables ////////
        ISmartVault vault1 = vaults[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);

        // Ensure owner has EUROs and TST
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners isactiviated
        // However the value does match that with TSBuilder::createVaultOwners
        // Because this uses the corrected mint() function.
        assertEq(tstBalance1, 100 * 1e18);
        assertEq(euroBalance1, 54_243 * 1e18);

        //////// Stake Tokens ////////
        // Without this warp you get an overflow/underflow 
        // because of the deadline logic in consolidatePendingStakes()
        vm.warp(block.timestamp + 2 days);

        _owner1TstAmount = bound(_owner1TstAmount, 1, tstBalance1);
        _owner1EurAmount = bound(_owner1EurAmount, 1, euroBalance1);
        // if(_owner1TstAmount == 0) vm.assume( _owner1EurAmount != 0); // avoid more reverts

        uint256 poolTstBalance0 = TST.balanceOf(address(liquidationPool));
        uint256 poolEurBalance0 = EUROs.balanceOf(address(liquidationPool));

        vm.startPrank(owner1);
        TST.approve(address(liquidationPool), _owner1TstAmount);
        EUROs.approve(address(liquidationPool), _owner1EurAmount);
        liquidationPool.increasePosition( _owner1TstAmount, _owner1EurAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        
        
        // Test Stake Increases Pending Stakes
        assertEq(liquidationPool.getTstTotal(), _owner1TstAmount);

        uint256 poolTstBalance1 = TST.balanceOf(address(liquidationPool));
        uint256 poolEurBalance1 = EUROs.balanceOf(address(liquidationPool));

        // Test Transfer of TST and EUROs Amount Correctness
        assertEq(poolTstBalance1, _owner1TstAmount + poolTstBalance0);
        assertEq(poolEurBalance1, _owner1EurAmount + poolEurBalance0);

        //////// Distribute Assets ////////
        // Bound value of asset distributed to total Euro available
        uint256 totalEurosStaked = EUROs.balanceOf(address(liquidationPool));
        _distributionFactor = bound(_distributionFactor, 1, 9);
        uint256 wbtcShare = totalEurosStaked * _distributionFactor / 10;
        uint256 paxgShare = totalEurosStaked - wbtcShare;

        // Extrapolate amount of wbtcusd and paxgusd to distribute
        (,int256 _btcUsd,,,) = clBtcUsdPrice.latestRoundData();
        (,int256 _paxgUsd,,,) = clPaxgUsdPrice.latestRoundData();

        uint256 _wbtcAmount = wbtcShare * uint256(_btcUsd);
        uint256 _paxgAmount = paxgShare * uint256(_paxgUsd);

        // Distribute Asset
        // setLiqPoolManagerAsset() is utility function that helps shorten this test
        // Caveat: we have to comment out the safeTransferFrom line in the distributionAsset
        // Because the assets in this case are not coming from liquidationPoolManager
        // Please remember to uncomment for other tests
        // Check SmartVaultManagerTest for the normal process.
        ILiquidationPoolManager.Asset[] memory assets = new ILiquidationPoolManager.Asset[](2);
        assets = setLiqPoolManagerAsset(_wbtcAmount, _paxgAmount);

        // // Sanity Check
        // assets = setLiqPoolManagerAsset(10e8, 100e18);


        uint256 owner1WbtcBalance0 = WBTC.balanceOf(address(owner1));
        uint256 owner1PaxgBalance0 = PAXG.balanceOf(address(owner1));

        // Bug fix: Without granting pool BURNER_ROLE, distributeAssets() reverts
        vm.startPrank(SmartVaultManager);
        IEUROs(euros_).grantRole(IEUROs(euros_).BURNER_ROLE(), pool);
        vm.stopPrank();

        // Mint assets to this address
        WBTC.mint(address(this), _wbtcAmount);
        PAXG.mint(address(this), _paxgAmount);

        // Approve liquidationPool to spend from address(this)
        WBTC.approve(address(liquidationPool), _wbtcAmount);
        PAXG.approve(address(liquidationPool), _paxgAmount);

        uint256 poolWbtcBalance0 = WBTC.balanceOf(pool);
        uint256 poolPaxgBalance0 = PAXG.balanceOf(pool);
        uint256 poolEurosBalance0 = EUROs.balanceOf(pool);

        // Note we have to call consolidatePendingStakes() first for owner1 to be added to holders array
        // otherwise the liquidationPool.position() call will revert. -- this is not a bug
        // Owner1 is yet to be added to holders array cause no function that consolidate positions has been called
        // since we created our position. To do this manually, we have to make consolidatePendingStakes() public
        liquidationPool.consolidatePendingStakes();

        // Sanity Check
        // ITokenManager.Token[] memory tokens = tokenManagerContract.getAcceptedTokens();
        // assertEq(tokens.length, 3);
        // ILiquidationPool.Reward[] memory holdersRewardN = liquidationPool.findRewards(owner1);
        // liquidationPool.findRewards(owner1);
        // console.log(liquidationPool.tokenManager());
        // console.log(tokenManager);

        ILiquidationPool.Position memory holdersPosition0;
        ILiquidationPool.Reward[] memory holdersReward0 = new ILiquidationPool.Reward[](3);
        (holdersPosition0, holdersReward0) = liquidationPool.position(owner1);


        liquidationPool.distributeAssets(assets, collateralRate, SmartVaultManagerContract.HUNDRED_PC());

        // Test that the correct amount of asset is sent to liquidationPool
        uint256 poolWbtcBalance1 = WBTC.balanceOf(pool);
        uint256 poolPaxgBalance1 = PAXG.balanceOf(pool);

        console.log("poolWbtcBalance1: ", poolWbtcBalance1);
        console.log("poolWbtcBalance0: ", poolWbtcBalance0);

        assertGe(poolWbtcBalance1, poolWbtcBalance0);
        assertGe(poolPaxgBalance1, poolPaxgBalance0);

        // // Sanity checks
        // console.log("owner1TstAmount: ",_owner1TstAmount);
        // console.log("owner1EurAmount: ",_owner1EurAmount);
        // console.log("distributionFactor: ",_distributionFactor);

        // Test that the correct amount of EURO is burnt.
        uint256 poolEurosBalance1 = EUROs.balanceOf(pool);

        // Note that totalEurosStaked is the value we converted to AssetUsd distributed
        assertEq(poolEurosBalance1, poolEurosBalance0 - totalEurosStaked);

        // Test Asset Distribution Increases Holder's Rewards
        ILiquidationPool.Position memory holdersPosition1;
        ILiquidationPool.Reward[] memory holdersReward1 = new ILiquidationPool.Reward[](3);
        (holdersPosition1, holdersReward1) = liquidationPool.position(owner1);

        // struct Reward { bytes32 symbol; uint256 amount; uint8 dec; }
        assertGe(holdersReward1[1].amount, holdersReward0[1].amount);
        assertGe(holdersReward1[2].amount, holdersReward0[2].amount);

        // Test EUROs Burned After Distribution
        // struct Position {  address holder; uint256 TST; uint256 EUROs; }
        assertLe(holdersPosition1.EUROs, holdersPosition0.EUROs);


        // Test No Distribution When Stake Total is Zero


        // Test Return of Unpurchased Native Currency


        //////// Claim Reward ////////
        uint256 owner1WbtcBalance1 = WBTC.balanceOf(address(owner1));
        uint256 owner1PaxgBalance1 = PAXG.balanceOf(address(owner1));

        vm.startPrank(owner1);
        liquidationPool.claimRewards();
        vm.stopPrank();

        uint256 owner1WbtcBalance2 = WBTC.balanceOf(address(owner1));
        uint256 owner1PaxgBalance2 = PAXG.balanceOf(address(owner1));

        uint256 wbtcReward = holdersReward1[1].amount;
        uint256 paxgReward = holdersReward1[2].amount;

        // Assert owner1 receives all their reward.
        assertEq(owner1WbtcBalance2, owner1WbtcBalance1 + wbtcReward);
        assertEq(owner1PaxgBalance2, owner1PaxgBalance1 + paxgReward);
    }



    /////////////////////////////////////
    //////     PoC Playgroung      //////
    /////////////////////////////////////
/*
Vulnerability: Incorrect Accounting in `LiquidationPool::distributeAssets()` Causes Permanent Loss of Holders' EUROs Position
The formula for calculating costInEuros in the distributeAsset() function is incorrect. It erroneously multiplies 
_portion by 10e(18 - asset.token.dec) instead of the correct 1e(18 - asset.token.dec), resulting in a cost that 
is an order of magnitude higher, causing the following if block to run and make erroneous changes to stakers position.

- Create one vaults with collateral
- Create two accounts
- Mint EUROs from vault to accounts
- Stake EUROs and TST in LiquidationPool
- Drop the collateral price
- Liquidate vaults
- Assert account loses EUROs position and receives no reward

*/

    function testAccountErrorLoss10e() public {

        ISmartVault[] memory vaults = new ISmartVault[](1);
        vaults = createVaultOwners(1);

        //////// Owner 1 variables ////////
        ISmartVault vault1 = vaults[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);

        // Assert  owner has EUROs and TST
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners isactiviated
        assertGt(tstBalance1, 45 * 1e18);
        assertGt(euroBalance1, 45_000 * 1e18);

        //////// Create two random accounts Transfer tokens to them ////////
        address account1 = vm.addr(111222);
        address account2 = vm.addr(888999);

        vm.startPrank(owner1);
        TST.transfer(account1, 20 * 1e18);
        TST.transfer(account2, 20 * 1e18);
        EUROs.transfer(account1, 20_000 * 1e18);
        EUROs.transfer(account2, 20_000 * 1e18);
        vm.stopPrank();

        uint256 account1TstBalance = TST.balanceOf(account1);
        uint256 account2TstBalance = TST.balanceOf(account2);
        uint256 account1EurosBalance = EUROs.balanceOf(account1);
        uint256 account2EurosBalance = EUROs.balanceOf(account2);

        assertEq(account1TstBalance, 20 * 1e18, "TEST 1");
        assertEq(account2TstBalance, 20 * 1e18, "TEST 2");
        assertEq(account1EurosBalance, 20_000 * 1e18, "TEST 3");
        assertEq(account2EurosBalance, 20_000 * 1e18, "TEST 4");


        //////// Stake Tokens ////////
        vm.warp(block.timestamp + 2 days);

        vm.startPrank(account1);
        TST.approve(pool, account1TstBalance);
        EUROs.approve(pool, account1EurosBalance);
        liquidationPool.increasePosition( account1TstBalance, account1EurosBalance);
        vm.stopPrank();

        vm.startPrank(account2);
        TST.approve(pool, account2TstBalance);
        EUROs.approve(pool, account2EurosBalance);
        liquidationPool.increasePosition( account2TstBalance, account2EurosBalance);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        // Assert LiquidationPool received the deposits
        assertEq(EUROs.balanceOf(pool), account1EurosBalance * 2, "TEST 5");
        assertEq(TST.balanceOf(pool), account1TstBalance * 2, "TEST 6");

        // starting prices: EUR/USD $11037; ETH/USD $2200; BTC/USD $42000; PAXGUSD $2000
        setPriceAndTime( 11037, 1100, 20000, 1000); // Drop collateral value

        //////// Liquidate vault ////////

        // struct Reward { bytes32 symbol; uint256 amount; uint8 dec; }
        // Position {  address holder; uint256 TST; uint256 EUROs; }

        // Account1 pre-liquidation Position
        ILiquidationPool.Position memory account1Position0;
        ILiquidationPool.Reward[] memory account1Reward0 = new ILiquidationPool.Reward[](3);
        (account1Position0, account1Reward0) = liquidationPool.position(account1);

        uint256 EurosPosition = account1Position0.EUROs;
        assertEq(account1EurosBalance, EurosPosition, "TEST 7");

        // Bug fix: Without granting pool BURNER_ROLE, distributeAssets() reverts
        vm.startPrank(SmartVaultManager);
        IEUROs(euros_).grantRole(IEUROs(euros_).BURNER_ROLE(), pool);
        vm.stopPrank();

        vm.startPrank(liquidator);
        liquidationPoolManagerContract.runLiquidation(1);
        vm.stopPrank();

        // account rewards
        ILiquidationPool.Position memory account1Position1;
        ILiquidationPool.Reward[] memory account1Reward1 = new ILiquidationPool.Reward[](3);
        (account1Position1, account1Reward1) = liquidationPool.position(owner1);

        // Assert account1 EUROs Position is wiped
        uint256 EurosPosition1 = account1Position1.EUROs;
        assertEq(EurosPosition1, 0, "TEST 8");

        // Assert account1 receive no Reward
        assertEq(account1Reward0[0].amount, account1Reward1[0].amount, "TEST 9");
        assertEq(account1Reward0[1].amount, account1Reward1[1].amount, "TEST 10");
        assertEq(account1Reward0[2].amount, account1Reward1[2].amount, "TEST 11");
    }

/*
Vulnerability: Permanent Loss of Stakers EUROs position
When the total value of the liquidated asset to be sold to the pool exceeds the total value of 'EUROs' available for the trade, 
the costInEuros is erroneously calculated. This results in the execution of the following if block, 
which wipes out stakers' balances. The miscalculation causes the if block to run, leading to inaccurate changes in stakers' positions.

To ensure this test actually test the vulnerability in question, and not just a copy of testAccountErrorLoss10e(),
we have to fix the vulnerability exposed by testAccountErrorLoss10e() in our scope contract.
To fix the vulnerability, change:
 uint256 costInEuros = _portion * 10 ** (18 - asset.token.dec) * uint256(assetPriceUsd) / uint256(priceEurUsd) * _hundredPC / _collateralRate;
to:
 uint256 costInEuros = _portion * 1 ** (18 - asset.token.dec) * uint256(assetPriceUsd) / uint256(priceEurUsd) * _hundredPC / _collateralRate;
*/

    function testLiquidatedAssetNoCap() public {

        ISmartVault[] memory vaults = new ISmartVault[](1);
        vaults = createVaultOwners(1);

        //////// Owner 1 variables ////////
        ISmartVault vault1 = vaults[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);

        // Assert  owner has EUROs and TST
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners isactiviated
        assertGt(tstBalance1, 45 * 1e18);
        assertGt(euroBalance1, 45_000 * 1e18);

        //////// Create two random accounts Transfer tokens to them ////////
        address account1 = vm.addr(111222);
        address account2 = vm.addr(888999);

        vm.startPrank(owner1);
        TST.transfer(account1, 20 * 1e18);
        TST.transfer(account2, 20 * 1e18);
        EUROs.transfer(account1, 20_000 * 1e18);
        EUROs.transfer(account2, 20_000 * 1e18);
        vm.stopPrank();

        uint256 account1TstBalance = TST.balanceOf(account1);
        uint256 account2TstBalance = TST.balanceOf(account2);
        uint256 account1EurosBalance = EUROs.balanceOf(account1);
        uint256 account2EurosBalance = EUROs.balanceOf(account2);

        assertEq(account1TstBalance, 20 * 1e18, "TEST 1");
        assertEq(account2TstBalance, 20 * 1e18, "TEST 2");
        assertEq(account1EurosBalance, 20_000 * 1e18, "TEST 3");
        assertEq(account2EurosBalance, 20_000 * 1e18, "TEST 4");


        //////// Stake Tokens ////////
        vm.warp(block.timestamp + 2 days);

        vm.startPrank(account1);
        TST.approve(pool, account1TstBalance);
        EUROs.approve(pool, account1EurosBalance);
        liquidationPool.increasePosition( account1TstBalance, account1EurosBalance);
        vm.stopPrank();

        vm.startPrank(account2);
        TST.approve(pool, account2TstBalance);
        EUROs.approve(pool, account2EurosBalance);
        liquidationPool.increasePosition( account2TstBalance, account2EurosBalance);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        // Assert LiquidationPool received the deposits
        assertEq(EUROs.balanceOf(pool), account1EurosBalance * 2, "TEST 5");
        assertEq(TST.balanceOf(pool), account1TstBalance * 2, "TEST 6");

        // starting prices: EUR/USD $11037; ETH/USD $2200; BTC/USD $42000; PAXGUSD $2000
        setPriceAndTime( 11037, 1100, 20000, 1000); // Drop collateral value

        //////// Liquidate vault ////////

        // struct Reward { bytes32 symbol; uint256 amount; uint8 dec; }
        // Position {  address holder; uint256 TST; uint256 EUROs; }

        // Account1 pre-liquidation Position
        ILiquidationPool.Position memory account1Position0;
        ILiquidationPool.Reward[] memory account1Reward0 = new ILiquidationPool.Reward[](3);
        (account1Position0, account1Reward0) = liquidationPool.position(account1);

        uint256 EurosPosition = account1Position0.EUROs;
        assertEq(account1EurosBalance, EurosPosition, "TEST 7");

        // Bug fix: Without granting pool BURNER_ROLE, distributeAssets() reverts
        vm.startPrank(SmartVaultManager);
        IEUROs(euros_).grantRole(IEUROs(euros_).BURNER_ROLE(), pool);
        vm.stopPrank();

        vm.startPrank(liquidator);
        liquidationPoolManagerContract.runLiquidation(1);
        vm.stopPrank();

        // account rewards
        ILiquidationPool.Position memory account1Position1;
        ILiquidationPool.Reward[] memory account1Reward1 = new ILiquidationPool.Reward[](3);
        (account1Position1, account1Reward1) = liquidationPool.position(owner1);

        // Assert account1 EUROs Position is wiped
        uint256 EurosPosition1 = account1Position1.EUROs;
        assertEq(EurosPosition1, 0, "TEST 8");

        // Assert account1 receive no Reward
        assertEq(account1Reward0[0].amount, account1Reward1[0].amount, "TEST 9");
        assertEq(account1Reward0[1].amount, account1Reward1[1].amount, "TEST 10");
        assertEq(account1Reward0[2].amount, account1Reward1[2].amount, "TEST 11");
    }

/*
Vulnerability: Potential Denial of Service (DoS) Attack in runLiquidation() Function Prevent Vault Liquidation
The runLiquidation() function contains sub-function calls that iterate through the pendingStakes, holders, and _asset arrays. 
As the protocol grows, these arrays become longer, resulting in increased gas consumption when calling the function. 
A malicious attacker could intentionally lengthen these arrays, making the distributeAsset() function unresponsive and 
preventing the liquidation of a vault.

For this test to work, you have to comment out the original liquidate() and mint() functions in SmartVaultV3
for the bug free versions. This way, the fees and liquidated assets are sent to the liquidator and not the protocol address
*/
    function testLiquidatorCantLiquidateVault() public {
        vm.txGasPrice(1);

        // //////// Create one vault ////////
        ISmartVault[] memory vaults = new ISmartVault[](20);
        vaults = createVaultOwners(20);

        //////// Owner 1 variables ////////
        ISmartVault vault1 = vaults[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);


        //////// Stake Tokens ////////
        vm.warp(block.timestamp + 2 days);

        vm.startPrank(owner1);
        TST.approve(pool, tstBalance1);
        EUROs.approve(pool, euroBalance1);
        liquidationPool.increasePosition( tstBalance1, euroBalance1);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        //////// Drop collateral assets value to liquidation threshold ////////

        // starting prices: EUR/USD $11037; ETH/USD $2200; BTC/USD $42000; PAXGUSD $2000
        setPriceAndTime( 11037, 1100, 20000, 1000); // Drop collateral value

        //////// Liquidate vault 1 ////////

        // Bug fix: Without granting pool BURNER_ROLE, distributeAssets() reverts
        vm.startPrank(SmartVaultManager);
        IEUROs(euros_).grantRole(IEUROs(euros_).BURNER_ROLE(), pool);
        vm.stopPrank();

        vm.startPrank(liquidator);
        uint256 gasStart1 = gasleft(); // see gas cost for subsequent transaction
        liquidationPoolManagerContract.runLiquidation(1);
        uint256 gasEnd1 = gasleft();
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        uint256 gasUsed1 = (gasStart1 - gasEnd1) * tx.gasprice;

        //////// Add more Holders to liquidationPool ////////

        for(uint256 i = 1; i < vaults.length; i++){

            vm.startPrank(vaults[i].owner());
            TST.approve(pool, tstBalance1);
            EUROs.approve(pool, euroBalance1);
            liquidationPool.increasePosition( 1, 1);
            vm.stopPrank();

        }

        //////// Liquidate vault 2 ////////
        vm.startPrank(liquidator);
        uint256 gasStart2 = gasleft(); // see gas cost for subsequent transaction
        liquidationPoolManagerContract.runLiquidation(2);
        uint256 gasEnd2 = gasleft();
        vm.stopPrank();

        uint256 gasUsed2 = (gasStart2 - gasEnd2) * tx.gasprice;

        //////// Assert increase in gas cost for both transactions ////////
        
        assertGt(gasUsed2, gasUsed1,"DoS TEST 1");
    }

/*
Vulnerability: Missing BURNER_ROLE for EURO in LiquidationPool Causes `distributeAssets()` to revert
When liquidated assets are sent to the LiquidationPool to be sold, the EUROs used in buying these assets are 
burned at the end of the distributeAssets() function call. However, the function call fails due to LiquidationPool 
being unable to burn EUROs because it is missing the BURNER_ROLE necessary to successfully complete this action.

For this test to work, you have to comment out the original liquidate() and mint() functions in SmartVaultV3
for the bug free versions. This way, the fees and liquidated assets are sent to the liquidator and not the protocol address
*/

    function testMissingBurnerRole() public {
        // //////// Create one vault ////////
        ISmartVault[] memory vaults = new ISmartVault[](20);
        vaults = createVaultOwners(20);

        //////// Owner 1 variables ////////
        ISmartVault vault1 = vaults[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);


        //////// Transfer EUROs to LiquidationPool ////////
        vm.startPrank(owner1);
        EUROs.transfer(pool, euroBalance1);
        vm.stopPrank();

        uint256 poolEurosBalance = EUROs.balanceOf(pool);
        assertEq(euroBalance1, poolEurosBalance); // Verify pool has EUROs in its account

        //////// Burn EUROs in Pool ////////
        vm.startPrank(pool);
        vm.expectRevert();
        EUROs.burn(pool, euroBalance1); // This line fails with a missing role error
        vm.stopPrank();
    }

/*
Vulnerability: `deleteHolder()` Looping Through `holders` Array for Stakers' Positions Poses a Potential Denial of Service (DoS) Attack
There is a potential DoS attack risk in the `decreasePosition()` function due to the `deletePosition()` method iterating 
over unbounded array lengths of `holders` and `pendingStakes`. When a user wants to decrease their position, they call the 
`decreasePosition()` function, which makes sub-calls down the stack to `deleteHolder()`. This function, in turn, loops 
through the `holders` array to find the user's position before taking action.Similarly, there is a potential DoS attack 
risk in the `increasePosition()` function due to the `addUniqueHolder()` method iterating over unbounded array lengths of
`holders`, When a user wants to increase their position.

For this test to work, you have to comment out the original liquidate() and mint() functions in SmartVaultV3
for the bug free versions. This way, the fees and liquidated assets are sent to the liquidator and not the protocol address
*/
    function testPositionDecrementDoS() public {
        vm.txGasPrice(1);

        // //////// Create one vault ////////
        ISmartVault[] memory vaults = new ISmartVault[](20);
        vaults = createVaultOwners(20);

        //////// Owner 1 variables ////////
        ISmartVault vault1 = vaults[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);


        //////// Stake Tokens ////////
        vm.warp(block.timestamp + 2 days);

        vm.startPrank(owner1);
        TST.approve(pool, tstBalance1);
        EUROs.approve(pool, euroBalance1);
        liquidationPool.increasePosition( tstBalance1, euroBalance1);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);


        //////// Decrease 1st half Position ////////
        vm.startPrank(owner1);
        TST.approve(pool, tstBalance1);
        EUROs.approve(pool, euroBalance1);
        uint256 gasStart1 = gasleft(); // see gas cost for subsequent transaction
        liquidationPool.decreasePosition( tstBalance1 / 2, euroBalance1 / 2);
        uint256 gasEnd1 = gasleft();
        vm.stopPrank();

        uint256 gasUsed1 = (gasStart1 - gasEnd1) * tx.gasprice;


        //////// Add more Holders to liquidationPool ////////

        for(uint256 i = 1; i < vaults.length; i++){

            vm.startPrank(vaults[i].owner());
            TST.approve(pool, tstBalance1);
            EUROs.approve(pool, euroBalance1);
            liquidationPool.increasePosition( 1, 1);
            vm.stopPrank();

        }

        vm.warp(block.timestamp + 2 days);

        //////// Decrease 2nd half Position ////////

        vm.startPrank(owner1);
        TST.approve(pool, tstBalance1);
        EUROs.approve(pool, euroBalance1);
        uint256 gasStart2 = gasleft(); 
        liquidationPool.decreasePosition( tstBalance1 / 2, euroBalance1 / 2);
        uint256 gasEnd2 = gasleft();
        vm.stopPrank();

        uint256 gasUsed2 = (gasStart2 - gasEnd2) * tx.gasprice;

        //////// Assert increase in gas cost for 2nd transactions ////////
        
        assertGt(gasUsed2, gasUsed1,"DoS TEST 1");
    }

/*
Vulnerability: `deleteHolder()` Looping Through `holders` Array for Stakers' Positions Poses a Potential Denial of Service (DoS) Attack
There is a potential DoS attack risk in the `decreasePosition()` function due to the `deletePosition()` method iterating 
over unbounded array lengths of `holders` and `pendingStakes`. When a user wants to decrease their position, they call the 
`decreasePosition()` function, which makes sub-calls down the stack to `deleteHolder()`. This function, in turn, loops 
through the `holders` array to find the user's position before taking action.Similarly, there is a potential DoS attack 
risk in the `increasePosition()` function due to the `addUniqueHolder()` method iterating over unbounded array lengths of
`holders`, When a user wants to increase their position.

For this test to work, you have to comment out the original liquidate() and mint() functions in SmartVaultV3
for the bug free versions. This way, the fees and liquidated assets are sent to the liquidator and not the protocol address
*/
    function testPositionIncrementDoS() public {
        vm.txGasPrice(1);

        // //////// Create one vault ////////
        ISmartVault[] memory vaults = new ISmartVault[](20);
        vaults = createVaultOwners(20);

        //////// Owner 1 variables ////////
        ISmartVault vault1 = vaults[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);


        //////// Stake Tokens ////////
        vm.warp(block.timestamp + 2 days);

        vm.startPrank(owner1);
        TST.approve(pool, tstBalance1);
        EUROs.approve(pool, euroBalance1);
        uint256 gasStart1 = gasleft(); // see gas cost for subsequent transaction
        liquidationPool.increasePosition( tstBalance1/2, euroBalance1/2);
        uint256 gasEnd1 = gasleft();
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        uint256 gasUsed1 = (gasStart1 - gasEnd1) * tx.gasprice;


        //////// Add more Holders to liquidationPool ////////

        for(uint256 i = 1; i < vaults.length; i++){

            vm.startPrank(vaults[i].owner());
            TST.approve(pool, tstBalance1);
            EUROs.approve(pool, euroBalance1);
            liquidationPool.increasePosition( 1, 1);
            vm.stopPrank();

        }

        vm.warp(block.timestamp + 2 days);

        //////// Decrease 2nd half Position ////////

        vm.startPrank(owner1);
        TST.approve(pool, tstBalance1);
        EUROs.approve(pool, euroBalance1);
        uint256 gasStart2 = gasleft(); 
        liquidationPool.increasePosition( tstBalance1 / 2, euroBalance1 / 2);
        uint256 gasEnd2 = gasleft();
        vm.stopPrank();

        uint256 gasUsed2 = (gasStart2 - gasEnd2) * tx.gasprice;

        //////// Assert increase in gas cost for 2nd transactions ////////
        
        assertGt(gasUsed2, gasUsed1,"DoS TEST 1");
    }

/*
Vulnerability: `distributeFees()` Looping Through `pendingStakes` Array for Stakers' Positions Pose a Potential Denial of Service (DoS) Attack
Whenever the following functions are called, they make sub-function calls that iterate over the `pendingStakes` array: 
`LiquidationPool::increasePosition()`, `LiquidationPool::decreasePosition()`, `LiquidationPool::distributeAssets()`, 
`LiquidationPoolManager::distributeFees()`, `LiquidationPoolManager::runLiquidation()`, and `LiquidationPool::distributeFees()`.
These sub-functions, in turn, loop through the `pendingStake` array to find the user's position before taking action.

For this test to work, you have to comment out the original liquidate() and mint() functions in SmartVaultV3
for the bug free versions. This way, the fees and liquidated assets are sent to the liquidator and not the protocol address

This test doubles for Vulnerability: `getTstTotal()` Looping Through `pendingStakes` Array for Stakers' Positions Pose a Potential Denial of Service (DoS) Attack

*/
    function testFeeDistributionDoS() public {
        vm.txGasPrice(1);

        // //////// Create one vault ////////
        ISmartVault[] memory vaults0 = new ISmartVault[](1);
        vaults0 = createVaultOwners(1);

        //////// Owner 1 variables ////////
        ISmartVault vault1 = vaults0[0];
        address owner1 = vault1.owner();
        uint256 tstBalance1 = TST.balanceOf(owner1);
        uint256 euroBalance1 = EUROs.balanceOf(owner1);


        //////// Stake Tokens -- create holder ////////
        vm.warp(block.timestamp + 2 days);

        vm.startPrank(owner1);
        TST.approve(pool, tstBalance1);
        EUROs.approve(pool, euroBalance1);
        liquidationPool.increasePosition( tstBalance1/4, euroBalance1/4);
        EUROs.transfer(liquidationPoolManager, tstBalance1/4);
        vm.stopPrank();

        assertEq(EUROs.balanceOf(liquidationPoolManager),tstBalance1/4);

        //////// Distribute fees ////////
        uint256 gasStart1 = gasleft(); // see gas cost for subsequent transaction
        liquidationPoolManagerContract.distributeFees();
        uint256 gasEnd1 = gasleft();


        vm.warp(block.timestamp + 2 days); // clear pendingStakes

        uint256 gasUsed1 = (gasStart1 - gasEnd1) * tx.gasprice;

        //////// Add more holders to liquidationPool ////////
        ISmartVault[] memory vaults = new ISmartVault[](20);
        vaults = createVaultOwners(20);

        for(uint256 i = 0; i < vaults.length; i++){
            vm.startPrank(vaults[i].owner());
            TST.approve(pool, tstBalance1);
            EUROs.approve(pool, euroBalance1);
            liquidationPool.increasePosition( 1000, 1000);
            vm.stopPrank();
        }

        //////// Distribute fees again ////////
        vm.startPrank(owner1);
        EUROs.transfer(liquidationPoolManager, tstBalance1/4);
        vm.stopPrank();

        assertGt(EUROs.balanceOf(liquidationPoolManager), 0);

        uint256 gasStart2 = gasleft(); // see gas cost for subsequent transaction
        liquidationPoolManagerContract.distributeFees();
        uint256 gasEnd2 = gasleft();

        uint256 gasUsed2 = (gasStart2 - gasEnd2) * tx.gasprice;

        //////// Assert increase in gas cost for 2nd transactions ////////
        assertGt(gasUsed2, gasUsed1,"DoS TEST 1");
    }
}