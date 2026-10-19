![Ta4 main chart](img/ta4j_main_chart.png)

# Welcome to the ta4j Wiki

ta4j gives you the building blocks for technical-analysis-driven systems in Java: bar series, indicators, rules, strategies, reports, portfolio backtests, and a unified trading-record model that now spans backtests, paper trading, and live execution.

The current wiki reflects ta4j's newer unified trading stack:

- `BaseTradingRecord` is the default trading-record implementation for both backtests and live or paper-trading flows.
- `BarSeriesManager` is the default single-strategy backtest driver and now accepts either its own default record factory or a record you provide.
- `PortfolioSeriesManager` extends backtesting to multi-asset baskets with custom allocations, rebalancing policies, and cost-aware execution.
- `BacktestExecutor` builds on `BarSeriesManager` when you want to rank or tune many strategies at once, including weighted normalized leaderboards.
- Manual loops are still the right tool when orders and fills are decoupled, partial fills matter, or your broker confirms executions asynchronously.
- `LiveTradingRecord` and `ExecutionFill` remain available only as 0.22.x compatibility facades. New code should use `BaseTradingRecord` and `TradeFill`.

## Choose your audience path

- **Production users and integrators** should start in [Start Here](#start-here), then follow [Canonical User Journey](Canonical-User-Journey.md).
- **Maintainers and design contributors** should use architecture and delivery artifacts under [`architecture/`](architecture/) and [`completed-features/README.md`](completed-features/README.md), which are not part of the primary user onboarding path.

## What’s Newer On Current Master

- **Composable Monte Carlo techniques**: `MonteCarloMethod` now chains decorators fluently (`pooledWith(other)`, `widenedByRecentVolatility()`, `withStudentTScaleMixing()`, and `NormalInverseGammaForecastMethod.overResiduals(...)`), bringing flexible residual resampling and Student-t scale mixing while maintaining deterministic random seeding.
- **Portfolio backtesting & minimum-variance optimization**: Backtest multi-asset baskets with `PortfolioSeries`, `PortfolioAllocation`, and `PortfolioSeriesManager`. Analyze correlations with `PortfolioCorrelations` and compute long-only target weights using `MinimumVarianceOptimizer` with Ledoit-Wolf covariance shrinkage.
- **No-lookahead backtests & logical position bounds**: Backtest runs capture series windows strictly without reading bars past run ends. Position criteria respect explicit `BaseTradingRecord` start/end bounds so trades outside the evaluated window do not leak into results.
- **Head advances & moving series stability**: `AbstractEMAIndicator` (EMA, MMA, EWMA), `ATRIndicator`, `SMMAIndicator`, `WildersMAIndicator`, `ElliottSwingIndicator`, and empirical forecasts continue recurrences across head advances on bounded series rather than re-seeding repeatedly.
- **Correctly rounded `DecimalNum.sqrt`**: `DecimalNum.sqrt()` now delegates directly to JDK's `BigDecimal.sqrt`, improving precision and performance over Newton iteration.
- **Unified parameter research pipeline**: `ParameterResearch` provides budget-exact hyperparameter tuning with grid, genetic, and particle-swarm search strategies (`SearchPlan.grid`, `genetic`, `particleSwarm`), duplicate caching, and holdout validation.
- **Robust correntropy Kalman & SPC control**: Maximum-correntropy-criterion `CorrentropyKalmanFilterIndicator` handles wild measurements without bias; `CusumIndicator`, `EwmaVarianceIndicator`, and `ProcessCapabilityCriterion` bring statistical process control (Cpk) to risk management.
- **Configurable backtest execution models**: `BarSeriesManager` and `BacktestExecutor` can stay on the default next-open model or switch to current-close, slippage, or stop-limit execution (with `ExitOnRunEndModel` to close open positions at run end).
- **Weighted strategy ranking**: `BacktestExecutionResult#getTopStrategiesWeighted(...)` and `WeightedCriterion` let you rank strategies by a normalized composite score instead of a single raw metric.
- **One trade-record story for partial fills**: Stream `TradeFill` values directly with `TradingRecord.operate(fill)` or group an order with `Trade.fromFills(...)`, then inspect `getCurrentPosition()` and `getOpenPositions()` on the same record.
- **Broader analysis surface**: Recent additions include `SharpeRatioCriterion`, `SortinoRatioCriterion`, `CalmarRatioCriterion`, `OmegaRatioCriterion`, `ProcessCapabilityCriterion`, and volume pressure indicators such as `ForceIndexIndicator`, `EaseOfMovementIndicator`, and `KlingerVolumeOscillatorIndicator`.
- **Correlation, lead-lag & event dependence**: Relationship-analysis APIs — `LeadLagCorrelationIndicator`, `DynamicTimeWarpingDistanceIndicator`, `EventSynchronizationIndicator`, and `EventMutualInformationEvaluator` — score lead/lag structure, shape similarity, sparse-event F1, and event-aware mutual information. See [Correlation, Lead-Lag & Event Dependence](Correlation-Lead-Lag-Event-Analysis.md).

## Start Here

- **Primary onboarding lane**: [Getting Started](Getting-started.md) -> [Usage Examples](Usage-examples.md) -> [Backtesting](Backtesting.md) -> [Live Trading](Live-trading.md) -> [Live Trading Runbook](Live-Trading-Runbook.md) -> [Troubleshooting Hub](Troubleshooting-Hub.md)
- **[Getting Started](Getting-started.md)** - Install ta4j, build a strategy, and pick the right driver
- **[Canonical User Journey](Canonical-User-Journey.md)** - Follow the end-to-end production path from data ingestion to live operations
- **[Backtesting](Backtesting.md)** - Single-series drivers, `PortfolioSeriesManager`, `BacktestExecutor`, supplied records, and manual loops
- **[Live Trading](Live-trading.md)** - Event-driven live or paper flows with `BaseTradingRecord`
- **[Usage Examples](Usage-examples.md)** - Runnable examples, including parity, portfolio, and bot loops
- **[Serialization and Named Shorthand](Serialization-and-Named-Shorthand.md)** - Guide for canonical JSON, compact strategy JSON v2, and named asset expressions
- **[Execution Decision Matrix](Execution-Decision-Matrix.md)** - Choose execution and simulation path by workload
- **[Migration and Version Compatibility](Migration-and-Version-Compatibility.md)** - Preferred APIs and incremental migration guidance
- **[Release Notes](https://github.com/ta4j/ta4j/blob/master/CHANGELOG.md)** - Version-by-version changelog and migration notes

## Core Concepts

- **[Bar Series & Bars](Bar-series-and-bars.md)** - OHLCV data, aggregation, moving windows, and streaming updates
- **[Data Sources](Data-Sources.md)** - Loading bars or trades from files and HTTP providers
- **[Num](Num.md)** - Precision-aware numeric types such as `DoubleNum` and `DecimalNum`
- **[Technical Indicators](Technical-indicators.md)** - Indicator composition, caching, and head advance behavior
- **[Indicators Inventory](Indicators-Inventory.md)** - Exhaustive index of all ta4j indicators and supporting types
- **[Highs and Lows](Highs-and-Lows.md)** - Recent swing methods, canonical defaults, confirmation timing, and forming extremes
- **[Correlation, Lead-Lag & Event Dependence](Correlation-Lead-Lag-Event-Analysis.md)** - Lead/lag profiles, DTW shape distance, event-synchronization F1, and event-aware mutual information
- **[Forecast Indicators](Forecast-Indicators.md)** - Forward-looking return and price distributions, point projections, and strategy filters
- **[Forecast State Estimation](Forecast-State-Estimation.md)** - Minimal lifecycle state, canonical, rough-volatility, and Bayesian regime moments, representation-bound schemas, and provenance-aware summaries
- **[Forecast Projection Models](Forecast-Projection-Models.md)** - Analog neighbors, rolling conformal calibration, maturity guards, tuning, and failure behavior
- **[Trading Strategies](Trading-strategies.md)** - Rules, strategies, unstable bars, and serialization
- **[Serialization and Named Shorthand](Serialization-and-Named-Shorthand.md)** - Guide for canonical JSON, compact strategy JSON v2, and named asset expressions
- **[Charting](Charting.md)** - Visual overlays, trading-record rendering, and analysis charts

## Pick The Right Execution Path

Use the canonical matrix for execution choices:

- [Execution Decision Matrix](Execution-Decision-Matrix.md) for driver and simulation-path selection
- [Backtesting](Backtesting.md) for single-series and portfolio backtest patterns
- [Live Trading](Live-trading.md) for fill-driven and event-driven live loops

## Where To Go Next

- **[Analysis Criteria and Risk Metrics](Analysis-Criteria-and-Risk-Metrics.md)** - Rolling criteria, risk-adjusted return, open exposure, and risk-unit scoring
- **[Walk-Forward Research](Walk-Forward-Research.md)** - Strategy walk-forward runs and generic prediction research workflows

## Community

- Chat on the [ta4j Discord](https://discord.gg/HX9MbWZ)
- Explore the [ta4j repository](https://github.com/ta4j/ta4j) and its `ta4j-examples` module
- **[How to Contribute](https://github.com/ta4j/ta4j/blob/master/.github/CONTRIBUTING.md)** - Development setup and contribution workflow
- **[Roadmap & Tasks](Roadmap-and-Tasks.md)** - Planned work and known gaps
- **[Related Projects](Related-projects.md)** - Ecosystem projects built around ta4j

## Maintainer design docs

- **[Architecture proposals](architecture/proposed/index.md)** - Active design drafts and in-progress PRDs
- **[Architecture archive](architecture/archive/index.md)** - Historical decisions and implementation records
- **[Completed feature dossiers](completed-features/README.md)** - Delivered PRD/checklist records
