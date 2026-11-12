# Perpetual Futures Backtesting

Use this page when you need realistic units, costs, sizing and risk interpretation for a perpetual-futures backtest.

Requires ta4j 0.28.1 or later. The APIs and examples described here are pending human merge; the [linear example](https://github.com/ta4j/ta4j/blob/50dbf50339bde9086308fcd5a8a5b0c2c5b15645/ta4j-examples/src/main/java/ta4jexamples/backtesting/PerpetualFuturesBacktest.java) and [inverse example](https://github.com/ta4j/ta4j/blob/50dbf50339bde9086308fcd5a8a5b0c2c5b15645/ta4j-examples/src/main/java/ta4jexamples/backtesting/InversePerpetualFuturesBacktest.java) are pinned to the pending example commit.

## 1) Units and contract size

For a linear contract, pass base-asset units to ta4j. Convert once in the adapter: 25 contracts at 0.01 BTC per contract are 0.25 BTC; at 40,000 USD/BTC their notional is 10,000 USD. Fees, funding, profit and capital are then in quote currency. Keep venue contract metadata outside core.

## 2) Fees and funding

Use a transaction cost model for each side's fee. `LinearTransactionCostModel` applies a rate to trade notional; fee tiers, floors and maker/taker selection require a custom `CostModel` or recorded fill fees.

`FundingCostModel` sums rate times mark price times base amount at settlement bars. Positive rates charge a long and credit a short; negative rates reverse that. `fixedRate` aligns settlement instants to UTC epoch multiples of the interval, counting every instant in a bar's time window, including boundaries crossed by missing bars. An eight-hour schedule settles at 00:00, 08:00 and 16:00 UTC; a daily bar may contain three settlements. The entry bar is excluded and the exit bar included. An interval shorter than a bar can therefore contribute multiple settlements.

**Execution convention:** this interval treats trade indices as bar-close observations. Use the four-argument `BarSeriesManager` constructor with `new TradeOnCurrentCloseModel()`, as all three backtest/recipe examples do. The three-argument constructor defaults to next-open execution and is not interchangeable: a settlement later in the entry bar would be skipped, and one later in an open-price exit bar could be charged. `CostModel` receives no execution-phase metadata, so it cannot infer or correct that difference. For venue-confirmed open/intrabar executions, record the actual settlements as described in [Live trading](Perpetual-Futures-Live-Trading.md).

For serious research prefer historical settlement rates, aligned to the price series, over a fixed teaching rate. Supply a rate indicator and optionally a mark-price indicator to `FundingCostModel`; otherwise its series close is used as mark. An existing `FixedNumIndicator` can supply a fixed sequence of historical rates. A NaN rate means no settlement; a NaN mark at a nonzero rate propagates NaN. Use actual venue marks and timestamps when available.

## 3) Leverage, rounding and shorts

The [linear example](Perpetual-Futures-Quickstart.md#1-what-you-will-build) composes `balance(capital)`, `leveraged` and `roundedDownTo`. Leverage multiplies the delegate's amount; the step floors base-unit quantity. Both parameters must be positive and finite. A zero entry amount from a sizer skips that entry, while invalid amounts still fail. Exits close the open amount. Balance sizing budgets the unlevered entry fee; leveraged fees still reduce P&L and are not reserved from margin up front.

Choose a sell entry for a short. Its price P&L and funding sign reverse relative to a long. This remains a position simulation, not borrowed-asset or collateral management.

## 4) Liquidation approximation

The example combines its regular exit with a `StopLossRule` at `100 × (1 / leverage − maintenance margin rate)` percent. It checks closes only: intrabar wicks through the level are missed, and a triggered exit fills at close. This approximation requires a positive threshold and does not reproduce venue margin tiers, cross-margin, collateral haircuts, liquidation fees, or forced fills. Gaps and execution slippage can also exceed the stop. Check the venue's actual rules and stress scenarios separately.

## 5) Measure results

`NetProfitLossCriterion` reports net P&L. `ReturnOnCapitalCriterion` divides net closed-position P&L by the supplied committed capital; it is additive and can be less than −100%. Its denominator is not automatically updated as margin changes. `CumulativePnL` added to starting capital gives a quote-currency equity curve; express absolute drawdown as a share of capital by dividing it by that same capital. Price-ratio return criteria are not a substitute for return on committed capital: they do not account for position size and leverage in the same way.

## 6) Walk-forward

Use the existing [walk-forward workflow](Walk-Forward-Research.md) to select parameters on training data and evaluate on subsequent unseen windows. Supply the same units, funding and execution assumptions to each window; avoid leaking future funding rates into entry decisions.

## 7) Pitfalls checklist

- Convert contracts to base units before sizing; round in the units expected by the sizer.
- Align funding rates and marks to bar indexes and account for settlements spanning missing bars.
- Check funding sign, entry/exit bar convention, and fee currency against the venue.
- Distinguish capital, notional and equity; leverage does not create a margin engine.
- Check stop behavior and fills under gaps; avoid treating simulated liquidation as guaranteed.
- Compare against venue statements with matching marks, rates, fees and rounding.

## 8) Inverse contracts

An inverse long of N quote units has gross base-coin profit `N × (1 / entry − 1 / exit)`. The example transforms positive-price bars to reciprocal prices, swapping high and low, and models the economic long as a short of amount N. Capital, fees, funding and drawdown are then in base coin. Negate the venue funding rate for this transformed short so a positive venue rate still charges the economic long. Volume remains source metadata, not inverse notional. This is a recipe, not native inverse valuation or a liquidation model.

## Maintainer update conditions

Hold publication until the core stack has merged and ta4j 0.28.1 has been released. At that point, remove the pending notices throughout these guides and replace commit-pinned source URLs with the actual release tag.

If a released core API gains execution-phase-aware funding, inverse-contract helpers, or modeled-versus-recorded settlement replacement, revise the corresponding convention notes here and in [Live trading, section 2](Perpetual-Futures-Live-Trading.md#2-create-the-record-and-record-confirmed-events). Remove manual conventions only when the replacement API actually guarantees them.

## Related pages

- [Perpetual futures](Perpetual-Futures.md)
- [Quickstart](Perpetual-Futures-Quickstart.md)
- [Cookbook](Perpetual-Futures-Cookbook.md)
- [Live trading](Perpetual-Futures-Live-Trading.md)
- [Backtesting](Backtesting.md)
