# Analysis Criteria and Risk Metrics

Use analysis criteria after a strategy run to compare returns, risk, duration, fees, and open exposure. Current ta4j criteria work with the same `TradingRecord` model used by both backtests and fill-driven live-style simulations.

## Recent Criteria Surface

| Need | Primary classes | Notes |
| --- | --- | --- |
| Risk-adjusted return | `SharpeRatioCriterion`, `SortinoRatioCriterion` | Support `SamplingFrequency`, `Annualization`, risk-free rates, grouping zones, cash-return policy, equity-curve mode, and open-position handling. |
| Drawdown-adjusted return | `CalmarRatioCriterion`, `ReturnOverMaxDrawdownCriterion` | `CalmarRatioCriterion` annualizes return and divides by maximum drawdown. |
| Distribution-aware return | `OmegaRatioCriterion` | Compares upside excess returns against downside shortfalls around a configurable threshold. |
| Trade duration | `PositionDurationCriterion` | Summarizes closed-position durations with `Statistics` such as mean/min/max. |
| Stop-model quality | `RMultipleCriterion` | Computes profit divided by per-trade risk from a `PositionRiskModel`. |
| Open exposure | `OpenPositionCostBasisCriterion`, `OpenPositionUnrealizedProfitCriterion` | Useful when evaluating records that can still have an open position. |
| Recorded fees | `TotalFeesCriterion` | Reads fees recorded on fills/trades instead of re-estimating them from a cost model. |

## Sampling And Equity-Curve Controls

`SharpeRatioCriterion` and `SortinoRatioCriterion` build a return sample from the equity curve. Choose these settings deliberately:

- `SamplingFrequency.BAR`, `SECOND`, `MINUTE`, `HOUR`, `DAY`, `WEEK`, or `MONTH` controls the return intervals.
- `Annualization.PERIOD` returns the per-sample ratio; `Annualization.ANNUALIZED` scales by observed periods per year.
- `EquityCurveMode.MARK_TO_MARKET` includes unrealized movement on each bar; `EquityCurveMode.REALIZED` updates the curve only when positions close.
- `OpenPositionHandling.MARK_TO_MARKET` includes the current open position; `IGNORE` evaluates only closed positions.

```java
AnalysisCriterion sharpe = new SharpeRatioCriterion(
        0.05,
        SamplingFrequency.DAY,
        Annualization.ANNUALIZED,
        ZoneOffset.UTC);

Num score = sharpe.calculate(series, tradingRecord);
```

## Windowed Criterion Evaluation

Since the window-aware criterion API, any `AnalysisCriterion` can be evaluated over a bounded slice without hand-copying a `TradingRecord`.

```java
AnalysisWindow window = AnalysisWindow.lookbackBars(120);
AnalysisContext context = AnalysisContext.defaults()
        .withMissingHistoryPolicy(AnalysisContext.MissingHistoryPolicy.CLAMP)
        .withOpenPositionHandling(OpenPositionHandling.MARK_TO_MARKET);

Num recentSharpe = sharpe.calculate(series, tradingRecord, window, context);
```

Available windows:

- `AnalysisWindow.barRange(startInclusive, endInclusive)`
- `AnalysisWindow.lookbackBars(barCount)`
- `AnalysisWindow.timeRange(startInclusive, endExclusive)`
- `AnalysisWindow.lookbackDuration(duration)`

Use `MissingHistoryPolicy.STRICT` when a missing lookback should fail fast. Use `CLAMP` for moving-series dashboards where the oldest requested bars may already have been evicted.

## Risk-Unit Evaluation

When a strategy is designed around stop placement, score it in risk units instead of raw profit:

```java
AnalysisCriterion rMultiple = new RMultipleCriterion(new StopLossPositionRiskModel(5));
Num averageR = rMultiple.calculate(series, tradingRecord);
```

`RMultipleCriterion` skips positions where the supplied `PositionRiskModel` cannot produce a positive risk value. That keeps invalid stop geometry from silently improving the average.

## Practical Workflow

1. Pick the business question first: absolute return, downside risk, trade duration, open exposure, or stop-model quality.
2. Match equity-curve mode and open-position handling to the system being measured.
3. Use `AnalysisWindow` for rolling dashboards, recent-regime checks, and moving-series records.
4. Use the same `NumFactory` through the originating `BarSeries`; criteria return `Num` values from that factory.

## Rationale Notes (2026-04-27)

- The new-feature scout flagged recent criteria and analysis classes that had no dedicated wiki entry point.
- Commit `9e0f63a9` added `SharpeRatioCriterion` plus sampling helpers such as `SamplingFrequency`, `SamplingFrequencyIndexes`, `Sample`, and `SampleSummary`.
- Commit `8d319169` added `SortinoRatioCriterion`; commit `b5f5d2d0` added `CalmarRatioCriterion` and `OmegaRatioCriterion`.
- Commit `3e7299a3` added the window-aware `AnalysisCriterion#calculate(..., AnalysisWindow, AnalysisContext)` API with `AnalysisWindow` and `AnalysisContext`.
- Commit `89cd2271` added risk-unit scoring around `RMultipleCriterion` and `PositionRiskModel`.
