# Migration and Version Compatibility

This page summarizes preferred APIs and compatibility guidance for current ta4j usage.

## Preferred APIs for new code

| Capability | Preferred API | Compatibility API |
| --- | --- | --- |
| Trading record | `BaseTradingRecord` | `LiveTradingRecord` (migration only) |
| Fill recording | `TradeFill` + `TradingRecord.operate(fill)` | `ExecutionFill` (migration only) |
| Backtest single strategy | `BarSeriesManager` | legacy custom loops where not needed |
| Backtest strategy batches | `BacktestExecutor` | custom batch wrappers without telemetry |
| Forecast summary | Num-only `Forecast` + `ForecastSupport` | 0.23.0 generic/positional forecast API (removed in 0.23.1) |
| Exact Monte Carlo price distribution | `MonteCarloPriceForecastIndicator` | transforming a return summary after simulation |
| Analytic price approximation | `LognormalApproximationPriceForecastIndicator` | removed `LogReturnToPriceForecastIndicator` |

## Forecast API correction in 0.23.1

The forecast API first released in 0.23.0 had ambiguous provenance and allowed mathematically invalid nonlinear summary transforms. ta4j 0.23.1 deliberately makes a breaking correction before later state-estimation phases build on it. This is an explicit exception to normal compatibility policy.

| Removed or changed 0.23.0 API | 0.23.1 replacement |
| --- | --- |
| `Forecast<Num>` | Num-only `Forecast` |
| `Forecast.map(...)` | `scale(...)` or `affine(...)` for affine transforms; transform empirical samples for nonlinear changes |
| `Forecast.ofSummary(...)` | `Forecast.builder(index, horizon, numFactory, support)` |
| Missing `forecast.quantile(p)` returned `null` | Missing valid quantiles return `NaN.NaN`; use `hasQuantile(p)` when presence matters |
| `sampleCount()` used for analytic/model metadata | `ForecastSupport`; sample count is empirical count and zero otherwise |
| `LogReturnToPriceForecastIndicator` | Exact `MonteCarloPriceForecastIndicator` or explicit `LognormalApproximationPriceForecastIndicator` |
| Broad `ForecastState` moment accessors | Minimal `ForecastState`; return models implement `ReturnMomentState` |
| Positional `ReturnForecastState` fields/constructor | `ReturnForecastState.stable(...)`, `.unstable(...)`, and composed `ReturnMoments` |
| `ReturnForecastStateIndicator<S extends ForecastState>` | `ReturnForecastStateIndicator<S extends ReturnMomentState>` |
| `meanDriftVarianceVolatility()` | `meanDriftVariance(representation)`; variance and volatility are not duplicated |
| `driftVolatility()` without representation | `driftVolatility(representation)` |
| `returnStateDefaults()` | `meanVolatility(representation)` |
| `ForecastFeatureExtractor.features(...)` only | `schema()`, allocation-free `extractInto(...)`, and convenience `features(...)` |

Migration order:

1. Remove the generic type argument from `Forecast` and replace nullable quantile handling.
2. Choose empirical or analytic `ForecastSupport`, then move positional summaries to the builder.
3. Replace nonlinear summary mapping with exact sample transformation or the explicitly analytic lognormal approximation.
4. Compose return state around `ReturnMoments` and bind feature extractors to the correct `ReturnRepresentation`.
5. Assert `ForecastProjectionIndicator.getHorizon()` and forecast metadata in custom projections.

Training and calibration row counts belong to model-specific state or diagnostics, not `Forecast.sampleCount()`. Conformal wrappers preserve base support; later analog projections use empirical neighbor support.

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
- The 0.23.1 forecast correction is intentionally source-incompatible with the new 0.23.0 forecast API; the mapping above is the supported migration path.

## Related pages

- [Getting Started](Getting-started.md)
- [Backtesting](Backtesting.md)
- [Live Trading](Live-trading.md)
- [Usage Examples](Usage-examples.md)
- [Forecast Indicators](Forecast-Indicators.md)
- [Forecast State Estimation](Forecast-State-Estimation.md)
