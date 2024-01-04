// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TSBuilder.t.sol";
import "./Handler.t.sol";

contract SmartVaultTest is TSBuilder {
    address user;
    ISmartVault vault;
    
    // struct VaultForTest { address owner; address vaultAddr; uint256 id;}

    function setUp() public override {
        super.setUp();
        super.setUpNetwork();
    }

    ////// liquidate Functions Tests //////
    /*
    Test Liquidation When Vault is Undercollateralized
    Test Liquidation When Vault is Not Undercollateralized
    Test Liquidation of all assets
    Test Liquidation State Persistence
    Test Liquidation Effects on EUROs Minting
    */
    // feel free to ignore all sanity checks. They merely debugging tools
    // Note: Ideally all assertions should have their own tests. 
    // I have cramped up multiple tests in this function to save time
    function testLiquidateUndercollateralisedVault(
        uint256 _amount,  
        uint256 _eurusd,  
        uint256 _ethPrice,  
        uint256 _btcPrice,  
        uint256 _paxgPrice
        ) public {
        // Fuzz price within a given range:
        // ETHUSD: $700 - 7000; WBTCUSD: $14000 - 100000; PAXGUSD: $700 - 7000; EURUSD: $1.03 - 1.12
        _eurusd = bound(_eurusd, 10000, 12000);
        _ethPrice = bound(_ethPrice, 700, 7000);
        _btcPrice = bound(_btcPrice, 14000, 100000);
        _paxgPrice = bound(_paxgPrice, 700, 7000);

        VaultForTest[] memory vaults = new VaultForTest[](1);
        vaults = createVaultOwners(1);

        address owner = vaults[0].owner;
        address vaultAddr = vaults[0].vaultAddr;
        uint256 vaultId = vaults[0].id;

        ISmartVault vault = ISmartVault(vaults[0].vaultAddr);
        ISmartVault.Status memory oldStatus = vault.status();
        uint256 oldMinted = oldStatus.minted;
        uint256 oldMaxMintable = oldStatus.maxMintable;
        // uint256 oldTotalCollateralValue = oldStatus.totalCollateralValue;
        // bool oldLiquidated = oldStatus.liquidated;

        // Ensures no EUROs has been minted
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners is commented out
        assertEq(oldMinted, 0);
        
        _amount = bound(_amount, 1, oldMaxMintable);
        // _amount = oldMaxMintable / 2; // Sanity check
        // console.log("Amount to mint: ", _amount); // Sanity check


        // Bug mint revert if _amount == maxMintable -- fixed!

        assertEq(vaultAddr, oldStatus.vaultAddress);

        vm.startPrank(owner);
        vault.mint(owner, _amount);
        vm.stopPrank();

        uint256 fee = _amount * feeRate / SmartVaultManagerContract.HUNDRED_PC();
        // Sanity checks
        // console.log("Vault ETH balance: ", vaultAddr.balance);
        // console.log("Vault BTC balance: ", WBTC.balanceOf(vaultAddr));
        // console.log("Vault PAXG balance: ", PAXG.balanceOf(vaultAddr));
        // console.log("Owner EUROs balance: ", EUROs.balanceOf(owner));
        // console.log("Max mintable: ", oldMaxMintable);
        // console.log("EUROs minted: ", oldMinted);

        // // starting prices: EUR/USD $11037; ETH/USD $2200; BTC/USD $42000; PAXGUSD $2000
        setPriceAndTime( _eurusd, _ethPrice, _btcPrice, _paxgPrice); // fuzz this with reasonable bounds

        // calculate collateral value in eur and max mintable
        uint256 nativeCollateralUsd = vaultAddr.balance * _ethPrice * 1e8 * 1e0; // balanc * priceUsd * 18 - decimal
        uint256 nativeBalanceEur =  nativeCollateralUsd  / (_eurusd * 1e4);
        uint256 wbtcCollateralUsd = WBTC.balanceOf(vaultAddr) * _btcPrice * 1e8 * 1e10;
        uint256 wbtcBalanceEur = wbtcCollateralUsd / (_eurusd * 1e4);
        uint256 paxgCollateralUsd = PAXG.balanceOf(vaultAddr) * _paxgPrice * 1e8 * 1e0;
        uint256 paxgBalanceEur = paxgCollateralUsd / (_eurusd * 1e4);

        uint256 totalCollateralValueEur = nativeBalanceEur + wbtcBalanceEur + paxgBalanceEur;
        uint256 maxMintable = totalCollateralValueEur * SmartVaultManagerContract.HUNDRED_PC() / collateralRate;

        ISmartVault.Status memory newStatus = vault.status();
        uint256 newMinted = newStatus.minted;
        uint256 newMaxMintable = newStatus.maxMintable;
        uint256 newTotalCollateralValue = newStatus.totalCollateralValue;
        bool newLiquidated = newStatus.liquidated;

        assertEq(newTotalCollateralValue, totalCollateralValueEur);
        assertEq(newMaxMintable, maxMintable);


        // If condition == true I expect the vault to be liquidated:
        // value of minted >= newMaxMintable1 
        if (newMinted > newMaxMintable){

            vm.startPrank(SmartVaultManager); // Prank vault manager
            vault.liquidate(); // call liquidate
            vm.stopPrank();

            ISmartVault.Status memory newStatus2 = vault.status();

            // assert newLiquidated is true
            assertEq(newStatus2.liquidated, true);
            // assert newMinted is 0
            assertEq(newStatus2.minted, 0);
            // Assert collateral balance is zero for ETH (native)
            assertEq(vaultAddr.balance, 0);
            // Assert collateral balance is zero for WBTC
            assertEq(WBTC.balanceOf(vaultAddr), 0);
            // Assert collateral balance is zero for PAXG
            assertEq(PAXG.balanceOf(vaultAddr), 0);
        } else{ // else I don't expect the vault to be liquidated

            vm.startPrank(SmartVaultManager); // Prank vault manager
            vm.expectRevert();
            vault.liquidate(); // call liquidate
            vm.stopPrank();

            ISmartVault.Status memory newStatus2 = vault.status();

            // assert newLiquidated is false
            assertEq(newStatus2.liquidated, false);
            // assert newMinted is 0
            assertGt(newStatus2.minted, 0);
            // Assert collateral balance is zero for ETH (native)
            assertGt(vaultAddr.balance, 0);
            // Assert collateral balance is zero for WBTC
            assertGt(WBTC.balanceOf(vaultAddr), 0);
            // Assert collateral balance is zero for PAXG
            assertGt(PAXG.balanceOf(vaultAddr), 0);
        }
    }

    function testCantLiquidateFullyCollateralisedVault() public {
        // mint a vault 
        // send collateral (all tokens)
        // mint EUROs
        // increase collateral price
        // call liquidate
        // Assert Native token didn't change
        // Assert WBTC token didn't change
        // Assert PAXG token didn't change
    }

    function testLiquidateStatePersistence() public {
        // mint a vault 
        // send collateral (all tokens)
        // mint EUROs
        // drop collateral price
        // call liquidate
        // Assert collateral balance is zero for ETH (native)
        // Assert collateral balance is zero for WBTC
        // Assert collateral balance is zero for PAXG
        // call liquidate (again)
        // Expect Revert
        // Assert collateral balance is zero for ETH (native)
        // Assert collateral balance is zero for WBTC
        // Assert collateral balance is zero for PAXG
    }

    function testMintEurosAfterLiquidation() public {
        // mint a vault 
        // send collateral (all tokens)
        // mint EUROs
        // drop collateral price
        // call liquidate
        // Assert collateral balance is zero for ETH (native)
        // Assert collateral balance is zero for WBTC
        // Assert collateral balance is zero for PAXG
        // call liquidate (again)
        // Expect Revert
        // Assert collateral balance is zero for ETH (native)
        // Assert collateral balance is zero for WBTC
        // Assert collateral balance is zero for PAXG
    }


    ////// removeCollateralNative & removeCollateral Functions Tests //////
    /*
    Test removal of Collateral by Owner
    Test removal of Collateral by beyond Collateral Rate
    */
    function testRemoveCollateral() public {
        // mint a vault
        // send collateral (all tokens)
        // Assert collateral balance is zero for ETH (native)
        // Assert collateral balance is zero for WBTC
        // Assert collateral balance is zero for PAXG
        // call removeCollateralNative
        // call removeCOllateral
        // Assert collateral balance is zero for ETH (native)
        // Assert collateral balance is zero for WBTC
        // Assert collateral balance is zero for PAXG
    }

    function testRemoveExcessCollateral() public {
        // mint a vault
        // send collateral (all tokens)
        // mint EUROs
        // Assert collateral balance is zero for ETH (native)
        // Assert collateral balance is zero for WBTC
        // Assert collateral balance is zero for PAXG
        // call removeCollateralNative
        // call removeCOllateral
        // Assert collateral balance is zero for ETH (native)
        // Assert collateral balance is zero for WBTC
        // Assert collateral balance is zero for PAXG
    }

    ////// mint Functions Tests //////
    /*
    Test Successful Minting by Owner
    Test Minting Leading to Undercollateralization
    */
    function testMint() public {
        // mint a vault
        // send collateral (all tokens)
        // bound amount to EUROs mintable by vault
        // Cache value of minted EUROs in USD
        // Assert collateral balance is zero for ETH (native)
        assert(true);
    }

    function testExcessMint() public {
        // mint a vault
        // send collateral (all tokens)
        // Cache value of collateral in USD
        // assume mint amount is >200% of collateral value
        // Expect revert
        // call mint
    }

    ////// burn Functions Tests //////
    // mint a vault
    // send collateral (all tokens)
    // bound mintAmount to EUROs mintable by vault
    // call mint EUROs
    // bound burnAmount to minted
    // !Expect revert
    // call burn (burnAmount)
    function testBurn(
        uint256 _mintAmount,
        uint256 _burnAmount
        ) public {
        VaultForTest[] memory vaults = new VaultForTest[](1);
        vaults = createVaultOwners(1);

        address owner = vaults[0].owner;
        address vaultAddr = vaults[0].vaultAddr;

        ISmartVault vault = ISmartVault(vaults[0].vaultAddr);
        ISmartVault.Status memory oldStatus = vault.status();
        uint256 minted = oldStatus.minted;
        uint256 maxMintable = oldStatus.maxMintable;

        // Ensures no EUROs has been minted
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners is commented out
        assertEq(minted, 0);

        _mintAmount = bound(_mintAmount, 1, maxMintable);

        vm.startPrank(owner);
        vault.mint(owner, _mintAmount);
        vm.stopPrank();

        ISmartVault.Status memory newStatus = vault.status();
        _burnAmount = bound(_burnAmount, 1, newStatus.minted);

        // factor in fee when test the bug fixed version of the contract. ref: testLiquidateUndercollateralisedVault
        // uint256 fee = _mintAmount * feeRate / SmartVaultManagerContract.HUNDRED_PC();
        // _mintAmount = _mintAmount - fee;

        // Bug burn reverts if _burnAmount == _mintAmount i.e.  EUROs.balanceOf(owner) -- fixed! 

        assertEq(_mintAmount, EUROs.balanceOf(owner));

        // Fails (ERC20: burn amount exceeds balance Counter) for the original contract
        // Passes for bug fixed version

        vault.burn(_burnAmount);

        assertEq(EUROs.balanceOf(owner), _mintAmount - _burnAmount);
    }

    function testCantBurnAllMinted(
        uint256 _mintAmount
        ) public {
        VaultForTest[] memory vaults = new VaultForTest[](1);
        vaults = createVaultOwners(1);

        address owner = vaults[0].owner;
        address vaultAddr = vaults[0].vaultAddr;

        ISmartVault vault = ISmartVault(vaults[0].vaultAddr);
        ISmartVault.Status memory oldStatus = vault.status();
        uint256 minted = oldStatus.minted;
        uint256 maxMintable = oldStatus.maxMintable;

        // Ensures no EUROs has been minted
        // i.e. mint vault.mint() in TSBuilder::createVaultOwners is commented out
        assertEq(minted, 0);

        _mintAmount = bound(_mintAmount, 1, maxMintable);

        vm.startPrank(owner);
        vault.mint(owner, _mintAmount);
        vm.stopPrank();

        ISmartVault.Status memory newStatus = vault.status();

        vm.expectRevert();
        vault.burn(EUROs.balanceOf(owner));
    }
}