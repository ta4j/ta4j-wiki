# Perpetual Futures Quickstart

Use this page when you want to run an offline leveraged linear perpetual backtest and understand its results.

Requires ta4j 0.28.1 or later. The example and supporting APIs are pending human merge; this excerpt is from [`PerpetualFuturesBacktest` at commit 71db021](https://github.com/ta4j/ta4j/blob/71db021f54852a3a91cb393d4857c552a92060c6/ta4j-examples/src/main/java/ta4jexamples/backtesting/PerpetualFuturesBacktest.java), not a claim about master.

## 1) What you will build

The complete runnable class at the source link supplies imports, constants, synthetic four-hour bars and a `main` method. Its central backtest is the following exact excerpt:

```java
    static TradingRecord run(BarSeries series, double leverage, double fundingRate) {
        ClosePriceIndicator price = new ClosePriceIndicator(series);
        double liquidationLossPercentage = 100 * (1 / leverage - MAINTENANCE_MARGIN_RATE);
        Rule liquidationStop = new StopLossRule(price, liquidationLossPercentage);
        Strategy strategy = new BaseStrategy(new FixedRule(series.getBeginIndex()),
                new FixedRule(series.getEndIndex()).or(liquidationStop));
        // Funding is a signed holding cost; positive rates charge this long.
        FundingCostModel funding = FundingCostModel.fixedRate(series, fundingRate, Duration.ofHours(8));
        LinearTransactionCostModel fees = new LinearTransactionCostModel(FEE_RATE);
        // Leverage scales exposure, not the capital denominator or a margin account.
        // balance() budgets the unlevered entry fee; leveraged fees still reduce P&L.
        PositionSizer sizing = PositionSizer.balance(CAPITAL).leveraged(leverage).roundedDownTo(0.001);
        return new BarSeriesManager(series, fees, funding, new TradeOnCurrentCloseModel()).run(strategy, sizing);
    }
```

## 2) Read the example

1. The close-price indicator feeds an approximate liquidation stop. The stop threshold is `100 × (1 / leverage − maintenance margin rate)` percent; it is not a venue liquidation engine.
2. The fixed rules enter at the first bar and exit at the last, unless the stop triggers first. This is an illustration, not a trading recommendation.
3. The fixed funding rate settles every eight hours; positive rates charge a long. Fees apply on notional.
4. The sizer treats capital as the unlevered budget, scales exposure, then floors to the quantity step. It does not create a margin account or reserve leveraged fees in advance.
5. The current-close execution model makes the example deterministic. Real fills may slip or gap.

## 3) Run and interpret

From a checkout containing the example, run:

```shell
mvn -pl ta4j-examples exec:java -Dexec.mainClass=ta4jexamples.backtesting.PerpetualFuturesBacktest
```

The synthetic closes are 100, 104, 98, 110, 107 and 115; capital is 10,000 quote units, leverage is 3, and the rounded amount is 299.85 base units. The example logs net profit **4459.3692** quote units, return on capital **44.593692%**, and maximum absolute drawdown **1802.03853** quote units. Results are illustrative, not a venue reconciliation.

## 4) Change one thing

Try leverage 1, 3 and 10 and compare exposure, fees, return and the stop threshold. Try a short by selecting the sell entry side in the manager run and check funding signs. Try negative funding to see a long receive a credit. A stop is only meaningful when its threshold is positive; higher leverage and venue maintenance rules can invalidate this simple approximation.

## Related pages

- [Perpetual futures](Perpetual-Futures.md)
- [Backtesting](Perpetual-Futures-Backtesting.md)
- [Cookbook](Perpetual-Futures-Cookbook.md)
