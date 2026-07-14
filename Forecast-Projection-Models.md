# Forecast Projection Models

ta4j 0.23.1 adds two complementary projection tools: analog forecasting creates an empirical return distribution from similar historical states, and rolling conformal calibration adjusts an existing forecast's tails using matured forecast errors. Both are causal `Indicator<Forecast>` implementations and return `ForecastSupport.Unavailable` rather than inventing a partial distribution.

## Analog Return Projection

`AnalogReturnProjectionIndicator<S extends ReturnMomentState>` answers: “What happened after historical states that looked like this one?” It projects cumulative log returns and reports `ForecastSupport.empirical(selectedNeighborCount)`.

### Default construction

```java
LogReturnIndicator returns = new LogReturnIndicator(series);
ReturnForecastStateIndicator<ReturnForecastState> states =
        new EwmaReturnForecastStateIndicator(returns);
AnalogReturnProjectionIndicator<ReturnForecastState> analog =
        new AnalogReturnProjectionIndicator<>(states);
```

The return-specific state contract is the joyful path: the projection infers the source return indicator, validates shared-series and log-return semantics, and uses the representation-bound `[mean, volatility]` schema.

### Advanced construction

```java
AnalogReturnProjectionIndicator<ReturnForecastState> analog =
        AnalogReturnProjectionIndicator.builder(states)
                .horizon(5)
                .lookbackBarCount(504)
                .neighborCount(40)
                .minimumNeighborCount(15)
                .featureExtractor(ForecastFeatureExtractors
                        .driftVolatility(ReturnRepresentation.LOG))
                .standardizeFeatures(true)
                .quantiles(0.01, 0.05, 0.5, 0.95, 0.99)
                .build();
```

Use `builder(ForecastStateIndicator<S>, ReturnIndicator)` only when a custom state source cannot expose its return stream through `ReturnForecastStateIndicator<S>`.

| Setting | Default | Operator intent |
| --- | --- | --- |
| `horizon(...)` | `1` | Match the forward-return label to the holding period. |
| `lookbackBarCount(...)` | `252` | Bound historical candidate decisions. |
| `neighborCount(...)` | `30` | Cap the empirical states represented by the forecast. |
| `minimumNeighborCount(...)` | `5` | Refuse forecasts that rely on too little comparable history. |
| `featureExtractor(...)` | log `[mean, volatility]` | Choose a fixed schema whose representation and units match the model. |
| `standardizeFeatures(...)` | `true` | Fit per-feature scale from eligible candidates only. |
| `quantiles(...)` | `0.05, 0.25, 0.5, 0.75, 0.95` | Request only probabilities consumed downstream. |

For decision `i`, candidate `j` is eligible only when `j + horizon <= i`. Its feature vector and complete forward return must be usable. Standardization is fit without the current state, so the query never influences training scale. Euclidean distances sort by distance and then source index. Normalized `exp(-distance)` weights drive the mean, population variance, and weighted empirical quantiles.

Use analog projection when state similarity has an interpretable historical meaning and an empirical neighbor distribution is useful. Do not use it when the history has too few comparable regimes, the schema mixes representations, or standardizing the chosen raw features cannot make their distances meaningful.

## Rolling Conformal Calibration

`RollingConformalForecastProjectionIndicator` wraps any numeric forecast and widens its configured tails using recent absolute median errors. It preserves the base mean, median, standard deviation, horizon, decision index, and support. Calibration rows are not samples and never replace base provenance.

### Generic realized values

```java
RollingConformalForecastProjectionIndicator calibrated =
        new RollingConformalForecastProjectionIndicator(priceForecast, closePrice);
```

The realized value for a decision is `closePrice.getValue(decision + horizon)`.

### Cumulative log returns

```java
RollingConformalForecastProjectionIndicator calibrated =
        RollingConformalForecastProjectionIndicator
                .cumulativeLogReturnBuilder(analog, returns)
                .targetCoverage(0.95)
                .calibrationWindow(504)
                .minimumCalibrationCount(60)
                .build();
```

This path validates that both the base forecast and realized stream use `ReturnRepresentation.LOG`, then sums returns from `decision + 1` through `decision + horizon`.

| Setting | Default | Operator intent |
| --- | --- | --- |
| `targetCoverage(...)` | `0.90` | Select the finite-sample absolute-error rank. |
| `calibrationWindow(...)` | `252` | Inspect this many recent matured decision rows. |
| `minimumCalibrationCount(...)` | `30` | Stay unavailable until enough valid scores mature. |

With `n` valid scores, the calibration radius is order statistic `ceil((n + 1) * coverage)`, capped at `n`. Lower quantiles subtract that radius, upper quantiles add it, and the median remains unchanged. This is intentionally called rolling conformal calibration, not Adaptive Conformal Inference: no online coverage-rate update is claimed.

Use the wrapper when recent, matured residuals are relevant to operational tail width and preserving the base model is important. Do not use it as a cure for a biased or semantically mismatched base model, and do not interpret target coverage as a guarantee under arbitrary distribution shift.

## Warm-Up and Failure Modes

Analog output stays unavailable until the current state and enough fully matured candidates are usable. Rolling conformal output stays unavailable until its base forecast is stable and the minimum valid calibration count has matured. Both can recover at later indexes.

Unavailable results include:

- state, forecast, or horizon metadata does not match the queried decision;
- state moments, feature extraction, realized values, or cumulative returns are null or non-finite;
- schema and return representation differ;
- indicators do not share the same underlying `BarSeries`;
- primitive feature conversion overflows or a nonzero value underflows to zero;
- too few analog neighbors or calibration scores remain after validation;
- weighted numeric normalization cannot be represented by the owning `NumFactory`;
- a positive conformal radius would widen a zero-dispersion base forecast.

Always branch on `forecast.isStable()` when reading a raw summary. Point adapters such as `projection.quantile(0.05)` emit `NaN.NaN` for unavailable forecasts.

## Runnable Example

`ta4jexamples.analysis.forecast.RollingConformalForecastExample` loads the committed Coinbase BTC-USD daily resource, builds a five-day analog return forecast, and calibrates it with matured five-day cumulative log returns.

```bash
./mvnw -pl ta4j-examples -am install
./mvnw -pl ta4j-examples exec:java \
  -Dexec.mainClass=ta4jexamples.analysis.forecast.RollingConformalForecastExample
```

## Related Guides

- [Forecast Indicators](Forecast-Indicators.md)
- [Forecast State Estimation](Forecast-State-Estimation.md)
- [Walk-Forward Research](Walk-Forward-Research.md)
