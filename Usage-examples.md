# Usage Examples

The [`ta4j-examples`](https://github.com/ta4j/ta4j/tree/master/ta4j-examples/src/main/java/ta4jexamples) module is the runnable companion to this wiki. Each example is a standalone `main` program you can open in your IDE or run with Maven.

## Start quickly

- **[Quickstart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/Quickstart.java)** - Load data, build a strategy, run a backtest, and render the result
- **[StrategyAnalysis](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/StrategyAnalysis.java)** - Print common criteria and strategy diagnostics

## Indicators & visualization

- **[IndicatorsToCsv](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/IndicatorsToCsv.java)** - Export indicator values for spreadsheet analysis
- **[IndicatorsToChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/IndicatorsToChart.java)** - Plot price plus indicator overlays
- **[CandlestickChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/CandlestickChart.java)** - Candlestick chart overlays
- **[Charting](Charting.md)** - Full `ChartWorkflow` guide

## Strategy patterns

- **[CCICorrectionStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/CCICorrectionStrategy.java)** - Baseline trend-reversion pattern
- **[RSI2Strategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/RSI2Strategy.java)** - Classic mean-reversion example
- **[NetMomentumStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/NetMomentumStrategy.java)** - Strategy built around Net Momentum
- **[WalkForward](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/walkforward/WalkForward.java)** - Full walk-forward optimization loop

## Backtesting & analytics

- **[SimpleMovingAverageBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/SimpleMovingAverageBacktest.java)** - Baseline crossover backtest
- **[MovingAverageCrossOverRangeBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/MovingAverageCrossOverRangeBacktest.java)** - Parameter sweeps across SMA windows
- **[CoinbaseBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/CoinbaseBacktest.java)** - Backtest against Coinbase-sourced data
- **[YahooFinanceBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/YahooFinanceBacktest.java)** - Backtest against Yahoo Finance data
- **[TradingRecordParityBacktest](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/TradingRecordParityBacktest.java)** - Shows that default `BarSeriesManager` runs, provided `BaseTradingRecord` runs, and factory-configured runs all converge on the same unified record behavior
- **[BacktestPerformanceTuningHarness](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/backtesting/BacktestPerformanceTuningHarness.java)** - Tune large batch runs built on `BacktestExecutor`
- **[StrategyExecutionLogging](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/logging/StrategyExecutionLogging.java)** - Trace rule evaluation and execution decisions line by line

If you are learning the new unified execution model, start with `Quickstart`, then `TradingRecordParityBacktest`.

## Bots & live trading

- **[TradingBotOnMovingBarSeries](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/bots/TradingBotOnMovingBarSeries.java)** - Minimal manual bot loop using a moving series and `BaseTradingRecord`
- **[Live Trading](Live-trading.md)** - Production-oriented guidance for `ConcurrentBarSeries`, fill-driven record updates, and recovery
- **[Bar Series & Bars](Bar-series-and-bars.md)** - Streaming aggregation and bar-ingestion patterns

For new live code:

- Use `BaseTradingRecord` as the record type
- Update the record from confirmed fills with `recordFill(BaseTrade)` or `recordExecutionFill(new TradeFill(...))`
- Use `ConcurrentBarSeries` when feed ingestion and strategy evaluation happen on different threads
- Treat `LiveTradingRecord` and `ExecutionFill` as compatibility-only APIs during migration

CF follows this same pattern downstream: strategy engines emit intents, fill listeners and paper ledgers mutate `BaseTradingRecord`, and performance reporting runs directly on ta4j criteria.

## More examples

The examples module also contains data-source adapters, charting helpers, Elliott Wave demos, and indicator showcases. If a workflow is documented in the wiki but missing a runnable example, contributions are welcome.
