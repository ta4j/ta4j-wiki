# Execution Decision Matrix

Use this matrix to choose the right ta4j execution path for your workload.

| Situation | Recommended path | Why | Verification signal |
| --- | --- | --- | --- |
| One strategy over one historical series | `BarSeriesManager` | Minimal setup and deterministic iteration | Trades and positions reproduce across reruns |
| Many strategies or parameter sweeps | `BacktestExecutor` | Batch execution, runtime telemetry, ranking helpers | Top strategy set remains stable under same data/config |
| Need explicit fill semantics (partial fills, delayed confirms) | Manual loop + `BaseTradingRecord.operate(fill)` | Preserves broker-confirmed execution stream | Recorded fills and open lots match broker feed |
| Need slippage/stop-limit behavior | `TradeExecutionModel` variants | Aligns simulation with venue assumptions | PnL delta is explainable by configured execution model |
| Leveraged perpetual backtest with funding | `BarSeriesManager` with funding cost and leveraged sizing | Reuses the generic cost and sizing APIs | Compare modeled funding and fees with [perpetual futures assumptions](Perpetual-Futures-Backtesting.md); requires ta4j 0.28.1 or later |

## Trade execution model chooser

| Model | Best for | Caution |
| --- | --- | --- |
| `TradeOnNextOpenModel` | Conservative signal-at-close simulation | Can understate fast-close fills |
| `TradeOnCurrentCloseModel` | Close-on-signal systems | Requires realistic close execution assumptions |
| `SlippageExecutionModel` | Price-impact modeling | Slippage settings can dominate results |
| `StopLimitExecutionModel` | Pending-order lifecycle simulation | Needs careful interpretation of rejects/partials |

## Related pages

- [Backtesting](Backtesting.md)
- [Perpetual Futures](Perpetual-Futures.md)
- [Live Trading](Live-trading.md)
- [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md)
- [Live Trading Runbook](Live-Trading-Runbook.md)
