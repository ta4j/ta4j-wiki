# Ta4j — Technical Analysis for Java

<img src="https://github.com/ta4j/ta4j-wiki/blob/master/img/ta4j_main_chart.png?raw=true" alt="Example chart built with ta4j" />

Welcome to the ta4j wiki, the working handbook for building indicators, strategies, backtests, and live trading systems on the JVM.

The current 0.22.x line uses one unified trading stack:

- `BaseTradingRecord` is the default trading-record implementation for both backtests and live or paper-trading flows.
- `BarSeriesManager` is the default single-strategy backtest driver and now accepts either its own default record factory or a record you provide.
- `BacktestExecutor` builds on `BarSeriesManager` when you want to rank or tune many strategies at once.
- Manual loops are still the right tool when orders and fills are decoupled, partial fills matter, or your broker confirms executions asynchronously.
- `LiveTradingRecord` and `ExecutionFill` remain available only as 0.22.x compatibility facades. New code should use `BaseTradingRecord` and `TradeFill`.

## Start Here

- **[Home](Home.md)** - Quick navigation and execution-path overview
- **[Getting Started](Getting-started.md)** - Install ta4j, build a strategy, and pick the right driver
- **[Backtesting](Backtesting.md)** - `BarSeriesManager`, `BacktestExecutor`, supplied records, and manual simulation loops
- **[Live Trading](Live-trading.md)** - Event-driven live or paper flows with `BaseTradingRecord`
- **[Usage Examples](Usage-examples.md)** - Runnable examples, including parity and bot loops
- **[Release Notes](Release-notes.md)** - Version-by-version changelog and migration notes

## Core Concepts

- **[Bar Series & Bars](Bar-series-and-bars.md)** - OHLCV data, aggregation, moving windows, and streaming updates
- **[Data Sources](Data-Sources.md)** - Loading bars or trades from files and HTTP providers
- **[Num](Num.md)** - Precision-aware numeric types such as `DoubleNum` and `DecimalNum`
- **[Technical Indicators](Technical-indicators.md)** - Indicator composition and caching
- **[Trading Strategies](Trading-strategies.md)** - Rules, strategies, unstable bars, and serialization
- **[Charting](Charting.md)** - Visual overlays, trading-record rendering, and analysis charts

## Pick The Right Execution Path

| Need | Recommended path | Why |
| --- | --- | --- |
| One strategy over historical data | `BarSeriesManager` + default `BaseTradingRecord` | Fastest path with minimal wiring |
| Backtest with a preconfigured record | `BarSeriesManager.run(strategy, providedRecord, ...)` | Keep a specific `ExecutionMatchPolicy`, fee model, or reusable record instance |
| Large batch runs or tuning | `BacktestExecutor` | Runtime telemetry, ranked statements, progress callbacks, and batching |
| Live or paper trading with confirmed fills | Manual loop + `BaseTradingRecord` | Signals and broker fills stay separate; partial fills and metadata are preserved |
| Maintaining older live adapters | `LiveTradingRecord` / `ExecutionFill` | Compatibility only while migrating toward `BaseTradingRecord` / `TradeFill` |

## Downstream Example: CF

The unified stack is already consumed by a production-style downstream system:

- CF strategy engines (`Ta4jStrategyEngine`, `MarketInputStrategyEngine`) evaluate ta4j `Strategy` objects on bar close.
- CF keeps market state in `ConcurrentBarSeries` and trading state in `BaseTradingRecord`.
- CF updates the record from confirmed fills through `LiveTradingRecordFillListener` and `PaperTradingLedger`, not from signal generation itself.
- CF persists snapshots through `LiveTradingRecordSnapshotCodec`, which now restores unified `BaseTradingRecord` instances.
- CF analytics reuse ta4j criteria directly through `TradingRecordPerformanceSnapshotProvider`, including `OpenPositionCostBasisCriterion`.

## Project & Community

- **[How to Contribute](How-to-contribute.md)** - Development setup and contribution workflow
- **[Found a Bug?](Found-a-bug.md)** - Reporting issues effectively
- **[Roadmap & Tasks](Roadmap-and-Tasks.md)** - Planned work and known gaps
- **[Alternative Libraries](Alternative-libraries.md)** - Comparable TA libraries
- **[Related Projects](Related-projects.md)** - Ecosystem projects built around ta4j

Need a runnable reference? Browse the [ta4j-examples](https://github.com/ta4j/ta4j/tree/master/ta4j-examples) module and the [community Discord](https://discord.gg/HX9MbWZ).
