![Ta4 main chart](img/ta4j_main_chart.png)

# Welcome to the ta4j Wiki

Your one-stop guide for building technical-analysis-driven trading systems in Java. This refresh focuses on making the content approachable for newcomers while preserving the depth power users expect.

## Start Here

1. **Install ta4j** – Grab the coordinates from the [Getting Started guide](Getting-started.md#install-ta4j) and run the quick sanity check project.
2. **Learn the building blocks** – Understand [bar series](Bar-series-and-bars.md), [Num implementations](Num.md), and [how indicators compose](Technical-indicators.md).
3. **Build your first strategy** – Follow the step-by-step tutorial in [Getting Started](Getting-started.md#walkthrough-build-your-first-strategy) and validate it by [backtesting](Backtesting.md).
4. **Iterate & deploy** – Explore [Trading Strategies](Trading-strategies.md) for composition patterns, [Backtesting](Backtesting.md) for performance diagnostics, and [Live Trading](Live-trading.md) for operational concerns.

## What's New in 0.21.0

- **Unified return representation system** – Consistent formatting across all return-based criteria (multiplicative, decimal, percentage, logarithmic) via `ReturnRepresentation` and `ReturnRepresentationPolicy`
- **New oscillators** – `TrueStrengthIndexIndicator`, `SchaffTrendCycleIndicator`, and `ConnorsRSIIndicator` expand oscillator coverage
- **Helper indicators** – `PercentRankIndicator`, `DifferenceIndicator`, and `StreakIndicator` for advanced indicator composition
- **High-precision improvements** – `DecimalNumFactory#exp` now uses configured `MathContext` for better precision in exponential calculations

### Previous highlights (0.19)

- **Fast, observable backtests** with `BacktestExecutor`, execution-time tracing, and streaming top-K selection for large strategy grids
- **Strategy portability** thanks to `StrategySerialization`, JSON round-trips, and compact `NamedStrategy` descriptors
- **Expanded indicator toolbox**: Renko brick detectors, MACDV, Net Momentum, vote-based rules, Amount bars, begin-time builders, and more
- **Richer analytics** including commission impact, drawdown Monte Carlo simulations, streak metrics, and capital utilization insights
- **Trendline and swing point analysis suite** – Automated support/resistance detection with fractal and ZigZag swing indicators
- **Unified data source interface** – Consistent API for loading data from files, Yahoo Finance, Coinbase, and more

Read the curated [Release Notes](Release-notes.md) for every addition plus migration guidance.

## How the Wiki Is Organized

- **Start Here** – [Getting Started](Getting-started.md), [FAQ](FAQ.md), and [Release Notes](Release-notes.md) get you productive quickly.
- **Core Concepts** – Deep dives into [Bar Series & Bars](Bar-series-and-bars.md), [Num](Num.md), [Technical Indicators](Technical-indicators.md), and [Moving Averages](Moving-Average-Indicators.md).
- **Build Strategies** – Compose rules with [Trading Strategies](Trading-strategies.md), evaluate them through [Backtesting](Backtesting.md), and inspect [Usage Examples](Usage-examples.md).
- **Deploy & Operate** – Run bots via [Live Trading](Live-trading.md), inspect logs, and leverage the [ta4j-examples](https://github.com/ta4j/ta4j/tree/master/ta4j-examples) project.
- **Project & Community** – Learn how to [contribute](How-to-contribute.md), follow the [Branching model](Branching-model.md), peek at the [Roadmap](Roadmap-and-Tasks.md), or [report issues](Found-a-bug.md).

## Community

- Chat with the team on the [ta4j Discord](https://discord.gg/HX9MbWZ).
- Share insights on GitHub Discussions and issues in the [main repository](https://github.com/ta4j/ta4j).
- If you improve or clarify anything, please send a PR or open an issue—this wiki is maintained by the community for the community.
