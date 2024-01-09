// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./TSBuilder.t.sol";
import "./Handler.t.sol";

contract SmartVaultManagerTest is TSBuilder {
    address user;
    ISmartVault vault;

    function setUp() public override {
        super.setUp();
        super.setUpNetwork();
    }

    // feel free to ignore all sanity checks. They are merely debugging tools
    // Note: Ideally all assertions should have their own tests. 
    // I have cramped up multiple tests into this function to save time
    /* Function Summary
    - Create two vaults: 
        - The deposit collateral and mint (80% of max mintable) EUROs
    - Drop price of collateral assets into liquidation zone
    - Vault owners stake variable amount of TST and EUROs
    - Calculate the value of owners' position
    - Liquidate vaults
        - call LiquidationPoolManager::runLiquidation
        - The collateral assets is sold in the liquidationPool
    - Calculate value of reward(liquidated assets) received by owners
    - Test the fairness of reward distribution i.e. is the owner adding the most value, receiving the most reward?
    */
    function testRewardDistributeIsFairness(
        uint256 _owner1TstAmount,  
        uint256 _owner1EurAmount,  
        uint256 _owner2TstAmount,  
        uint256 _owner2EurAmount,  
        uint256 _eurusd,  
        uint256 _ethPrice,  
        uint256 _btcPrice, 
        uint256 _paxgPrice,
        uint256 _tstPrice,
        uint256 _distributionFactor
        ) public {
        // Fuzz price within a given range:
        // starting prices: EUR/USD $11037; ETH/USD $2200; BTC/USD $42000; PAXGUSD $2000
        // ETHUSD: $700 - 7000; WBTCUSD: $14000 - 100000; PAXGUSD: $700 - 7000; EURUSD: $1.03 - 1.12
        _eurusd = bound(_eurusd, 10000, 12000);
        _ethPrice = bound(_ethPrice, 700, 1500);
        _btcPrice = bound(_btcPrice, 14000, 25000);
        _paxgPrice = bound(_paxgPrice, 700, 1500);
        _tstPrice = bound(_tstPrice, 700, 7000);

        _tstPrice = _tstPrice * 1e8; // assumed price

        ISmartVault[] memory vaults = new ISmartVault[](2);
        vaults = createVaultOwners(2);

        setPriceAndTime( _eurusd, _ethPrice, _btcPrice, _paxgPrice); // fuzz this with reasonable bounds

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

        assertEq(tstBalance2, 100 * 1e18);
        assertEq(euroBalance2, 54_243 * 1e18);

        //////// Stake Tokens ////////
        vm.warp(block.timestamp + 2 days);

        _owner1TstAmount = bound(_owner1TstAmount, 0, tstBalance1);
        _owner1EurAmount = bound(_owner1EurAmount, 0, euroBalance1);
        if(_owner1TstAmount == 0) vm.assume( _owner1EurAmount > 0);

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

        // uint256 nativeBalanceEur =  nativeCollateralUsd  / (priceEurUsd);
        // uint256 nativeCollateralUsd = nativeBalanceEur * (priceEurUsd);
        // (,int256 btcPriceUsd,,,) = clBtcUsdPrice.latestRoundData();
        // (,int256 paxgPriceUsd,,,) = clPaxgUsdPrice.latestRoundData();
        (,int256 priceEurUsd,,,) = clEurUsdPrice.latestRoundData();

        // Calculate the value of owners staked positions
        // owner1 position value
        uint256 owner1TstPosition = _owner1TstAmount * _tstPrice * 1e0;
        uint256 owner1EurosPosition = _owner1EurAmount * uint256(priceEurUsd);
        uint256 owner1PosValue = owner1TstPosition + owner1EurosPosition;

        // owner2 position value
        uint256 owner2TstPosition = (_owner2TstAmount * _tstPrice) * uint256(priceEurUsd);
        uint256 owner2EurosPosition = _owner2EurAmount * uint256(priceEurUsd);
        uint256 owner2PosValue = owner2TstPosition + owner2EurosPosition;

        vm.warp(block.timestamp + 2 days);


        // Pool pre-liquidation balance
        uint256 poolEthBalance0 = pool.balance;
        uint256 poolWbtcBalance0 = WBTC.balanceOf(address(pool));
        uint256 poolPaxgBalance0 = PAXG.balanceOf(address(pool));

        // Bug fix: Without granting pool BURNER_ROLE, distributeAssets() reverts
        vm.startPrank(SmartVaultManager);
        IEUROs(euros_).grantRole(IEUROs(euros_).BURNER_ROLE(), pool);
        vm.stopPrank();

        // Liquidate any of the vaults
        vm.startPrank(liquidator);
        liquidationPoolManagerContract.runLiquidation(1);
        vm.stopPrank();

        // Pool pre-liquidation balance
        uint256 poolEthBalance1 = pool.balance;
        uint256 poolWbtcBalance1 = WBTC.balanceOf(address(pool));
        uint256 poolPaxgBalance1 = PAXG.balanceOf(address(pool));

        // Assert increment in pool's balance for collateral assets
        bool ethDelta = poolEthBalance1 > poolEthBalance0;
        bool wbtcDelta = poolWbtcBalance1 > poolWbtcBalance0;
        bool paxgDelta = poolPaxgBalance1 > poolPaxgBalance0;

        // assertTrue(ethDelta || wbtcDelta || paxgDelta);

        // struct Reward { bytes32 symbol; uint256 amount; uint8 dec; }
        // owner1 rewards
        ILiquidationPool.Position memory holdersPosition1;
        ILiquidationPool.Reward[] memory holdersReward1 = new ILiquidationPool.Reward[](3);
        (holdersPosition1, holdersReward1) = liquidationPool.position(owner1);

        // uint256 owner1TstPosition = _owner1TstAmount * _tstPrice * 1e0
        uint256 owner1EthReward = holdersReward1[0].amount * _ethPrice * 1e8 * 1e0; // amount * priceUsd * 1 ** 18 - decimal
        uint256 owner1WbtcReward = holdersReward1[1].amount * _btcPrice * 1e8 * 1e10;
        uint256 owner1PaxgReward = holdersReward1[2].amount * _paxgPrice * 1e8 * 1e0;
        uint256 owner1TotalReward = owner1EthReward + owner1WbtcReward + owner1PaxgReward;

        ILiquidationPool.Position memory holdersPosition2;
        ILiquidationPool.Reward[] memory holdersReward2 = new ILiquidationPool.Reward[](3);
        (holdersPosition2, holdersReward2) = liquidationPool.position(owner2);

        // uint256 owner1TstPosition = _owner1TstAmount * _tstPrice * 1e0
        uint256 owner2EthReward = holdersReward2[0].amount * _ethPrice * 1e8 * 1e0; // amount * priceUsd * 1 ** 18 - decimal
        uint256 owner2WbtcReward = holdersReward2[1].amount * _btcPrice * 1e8 * 1e10;
        uint256 owner2PaxgReward = holdersReward2[2].amount * _paxgPrice * 1e8 * 1e0;
        uint256 owner2TotalReward = owner1EthReward + owner1WbtcReward + owner1PaxgReward;

        // Test the fairness of reward distribution
        // If the value of owners1's stake is larger than owner2's stake
        // Owner's reward should be greater than owner's rewards.
        if(owner1PosValue > owner2PosValue) assertTrue(owner1TotalReward > owner2TotalReward);
        if(owner2PosValue > owner1PosValue) assertTrue(owner2TotalReward > owner1TotalReward);
    }

}