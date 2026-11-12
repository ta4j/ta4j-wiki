# Perpetual Futures Cookbook

Use this page when adapting common funding, sizing and risk techniques to a perpetual-futures strategy.

Requires ta4j 0.28.1 or later. The examples and APIs are pending human merge. The excerpts below are from [`PerpetualFuturesBacktest`](https://github.com/ta4j/ta4j/blob/71db021f54852a3a91cb393d4857c552a92060c6/ta4j-examples/src/main/java/ta4jexamples/backtesting/PerpetualFuturesBacktest.java) and [`InversePerpetualFuturesBacktest`](https://github.com/ta4j/ta4j/blob/71db021f54852a3a91cb393d4857c552a92060c6/ta4j-examples/src/main/java/ta4jexamples/backtesting/InversePerpetualFuturesBacktest.java), pinned to the pending example commit.

The fee, historical-rate, entry-filter, drawdown, rounding and comparison excerpts come from [`PerpetualFuturesRecipes`](https://github.com/ta4j/ta4j/blob/ee7cd1bebb3d405f8363f262d5b2256bfbf0177b/ta4j-examples/src/main/java/ta4jexamples/backtesting/PerpetualFuturesRecipes.java), in the pending [recorded holding-costs PR](https://github.com/ta4j/ta4j/pull/1734). Its `main` runs offline; retain the surrounding class and imports when adapting individual methods.

## 1) Fee floors and maker/taker rates

**Problem:** A venue charges a minimum fee or different rates for makers and takers.

**Code:** The custom `MinimumCommission` model's per-trade calculation:

```java
        public Num calculate(Num price, Num amount) {
            if (amount.isZero()) {
                return amount.getNumFactory().zero();
            }
            Num proportional = price.multipliedBy(amount).multipliedBy(amount.getNumFactory().numOf(rate));
            Num floor = amount.getNumFactory().numOf(minimum);
            return proportional.isLessThan(floor) ? floor : proportional;
        }
```

**Notes:** The example constructs `MinimumCommission(0.001, 0.25)` and implements the other `CostModel` overloads in the same nested class. Fees apply separately to entry and exit. A rate-only model cannot infer whether an order supplied liquidity: select maker/taker tiers and convert currencies in your adapter, or record actual fill fees with `RecordedTradeCostModel`. Reconcile with venue statements.

## 2) Historical funding

**Problem:** Fixed funding is not representative.

**Code:** Historical rate observations and mark-price composition:

```java
    static Indicator<Num> historicalRates(BarSeries series) {
        return new FixedNumIndicator(series, 0.0005, 0.001, 0, -0.002, 0);
    }

    static CostModel historicalFunding(BarSeries series, Indicator<Num> rates) {
        Indicator<Num> marks = new ClosePriceIndicator(series);
        return new FundingCostModel(rates, marks);
    }
```

**Notes:** Align settlements to the price-series indices; zero or NaN rates mean no settlement. Replace closes with venue marks where appropriate. These are historical observations, not a forecast available before publication. See [funding conventions](Perpetual-Futures-Backtesting.md#2-fees-and-funding).

## 3) Funding-aware entry

**Problem:** Filter entries when funding is expensive.

**Code:** Reuse the observed rate indicator in an entry rule:

```java
    static Strategy fundingAwareStrategy(BarSeries series, Indicator<Num> rates) {
        // Only enter on the chosen signal when the observed rate is below 0.1%.
        Rule entry = new FixedRule(series.getBeginIndex()).and(new UnderIndicatorRule(rates, 0.001));
        return new BaseStrategy(entry, new FixedRule(series.getEndIndex()));
    }
```

**Notes:** Use only rates available at the decision time. The guard illustrates an economic long; adapt the threshold and sign for shorts. Replace the fixed entry/exit signals with your own strategy without changing the funding model.

## 4) Approximate liquidation stop

**Problem:** A position should exit near a simple maintenance-margin threshold.

**Code:** From the linear example's `run` method:

```java
        ClosePriceIndicator price = new ClosePriceIndicator(series);
        double liquidationLossPercentage = 100 * (1 / leverage - MAINTENANCE_MARGIN_RATE);
        Rule liquidationStop = new StopLossRule(price, liquidationLossPercentage);
        Strategy strategy = new BaseStrategy(new FixedRule(series.getBeginIndex()),
                new FixedRule(series.getEndIndex()).or(liquidationStop));
```

**Notes:** Require a positive threshold. This stop does not simulate venue liquidation, collateral changes, gaps or liquidation fees.

## 5) Inverse contract

**Problem:** Express inverse-long P&L in base coin without a separate valuation model.

**Code:** From the inverse example's `run` method:

```java
        Strategy strategy = new BaseStrategy(new FixedRule(reciprocal.getBeginIndex()),
                new FixedRule(reciprocal.getEndIndex()));
        LinearTransactionCostModel fees = new LinearTransactionCostModel(FEE_RATE);
        FundingCostModel funding = FundingCostModel.fixedRate(reciprocal, -venueFundingRate, Duration.ofHours(8));
        return new BarSeriesManager(reciprocal, fees, funding, new TradeOnCurrentCloseModel()).run(strategy,
                TradeType.SELL, sizing);
```

**Notes:** The reciprocal series swaps high and low. Amount is quote face value, profit is base coin, and the negated funding rate preserves the economic long's funding sign. See [inverse details](Perpetual-Futures-Backtesting.md#8-inverse-contracts).

## 6) Drawdown relative to capital

**Problem:** Compare absolute drawdown with committed capital rather than quote notional.

**Code:** Express absolute drawdown as a fraction of committed capital:

```java
    static Num drawdownAsShareOfCapital(BarSeries series, TradingRecord record, Number capital) {
        return new MaximumAbsoluteDrawdownCriterion().calculate(series, record)
                .dividedBy(series.numFactory().numOf(capital));
    }
```

**Notes:** Use positive finite capital in the same currency as P&L and as supplied to `ReturnOnCapitalCriterion`; multiply the fraction by 100 for a percentage. A value above one is possible. This is not a margin or liquidation model.

## 7) Contract-size rounding

**Problem:** Orders must be whole venue contracts.

**Code:** Convert a venue contract increment to base units before flooring:

```java
    // Contract size is base units per contract; lot increment is contracts per step.
    static BigDecimal baseAmountIncrement(String contractSize, String contractLotIncrement) {
        return new BigDecimal(contractSize).multiply(new BigDecimal(contractLotIncrement));
    }

    static PositionSizer lotSizer(double baseAmount, double leverage, BigDecimal baseIncrement) {
        return PositionSizer.fixed(baseAmount).leveraged(leverage).roundedDownTo(baseIncrement);
    }
```

**Notes:** For 0.01 BTC per contract and 0.1 contracts per step, the quantity step is 0.001 BTC. Convert the resulting base amount back to contracts in your adapter. Zero after flooring skips the entry; never round up beyond intended exposure. Inverse contracts instead use quote face-value units.

## 8) Spot versus perpetual

**Problem:** Compare a strategy on spot and a perpetual without attributing all differences to price movement.

**Code:** Run one strategy over aligned bars with different cost and sizing assumptions:

```java
    public static void main(String[] args) {
        BarSeries series = PerpetualFuturesBacktest.createSeries(100, 110, 120, 130, 140);
        Indicator<Num> rates = historicalRates(series);
        Strategy strategy = fundingAwareStrategy(series, rates);
        CostModel fees = new MinimumCommission(0.001, 0.25);
        BigDecimal step = baseAmountIncrement("0.01", "0.1");
        double capital = 1_000;
        TradingRecord spot = run(series, strategy, fees, new ZeroCostModel(), 2, 1, step);
        TradingRecord perpetual = run(series, strategy, fees, historicalFunding(series, rates), 2, 3, step);
        report("Spot", series, spot, capital);
        report("Perpetual", series, perpetual, capital);
    }
```

**Notes:** Compare net P&L and return on the same committed capital; the size here is a fixed base amount, not the whole capital balance. Funding, leverage and fee floors all affect results. Do not assume that a real spot account has identical execution or borrowing costs. Keep data, timing and execution assumptions explicit.

## Related pages

- [Perpetual futures](Perpetual-Futures.md)
- [Quickstart](Perpetual-Futures-Quickstart.md)
- [Backtesting](Perpetual-Futures-Backtesting.md)
- [Live trading](Perpetual-Futures-Live-Trading.md)
