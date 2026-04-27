# Backtesting

Backtesting estimates how a strategy would have behaved over historical data. In current ta4j, the default building blocks are:

- `BarSeriesManager` for one strategy over one series
- `BacktestExecutor` for many strategies over one series
- `BaseTradingRecord` as the trading-state object underneath both backtest and live-style flows

## Choose The Right Backtest Driver

| Need | Recommended path | Notes |
| --- | --- | --- |
| One strategy, minimal setup | `BarSeriesManager.run(strategy)` | Creates a fresh `BaseTradingRecord` through the manager's configured factory and defaults to next-open execution |
| One strategy with a preconfigured record | `BarSeriesManager.run(strategy, tradingRecord, ...)` | Reuse a record instance or keep a custom `ExecutionMatchPolicy` / fee setup |
| Many strategies or tuning | `BacktestExecutor` | Builds on the same next-open default, collects `TradingStatement`s, and adds telemetry plus ranking helpers |
| Event-driven or fill-driven replay | Manual loop + `BaseTradingRecord` | Use when fills do not happen exactly where the default execution model would place them |
| Older live-oriented adapters | `LiveTradingRecord` | Compatibility facade only; not recommended for new backtests |

The main thing to keep in mind is that you do **not** need a manual loop just to get open-lot views, recorded fees, or open-position criteria. `BaseTradingRecord` already exposes `getCurrentPosition()`, `getOpenPositions()`, and recorded-fee-aware metrics.

## Default Path: `BarSeriesManager`

For a normal single-strategy backtest, start here:

```java
BarSeriesManager manager = new BarSeriesManager(series);
TradingRecord record = manager.run(strategy);

System.out.println("Closed positions: " + record.getPositionCount());
System.out.println("Open position? " + record.getCurrentPosition().isOpened());
```

`BarSeriesManager` handles the bar-by-bar loop, applies the configured `TradeExecutionModel`, and returns the resulting trading record.

If you also need specific cost models or execution semantics, configure them on the manager:

```java
BarSeriesManager manager = new BarSeriesManager(
        series,
        new LinearTransactionCostModel(0.001),
        new ZeroCostModel(),
        new TradeOnNextOpenModel());
```

Current execution-model choices are:

- `TradeOnNextOpenModel` - default; signal at bar `t`, fill at the next bar open when one exists.
- `TradeOnCurrentCloseModel` - signal and fill on the current bar close.
- `SlippageExecutionModel` - applies directional slippage to either next-open or current-close fills.
- `StopLimitExecutionModel` - models pending stop-limit orders, partial fills, expiries, and rejected-order metadata.

Execution models can do per-bar work before signals through `TradeExecutionModel.onBar(...)` and clean up at the end of the run through `onRunEnd(...)`. That matters for pending-order models such as `StopLimitExecutionModel`; immediate-fill models leave those hooks as no-ops.

## Provide Your Own `BaseTradingRecord`

Recent ta4j versions let `BarSeriesManager` run directly against a record you provide. That is the right choice when you want to preserve a specific match policy, start and end window, or recorded-fee behavior.

```java
BaseTradingRecord record = new BaseTradingRecord(
        strategy.getStartingType(),
        ExecutionMatchPolicy.FIFO,
        new ZeroCostModel(),
        new ZeroCostModel(),
        series.getBeginIndex(),
        series.getEndIndex());

BarSeriesManager manager = new BarSeriesManager(series);
manager.run(strategy, record, series.numFactory().one(), series.getBeginIndex(), series.getEndIndex());
```

If you want every default `run(...)` overload to create your preferred record shape, provide a custom trading-record factory to the manager constructor.

The maintained parity example for this flow is [`TradingRecordParityBacktest`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/TradingRecordParityBacktest.java), which compares:

- the plain default `BarSeriesManager` run
- a run against a provided `BaseTradingRecord`
- a manager configured with a custom trading-record factory

## Batch Runs With `BacktestExecutor`

When you want to rank many strategies, switch to `BacktestExecutor`:

```java
BacktestExecutor executor = new BacktestExecutor(series);
BacktestExecutionResult result = executor.executeWithRuntimeReport(
        strategies,
        series.numFactory().one(),
        Trade.TradeType.BUY,
        ProgressCompletion.logging("wiki.backtesting"));

List<TradingStatement> topRuns = result.getTopStrategiesWeighted(
        20,
        WeightedCriterion.of(new NetProfitCriterion(), 7.0),
        WeightedCriterion.of(new ReturnOverMaxDrawdownCriterion(), 3.0));
```

Use `BacktestExecutor` when you care about:

- strategy leaderboards
- normalized weighted ranking such as "net profit + RoMaD"
- progress callbacks
- runtime telemetry (`BacktestRuntimeReport`)
- batched execution for large candidate sets

You have the same execution-wiring flexibility here as in `BarSeriesManager`: use `new BacktestExecutor(series, tradeExecutionModel)` for the common slippage/stop-limit case, or pass a preconfigured `BarSeriesManager` when you want a custom `TradingRecordFactory` or other manager-level defaults to flow through every batch run.

Choose the ranking style that matches the job:

- `getTopStrategies(...)` for simple lexicographic ranking by one or more criteria
- `getTopStrategiesWeighted(...)` plus `WeightedCriterion.of(...)` when you want normalized weighted scoring across different metrics
- `executeAndKeepTopK(...)` when the candidate set is so large that you want streaming top-K retention with one primary criterion instead of materializing every statement

## When A Manual Loop Is The Right Tool

Manual loops still matter, but for a narrower reason than before. Use them when execution itself is the thing you are modeling:

- partial fills
- broker-confirmed fills arriving later
- venue-specific matching or lot handling
- replaying historical executions instead of synthetic ta4j trades

Deterministic custom loop:

```java
BaseTradingRecord record = new BaseTradingRecord(strategy.getStartingType());
Num amount = series.numFactory().one();

for (int i = series.getBeginIndex(); i <= series.getEndIndex(); i++) {
    Num price = series.getBar(i).getClosePrice();
    if (strategy.shouldEnter(i, record)) {
        record.enter(i, price, amount);
    } else if (strategy.shouldExit(i, record)) {
        record.exit(i, price, amount);
    }
}
```

Fill-driven replay:

```java
BaseTradingRecord record = new BaseTradingRecord(strategy.getStartingType());

record.operate(new TradeFill(
        42,
        Instant.parse("2025-01-02T10:15:00Z"),
        series.numFactory().numOf("42100"),
        series.numFactory().numOf("0.50"),
        series.numFactory().numOf("4.21"),
        ExecutionSide.BUY,
        "order-42",
        "decision-42"));
```

That same fill-driven pattern is what you will use in live or paper-trading systems when the broker is the source of truth for fills. If you already have the full partial-fill batch for one logical order, keep it together with `Trade.fromFills(...)` and pass the grouped trade into `operate(...)` instead.

## Criteria, Statements, And Charts

Once you have a `TradingRecord`, the same analysis layer works no matter how the record was produced:

```java
AnalysisCriterion netReturn = new NetReturnCriterion();
AnalysisCriterion totalFees = new TotalFeesCriterion();
AnalysisCriterion openCostBasis = new OpenPositionCostBasisCriterion();
AnalysisCriterion openUnrealized = new OpenPositionUnrealizedProfitCriterion();

System.out.println(netReturn.calculate(series, record));
System.out.println(totalFees.calculate(series, record));
System.out.println(openCostBasis.calculate(series, record));
System.out.println(openUnrealized.calculate(series, record));
```

Useful companions:

- `BaseTradingStatement`
- `CommissionsImpactPercentageCriterion`
- `PositionDurationCriterion`
- `RMultipleCriterion`
- `MonteCarloMaximumDrawdownCriterion`
- `SharpeRatioCriterion`
- `SortinoRatioCriterion`
- `CalmarRatioCriterion`
- `OmegaRatioCriterion`

For open exposure, prefer `getCurrentPosition()` as the canonical net-open view and `getOpenPositions()` when you want one snapshot per remaining lot. `getNetOpenPosition()` remains available only as a compatibility alias.

Risk-adjusted criteria can be configured for sampling frequency, annualization, equity-curve mode, and open-position handling. Use `SharpeRatioCriterion` and `SortinoRatioCriterion` when you need return distributions with risk-free-rate handling; use `CalmarRatioCriterion` when maximum drawdown is the denominator; use `OmegaRatioCriterion` when you want upside-vs-downside return mass around a configurable threshold.

For recent-window reporting, use the window-aware criterion overloads instead of trimming the series yourself:

```java
Num thirtyDayDrawdown = new MaximumDrawdownCriterion().calculate(
        series,
        record,
        AnalysisWindow.lookbackDuration(Duration.ofDays(30)),
        AnalysisContext.defaults());
```

Window boundaries are resolved against the available `BarSeries`. Use the `AnalysisContext` missing-history policy when a moving series may have evicted older bars.

For visualization, combine the resulting record with the `ChartWorkflow` APIs documented in [Charting](Charting.md).

## Visualize and sanity-check your results

After you have a `TradingRecord`, render it with `ChartWorkflow` or inspect it with `StrategyExecutionLogging` from `ta4j-examples`. That is often the fastest way to catch look-ahead bias, missing warmup bars, or surprising execution timing before you trust a criterion leaderboard.

## Avoid common pitfalls

- **Look-ahead bias** - Ensure your indicator windows and any custom execution logic never peek past the current bar.
- **Insufficient warm-up** - Set `strategy.setUnstableBars(n)` so signals do not fire before your indicators stabilize.
- **Moving series** - If you use `setMaximumBarCount`, do not evaluate criteria against evicted bars.
- **Execution assumptions** - Keep your `TradeExecutionModel`, fees, and borrowing costs aligned with what you are trying to simulate.

## Walk-Forward And Tuning

Use walk-forward execution when you want training and testing windows instead of one monolithic run:

```java
WalkForwardConfig config = WalkForwardConfig.defaultConfig(series);

BacktestExecutor.BacktestAndWalkForwardResult result = new BacktestExecutor(series)
        .executeWithWalkForward(strategy, config);

BacktestExecutionResult standardRun = result.backtest();
StrategyWalkForwardExecutionResult walkForward = result.walkForward();
```

For fixed study geometry, construct `WalkForwardConfig` directly with your chosen train/test, purge, embargo, holdout, horizon, top-K, and seed values, then keep that configuration unchanged across candidate comparisons. For large-scale performance tuning, use [`BacktestPerformanceTuningHarness`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/BacktestPerformanceTuningHarness.java), which sits on top of `BacktestExecutor`.

## Compatibility Note

`LiveTradingRecord` and `ExecutionFill` still exist for 0.22.x migration paths, but they are no longer the preferred way to explain or build new backtests.

## Maintainer rationale notes

- Execution-model guidance reflects `TradeExecutionModel`, `SlippageExecutionModel`, `StopLimitExecutionModel`, `BarSeriesManager`, and `BacktestExecutor` changes from commit `49f3f5f8`.
- Criteria coverage reflects `CalmarRatioCriterion` and `OmegaRatioCriterion` from commit `b5f5d2d0`, plus the windowed `MaximumDrawdownCriterion` fix from commit `a6cf6149`.
- Walk-forward examples now match `WalkForwardConfig.defaultConfig(...)` and `BacktestExecutor.executeWithWalkForward(...)` in the current `org.ta4j.core.backtest` and `org.ta4j.core.walkforward` APIs.
