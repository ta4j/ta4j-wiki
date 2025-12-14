# Backtesting

Backtesting estimates how a strategy would have performed historically. In ta4j this is the core workflow: load a `BarSeries`, pick a Strategy, and measure the resulting `TradingRecord` with analysis criteria.

## Pick the right driver

| Driver | When to use | Highlights |
| --- | --- | --- |
| `BarSeriesManager` | Quick explorations or single strategies. | Minimal setup, returns a `TradingRecord` immediately. |
| `BacktestExecutor` (introduced in 0.19) | Large parameter sweeps, grid searches, inventorying many strategies. | Parallel execution, runtime telemetry, streaming top-K filtering, progress callbacks. |

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
    .addIndicators(sma, ema)
    .withAnalysisCriterion(series, record, new MaximumDrawdownCriterion())
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
- When bar data is inconsistent (missing timestamps, zero volumes), preprocess it with the JSON/CSV datasources or aggregator builders described in [Bar Series & Bars](Bar-series-and-bars.md).

## Performance Tuning with BacktestPerformanceTuningHarness

When running large-scale backtests with thousands of strategies, performance optimization becomes critical. The `BacktestPerformanceTuningHarness` class provides a comprehensive tool for systematically testing different parameter combinations and identifying optimal settings for your hardware and dataset.

### Overview

The harness helps tune several interrelated performance parameters:

- **Strategy count**: How many strategies to evaluate in a single backtest run
- **Bar series size**: Number of bars to use (last-N bars from the dataset)
- **Maximum bar count hint**: Indicator cache window size via `BarSeries.getMaximumBarCount()` to control memory usage
- **JVM heap size**: Optional: fork child JVMs with different heap sizes to find optimal memory configuration

The harness uses a non-trivial NetMomentumIndicator-based strategy workload to make garbage collection (GC) and caching behavior visible. It automatically detects non-linear performance degradation (e.g., excessive GC overhead or slowdown beyond expected scaling) and recommends optimal parameter combinations.

### Execution Modes

The harness supports three execution modes:

1. **Run Once (default)**: Execute a single backtest with specified parameters. Useful for quick performance checks or production runs with known optimal settings.
2. **Tune In-Process**: Run multiple backtests with varying parameters to find optimal settings. Tests different strategy counts, bar counts, and maximum bar count hints systematically.
3. **Tune Across Heaps**: Fork child JVMs with different heap sizes to test memory configuration impact. Each child JVM runs a full tuning cycle.

### Quick Start

#### Example 1: Quick Performance Check

Run a single backtest with 1000 strategies on the last 2000 bars:

```bash
java -cp ta4j-examples.jar ta4jexamples.backtesting.BacktestPerformanceTuningHarness \
  --strategies 1000 \
  --barCount 2000 \
  --executionMode full
```

#### Example 2: Find Optimal Settings

Run a tuning cycle to find optimal parameters for your hardware:

```bash
java -cp ta4j-examples.jar ta4jexamples.backtesting.BacktestPerformanceTuningHarness \
  --tune \
  --tuneStrategyStart 2000 \
  --tuneStrategyStep 2000 \
  --tuneStrategyMax 20000 \
  --tuneBarCounts 500,1000,2000,full \
  --tuneMaxBarCountHints 0,512,1024,2048 \
  --executionMode topK \
  --topK 20
```

This will test strategy counts from 2000 to 20000 (in steps of 2000) across different bar counts and maximum bar count hints, then recommend the best configuration.

#### Example 3: Test Different Heap Sizes

Test performance across different JVM heap sizes:

```bash
java -cp ta4j-examples.jar ta4jexamples.backtesting.BacktestPerformanceTuningHarness \
  --tuneHeaps 4g,8g,16g \
  --tuneStrategyStart 5000 \
  --tuneStrategyMax 50000 \
  --executionMode topK \
  --topK 20
```

This forks separate JVMs with 4GB, 8GB, and 16GB heaps, running a full tuning cycle in each.

#### Example 4: Production Run with Optimal Settings

After tuning, use the recommended settings for a production run:

```bash
java -cp ta4j-examples.jar ta4jexamples.backtesting.BacktestPerformanceTuningHarness \
  --strategies 10000 \
  --barCount 2000 \
  --maxBarCountHint 1024 \
  --executionMode topK \
  --topK 20 \
  --progress
```

The `--progress` flag enables progress logging with memory usage information.

### Performance Tuning Workflow

A typical performance tuning workflow follows these steps:

1. **Initial Exploration**: Start with a broad tuning run to identify promising regions:
   ```bash
   --tune --tuneStrategyStart 1000 --tuneStrategyStep 5000 --tuneStrategyMax 50000
   ```

2. **Fine-Tuning**: Narrow down to the promising region with smaller steps:
   ```bash
   --tune --tuneStrategyStart 8000 --tuneStrategyStep 1000 --tuneStrategyMax 15000
   ```

3. **Memory Optimization**: Test different maximum bar count hints to balance memory and performance:
   ```bash
   --tune --tuneMaxBarCountHints 0,256,512,1024,2048,4096
   ```

4. **Heap Size Testing**: If memory is a concern, test different heap sizes:
   ```bash
   --tuneHeaps 2g,4g,8g,16g
   ```

### Understanding Results

The harness outputs several types of information:

- **HARNESS_RESULT**: JSON-formatted results for each run, including runtime statistics, GC overhead, heap usage, and work units (strategies × bars)
- **RECOMMENDED_SETTINGS**: Optimal parameter combinations based on linear performance behavior (before non-linear degradation is detected)
- **Non-linear detection**: When performance degrades beyond expected scaling (excessive GC overhead or slowdown ratio), the harness flags this and recommends staying below that threshold

Example output:

```
HARNESS_RESULT: {"executionMode":"KEEP_TOP_K","strategyCount":10000,"barCount":2000,...}
RECOMMENDED_SETTINGS: BEST {strategies=10000, bars=2000, maxBarCountHint=1024, ...}
RECOMMENDED_SETTINGS: BEST CLI --dataset Coinbase-ETH-USD-PT1D-20160517_20251028.json --strategies 10000 --barCount 2000 --maxBarCountHint 1024 --executionMode topK --topK 20
```

### Strategy Generation

The harness generates strategies using a grid search over NetMomentumIndicator parameters:

- RSI bar count: 7 to 49 (increment: 7)
- Momentum timeframe: 100 to 400 (increment: 100)
- Oversold threshold: -2000 to 0 (increment: 250)
- Overbought threshold: 0 to 1500 (increment: 250)
- Decay factor: 0.9 to 1.0 (increment: 0.02)

This generates approximately 10,416 unique strategy combinations. When fewer strategies are requested, the harness samples from this grid. When more are requested, it repeats the grid with different repetition markers.

### Command-Line Options

Run with `--help` to see all available options. Key options include:

| Option | Description | Default |
| --- | --- | --- |
| `--dataset <file>` | OHLC data file | `Coinbase-ETH-USD-PT1D-20160517_20251028.json` |
| `--strategies <N>` | Number of strategies to test | Full grid (~10,416) |
| `--barCount <N>` | Number of bars to use | Full series |
| `--maxBarCountHint <N>` | Maximum bar count hint for indicator caching | 0 (disabled) |
| `--executionMode full\|topK` | Execution mode | `full` |
| `--topK <N>` | Number of top strategies to keep (topK mode) | 20 |
| `--tune` | Enable tuning mode | false |
| `--tuneStrategyStart <N>` | Starting strategy count for tuning | 2000 |
| `--tuneStrategyStep <N>` | Strategy count increment for tuning | 2000 |
| `--tuneStrategyMax <N>` | Maximum strategy count for tuning | 20000 |
| `--tuneBarCounts <csv>` | Bar counts to test | `500,1000,2000,full` |
| `--tuneMaxBarCountHints <csv>` | Maximum bar count hints to test | `0,512,1024,2048` |
| `--nonlinearGcOverhead <0..1>` | GC overhead threshold for non-linear detection | 0.25 |
| `--nonlinearSlowdownRatio <x>` | Slowdown ratio threshold for non-linear detection | 1.25 |
| `--tuneHeaps <csv>` | Heap sizes to test (e.g., `4g,8g,16g`) | None |
| `--progress` | Enable progress logging with memory information | false |
| `--gcBetweenRuns` | Force GC between tuning runs | true |

### Performance Notes

- The default parameter ranges generate ~10,000+ strategies. `BacktestExecutor` automatically uses batch processing for large strategy counts (>1000) to prevent memory exhaustion.
- If execution is too slow, consider:
  1. Increasing increment values to reduce grid density
  2. Narrowing MIN/MAX ranges based on preliminary results
  3. Using coarser increments for initial exploration, then fine-tuning promising regions
- The harness performs a warm-up run before tuning to stabilize JVM performance metrics.
- Non-linear behavior detection helps identify when increasing strategy count or bar count causes performance to degrade beyond expected linear scaling.

### See Also

- [`BacktestPerformanceTuningHarness` source code](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/BacktestPerformanceTuningHarness.java) - Full implementation with comprehensive Javadoc
- [`BacktestExecutor`](https://github.com/ta4j/ta4j/blob/master/ta4j-core/src/main/java/org/ta4j/core/backtest/BacktestExecutor.java) - The underlying executor used for backtesting
- `BarSeries.getMaximumBarCount()` - Maximum bar count hint for indicator caching
