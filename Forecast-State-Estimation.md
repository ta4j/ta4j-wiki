# Forecast State Estimation

ta4j 0.23.1 separates estimator lifecycle, return moments, feature schemas, and projection models. The small contracts make custom states natural to compose without forcing every estimator into one flat record.

## Default Composition

```java
LogReturnIndicator returns = new LogReturnIndicator(series);
ReturnForecastStateIndicator<ReturnForecastState> state =
        new EwmaReturnForecastStateIndicator(returns);
MonteCarloPriceForecastIndicator projection =
        new MonteCarloPriceForecastIndicator(state, 5);
```

`state.getReturnIndicator()` exposes the exact semantic return stream consumed by the estimator. `state.getReturnRepresentation()` delegates to that stream. Projections validate the state index, representation, stability, observation count, and canonical moments before use.

## State Contracts

`ForecastState` contains only `index()` and `isStable()`. Estimator-specific state belongs in focused records rather than a universal bag of fields.

Return estimators implement `ReturnMomentState` and expose one validated `ReturnMoments` component:

| Field | Meaning |
| --- | --- |
| `index` | Source index represented by the moments. |
| `observationCount` | Valid observations incorporated by the estimator; not forecast sample count. |
| `isStable` | Whether the moment values are usable. |
| `representation` | `LOG`, `DECIMAL`, `PERCENTAGE`, or `MULTIPLICATIVE`. |
| `mean` | Estimated return location. |
| `drift` | Forward drift assumption used by a projection. |
| `variance` | Canonical dispersion value. |
| `volatility()` | Derived square root of canonical variance using its owning factory. |

```java
ReturnMoments moments = ReturnMoments.stable(
        index, observations, ReturnRepresentation.LOG, mean, drift, variance);
ReturnForecastState state = ReturnForecastState.stable(
        index, observations, ReturnRepresentation.LOG, mean, drift, variance);
```

Unstable moments may retain a positive observation count, which is useful when data exists but an estimator-specific condition is not met. They must use `NaN.NaN` for mean, drift, and variance:

```java
ReturnMoments unavailable =
        ReturnMoments.unstable(index, observations, ReturnRepresentation.LOG);
```

## Rich Custom States

Compose common moments instead of duplicating their invariants:

```java
record RegimeReturnState(ReturnMoments moments, Num regimeProbability)
        implements ReturnMomentState {
}

final class RegimeStateIndicator
        implements ReturnForecastStateIndicator<RegimeReturnState> {
    // Implement getValue, getReturnIndicator, getBarSeries, and warm-up metadata.
}
```

This preserves typed specialized fields while allowing existing return projections to consume the shared moments. A stable custom state must report the queried index, the indicator's return representation, at least one observation, finite moments, and non-negative variance.

## Rough-Volatility State

`RoughVolatilityForecastStateIndicator` is the built-in rich-state example for operators who need more than current return location and scale. It composes the same `ReturnMoments` used by EWMA with a bounded roughness estimate, log-volatility variability, and a cumulative variance term structure.

```java
LogReturnIndicator returns = new LogReturnIndicator(series);
RoughVolatilityForecastStateIndicator states =
        new RoughVolatilityForecastStateIndicator(returns);

RoughVolatilityForecastState state = states.getValue(series.getEndIndex());
if (state.isStable()) {
    Num oneBarVariance = state.horizonVarianceForecasts().get(0);
    Num fiveBarVariance = state.horizonVarianceForecasts().get(4);
}
```

Advanced construction keeps the same semantic return source and changes only explicit model assumptions:

```java
RoughVolatilityForecastStateIndicator states =
        RoughVolatilityForecastStateIndicator.builder(returns)
                .initializationBarCount(90)
                .decayFactor(0.97)
                .driftMode(EwmaReturnForecastStateIndicator.DriftMode.ZERO)
                .roughnessWindow(180)
                .volOfVolWindow(90)
                .horizon(10)
                .build();
```

| Setting | Default | Operator intent |
| --- | --- | --- |
| `initializationBarCount(...)` | `60` | Valid returns required by the shared EWMA moments. |
| `decayFactor(...)` | `0.94` | Persistence of current mean and canonical variance. |
| `driftMode(...)` | `ZERO` | Forward drift assumption carried by the common moments. |
| `roughnessWindow(...)` | `120` | History used by the log-variogram regression. |
| `volOfVolWindow(...)` | `60` | Population dispersion window for the log-volatility proxy. |
| `horizon(...)` | `5` | Number of cumulative variance horizons emitted. |

| State field | Meaning |
| --- | --- |
| `moments()` | Stable log-return mean, drift, canonical variance, and observation provenance. |
| `roughnessHurst()` | OLS log-variogram slope divided by two and clamped to `[0.01, 0.49]`. |
| `volOfVol()` | Population standard deviation of `log(abs(return) + 1e-8)` over its configured window. |
| `horizonVarianceForecasts()` | Immutable cumulative variances; entry `h - 1` is `currentVariance * h^(2H)`. |

The first horizon variance is factory-coherent with the current canonical variance. The estimator uses lags one through ten, or all available lags for shorter configured windows, and floors each variogram at `1e-12` before taking its logarithm. These are deterministic state diagnostics, not a claim that returns follow a complete rough-volatility pricing model.

The state remains unstable until EWMA initialization, the roughness window, and the vol-of-vol window are all complete and finite. A non-finite return resets availability for every affected rolling window; later indices recover automatically. Unstable state preserves the known observation count, uses `NaN.NaN` for specialized scalars, and exposes an empty variance list.

Use rough-volatility state when changing volatility persistence or multi-horizon risk shape is part of the model. Prefer `EwmaReturnForecastStateIndicator` when current mean and variance are sufficient, the available history is short, or the extra dimensions have not earned their place in out-of-sample testing.

## Online Change-Point State

`OnlineChangePointForecastStateIndicator` estimates uncertainty about the current log-return regime. It uses canonical constant-hazard Bayesian online change-point detection with Normal-Inverse-Gamma sufficient statistics, Student-t predictive densities, and log-space normalization.

```java
LogReturnIndicator returns = new LogReturnIndicator(series);
OnlineChangePointForecastStateIndicator states =
        new OnlineChangePointForecastStateIndicator(returns);

OnlineChangePointForecastState state = states.getValue(series.getEndIndex());
if (state.isStable()) {
    Num recentChangeProbability = state.recentChangeProbability();
    int regimeAge = state.mostLikelyRunLength();
    List<RunLengthPosterior> alternatives = state.topRunLengths();
}
```

Advanced construction keeps the same semantic return source and names every model assumption:

```java
OnlineChangePointForecastStateIndicator states =
        OnlineChangePointForecastStateIndicator.builder(returns)
                .expectedRunLength(150)
                .maximumRunLength(500)
                .topRunLengthCount(8)
                .minimumObservationCount(30)
                .recentChangeWindow(10)
                .priorMean(0)
                .priorMeanPrecision(1e-3)
                .priorShape(3)
                .priorScale(1e-3)
                .build();
```

| Setting | Default | Operator intent |
| --- | --- | --- |
| `expectedRunLength(...)` | `100` | Controls the constant hazard `1 / expectedRunLength`; larger values favor longer regimes. |
| `maximumRunLength(...)` | `252` | Bounds posterior cost and the oldest retained run-length hypothesis. |
| `topRunLengthCount(...)` | `5` | Number of typed posterior summaries published without subset renormalization. |
| `minimumObservationCount(...)` | `20` | Consecutive valid returns required after construction or reset. |
| `recentChangeWindow(...)` | `5` | Inclusive run-length boundary used by the recent-change probability. |
| `priorMean(...)` | `0` | Prior location for a newly reset component. |
| `priorMeanPrecision(...)` | `1e-4` | Confidence in the prior mean; higher values shrink regimes toward it. |
| `priorShape(...)` | `2` | Inverse-Gamma shape; must exceed one so expected observation variance exists. |
| `priorScale(...)` | `1e-4` | Positive prior observation-variance scale. |

| State field | Meaning |
| --- | --- |
| `moments()` | MAP component mean, drift, canonical expected observation variance, and consecutive valid observation count. Drift equals the component mean. |
| `recentChangeProbability()` | Complete posterior mass for run lengths `0..recentChangeWindow`. |
| `mostLikelyRunLength()` | Run length of the probability-leading component after deterministic tie-breaking. |
| `topRunLengths()` | Immutable probability-descending summaries; equal probabilities use shorter run length first. |

Each `RunLengthPosterior` contains run length, its probability in the complete posterior, posterior mean, and expected observation variance. The top list generally sums to less than one because omitted hypotheses retain their probability. In the untruncated constant-hazard filter, `P(runLength = 0)` equals the hazard. Configured tail truncation and renormalization can increase it slightly, but it still is not a responsive change signal; `recentChangeProbability()` intentionally aggregates short run lengths instead.

The estimator remains unstable until 20 consecutive valid returns mature by default. A non-finite return or primitive conversion overflow/underflow resets the posterior and observation count. Removed history is not silently reused: a bounded series must warm up again from its first retained bar. Unstable state preserves its current valid-run count, uses `NaN.NaN` for recent-change probability, reports run length `-1`, and exposes an empty posterior list.

Use change-point state when abrupt location/variance regimes and uncertainty about regime age are intentional model inputs. Prefer EWMA for smooth adaptation, rough-volatility state for volatility persistence and term structure, or a smaller schema when regime dimensions have not improved walk-forward results. This state is diagnostic, not a standalone entry signal.

## Feature Schemas

Feature vectors are representation-bound and self-describing. Choose a schema by modeling intent:

```java
ForecastFeatureExtractor<ReturnForecastState> extractor =
        ForecastFeatureExtractors.meanVolatility(ReturnRepresentation.LOG);

ForecastFeatureSchema schema = extractor.schema();
double[] values = extractor.features(state.getValue(index));
```

| Factory | Schema ID | Ordered shape | Raw units | Use when |
| --- | --- | --- | --- | --- |
| `meanVolatility(rep)` | `return-moments/mean-volatility` | `[mean, volatility]` | return, return | Similarity needs level and scale. |
| `driftVolatility(rep)` | `return-moments/drift-volatility` | `[drift, volatility]` | return, return | The model intentionally uses forward drift. |
| `meanDriftVariance(rep)` | `return-moments/mean-drift-variance` | `[mean, drift, variance]` | return, return, return squared | A model needs separate location assumptions and canonical variance. |
| `roughVolatility()` | `rough-volatility/default` | `[mean, volatility, roughness_hurst, vol_of_vol]` | log-return, log-return, dimensionless, dimensionless | Similarity should include roughness and volatility variability. |
| `changePoint()` | `change-point/default` | `[mean, volatility, recent_change_probability, most_likely_run_length]` | log-return, log-return, probability, observations | Similarity should include recent regime uncertainty and age. |

Every schema has version `1`, its required return representation, a defensive ordered descriptor list, and `dimension()`. Unit names are `log-return`, `decimal-return`, `percentage-points`, or `multiplicative-return`; variance appends `^2`.

For allocation-sensitive model loops, reuse a target array:

```java
double[] row = new double[10];
extractor.extractInto(state.getValue(index), row, 4);
```

`extractInto` writes exactly `schema.dimension()` values beginning at `offset`. It rejects an unstable or mismatched-representation state, insufficient target space, non-finite primitive conversion, primitive overflow, and a nonzero `Num` that underflows to primitive zero. `features(state)` allocates a fresh defensive array for convenience.

Feature values remain in raw declared units. Consumers such as analog-distance models own training-window standardization; the extractor does not hide scaling assumptions.

`AnalogReturnProjectionIndicator` validates the schema representation against each candidate's `ReturnMoments`, rejects inconsistent feature dimensions or non-finite primitive values, and fits optional standardization from matured historical candidates only. The current query state is never part of that fit. See [Forecast Projection Models](Forecast-Projection-Models.md) for construction and tuning.

## Forecast Construction and Provenance

State observation counts are training metadata. Forecast support describes the output distribution:

- `ForecastSupport.empirical(count)` counts terminal paths, selected analog neighbors, or bootstrap draws.
- `ForecastSupport.analytic(assumption)` names the distribution or model assumption and has `sampleCount() == 0`.
- `ForecastSupport.unavailable()` identifies an unstable summary.

Use `Forecast.ofSamples(...)` for empirical output and `Forecast.builder(...)` for coherent analytic or externally summarized output. Conformal wrappers preserve the base support; they do not replace it with calibration-row count.

## Warm-Up and Recovery

EWMA state is unstable until its configured initialization window contains valid returns. Rough-volatility state also waits for its rolling proxy windows. Online change-point state requires a complete consecutive-valid warm-up after any reset. Invalid inputs produce unstable moments rather than partially valid fields, and later indices recover only after the relevant estimator contract is satisfied again.

Model consumers should treat these as unusable:

- null state or moments;
- state or moment index different from the requested index;
- return representation different from the indicator/schema contract;
- unstable moments, zero stable observation count, or non-finite moment values;
- negative canonical variance;
- values that cannot be normalized through the owning `NumFactory` without overflow or nonzero underflow.

## When to Extend

Implement only `ForecastState` for lifecycle-only estimator output. Implement `ReturnMomentState` when the estimator has canonical return moments. Implement `ReturnForecastStateIndicator<S>` when it also owns a semantic `ReturnIndicator` and should compose with return projections.

Do not add specialized fields to `ReturnMoments`, overload `Forecast.sampleCount()` with training rows, expose unnamed feature arrays, or let an extractor silently standardize data.

## Migration

The 0.23.1 correction deliberately replaces the forecast foundation introduced in 0.23.0. See the complete mapping in [Migration and Version Compatibility](Migration-and-Version-Compatibility.md#forecast-api-correction-in-0231).
