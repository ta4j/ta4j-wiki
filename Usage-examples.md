# Usage Examples

The [`ta4j-examples`](https://github.com/ta4j/ta4j/tree/master/ta4j-examples/src/main/java/ta4jexamples) module mirrors the structure of this wiki. Each example is a standalone `main` program—open it in your IDE or run `mvn -pl ta4j-examples exec:java -Dexec.mainClass=…`.

## Start quickly

- **[Quickstart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/Quickstart.java)** – load data, build a strategy, run a backtest, and visualize the signals.
- **[StrategyAnalysis](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/StrategyAnalysis.java)** – prints the criteria covered in [Backtesting](Backtesting.md).

## Bar series & `Num`

- **[BuildBarSeries](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/barSeries/BuildBarSeries.java)** – demonstrates bar builders, sub-series, and moving windows.
- **[CsvBarsDataSource](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/datasources/CsvBarsDataSource.java)** / **[BitstampCsvTradesDataSource](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/datasources/BitstampCsvTradesDataSource.java)** – ingest historical OHLCV data.
- **[AdaptiveJsonBarsSerializer](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/datasources/AdaptiveJsonBarsSerializer.java)** – parse Coinbase/Binance OHLC JSON payloads (introduced in 0.19).
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

Strategy examples that use charting:
- **[RSI2Strategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/RSI2Strategy.java)**
- **[NetMomentumStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/NetMomentumStrategy.java)**
- **[ADXStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/ADXStrategy.java)**

## Strategy patterns

- **[CCICorrectionStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/CCICorrectionStrategy.java)**, **[MovingMomentumStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/MovingMomentumStrategy.java)**, **[RSI2Strategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/RSI2Strategy.java)** – foundational strategies referenced throughout [Trading Strategies](Trading-strategies.md).
- **[ADXStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/ADXStrategy.java)** and **[GlobalExtremaStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/GlobalExtremaStrategy.java)** – trend following setups with multiple indicators.
- **[DayOfWeekStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/DayOfWeekStrategy.java)** – combines calendar rules with indicator signals.
- **[NetMomentumStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/NetMomentumStrategy.java)** – showcases the Net Momentum indicator (introduced in 0.19).
- **[UnstableIndicatorStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/UnstableIndicatorStrategy.java)** – demonstrates how to handle indicators that require long warm-up periods.
- **[WalkForward](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/walkforward/WalkForward.java)** – complete walk-forward optimization loop.

## Backtesting & analytics

- **[SimpleMovingAverageBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/SimpleMovingAverageBacktest.java)** / **[SimpleMovingAverageRangeBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/SimpleMovingAverageRangeBacktest.java)** – baseline moving-average crossover tests.
- **[MovingAverageCrossOverRangeBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/MovingAverageCrossOverRangeBacktest.java)** – parameter sweeps over SMA periods.
- **[MultiStrategyBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/MultiStrategyBacktest.java)** – evaluate several strategies across the same dataset.
- **[TopStrategiesExample](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtest/TopStrategiesExample.java)** – uses the `BacktestExecutor` (introduced in 0.19) to keep a rolling leaderboard of strategies.
- **[CashFlowToChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/CashFlowToChart.java)** and **[BuyAndSellSignalsToChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/BuyAndSellSignalsToChart.java)** – visualize equity curves and trade signals.
- **[TradeCost](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/TradeCost.java)** – study how transaction/holding costs impact returns.
- **[StrategyExecutionLogging](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/logging/StrategyExecutionLogging.java)** – trace rule evaluations line-by-line.

## Elliott Wave analysis

- **[ElliottWaveAnalysis](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/ElliottWaveAnalysis.java)** – comprehensive Elliott Wave analysis with scenario-based confidence scoring, chart visualization, and wave pivot labels. Supports command-line arguments for loading data from Yahoo Finance or Coinbase, or uses a default dataset if no arguments provided. See [Elliott Wave Indicators](Elliott-Wave-Indicators.md) for detailed documentation.
- **[BTCUSDElliottWaveAnalysis](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/BTCUSDElliottWaveAnalysis.java)** – example Elliott Wave analysis for Bitcoin (BTC-USD) using Coinbase data with PRIMARY degree.
- **[ETHUSDElliottWaveAnalysis](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/ETHUSDElliottWaveAnalysis.java)** – example Elliott Wave analysis for Ethereum (ETH-USD) using Coinbase data.
- **[SP500ElliottWaveAnalysis](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/SP500ElliottWaveAnalysis.java)** – example Elliott Wave analysis for S&P 500 Index (^GSPC) using Yahoo Finance data.

## Bots & live trading

- **[TradingBotOnMovingBarSeries](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/bots/TradingBotOnMovingBarSeries.java)** – continuously updates a moving bar series and reacts to strategy signals.

Have a favorite workflow or integration that is not covered yet? Contributions to `ta4j-examples` are welcome—new examples make the wiki even more actionable.
