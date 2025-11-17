# Backtesting

Backtesting estimates how a strategy would have performed historically. In ta4j this is the core workflow: load a `BarSeries`, pick a Strategy, and measure the resulting `TradingRecord` with analysis criteria.

## Pick the right driver

| Driver | When to use | Highlights |
| --- | --- | --- |
| `BarSeriesManager` | Quick explorations or single strategies. | Minimal setup, returns a `TradingRecord` immediately. |
| `BacktestExecutor` (new in 0.19) | Large parameter sweeps, grid searches, inventorying many strategies. | Parallel execution, runtime telemetry, streaming top-K filtering, progress callbacks. |

```java
BarSeriesManager manager = new BarSeriesManager(series);
TradingRecord record = manager.run(strategy);
```

```java
BacktestExecutor executor = new BacktestExecutor(series);
BacktestExecutionResult result = executor.executeWithRuntimeReport(
        strategies,
        series.numFactory().numOf(1),
        Trade.TradeType.BUY,
        ProgressCompletion.logging("wiki.backtesting"));
List<TradingStatement> ranked = result.getTopStrategies(
        20,
        new ReturnOverMaxDrawdownCriterion(),
        new NetReturnCriterion());
```

*What this does:* the first block runs a single strategy through the traditional `BarSeriesManager`. The second block spins up `BacktestExecutor`, runs a batch of strategies while collecting runtime telemetry, and then ranks the resulting `TradingStatement`s by ROMAD and net return. For a full working sample see [`ta4jexamples.backtesting.TopStrategiesExampleBacktest`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/TopStrategiesExampleBacktest.java).

## Get useful results

- `TradingRecord` – chronological trades with entry/exit prices, costs, exposure, and net/gross PnL. Pass it into any criterion or build a `BaseTradingStatement`.
- `BacktestExecutionResult` – wraps a `TradingRecord` plus execution metrics (runtime, bars processed, memory estimates). Great for profiling slow strategies.
- `BacktestRuntimeReport` – aggregated stats from a `BacktestExecutor` run, used by the progress listener hook.

## Measure what matters

```java
AnalysisCriterion net = new NetReturnCriterion();
AnalysisCriterion buyHold = new VersusEnterAndHoldCriterion(new NetReturnCriterion());
AnalysisCriterion romad = new ReturnOverMaxDrawdownCriterion();
AnalysisCriterion drawdownRisk = new MonteCarloMaximumDrawdownCriterion();
AnalysisCriterion commissions = new CommissionsImpactPercentageCriterion();

System.out.println("Net return: " + net.calculate(series, record));
System.out.println("Vs buy & hold: " + buyHold.calculate(series, record));
System.out.println("Return / Max DD: " + romad.calculate(series, record));
System.out.println("Drawdown risk p95: " + drawdownRisk.calculate(series, record));
System.out.println("Commission drag: " + commissions.calculate(series, record));
```

Ta4j includes dozens of criteria organized by package:

- `criteria.pnl.*` – differentiate net vs. gross results.
- `criteria.drawdown.*` – absolute, relative, duration, Monte Carlo.
- `criteria.costs.*` – commissions and holding costs.
- `criteria.position.*` – streaks, max profit/loss per position, time in market.

Mix and match to build your own evaluation stack.

## Compare strategies

Use `AnalysisCriterion#chooseBest(...)` to rank alternatives:

```java
List<Strategy> candidates = List.of(meanReversion, trendFollowing, breakout);
Strategy best = romad.chooseBest(manager, candidates);
```

With `BacktestExecutor`, keep a ranked leaderboard after a batch run:

```java
BacktestExecutionResult batch = executor.executeWithRuntimeReport(
        candidates,
        series.numFactory().numOf(1));
List<TradingStatement> topFive = batch.getTopStrategies(5, romad, net);
```

## Visualize your backtests

After you have a `TradingRecord`, you can render candlesticks, trades, and indicator overlays using the `ChartMaker` helper that lives in the `ta4j-examples` module.

### Using the Fluent Builder API (Recommended)

The builder API provides a clean, composable way to create and display charts:

```java
TradingRecord record = manager.run(strategy);
ChartMaker chartMaker = new ChartMaker("target/charts");

ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
SMAIndicator sma = new SMAIndicator(closePrice, 50);
EMAIndicator ema = new EMAIndicator(closePrice, 200);

chartMaker.builder()
    .withTradingRecord(series, strategy.getName(), record)
    .withIndicators(sma, ema)
    .addAnalysis(AnalysisType.MOVING_AVERAGE_20)
    .build()
    .display()
    .save("my-strategy");
```

See the [Charting](Charting.md) guide for comprehensive documentation and more examples.

### Legacy API

The original methods remain available for backward compatibility:

```java
ChartMaker charts = new ChartMaker("target/charts");
charts.displayTradingRecordChart(
        series,
        strategy.getName(),
        record,
        new SMAIndicator(new ClosePriceIndicator(series), 50),
        new EMAIndicator(new ClosePriceIndicator(series), 200));
```

Saved images are JPEGs (see `FileSystemChartStorage`), so the directory you pass to the constructor ends up with files like `mySeries_2023-01-01_to_2024-05-01_timestamp.jpg`. `ChartMaker` composes JFreeChart visualizations through pluggable display and storage backends, so you can pop up Swing windows, stream bytes, or save those JPEGs after each backtest. Explore [`ta4jexamples.charting.ChartMaker`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/charting/ChartMaker.java) and the [`ta4jexamples.strategies.NetMomentumStrategy`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/NetMomentumStrategy.java) sample, which loads data, runs a strategy, and drops charts into `ta4j-examples/log/charts`.

## Avoid common pitfalls

- **Look-ahead bias** – Ensure your indicator windows do not peek at future bars. Ta4j indicators automatically cap their lookbacks, but custom logic must do the same.
- **Insufficient warm-up** – Set `strategy.setUnstableBars(n)` to skip the early `n` indices when indicators have not stabilized yet (`Indicator.isStable()` helps confirm).
- **Moving series** – When using `setMaximumBarCount`, do not reference indexes older than `series.getBeginIndex()`. Criteria referencing evicted bars will return `NaN`.
- **Transaction costs** – Always configure `TransactionCostModel` / `HoldingCostModel` on `BarSeriesManager` or pass explicit cost models to `BacktestExecutor`.

## Walk-forward optimization

Use the helper methods in `ta4jexamples.walkforward.WalkForward` to slice the series into alternating training/testing windows:

```java
List<BarSeries> trainingSlices = WalkForward.splitSeries(series, Duration.ofDays(120), Duration.ofDays(90));

for (BarSeries training : trainingSlices) {
    BarSeries testing = WalkForward.subseries(series, training.getEndIndex() + 1, Duration.ofDays(30));
    Strategy tuned = tuneStrategy(training);
    TradingRecord forwardResult = new BarSeriesManager(testing).run(tuned);
    // evaluate and store the outcome
}
```

See the [Walk Forward example](Usage-examples.md#strategy-patterns) for a turnkey implementation.

## Debugging slow or flaky backtests

- Instrument rule evaluation with `ta4jexamples.logging.StrategyExecutionLogging` to print which rules triggered on each bar.
- Use `BacktestRuntimeReport` to spot strategies that repeatedly trigger cost-heavy operations.
- When bar data is inconsistent (missing timestamps, zero volumes), preprocess it with the JSON/CSV loaders or aggregator builders described in [Bar Series & Bars](Bar-series-and-bars.md).
