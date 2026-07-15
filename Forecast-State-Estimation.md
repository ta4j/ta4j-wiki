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

EWMA state is unstable until its configured initialization window contains valid returns. Invalid inputs produce unstable moments rather than partially valid fields. Later indices recover once all required state and lookback inputs are valid again.

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
