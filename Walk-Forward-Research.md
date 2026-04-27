# Walk-Forward Research

Walk-forward analysis tests whether a strategy or predictive model holds up as training windows move forward through time. Current ta4j exposes two layers:

- Strategy walk-forward execution through `BarSeriesManager` and `BacktestExecutor`.
- Generic prediction research through the `org.ta4j.core.walkforward` package.

## Strategy Walk-Forward

For normal strategy validation, start with `WalkForwardConfig.defaultConfig(series)` and keep the resulting configuration fixed for every candidate in the same comparison cycle.

```java
WalkForwardConfig config = WalkForwardConfig.defaultConfig(series);
BarSeriesManager manager = new BarSeriesManager(series);

StrategyWalkForwardExecutionResult result = manager.runWalkForward(strategy, config);
List<Num> outOfSampleScores = result.outOfSampleCriterionValues(new GrossReturnCriterion());
```

When you also need the standard one-series backtest result, use `BacktestExecutor`:

```java
BacktestExecutor executor = new BacktestExecutor(series);
BacktestExecutor.BacktestAndWalkForwardResult combined =
        executor.executeWithWalkForward(strategy, config);
```

Use the maintained example [`ta4jexamples.walkforward.WalkForward`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/walkforward/WalkForward.java) for the current end-to-end pattern.

## Generic Prediction Research

Use `WalkForwardEngine` when the candidate is not just a `Strategy`, for example a ranked signal generator, Elliott Wave scenario scorer, or model family.

Core roles:

| Role | Class |
| --- | --- |
| Fold geometry and horizons | `WalkForwardConfig` |
| Train/test/holdout splits | `AnchoredExpandingWalkForwardSplitter`, `WalkForwardSplit` |
| Candidate predictions | `PredictionProvider`, `RankedPrediction`, `PredictionSnapshot` |
| Realized outcomes | `OutcomeLabeler` |
| Metrics | `WalkForwardMetric` |
| Run outputs | `WalkForwardRunResult`, `WalkForwardRuntimeReport`, `WalkForwardExperimentManifest` |
| Candidate ranking | `WalkForwardTuner`, `WalkForwardObjective`, `WalkForwardLeaderboard` |
| Holdout checks | `WalkForwardHoldoutValidator` |

```java
WalkForwardConfig config = WalkForwardConfig.defaultConfig(series);

WalkForwardEngine<MyContext, MySignal, Boolean> engine = new WalkForwardEngine<>(
        new AnchoredExpandingWalkForwardSplitter(),
        provider,
        labeler,
        List.of(
                WalkForwardMetric.topKHitRate("top1Hit", 1, (prediction, outcome) -> outcome),
                WalkForwardMetric.brierScore("brier", 1,
                        outcome -> outcome ? series.numFactory().one() : series.numFactory().zero())));

WalkForwardRunResult<MySignal, Boolean> run = engine.run(
        series,
        context,
        config,
        "candidate-a",
        Map.of("family", "example"));
```

The engine records leakage-audit rows for every decision/horizon pair and skips labels whose future window would cross the fold boundary.

## Tuning And Calibration

`WalkForwardTuner` evaluates a list of `WalkForwardCandidate<C>` values, keeps the top K candidates, and ranks them with a `WalkForwardObjective`.

Use `WalkForwardObjective.weighted(...)` when you want a composite objective with metric weights, guardrails, and fold-variance penalties. If the provider emits probabilities, calibration modes on `WalkForwardTuner` can compare raw probabilities against Platt scaling or an isotonic challenger with a guarded selection rule.

## Elliott Wave Research

Recent Elliott Wave examples use the generic walk-forward package for scenario research:

- [`ElliottWaveMultiDegreeAnalysisDemo`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/demo/ElliottWaveMultiDegreeAnalysisDemo.java) runs automatic multi-degree analysis.
- `ElliottWavePredictionProvider`, `ElliottWaveOutcomeLabeler`, and `ElliottWaveWalkForwardProfiles` adapt Elliott scenarios to the generic `PredictionProvider` / `OutcomeLabeler` model.

## Practical Guardrails

- Keep one `WalkForwardConfig` fixed while ranking a candidate set.
- Use purge and embargo bars when indicators or labels can leak neighboring information.
- Reserve holdout bars when you need a final untouched check.
- Compare candidates on out-of-sample metrics, not just the initial backtest result.
- Keep candidate IDs and manifest metadata stable enough to reproduce a study.

## Rationale Notes (2026-04-27)

- The new-feature scout found the `org.ta4j.core.walkforward` package and related backtest APIs added in commit `279d9056` with only sparse wiki coverage.
- The documented strategy path is grounded in `BarSeriesManager#runWalkForward(...)`, `BacktestExecutor#executeWalkForward(...)`, and `BacktestExecutor#executeWithWalkForward(...)`.
- The generic research path is grounded in `WalkForwardEngine`, `WalkForwardTuner`, `WalkForwardMetric`, `WalkForwardObjective`, `PredictionProvider`, and `OutcomeLabeler`.
- The examples scan confirmed current usage in `ta4jexamples.walkforward.WalkForward` and Elliott Wave demos added with commit `279d9056`.
