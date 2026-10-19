# Analysis Criteria and Risk Metrics

Use analysis criteria after a strategy run or portfolio simulation to compare returns, risk, duration, fees, open exposure, and statistical process control. Current ta4j criteria work with the same `TradingRecord` model used by both backtests and fill-driven live-style simulations.

## Recent Criteria Surface

| Need | Primary classes | Notes |
| --- | --- | --- |
| Risk-adjusted return | `SharpeRatioCriterion`, `SortinoRatioCriterion` | Support `SamplingFrequency` (including trade-level sampling), `Annualization`, risk-free rates, grouping zones, cash-return policy, equity-curve mode, and open-position handling. |
| Drawdown-adjusted return | `CalmarRatioCriterion`, `ReturnOverMaxDrawdownCriterion` | `CalmarRatioCriterion` annualizes return and divides by maximum drawdown. |
| Distribution-aware return | `OmegaRatioCriterion` | Compares upside excess returns against downside shortfalls around a configurable threshold. |
| Statistical process capability | `ProcessCapabilityCriterion` | Ranks strategies by $C_{pk}$ capability over closed-position gross returns relative to one- or two-sided specification limits. |
| Trade duration | `PositionDurationCriterion` | Summarizes closed-position durations with `Statistics` such as mean/min/max. |
| Stop-model quality | `RMultipleCriterion` | Computes profit divided by per-trade risk from a `PositionRiskModel`. |
| Open exposure | `OpenPositionCostBasisCriterion`, `OpenPositionUnrealizedProfitCriterion` | Useful when evaluating records that can still have an open position. |
| Recorded fees | `TotalFeesCriterion` | Reads fees recorded on fills/trades instead of re-estimating them from a cost model. |

## Sampling And Equity-Curve Controls

`SharpeRatioCriterion` and `SortinoRatioCriterion` build a return sample from the equity curve. Choose these settings deliberately:

- `SamplingFrequency.BAR`, `SECOND`, `MINUTE`, `HOUR`, `DAY`, `WEEK`, or `MONTH` controls time-based return intervals.
- `SamplingFrequency.TRADE` creates one return per included position interval. Use it when each trade, not each bar or calendar bucket, should contribute one observation.
- `Annualization.PERIOD` returns the per-sample ratio; `Annualization.ANNUALIZED` scales by observed periods per year.
- `EquityCurveMode.MARK_TO_MARKET` includes unrealized movement on each bar; `EquityCurveMode.REALIZED` updates the curve only when positions close.
- `OpenPositionHandling.MARK_TO_MARKET` includes the current open position; `IGNORE` evaluates only closed positions. Realized Sharpe calculations always ignore open positions.

```java
AnalysisCriterion sharpe = new SharpeRatioCriterion(
        0.05,
        SamplingFrequency.DAY,
        Annualization.ANNUALIZED,
        ZoneOffset.UTC);

Num score = sharpe.calculate(series, tradingRecord);
```

For a trade-level distribution, switch only the sampling frequency:

```java
AnalysisCriterion tradeSharpe = new SharpeRatioCriterion(
        0.05,
        SamplingFrequency.TRADE,
        Annualization.PERIOD,
        ZoneOffset.UTC);
AnalysisCriterion tradeSortino = new SortinoRatioCriterion(
        0.05,
        SamplingFrequency.TRADE,
        Annualization.PERIOD,
        ZoneOffset.UTC);

Num perTradeSharpe = tradeSharpe.calculate(series, tradingRecord);
Num perTradeSortino = tradeSortino.calculate(series, tradingRecord);
```

`TRADE` is for criteria that receive a `TradingRecord`, such as Sharpe and Sortino. It is intentionally not supported by `SamplingFrequencyIndexes`, because that helper can only group bar indices and cannot inspect positions.

## Windowed Criterion Evaluation & Logical Bounds

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

When evaluating a `BaseTradingRecord` created with explicit start or end bounds, position-based criteria automatically evaluate only positions entered at or after the start index, preventing pre-window trades on rolling series from leaking into results.

Use `MissingHistoryPolicy.STRICT` when a missing lookback should fail fast. Use `CLAMP` for moving-series dashboards where the oldest requested bars may already have been evicted.

## Risk-Unit Evaluation

When a strategy is designed around stop placement, score it in risk units instead of raw profit:

```java
AnalysisCriterion rMultiple = new RMultipleCriterion(new StopLossPositionRiskModel(5));
Num averageR = rMultiple.calculate(series, tradingRecord);
```

`RMultipleCriterion` skips positions where the supplied `PositionRiskModel` cannot produce a positive risk value. That keeps invalid stop geometry from silently improving the average.

## Practical Workflow

1. Pick the business question first: absolute return, downside risk, trade duration, open exposure, statistical process capability, or stop-model quality.
2. Match equity-curve mode and open-position handling to the system being measured.
3. Use `AnalysisWindow` for rolling dashboards, recent-regime checks, and moving-series records.
4. Use the same `NumFactory` through the originating `BarSeries`; criteria return `Num` values from that factory.

## Rationale Notes

- Added `ProcessCapabilityCriterion` ($C_{pk}$) and updated logical position bounds behavior on `BaseTradingRecord`.
- Preserved `SharpeRatioCriterion`, `SortinoRatioCriterion`, `CalmarRatioCriterion`, `OmegaRatioCriterion`, and `AnalysisWindow` overloads.
