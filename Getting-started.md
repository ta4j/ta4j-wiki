# Getting Started

Welcome! This guide walks you from “What is ta4j?” to running a validated backtest and knowing what to explore next. It assumes you are new to both the project and systematic technical-analysis trading.

## Prerequisites

- **JDK 21+** (ta4j 0.21.0 targets modern JVMs).
- A build tool such as Maven, Gradle, or your preferred IDE.
- Basic familiarity with Java syntax. No prior quant experience is required—we explain each concept as it shows up.

If technical analysis is brand new to you, skim [Wikipedia](https://en.wikipedia.org/wiki/Technical_analysis) or [Investopedia](https://www.investopedia.com/university/technical/) for the vocabulary we use throughout this guide.

## Install ta4j

ta4j is published on Maven Central as `org.ta4j:ta4j-core`.

<details>
<summary>Maven</summary>

```xml
<dependency>
  <groupId>org.ta4j</groupId>
  <artifactId>ta4j-core</artifactId>
  <version>0.21.0</version>
</dependency>
```
</details>

<details>
<summary>Gradle (Groovy DSL)</summary>

```groovy
implementation 'org.ta4j:ta4j-core:0.21.0'
```
</details>

Prefer to inspect the code? Clone [ta4j](https://github.com/ta4j/ta4j) and import the root Maven project—`ta4j-core` and `ta4j-examples` live side-by-side.

### Verify your environment

1. Run `mvn -pl ta4j-examples test` (or `./mvnw` if you pulled the repo).  
2. Launch `ta4jexamples.Quickstart` from your IDE.  
3. You should see backtest output in the console along with a chart window.

Now you know your toolchain, ta4j dependency, and plotting libraries are wired correctly.

## Understand the building blocks

| Concept | Description | Where to learn more |
| --- | --- | --- |
| [`BarSeries`](https://github.com/ta4j/ta4j/blob/master/ta4j-core/src/main/java/org/ta4j/core/BarSeries.java) | Ordered collection of bars (OHLCV data) used for all calculations. | [Bar Series & Bars](Bar-series-and-bars.md) |
| `Num` | Precision-safe numeric abstraction (Decimal, Double, custom). | [Num](Num.md) |
| `Indicator<T extends Num>` | Lazily evaluated time series derived from bars or other indicators. | [Technical Indicators](Technical-indicators.md) |
| `Rule` / `Strategy` | Boolean conditions that generate entry/exit signals; strategies pair entry + exit rules. | [Trading Strategies](Trading-strategies.md) |
| `BarSeriesManager` & `BacktestExecutor` | Drivers that run strategies against data and return a `TradingRecord`. | [Backtesting](Backtesting.md) |

Why this matters: each component is composable. Bars feed indicators; indicators feed rules; rules feed strategies; strategies feed backtests. Once you understand one layer, the next is just another combination.

## Walkthrough: build your first strategy

We will:

1. Load historic data.
2. Create indicators.
3. Compose entry/exit rules.
4. Run a backtest and inspect the metrics.

### 1. Load a bar series

```java
BarSeries series = new BaseBarSeriesBuilder()
        .withName("bitstamp_btc")
        .build();

try (InputStream csv = Files.newInputStream(Path.of("data/bitstamp_btc.csv"))) {
    new BitstampCsvTradesDataSource().load(csv, series); // see ta4j-examples/datasources
}
```

Other options:

- Use builders such as `TimeBarBuilder`, `TickBarBuilder`, `VolumeBarBuilder`, or the new `AmountBarBuilder` when aggregating streaming trades.
- If your data already contains bars, call `series.addBar(...)` directly—`barBuilder()` lets you specify `beginTime` or `endTime` depending on how the exchange reports timestamps.

### 2. Create indicators

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
SMAIndicator fastSma = new SMAIndicator(close, 5);
SMAIndicator slowSma = new SMAIndicator(close, 30);
MACDVIndicator macdv = new MACDVIndicator(series, 12, 26, 9); // uses volume weighting
```

Indicators are cached automatically. If you mutate the most recent bar (typical in live trading), ta4j recalculates the final value on demand.

### 3. Compose rules and a strategy

```java
Rule entryRule = new CrossedUpIndicatorRule(fastSma, slowSma)
        .and(new OverIndicatorRule(macdv.getMacd(), series.numFactory().numOf(0)));

Rule exitRule = new CrossedDownIndicatorRule(fastSma, slowSma)
        .or(new StopLossRule(close, series.numFactory().numOf(2.5)))
        .or(new StopGainRule(close, series.numFactory().numOf(4.0)));

Strategy strategy = new BaseStrategy("SMA + MACDV swing", entryRule, exitRule);
strategy.setUnstableBars(30); // ignore early warm-up signals
```

Prefer reusable presets? Explore `NamedStrategy` implementations under `org.ta4j.core.strategy.named`. They can be serialized/deserialized, parameterized, and discovered at runtime via `NamedStrategy.initializeRegistry(...)`.

### 4. Backtest

```java
BarSeriesManager manager = new BarSeriesManager(series);
TradingRecord record = manager.run(strategy);
System.out.printf("Trades: %d%n", record.getPositionCount());
```

For large strategy grids or long histories, switch to the new `BacktestExecutor`:

```java
BacktestExecutor executor = new BacktestExecutor(series);
BacktestExecutionResult batch = executor.executeWithRuntimeReport(
        strategies,
        series.numFactory().numOf(1),
        Trade.TradeType.BUY,
        ProgressCompletion.logging("getting-started"));

List<TradingStatement> topRuns = batch.getTopStrategies(10, new NetReturnCriterion());
```

`executeWithRuntimeReport` collects trading statements plus runtime analytics, while `getTopStrategies` helps you home in on the best parameter sets without hand-rolling a sorter. The snippet wires everything up manually; if you prefer a full working example, inspect [`ta4jexamples.backtesting.TopStrategiesExampleBacktest`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/TopStrategiesExampleBacktest.java).

### 5. Inspect metrics

```java
AnalysisCriterion netReturn = new NetReturnCriterion();
AnalysisCriterion romad = new ReturnOverMaxDrawdownCriterion();
AnalysisCriterion commissions = new CommissionsImpactPercentageCriterion();

System.out.printf("Net return: %s%n", netReturn.calculate(series, record));
System.out.printf("Return / Max Drawdown: %s%n", romad.calculate(series, record));
System.out.printf("Commission drag: %s%n", commissions.calculate(series, record));
```

Need deeper insight?

- Risk-adjusted return: `SharpeRatioCriterion`.
- Drawdown distribution: `MonteCarloMaximumDrawdownCriterion`.
- Time invested: `InPositionPercentageCriterion`.
- Streaks: `MaxConsecutiveLossCriterion` and `MaxConsecutiveProfitCriterion`.
- Total fees: `TotalFeesCriterion`; open-position cost basis and unrealized PnL: `OpenPositionCostBasisCriterion`, `OpenPositionUnrealizedProfitCriterion` (with `LiveTradingRecord`).
- Full statement: `new BaseTradingStatement(strategy, record)` exposes trades, exposure, and commission totals.

## Standard Next Steps

| Goal | Where to go |
| --- | --- |
| Load better data | [Bar Series & Bars](Bar-series-and-bars.md) covers CSV datasources, bar builders, and moving series. |
| Explore indicator coverage | [Technical Indicators](Technical-indicators.md) + [Moving Averages](Moving-Average-Indicators.md) list every indicator family, including Renko helpers and Net Momentum. |
| Compare many parameter sets | See [Trading Strategies](Trading-strategies.md#parameterizing-and-named-strategies) for best practices plus `VoteRule` tips for ensembles. |
| Persist and share strategies | Use `StrategySerialization` / `Strategy.fromJson(...)` (documented in [Trading Strategies](Trading-strategies.md#serializing-strategies)). |
| Prepare for live trading | Read [Live Trading](Live-trading.md) for architecture patterns, bar updates, and trade execution models. |
| Track partial fills, cost basis, or unrealized PnL | Use [LiveTradingRecord](Live-trading.md#walkthrough-livetradingrecord-with-partial-fills-and-cost-basis) and the walkthrough there for code examples and criteria. |

## Keep Going

- Browse the curated [Usage Examples](Usage-examples.md) page—each example links to runnable code in `ta4j-examples`.
- Join the [ta4j Discord](https://discord.gg/HX9MbWZ) to compare notes with other builders.
- Dive into the [Backtesting](Backtesting.md) guide for profiling slow runs, avoiding look-ahead bias, and extracting reports.
- Track ongoing work via the [Roadmap and Tasks](Roadmap-and-Tasks.md); contributions are welcome!

System.out.println("Return over Max Drawdown: " + romad.calculate(series, tradingRecord));

// Net return of our strategy vs net return of a buy-and-hold strategy
AnalysisCriterion vsBuyAndHold = new VersusEnterAndHoldCriterion(new NetReturnCriterion());
System.out.println("Our net return vs buy-and-hold net return: " + vsBuyAndHold.calculate(series, tradingRecord));
```

Trading strategies can be easily compared according to [a set of analysis criteria](Backtesting.md).

##### Visualizing your results

Ta4j provides powerful charting capabilities through the `ChartWorkflow` class and its fluent `ChartBuilder` API. You can create charts with price data, indicators, trading signals, and performance metrics.

**Basic chart with trading signals**:

```java
// Create a chart with trading record overlay
ChartWorkflow chartWorkflow = new ChartWorkflow();
chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .display();
```

**Advanced chart with indicators and performance metrics**:

```java
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
SMAIndicator sma = new SMAIndicator(closePrice, 50);

chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .withIndicatorOverlay(sma)
    .withLineColor(Color.ORANGE)
    // Visualize net profit over time using AnalysisCriterionIndicator
    .withAnalysisCriterionOverlay(new NetProfitCriterion(), tradingRecord)
    .withLineColor(Color.GREEN)
    .display();
```

**Key features**:
- **Automatic axis management**: The builder intelligently assigns overlays to primary or secondary axes based on value ranges
- **Analysis criterion visualization**: Use `AnalysisCriterionIndicator` to track performance metrics (profit, return, drawdown) over time
- **Interactive mouseover**: Hover over chart elements to see detailed OHLC data and indicator values
- **Flexible styling**: Customize colors, line widths, and chart titles

See the [Charting Guide](Charting.md) for comprehensive documentation on creating sophisticated trading charts, including sub-charts, custom styling, and advanced examples.

### Going further

Ta4j can also be used for [live trading](Live-trading.md) with more complicated [strategies](Trading-strategies.md). Check out the rest of the documentation and [the examples](Usage-examples.md).