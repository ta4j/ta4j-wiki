# Forecast State Estimation

Forecast state separates what the market looks like at a decision index from how a model projects that state forward. This page covers the common state API introduced for estimator-independent forecast models. For the complete EWMA-to-Monte-Carlo workflow, start with [Forecast Indicators](Forecast-Indicators.md).

**Release status:** The core forecast workflow shipped in ta4j 0.23.0. The generic state contract, standard feature extractors, typed return-state refinement, and summary-only factory on this page target ta4j 0.23.1.

## The common state contract

Every reusable forecast state implements `ForecastState`:

| Method | Meaning |
| --- | --- |
| `index()` | Bar index represented by the state. |
| `observationCount()` | Number of observations represented by a stable state. |
| `isStable()` | Whether downstream projections may use the state. |
| `mean()` | Current return-domain mean estimate. |
| `drift()` | Drift assumption intended for forward projection. |
| `variance()` | Current non-negative return variance. |
| `volatility()` | Current non-negative return volatility. |

Concrete records may add estimator-specific fields. Generic projections should use the common methods unless their algorithm genuinely requires those specialized values.

A stable built-in state has at least one observation and finite common values. An unstable state has zero observations and `NaN.NaN` common values. Always check `isStable()` before extracting features or making an operator decision.

```java
LogReturnIndicator returns = new LogReturnIndicator(series);
ReturnForecastStateIndicator<ReturnForecastState> states =
        new EwmaReturnForecastStateIndicator(returns);

ForecastState state = states.getValue(series.getEndIndex());
if (state.isStable()) {
    Num expectedReturn = state.mean();
    Num forecastDrift = state.drift();
    Num currentVolatility = state.volatility();
}
```

`ForecastStateIndicator<S extends ForecastState>` is the normal ta4j `Indicator` extension point for custom estimators. Return-derived estimators should implement `ReturnForecastStateIndicator<S>` instead. Its `getReturnIndicator()` method lets projections reuse the original return stream, and `getReturnRepresentation()` declares whether that stream contains log or decimal returns without another constructor argument.

Keep `getValue(i)` causal: it may read source values through `i`, never values after `i`. Return a deterministic unstable state during warm-up rather than leaking partial or non-finite model state.

## Feature extraction

`ForecastFeatureExtractor<S>` marks the deliberate boundary between precision-aware `Num` values and primitive-only algorithms such as Commons Math distance measures and regressions.

```java
ForecastFeatureExtractor<ReturnForecastState> extractor =
        ForecastFeatureExtractors.returnStateDefaults();

ReturnForecastState state = stateIndicator.getValue(index);
if (state.isStable()) {
    double[] features = extractor.features(state);
    // [mean, volatility]
}
```

The standard factories are:

| Factory | Feature order | Typical use |
| --- | --- | --- |
| `meanDriftVarianceVolatility()` | mean, drift, variance, volatility | Complete generic state comparison. |
| `driftVolatility()` | drift, volatility | Compact path-simulation or regime features. |
| `returnStateDefaults()` | mean, volatility | Default return-state similarity without duplicating EWMA mean through drift. |

Each call returns a new array. The built-in extractors reject `null`, unstable states, and selected values that cannot be represented as finite doubles. Keep calculations in `Num` before this boundary; do not convert an entire indicator pipeline to primitives merely to simplify one model.

Custom extractors are ordinary lambdas:

```java
ForecastFeatureExtractor<ReturnForecastState> riskFeatures = state -> new double[] {
        state.volatility().doubleValue(),
        state.variance().doubleValue()
};
```

Custom extractors and consumers should reject empty, non-finite, or changing-length vectors. The built-in extractors also reject a finite high-precision `Num` when it overflows at the deliberate primitive `double[]` boundary. Feature scaling belongs to the consuming model because the correct scaling depends on its distance or regression method.

## Creating a forecast summary without samples

Use `Forecast.ofSummary(...)` when a model or calibration wrapper has legitimate summary statistics but did not generate a sample collection:

```java
Map<Double, Num> quantiles = Map.of(
        0.05, lower,
        0.50, median,
        0.95, upper);

Forecast<Num> forecast = Forecast.ofSummary(
        decisionIndex,
        horizon,
        representedDistributionValueCount,
        mean,
        median,
        standardDeviation,
        quantiles);
```

The factory creates a stable forecast, requires a positive count of represented distribution values, validates finite numeric summary fields and non-negative standard deviation, validates probabilities in `[0, 1]`, requires numeric quantile values to be nondecreasing, sorts quantiles, and copies the map. Weighted models report represented neighbors, bootstrap models report draws, conformal wrappers preserve the base forecast count, and an analytic single-model summary reports `1`. Training and calibration observation counts are model metadata and must not be placed in `Forecast.sampleCount()`.

Use `Forecast.ofSamples(...)` when real samples exist; it calculates the summary for you. Use `Forecast.unstable(...)` when the model is not ready or any numeric summary value is unavailable. Finite high-precision `Num` values remain valid even when their primitive `doubleValue()` would overflow because summary validation stays in the `Num` domain.

## Operator checklist

- Set strategy unstable bars from the complete projection pipeline, not only the state estimator.
- Inspect `observationCount()` when diagnosing warm-up or reset behavior.
- Treat `sampleCount()` as distribution provenance, not estimator training metadata.
- Keep feature order and scaling stable across research, replay, and production.
- Treat forecasts as estimates rather than targets or guarantees.
- Reject non-finite source data instead of allowing it to contaminate cached state.

## When not to use the generic surface

Use a concrete state record when the projection truly depends on an estimator-specific value. Do not add untyped metadata maps to `ForecastState`, expose rolling training histories through it, or treat common `mean` and `volatility` as proof that two estimators use the same internal model.

## Related pages

- [Forecast Indicators](Forecast-Indicators.md)
- [Technical Indicators](Technical-indicators.md)
- [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md)
