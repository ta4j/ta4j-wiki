# Migration and Version Compatibility

This page summarizes preferred APIs and compatibility guidance for current ta4j usage.

## Preferred APIs for new code

| Capability | Preferred API | Compatibility API |
| --- | --- | --- |
| Trading record | `BaseTradingRecord` | `LiveTradingRecord` (migration only) |
| Fill recording | `TradeFill` + `TradingRecord.operate(fill)` | `ExecutionFill` (migration only) |
| Backtest single strategy | `BarSeriesManager` | legacy custom loops where not needed |
| Backtest strategy batches | `BacktestExecutor` | custom batch wrappers without telemetry |

## Migration lane

1. Keep existing adapter interfaces stable.
2. Replace execution events with `TradeFill`.
3. Route record updates through `TradingRecord.operate(fill)` or grouped `Trade.fromFills(...)`.
4. Validate parity with `TradingRecordParityBacktest` and `TradeFillRecordingExample`.
5. Remove compatibility APIs once downstream consumers are migrated.

## Compatibility notes

- `LiveTradingRecord` and `ExecutionFill` remain available in 0.22.x for incremental migration.
- New examples and documentation use `BaseTradingRecord` and `TradeFill` as canonical APIs.
- Release notes remain the source of truth for version-specific changes.

## Related pages

- [Getting Started](Getting-started.md)
- [Backtesting](Backtesting.md)
- [Live Trading](Live-trading.md)
- [Usage Examples](Usage-examples.md)
