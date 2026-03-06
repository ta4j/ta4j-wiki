# Usage Examples

The [`ta4j-examples`](https://github.com/ta4j/ta4j/tree/master/ta4j-examples/src/main/java/ta4jexamples) module mirrors the structure of this wiki. Each example is a standalone `main` program—open it in your IDE or run `mvn -pl ta4j-examples exec:java -Dexec.mainClass=…`.

## Start quickly

- **[Quickstart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/Quickstart.java)** – load data, build a strategy, run a backtest, and visualize the signals.
- **[StrategyAnalysis](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/StrategyAnalysis.java)** – prints the criteria covered in [Backtesting](Backtesting.md).

## Bar series & `Num`

- **[BuildBarSeries](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/barSeries/BuildBarSeries.java)** – demonstrates bar builders, sub-series, and moving windows.
- **[CsvFileBarSeriesDataSource](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/datasources/CsvFileBarSeriesDataSource.java)** / **[BitStampCsvTradesFileBarSeriesDataSource](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/datasources/BitStampCsvTradesFileBarSeriesDataSource.java)** – ingest historical OHLCV or trade-level CSV data.
- **[JsonFileBarSeriesDataSource](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/datasources/JsonFileBarSeriesDataSource.java)** – parse Coinbase/Binance OHLC JSON payloads via the adaptive type adapter.
- **[CompareNumTypes](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/num/CompareNumTypes.java)** – compare `DecimalNum` vs `DoubleNum` implementations
- **[DecimalNumPrecisionPerformanceTest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/num/DecimalNumPrecisionPerformanceTest.java)** – benchmark precision vs. performance trade-offs for `DecimalNum` (see [Num](Num.md#performance-characteristics) for details)

## Indicators & visualization

- **[IndicatorsToCsv](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/IndicatorsToCsv.java)** – export indicator values for spreadsheet analysis.
- **[IndicatorsToChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/IndicatorsToChart.java)** – plot price plus indicator overlays.
- **[CandlestickChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/CandlestickChart.java)** and **[CandlestickChartWithChopIndicator](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/CandlestickChartWithChopIndicator.java)** – visualize entry/exit markers alongside candlestick data.

### Charting with ChartWorkflow

The `ChartWorkflow` class provides a fluent `ChartBuilder` API for creating trading charts. See the [Charting](Charting.md) guide for comprehensive documentation. Quick example:

```java
ChartWorkflow chartWorkflow = new ChartWorkflow();
chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .withIndicatorOverlay(rsi)
    .withIndicatorOverlay(macd)
    .withAnalysisCriterionOverlay(new MaximumDrawdownCriterion(), tradingRecord)
    .display();
    
// Or save to a file
chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .save("target/charts", "my-strategy");
```

To compress weekend/holiday gaps on the time axis, switch to bar-indexed spacing:

```java
ChartWorkflow chartWorkflow = new ChartWorkflow();
chartWorkflow.builder()
    .withTimeAxisMode(TimeAxisMode.BAR_INDEX)
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .display();
```

Strategy examples that use charting:
- **[RSI2Strategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/RSI2Strategy.java)**
- **[NetMomentumStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/NetMomentumStrategy.java)**
- **[ADXStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/ADXStrategy.java)**
- **[MACDVMomentumStateStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/MACDVMomentumStateStrategy.java)**

## Strategy patterns

- **[CCICorrectionStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/CCICorrectionStrategy.java)**, **[MovingMomentumStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/MovingMomentumStrategy.java)**, **[RSI2Strategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/RSI2Strategy.java)** – foundational strategies referenced throughout [Trading Strategies](Trading-strategies.md).
- **[ADXStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/ADXStrategy.java)** and **[GlobalExtremaStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/GlobalExtremaStrategy.java)** – trend following setups with multiple indicators.
- **[DayOfWeekStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/DayOfWeekStrategy.java)** – combines calendar rules with indicator signals.
- **[HourOfDayStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/HourOfDayStrategy.java)** / **[MinuteOfHourStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/MinuteOfHourStrategy.java)** – intraday calendar-time strategies using hour/minute rules.
- **[NetMomentumStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/NetMomentumStrategy.java)** – showcases the Net Momentum indicator (introduced in 0.19).
- **[MACDVMomentumStateStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/MACDVMomentumStateStrategy.java)** – demonstrates volatility-normalized MACD-V momentum states with chart overlays (0.22.x+).
- **[UnstableIndicatorStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/UnstableIndicatorStrategy.java)** – demonstrates how to handle indicators that require long warm-up periods.
- **[WalkForward](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/walkforward/WalkForward.java)** – complete walk-forward optimization loop.

## Backtesting & analytics

- **[SimpleMovingAverageBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/SimpleMovingAverageBacktest.java)** / **[SimpleMovingAverageRangeBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/SimpleMovingAverageRangeBacktest.java)** – baseline moving-average crossover tests.
- **[MovingAverageCrossOverRangeBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/MovingAverageCrossOverRangeBacktest.java)** – parameter sweeps over SMA periods.
- **[CoinbaseBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/CoinbaseBacktest.java)** / **[YahooFinanceBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/YahooFinanceBacktest.java)** – backtest strategies using live HTTP data-source adapters.
- **[BacktestPerformanceTuningHarness](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/BacktestPerformanceTuningHarness.java)** – tune strategy-count/bar-count/heap settings for large backtest runs.
- **[CashFlowToChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/CashFlowToChart.java)** and **[BuyAndSellSignalsToChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/BuyAndSellSignalsToChart.java)** – visualize equity curves and trade signals.
- **[TradeCost](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/TradeCost.java)** – study how transaction/holding costs impact returns.
- **[StrategyExecutionLogging](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/logging/StrategyExecutionLogging.java)** – trace rule evaluations line-by-line.

## Elliott Wave analysis

- **[ElliottWaveIndicatorSuiteDemo](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/ElliottWaveIndicatorSuiteDemo.java)** – consolidated Elliott Wave demo with scenario scoring, chart overlays, and optional live/ossified data loading.
- **[ElliottWavePresetDemo](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/ElliottWavePresetDemo.java)** – launcher for `ossified` presets (`btc`, `eth`, `sp500`) and `live` runs (Coinbase/YahooFinance).
- **[ElliottWaveMultiDegreeAnalysisDemo](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/demo/ElliottWaveMultiDegreeAnalysisDemo.java)** (0.22.4+) – cross-degree scenario validation and reranking for stronger trend-bias decisions.
- **[ElliottWaveAdaptiveSwingAnalysis](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/demo/ElliottWaveAdaptiveSwingAnalysis.java)** (0.22.2+) – adaptive ZigZag swing detection demo with pluggable detector settings.
- **[ElliottWavePatternProfileDemo](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/demo/ElliottWavePatternProfileDemo.java)** (0.22.2+) – scenario-type confidence profile tuning demo.
- **[ElliottWaveTrendBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/backtest/ElliottWaveTrendBacktest.java)** (0.22.2+) – trend-bias walk-forward/backtest harness for Elliott outputs.
- **[HighRewardElliottWaveBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/backtest/HighRewardElliottWaveBacktest.java)** (0.22.2+) – backtest harness for `HighRewardElliottWaveStrategy`.
- **[HighRewardElliottWaveStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/HighRewardElliottWaveStrategy.java)** (0.22.2+) – named strategy targeting high-confidence impulse scenarios.

## Bots & live trading

- **[TradingBotOnMovingBarSeries](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/bots/TradingBotOnMovingBarSeries.java)** – continuously updates a moving bar series and reacts to strategy signals.
- **[WyckoffCycleIndicatorSuiteDemo](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/wyckoff/WyckoffCycleIndicatorSuiteDemo.java)** – one-shot and streaming Wyckoff cycle analysis demo (0.22.x+).
- **ConcurrentBarSeries for live trading**: Since 0.22.2, use `ConcurrentBarSeries` for thread-safe bar ingestion in multi-threaded live trading scenarios. See [Live Trading](Live-trading.md) and [Bar Series & Bars](Bar-series-and-bars.md#concurrent-bar-series-for-multi-threaded-scenarios) for comprehensive documentation and examples.
- **LiveTradingRecord (partial fills, cost basis, position book)**: For bots that receive partial fills or need per-lot cost basis and unrealized PnL, use `LiveTradingRecord` with `recordFill(ExecutionFill)` or `enter`/`exit`. See the [Live Trading – LiveTradingRecord walkthrough](Live-trading.md#walkthrough-livetradingrecord-with-partial-fills-and-cost-basis) for a step-by-step code guide and criteria (`OpenPositionCostBasisCriterion`, `OpenPositionUnrealizedProfitCriterion`).

Have a favorite workflow or integration that is not covered yet? Contributions to `ta4j-examples` are welcome—new examples make the wiki even more actionable.

### Sync rationale (2026-03-06)

- Updated Elliott example links to current classes after the reorganization in commit `279d9056` (`ElliottWaveIndicatorSuiteDemo`, `ElliottWavePresetDemo`, `demo/*`, `backtest/*`).
- Retained live-trading pointers for `ConcurrentBarSeries` and `LiveTradingRecord` aligned with commit `b112d34b`.
