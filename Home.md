![Ta4 main chart](img/ta4j_main_chart.png)

# Welcome to the ta4j Wiki

ta4j gives you the building blocks for technical-analysis-driven systems in Java: bar series, indicators, rules, strategies, reports, and a unified trading-record model that now spans backtests, paper trading, and live execution.

The current wiki reflects ta4j's newer unified trading stack:

- `BaseTradingRecord` is the default trading-record implementation for both backtests and live or paper-trading flows.
- `BarSeriesManager` is the default single-strategy backtest driver and now accepts either its own default record factory or a record you provide.
- `BacktestExecutor` builds on `BarSeriesManager` when you want to rank or tune many strategies at once, including weighted normalized leaderboards.
- Manual loops are still the right tool when orders and fills are decoupled, partial fills matter, or your broker confirms executions asynchronously.
- `LiveTradingRecord` and `ExecutionFill` remain available only as 0.22.x compatibility facades. New code should use `BaseTradingRecord` and `TradeFill`.

## Choose your audience path

- **Production users and integrators** should start in [Start Here](#start-here), then follow [Canonical User Journey](Canonical-User-Journey.md).
- **Maintainers and design contributors** should use architecture and delivery artifacts under [`architecture/`](architecture/) and [`completed-features/`](completed-features/), which are not part of the primary user onboarding path.

## What’s Newer On Current Master

- **Configurable backtest execution models**: `BarSeriesManager` and `BacktestExecutor` can now stay on the default next-open model or switch to current-close, slippage, or stop-limit execution.
- **Weighted strategy ranking**: `BacktestExecutionResult#getTopStrategiesWeighted(...)` and `WeightedCriterion` let you rank strategies by a normalized composite score instead of a single raw metric.
- **One trade-record story for partial fills**: New code can stream `TradeFill` values directly with `TradingRecord.operate(fill)` or group an order with `Trade.fromFills(...)`, then inspect `getCurrentPosition()` and `getOpenPositions()` on the same record.
- **Broader analysis surface**: Recent current-master additions include `SharpeRatioCriterion`, `SortinoRatioCriterion`, `CalmarRatioCriterion`, `OmegaRatioCriterion`, and volume pressure indicators such as `ForceIndexIndicator`, `EaseOfMovementIndicator`, and `KlingerVolumeOscillatorIndicator`.

## Start Here

- **Primary onboarding lane**: [Getting Started](Getting-started.md) -> [Usage Examples](Usage-examples.md) -> [Backtesting](Backtesting.md) -> [Live Trading](Live-trading.md) -> [Live Trading Runbook](Live-Trading-Runbook.md) -> [Troubleshooting Hub](Troubleshooting-Hub.md)
- **[Getting Started](Getting-started.md)** - Install ta4j, build a strategy, and pick the right driver
- **[Canonical User Journey](Canonical-User-Journey.md)** - Follow the end-to-end production path from data ingestion to live operations
- **[Backtesting](Backtesting.md)** - `BarSeriesManager`, `BacktestExecutor`, supplied records, and manual simulation loops
- **[Live Trading](Live-trading.md)** - Event-driven live or paper flows with `BaseTradingRecord`
- **[Usage Examples](Usage-examples.md)** - Runnable examples, including parity and bot loops
- **[Execution Decision Matrix](Execution-Decision-Matrix.md)** - Choose execution and simulation path by workload
- **[Migration and Version Compatibility](Migration-and-Version-Compatibility.md)** - Preferred APIs and incremental migration guidance
- **[Release Notes](https://github.com/ta4j/ta4j/blob/master/CHANGELOG.md)** - Version-by-version changelog and migration notes

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
| Large batch runs or tuning | `BacktestExecutor` | Runtime telemetry, weighted leaderboards, progress callbacks, and batching |
| Live or paper trading with confirmed fills | Manual loop + `BaseTradingRecord` | Signals and broker fills stay separate; stream `TradingRecord.operate(fill)` or batch `Trade.fromFills(...)` |
| Maintaining older live adapters | `LiveTradingRecord` / `ExecutionFill` | Compatibility only while migrating toward `BaseTradingRecord` / `TradeFill` |

## Where To Go Next

- **[Analysis Criteria and Risk Metrics](Analysis-Criteria-and-Risk-Metrics.md)** - Rolling criteria, risk-adjusted return, open exposure, and risk-unit scoring
- **[Walk-Forward Research](Walk-Forward-Research.md)** - Strategy walk-forward runs and generic prediction research workflows

## Community

- Chat on the [ta4j Discord](https://discord.gg/HX9MbWZ)
- Explore the [ta4j repository](https://github.com/ta4j/ta4j) and its `ta4j-examples` module
- **[How to Contribute](https://github.com/ta4j/ta4j/blob/master/.github/CONTRIBUTING.md)** - Development setup and contribution workflow
- **[Roadmap & Tasks](Roadmap-and-Tasks.md)** - Planned work and known gaps
- **[Alternative Libraries](Alternative-libraries.md)** - Comparable TA libraries
- **[Related Projects](Related-projects.md)** - Ecosystem projects built around ta4j

## Maintainer design docs

- **[Architecture proposals](architecture/proposed/)** - Active design drafts and TODO PRDs
- **[Architecture archive](architecture/archive/)** - Historical decisions and implementation records
- **[Completed feature dossiers](completed-features/README.md)** - Delivered PRD/checklist records