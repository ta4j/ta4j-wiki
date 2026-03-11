# Backtesting

Backtesting estimates how a strategy would have behaved over historical data. In ta4j's current 0.22.x line, the default building blocks are:

- `BarSeriesManager` for one strategy over one series
- `BacktestExecutor` for many strategies over one series
- `BaseTradingRecord` as the trading-state object underneath both backtest and live-style flows

## Choose The Right Backtest Driver

| Need | Recommended path | Notes |
| --- | --- | --- |
| One strategy, minimal setup | `BarSeriesManager.run(strategy)` | Creates a fresh `BaseTradingRecord` through the manager's configured factory |
| One strategy with a preconfigured record | `BarSeriesManager.run(strategy, tradingRecord, ...)` | Reuse a record instance or keep a custom `ExecutionMatchPolicy` / fee setup |
| Many strategies or tuning | `BacktestExecutor` | Collects `TradingStatement`s plus `BacktestRuntimeReport` telemetry |
| Event-driven or fill-driven replay | Manual loop + `BaseTradingRecord` | Use when fills do not happen exactly where the default execution model would place them |
| Older live-oriented adapters | `LiveTradingRecord` | Compatibility facade only; not recommended for new backtests |

The main thing to keep in mind is that you do **not** need a manual loop just to get open-lot views, recorded fees, or open-position criteria. `BaseTradingRecord` already exposes `getOpenPositions()`, `getNetOpenPosition()`, and recorded-fee-aware metrics.

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

## Provide Your Own `BaseTradingRecord`

As of 0.22.4, `BarSeriesManager` can run directly against a record you provide. That is the right choice when you want to preserve a specific match policy, start and end window, or recorded-fee behavior.

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

List<TradingStatement> topRuns = result.getTopStrategies(
        20,
        new ReturnOverMaxDrawdownCriterion(),
        new NetReturnCriterion());
```

Use `BacktestExecutor` when you care about:

- strategy leaderboards
- progress callbacks
- runtime telemetry (`BacktestRuntimeReport`)
- batched execution for large candidate sets

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

record.recordExecutionFill(new TradeFill(
        42,
        Instant.parse("2025-01-02T10:15:00Z"),
        series.numFactory().numOf("42100"),
        series.numFactory().numOf("0.50"),
        series.numFactory().numOf("4.21"),
        ExecutionSide.BUY,
        "order-42",
        "decision-42"));
```

That same fill-driven pattern is what you will use in live or paper-trading systems when the broker is the source of truth for fills.

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

For visualization, combine the resulting record with the `ChartWorkflow` APIs documented in [Charting](Charting.md).

## Walk-Forward And Tuning

Use walk-forward execution when you want training and testing windows instead of one monolithic run:

```java
WalkForwardConfig config = WalkForwardConfig.builder()
        .trainingBars(500)
        .testingBars(100)
        .build();

StrategyWalkForwardExecutionResult walkForward = new BarSeriesManager(series)
        .runWalkForward(strategy, config);
```

For large-scale performance tuning, use [`BacktestPerformanceTuningHarness`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/BacktestPerformanceTuningHarness.java), which sits on top of `BacktestExecutor`.

## CF Alignment

CF consumes the same backtest primitives described here:

- strategy engines hold a ta4j `Strategy`
- state is carried in `BaseTradingRecord`
- snapshots are persisted through `LiveTradingRecordSnapshotCodec`
- performance is measured through ta4j criteria in `TradingRecordPerformanceSnapshotProvider`

That means the backtest and live documentation now describe the same record type and the same metrics surface.

## Compatibility Note

`LiveTradingRecord` and `ExecutionFill` still exist for 0.22.x migration paths, but they are no longer the preferred way to explain or build new backtests.
