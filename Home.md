![Ta4 main chart](img/ta4j_main_chart.png)

# Welcome to the ta4j Wiki

ta4j gives you the building blocks for technical-analysis-driven systems in Java: bar series, indicators, rules, strategies, reports, and a unified trading-record model that now spans backtests, paper trading, and live execution.

## What’s Newer On Current Master

- **Configurable backtest execution models**: `BarSeriesManager` and `BacktestExecutor` can now stay on the default next-open model or switch to current-close, slippage, or stop-limit execution.
- **Weighted strategy ranking**: `BacktestExecutionResult#getTopStrategiesWeighted(...)` and `WeightedCriterion` let you rank strategies by a normalized composite score instead of a single raw metric.
- **One trade-record story for partial fills**: New code can stream `TradeFill` values directly with `TradingRecord.operate(fill)` or group an order with `Trade.fromFills(...)`, then inspect `getCurrentPosition()` and `getOpenPositions()` on the same record.
- **Broader analysis surface**: Recent current-master additions include `SharpeRatioCriterion`, `SortinoRatioCriterion`, `CalmarRatioCriterion`, `OmegaRatioCriterion`, and volume pressure indicators such as `ForceIndexIndicator`, `EaseOfMovementIndicator`, and `KlingerVolumeOscillatorIndicator`.

## Start Here

1. **Install ta4j** - Follow [Getting Started](Getting-started.md#install-ta4j) to build from the current branch or wire the latest release into your project.
2. **Learn the building blocks** - Read [Bar Series & Bars](Bar-series-and-bars.md), [Num](Num.md), and [Technical Indicators](Technical-indicators.md).
3. **Build your first strategy** - Use the walkthrough in [Getting Started](Getting-started.md#walkthrough-build-your-first-strategy).
4. **Choose the right execution path** - Use [Backtesting](Backtesting.md) for `BarSeriesManager` and `BacktestExecutor`, then [Live Trading](Live-trading.md) for event-driven loops.

## Unified Trading Stack At A Glance

| Scenario | Recommended path | Core classes |
| --- | --- | --- |
| Quick historical validation | `BarSeriesManager` | `BarSeriesManager`, `BaseTradingRecord`, `TradeExecutionModel` |
| Parameter sweeps and leaderboards | `BacktestExecutor` | `BacktestExecutor`, `WeightedCriterion`, `BacktestRuntimeReport` |
| Deterministic replay with a preconfigured record | `BarSeriesManager.run(..., tradingRecord, ...)` | `BaseTradingRecord`, `ExecutionMatchPolicy` |
| Live or paper execution with asynchronous fills | Manual loop | `Strategy`, `TradingRecord`, `TradeFill`, `Trade.fromFills(...)`, `ConcurrentBarSeries` |
| Older live adapter compatibility | Temporary bridge only | `LiveTradingRecord`, `ExecutionFill` |

The key change is simple: new code no longer needs a split "backtest record" versus "live record" mental model. `BaseTradingRecord` already supports classic `enter` / `exit` operations, fill-aware updates, open-lot views, recorded fees, and open-position criteria.

## Where To Go Next

- **[Getting Started](Getting-started.md)** - First strategy, first backtest, and first live-style loop
- **[Backtesting](Backtesting.md)** - When to use `BarSeriesManager`, `BacktestExecutor`, or a manual simulation loop
- **[Analysis Criteria and Risk Metrics](Analysis-Criteria-and-Risk-Metrics.md)** - Rolling criteria, risk-adjusted return, open exposure, and risk-unit scoring
- **[Walk-Forward Research](Walk-Forward-Research.md)** - Strategy walk-forward runs and generic prediction research workflows
- **[Live Trading](Live-trading.md)** - `ConcurrentBarSeries`, broker-confirmed fills, persistence, and downstream integration patterns
- **[Usage Examples](Usage-examples.md)** - Runnable examples like `Quickstart`, `TradingRecordParityBacktest`, `TradeFillRecordingExample`, and `SimpleMovingAverageRangeBacktest`
- **[Release Notes](Release-notes.md)** - Migration details and version history

## Community

- Chat on the [ta4j Discord](https://discord.gg/HX9MbWZ)
- Explore the [ta4j repository](https://github.com/ta4j/ta4j) and its `ta4j-examples` module
- Open a PR or issue when you spot drift, missing examples, or confusing behavior
