// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol" as Chainlink;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../test/foundry/interfaces/AggregatorV3InterfaceForTest.sol";
import "../test/foundry/interfaces/IERC20Mock.sol";
import "contracts/interfaces/IPriceCalculator.sol";


// Changes made for mock test to work
// import custom mock price oracle interfaces: AggregatorV3InterfaceForTest and IERC20Mock
// changed all instances of Chainlink.AggregatorV3Interface to AggregatorV3InterfaceForTest 
// changed return _symbol == NATIVE ? 0 : 18 - ERC20(_tokenAddress).decimals(); 
// to: return _symbol == NATIVE ? 0 : 18 - IERC20Mock(_tokenAddress).decimals();
// changed uint256 collateralUsd = scaledCollateral * avgPrice(4, tokenUsdClFeed);
// to: (, int256 latestPrice,,,) = tokenUsdClFeed.latestRoundData()
// uint256 collateralUsd = scaledCollateral * uint256(latestPrice);


contract PriceCalculator is IPriceCalculator {
    bytes32 private immutable NATIVE;

    AggregatorV3InterfaceForTest public immutable clEurUsd;

    constructor (bytes32 _native, address _clEurUsd) {
        NATIVE = _native;
        clEurUsd = AggregatorV3InterfaceForTest(_clEurUsd);
    }

    function avgPrice(uint8 _hours, AggregatorV3InterfaceForTest _priceFeed) private view returns (uint256) {
        uint256 startPeriod = block.timestamp - _hours * 1 hours;
        uint256 roundTS;
        uint80 roundId;
        int256 answer;
        (roundId, answer,, roundTS,) = _priceFeed.latestRoundData();
        uint256 accummulatedRoundPrices = uint256(answer);
        uint256 roundCount = 1;
        while (roundTS > startPeriod && roundId > 1) {
            roundId--;
            try _priceFeed.getRoundData(roundId) {
                (, answer,, roundTS,) = _priceFeed.getRoundData(roundId);
                accummulatedRoundPrices += uint256(answer);
                roundCount++;
            } catch {
                continue;
            }
        }
        return accummulatedRoundPrices / roundCount;
    }

    function getTokenScaleDiff(bytes32 _symbol, address _tokenAddress) private view returns (uint256 scaleDiff) {
        return _symbol == NATIVE ?  0 : 18 - IERC20Mock(_tokenAddress).decimals();
    }

    function tokenToEurAvg(ITokenManager.Token memory _token, uint256 _tokenValue) external view returns (uint256) {
        AggregatorV3InterfaceForTest tokenUsdClFeed = AggregatorV3InterfaceForTest(_token.clAddr);
        uint256 scaledCollateral = _tokenValue * 10 ** getTokenScaleDiff(_token.symbol, _token.addr);
        // uint256 collateralUsd = scaledCollateral * avgPrice(4, tokenUsdClFeed);
        (, int256 latestPrice,,,) = tokenUsdClFeed.latestRoundData();
        uint256 collateralUsd = scaledCollateral * uint256(latestPrice);
        (, int256 eurUsdPrice,,,) = clEurUsd.latestRoundData();
        return collateralUsd / uint256(eurUsdPrice);
    }

    function tokenToEur(ITokenManager.Token memory _token, uint256 _tokenValue) external view returns (uint256) {
        AggregatorV3InterfaceForTest tokenUsdClFeed = AggregatorV3InterfaceForTest(_token.clAddr);
        uint256 scaledCollateral = _tokenValue * 10 ** getTokenScaleDiff(_token.symbol, _token.addr);
        (,int256 _tokenUsdPrice,,,) = tokenUsdClFeed.latestRoundData();
        uint256 collateralUsd = scaledCollateral * uint256(_tokenUsdPrice);
        (, int256 eurUsdPrice,,,) = clEurUsd.latestRoundData();
        return collateralUsd / uint256(eurUsdPrice);
    }

    function eurToToken(ITokenManager.Token memory _token, uint256 _eurValue) external view returns (uint256) {
        AggregatorV3InterfaceForTest tokenUsdClFeed = AggregatorV3InterfaceForTest(_token.clAddr);
        (, int256 tokenUsdPrice,,,) = tokenUsdClFeed.latestRoundData();
        (, int256 eurUsdPrice,,,) = clEurUsd.latestRoundData();
        return _eurValue * uint256(eurUsdPrice) / uint256(tokenUsdPrice) / 10 ** getTokenScaleDiff(_token.symbol, _token.addr);
    }
}