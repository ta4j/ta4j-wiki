# Ta4j — Technical Analysis for Java

<img src="https://github.com/ta4j/ta4j-wiki/blob/master/img/ta4j_main_chart.png?raw=true" alt="Example chart built with ta4j" />

Welcome to the ta4j wiki, the living handbook for building, evaluating, and deploying TA-driven trading systems on the JVM.  
The wiki follows a task-focused layout organized into clear sections:

## Start Here

Get up and running quickly with essential guides:

- **[Home](Home.md)** – Overview and quick navigation
- **[Getting Started](Getting-started.md)** – Installation, first steps, and your first strategy
- **[FAQ](FAQ.md)** – Common questions and answers
- **[Release Notes](Release-notes.md)** – What's new in each version, migration guides, and breaking changes

## Core Concepts

Deep dives into ta4j's fundamental building blocks:

- **[Bar Series & Bars](Bar-series-and-bars.md)** – How ta4j models OHLCV market data
- **[Data Sources](Data-Sources.md)** – Unified interface for loading data from CSV files, JSON files, Yahoo Finance, Coinbase, and more
- **[Num](Num.md)** – Precision-aware numeric types (`DoubleNum`, `DecimalNum`) for calculations
- **[Technical Indicators](Technical-indicators.md)** – Building blocks for technical analysis
- **[Moving Average Indicators](Moving-Average-Indicators.md)**
- **[Trendlines & Swing Points](Trendlines-and-Swing-Points.md)** – Automated support/resistance detection and swing point identification
- **[Elliott Wave Indicators](Elliott-Wave-Indicators.md)** – Elliott Wave pattern detection
- **[Maven Notes](Maven-notes.md)** – Build configuration and dependency management

## Build Strategies

Learn to compose, test, and visualize trading strategies:

- **[Trading Strategies](Trading-strategies.md)** – Composing rules into complete strategies
- **[Backtesting](Backtesting.md)** – Evaluating strategy performance with historical data
- **[Charting](Charting.md)** – Creating professional charts with indicators, trading records, and analysis overlays
- **[Usage Examples](Usage-examples.md)** – Real-world examples and patterns

## Deploy & Operate

Take your strategies to production:

- **[Live Trading](Live-trading.md)** – Running strategies in live markets
- **[Backtesting › Analysis & Logging](Usage-examples.md#backtesting--analytics)** – Performance analysis and debugging
- **[Bots & Automation](Usage-examples.md#bots--live-trading)** – Automating trading workflows

## Project & Community

Contribute, report issues, and stay informed:

- **[How to Contribute](How-to-contribute.md)** – Development setup and contribution guidelines
- **[Found a Bug?](Found-a-bug.md)** – How to report issues effectively
- **[Roadmap & Tasks](Roadmap-and-Tasks.md)** – Planned features and known limitations
- **[Branching Model](Branching-model.md)** – Git workflow and release process
- **[Alternative Libraries](Alternative-libraries.md)** – Other technical analysis libraries for comparison
- **[Related Projects](Related-projects.md)** – Community projects built on ta4j
- **[XLS Testing](XLS-Testing.md)** – Excel-based testing workflows

### What's new in 0.21.0

Release 0.21.0 (November 29, 2025) introduces unified return representation and enhanced oscillator coverage:

- **Unified return representation system** – Consistent formatting across all return-based criteria (multiplicative, decimal, percentage, logarithmic) via `ReturnRepresentation` and `ReturnRepresentationPolicy`
- **Ratio criteria standardization** – All ratio-producing criteria now support `ReturnRepresentation` for consistent dashboard and reporting outputs
- **New oscillators** – `TrueStrengthIndexIndicator`, `SchaffTrendCycleIndicator`, and `ConnorsRSIIndicator` expand oscillator coverage
- **Helper indicators** – `PercentRankIndicator`, `DifferenceIndicator`, and `StreakIndicator` for advanced indicator composition
- **High-precision improvements** – `DecimalNumFactory#exp` now uses configured `MathContext` for better precision in exponential calculations
- **Breaking changes** – EMA indicators now return `NaN` during unstable periods; `DifferencePercentageIndicator` deprecated in favor of `PercentageChangeIndicator`

### Previous highlights (0.19)

Release 0.19 focused on production-ready workflows:

- **Accelerated backtesting** with `BacktestExecutor`, runtime reports, and streaming top-K selection
- **Strategy serialization & presets** via `StrategySerialization` and compact `NamedStrategy` formats
- **Expanded indicator set** including Renko brick helpers, MACDV, Net Momentum, and vote-based rules
- **Deeper analytics** like drawdown Monte Carlo simulation, commission impact, and capital utilization metrics
- **Trendline and swing point analysis suite** – Automated support/resistance detection with fractal and ZigZag swing indicators
- **Unified data source interface** – Consistent API for loading data from files, Yahoo Finance, Coinbase, and more

Browse the [Release Notes](Release-notes.md) for the complete changelog with migration guidance.

### Need help or want to collaborate?

- Join the [community Discord](https://discord.gg/HX9MbWZ) to discuss trading ideas, ask questions, or showcase projects
- Explore the [ta4j-examples](https://github.com/ta4j/ta4j/tree/master/ta4j-examples) module for runnable samples referenced throughout the wiki
- Open issues or PRs in the [main ta4j repository](https://github.com/ta4j/ta4j) when you spot bugs or have improvements in mind
