![Ta4 main chart](img/ta4j_main_chart.png)

# Welcome to the ta4j Wiki

ta4j gives you the building blocks for technical-analysis-driven systems in Java: bar series, indicators, rules, strategies, reports, and a unified trading-record model that now spans backtests, paper trading, and live execution.

## Start Here

1. **Install ta4j** - Follow [Getting Started](Getting-started.md#install-ta4j) to build from the current branch or wire the latest release into your project.
2. **Learn the building blocks** - Read [Bar Series & Bars](Bar-series-and-bars.md), [Num](Num.md), and [Technical Indicators](Technical-indicators.md).
3. **Build your first strategy** - Use the walkthrough in [Getting Started](Getting-started.md#walkthrough-build-your-first-strategy).
4. **Choose the right execution path** - Use [Backtesting](Backtesting.md) for `BarSeriesManager` and `BacktestExecutor`, then [Live Trading](Live-trading.md) for event-driven loops.

## Unified Trading Stack At A Glance

| Scenario | Recommended path | Core classes |
| --- | --- | --- |
| Quick historical validation | `BarSeriesManager` | `BarSeriesManager`, `BaseTradingRecord`, `TradeExecutionModel` |
| Parameter sweeps and leaderboards | `BacktestExecutor` | `BacktestExecutor`, `TradingStatement`, `BacktestRuntimeReport` |
| Deterministic replay with a preconfigured record | `BarSeriesManager.run(..., tradingRecord, ...)` | `BaseTradingRecord`, `ExecutionMatchPolicy` |
| Live or paper execution with asynchronous fills | Manual loop | `Strategy`, `BaseTradingRecord`, `BaseTrade`, `TradeFill`, `ConcurrentBarSeries` |
| Older live adapter compatibility | Temporary bridge only | `LiveTradingRecord`, `ExecutionFill` |

The key change is simple: new code no longer needs a split "backtest record" versus "live record" mental model. `BaseTradingRecord` already supports classic `enter` / `exit` operations, fill-aware updates, open-lot views, recorded fees, and open-position criteria.

## Where To Go Next

- **[Getting Started](Getting-started.md)** - First strategy, first backtest, and first live-style loop
- **[Backtesting](Backtesting.md)** - When to use `BarSeriesManager`, `BacktestExecutor`, or a manual simulation loop
- **[Live Trading](Live-trading.md)** - `ConcurrentBarSeries`, broker-confirmed fills, persistence, and downstream integration patterns
- **[Usage Examples](Usage-examples.md)** - Runnable examples like `Quickstart`, `TradingRecordParityBacktest`, and `TradingBotOnMovingBarSeries`
- **[Release Notes](Release-notes.md)** - Migration details and version history

## Downstream Example: CF

CF now consumes the same unified ta4j stack that the wiki recommends:

- `Ta4jStrategyEngine` and `MarketInputStrategyEngine` evaluate ta4j `Strategy` instances on closed bars.
- `BaseTradingRecord` is the shared state object across live trading, paper trading, snapshot persistence, and performance reporting.
- `LiveTradingRecordFillListener` and `PaperTradingLedger` record confirmed fills into `BaseTradingRecord`.
- `TradingRecordPerformanceSnapshotProvider` calculates live metrics from ta4j criteria, including open-position cost basis.

## Community

- Chat on the [ta4j Discord](https://discord.gg/HX9MbWZ)
- Explore the [ta4j repository](https://github.com/ta4j/ta4j) and its `ta4j-examples` module
- Open a PR or issue when you spot drift, missing examples, or confusing behavior
