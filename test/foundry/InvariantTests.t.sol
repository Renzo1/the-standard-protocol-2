// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TSBuilder.t.sol";
import "./Handler.t.sol";

contract RevolutionInvariantTest is TSBuilder {
    Handler internal handler;

    function setUp() public override {
        super.setUp();
        super.setUpNetwork();

        handler = new Handler(SmartVaultManagerContract, liquidationPoolManagerContract, liquidationPool, EUROs, TST, WBTC, PAXG, clNativeUsdPrice, clEurUsdPrice, clBtcUsdPrice, clPaxgUsdPrice);

        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](11);
        selectors[0] = Handler.distributeAssetsWrap.selector;
        selectors[1] = Handler.addCollateral.selector;
        selectors[2] = Handler.removeCollateralNativeWrap.selector;
        selectors[3] = Handler.removeCollateralWrap.selector;
        selectors[4] = Handler.removeAssetWrap.selector;
        selectors[5] = Handler.mintWrap.selector;
        selectors[6] = Handler.burnWrap.selector;
        selectors[7] = Handler.distributeFeesWrap.selector;
        selectors[8] = Handler.increasePositionWrap.selector;
        selectors[9] = Handler.decreasePositionWrap.selector;
        selectors[10] = Handler.claimRewardWrap.selector;

        // Handler Util functions are not called
        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
    }

    function invariant_just_for_test() public {
        // console.log("just for test");
        assert(true);
    }

    ///////////////////////////////////////////////
    ////// SmartVaultManager Invariant Tests //////
    ///////////////////////////////////////////////


    //////////////////////////////////////////
    ////// SmartVault Invariant Tests ////////
    //////////////////////////////////////////


    ////////////////////////////////////////////////////
    ////// liquidationPoolManager Invariant Tests //////
    ////////////////////////////////////////////////////


    /////////////////////////////////////////////
    ////// liquidationPool Invariant Tests //////
    /////////////////////////////////////////////

}