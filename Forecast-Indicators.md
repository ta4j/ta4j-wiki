# Forecast Indicators

Forecast indicators estimate a future return or price distribution using only information available at a decision index. The 0.23.1 API makes the distribution's numeric domain, horizon, and provenance explicit.

Use them for probabilistic filters, sizing, risk limits, chart overlays, and out-of-sample research. Do not treat a quantile as a guaranteed target or use a horizon that does not match the strategy's execution and holding period.

For reusable state contracts and feature schemas, see [Forecast State Estimation](Forecast-State-Estimation.md). Applications upgrading from 0.23.0 should read [Migration and Version Compatibility](Migration-and-Version-Compatibility.md#forecast-api-correction-in-0231).

For detailed analog and rolling calibration tuning, see [Forecast Projection Models](Forecast-Projection-Models.md).

## Quick Start: Exact Monte Carlo Prices

```java
BarSeries series = ...;
LogReturnIndicator returns = new LogReturnIndicator(series);
ReturnForecastStateIndicator<ReturnForecastState> state =
        new EwmaReturnForecastStateIndicator(returns);
ForecastProjectionIndicator prices =
        new MonteCarloPriceForecastIndicator(state, 5);

int index = series.getEndIndex();
Forecast forecast = prices.getValue(index);
if (forecast.isStable()) {
    Num downside = forecast.quantile(0.05);
    Num median = forecast.median();
    Num upside = forecast.quantile(0.95);
}

Indicator<Num> medianSeries = prices.median();
Indicator<Num> downsideSeries = prices.quantile(0.05);
```

`MonteCarloPriceForecastIndicator` infers the price source when the state uses `LogReturnIndicator`. It converts every simulated cumulative return to a terminal price before calculating any moment or quantile. Mean, median, standard deviation, and quantiles therefore describe the same empirical price paths.

The shortest constructor uses a 30-observation EWMA state, one or five bars as requested, 1,000 paths, a 252-return lookback, seed `42`, standardized empirical shocks, constant path volatility, and quantiles `0.05`, `0.25`, `0.5`, `0.75`, and `0.95`.

## Quick Start: Analog Returns With Rolling Calibration

```java
LogReturnIndicator returns = new LogReturnIndicator(series);
ReturnForecastStateIndicator<ReturnForecastState> states =
        new EwmaReturnForecastStateIndicator(returns);
AnalogReturnProjectionIndicator<ReturnForecastState> analog =
        new AnalogReturnProjectionIndicator<>(states, 5);
ReturnForecastProjectionIndicator calibrated =
        RollingConformalForecastProjectionIndicator
                .cumulativeLogReturnBuilder(analog, returns)
                .build();

Forecast result = calibrated.getValue(series.getEndIndex());
```

Analog projection uses only post-warm-up candidates whose complete five-bar outcomes have matured, fits feature standardization from historical candidates only, and reports selected neighbors as empirical support. The conformal wrapper remains unavailable until at least 30 valid historical forecasts mature and the finite-sample coverage rank is attainable, then widens lower and upper quantiles while preserving the analog mean, median, standard deviation, support, and semantic return-projection contract.

## Forecast Semantics

Every `Forecast` is Num-only and contains:

| API | Meaning |
| --- | --- |
| `decisionIndex()` / `index()` | Index where the forecast was made. |
| `horizon()` | Number of bars represented by the outcome distribution. |
| `support()` | `Unavailable`, `Empirical(count)`, or `Analytic(assumption)`. |
| `sampleCount()` | Empirical represented-value count; zero for analytic or unavailable support. |
| `mean()`, `median()`, `standardDeviation()` | Coherent distribution summary values. |
| `quantiles()` | Immutable configured probability-to-value map. |
| `quantile(p)` | Configured quantile, or `NaN.NaN` when valid `p` is absent. |
| `isStable()` | Whether the summary is available and usable. |

All built-in projections return a non-null forecast whose decision index and horizon match the query and `getHorizon()`. Point adapters return `NaN.NaN` if that contract is violated, if the forecast is unavailable, or if the requested quantile is absent.

`Forecast.ofSamples(...)` is the shortest empirical factory. It retains finite samples, normalizes them to the first retained sample's `NumFactory`, and reports retained count as empirical support. For analytic or externally summarized distributions, use the builder:

```java
Forecast forecast = Forecast.builder(
                index,
                horizon,
                series.numFactory(),
                ForecastSupport.analytic("normal-residual"))
        .mean(mean)
        .median(median)
        .standardDeviation(standardDeviation)
        .quantiles(quantiles)
        .build();
```

The builder requires finite mean, median, and non-negative standard deviation. It normalizes all values through the declared factory and validates ordered quantiles, median/0.5 agreement, zero-dispersion equality, and one-value empirical coherence. Use `Forecast.unstable(index, horizon)` when a valid summary cannot be produced.

Use `forecast.scale(factor)` or `forecast.affine(scale, offset)` only for mathematically affine domain changes. Negative scaling reverses quantile probabilities and standard deviation uses the absolute scale. Nonlinear transforms such as `price * exp(logReturn)` must be applied to samples before summarization or modeled as an explicitly named analytic approximation.

## Advanced Exact Price Forecast

Custom return-state estimators often cannot expose an inferable source price. Supply it explicitly and tune the price projection directly:

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
ReturnForecastStateIndicator<? extends ReturnMomentState> state = ...;

MonteCarloPriceForecastIndicator prices =
        MonteCarloPriceForecastIndicator.builder(close, state)
                .horizon(5)
                .iterationCount(5_000)
                .lookbackBarCount(504)
                .seed(7L)
                .shockModel(MonteCarloReturnProjectionIndicator.ShockModel.STANDARDIZED_EMPIRICAL)
                .volatilityUpdateMode(MonteCarloReturnProjectionIndicator.VolatilityUpdateMode.EWMA)
                .volatilityDecayFactor(0.97)
                .quantiles(0.01, 0.05, 0.5, 0.95, 0.99)
                .build();
```

| Setting | Default | Operator intent |
| --- | --- | --- |
| `horizon(...)` | `1` | Match the forecast label and holding period. |
| `iterationCount(...)` | `1_000` | Increase for smoother tails after measuring latency. |
| `lookbackBarCount(...)` | `252` | Choose the historical regime represented by shocks. |
| `seed(...)` | `42` | Keep fixed for reproducible research and operations. |
| `shockModel(...)` | `STANDARDIZED_EMPIRICAL` | Preserve recent residual shape at current state volatility. |
| `volatilityUpdateMode(...)` | `CONSTANT` | Use `EWMA` only when path-dependent volatility is intentional. |
| `volatilityDecayFactor(...)` | `0.94` | Path EWMA persistence when updates are enabled. |
| `quantiles(...)` | five defaults | Request only tails consumed by rules or reports. |
| `monteCarloMethod(...)` | shock-path defaults above | Replace the whole sampling technique, e.g. with a decorator composition. |

Shock model choices:

| Model | Behavior | Use when |
| --- | --- | --- |
| `HISTORICAL_BOOTSTRAP` | Samples raw historical returns. | Recent realized scale and shape should be preserved directly. |
| `STANDARDIZED_EMPIRICAL` | Samples standardized residuals and applies state drift/volatility. | Current scale plus empirical tail shape is desired. |
| `NORMAL` | Samples standard-normal shocks. | A transparent parametric baseline is appropriate. |

## Custom Techniques and Composition

`monteCarloMethod(...)` replaces the entire sampling technique behind the forecast while the engine keeps gating, lookback-window assembly, seeding, quantiles, and price mapping. A technique is a `MonteCarloMethod` receiving a `MonteCarloContext` (decision index, horizon, iteration count, historical log-return window, stable `ReturnMoments`, and a deterministic `random()`). It must draw exclusively from `context.random()` and return exactly `iterationCount` finite samples; a `null` result, a wrong sample count, or a non-finite sample degrades the forecast to unstable.

Stock techniques and composition decorators live in `org.ta4j.core.analysis.montecarlo`:

| Type | Behavior |
| --- | --- |
| `ShockPathMonteCarloMethod` | Shock/volatility engine behind the builder defaults (shock model, update mode, decay factor). |
| `NormalInverseGammaForecastMethod` | Samples horizon paths from the conjugate Normal-Inverse-Gamma posterior predictive of the lookback window; data-driven weakly-informative priors by default. |
| `PosteriorSmoothedResidualMonteCarloMethod` | Draws `(mu, sigma^2)` from the NIG posterior and re-composes kernel-smoothed residual paths over an inner technique's shocks. |
| `RecentVolatilityWideningMonteCarloMethod` | Scales an inner technique's centered samples outward by the bounded ratio of recent realized to state volatility; calm regimes stay untouched. |
| `StudentTScaleMixingMonteCarloMethod` | Fattens tails with a mean-normalized Student-t scale-mixing factor so the quantile spread grows in high-volatility regimes. |
| `EnsembleMonteCarloMethod` | Pools two techniques 50/50 through derived sub-generators. |

Composition is recursive: wrap an inner technique with any decorator and hand the result to the builder:

```java
MonteCarloMethod technique = new StudentTScaleMixingMonteCarloMethod(
        new RecentVolatilityWideningMonteCarloMethod(
                new PosteriorSmoothedResidualMonteCarloMethod(
                        new ShockPathMonteCarloMethod(
                                ShockModel.NORMAL, VolatilityUpdateMode.CONSTANT, 0.94))));
MonteCarloPriceForecastIndicator prices =
        MonteCarloPriceForecastIndicator.builder(close, state)
                .horizon(4)
                .monteCarloMethod(technique)
                .build();
```

`WalkForwardCalibrationBakeoffExample` is a paired bake-off of these techniques (12 arms) scored by central-interval coverage, pinball loss, and sample-based CRPS, sliced by forward-volatility terciles. With zero drift (below), the composition decorators close roughly half of the high-volatility under-coverage of the baseline: the winning arm `NIG-NORMAL+RECENTVOL+TTAIL` reaches 78% (S&P 500) and 79% (ETH-USD) coverage on the highest-volatility tercile against 69% and 72% for the un-widened NIG composition, at essentially unchanged CRPS.

## Explicit Analytic Approximation

Use `LognormalApproximationPriceForecastIndicator` only when you have a log-return summary but not terminal paths and explicitly accept moment matching:

```java
ReturnForecastProjectionIndicator returns = ...;
ForecastProjectionIndicator prices =
        LognormalApproximationPriceForecastIndicator
                .builder(new ClosePriceIndicator(series), returns)
                .quantiles(0.05, 0.5, 0.95)
                .build();
```

It fits one coherent lognormal distribution from source mean and standard deviation, recomputes all requested quantiles, and reports `ForecastSupport.analytic("lognormal-moment-match")`. This is not an empirical adapter and should not be presented as exact Monte Carlo output.

Use it when only moments are available and the lognormal assumption is acceptable. Do not use it when terminal samples are available, returns are not logarithmic, or tail shape is central to the decision.

## EWMA State

`EwmaReturnForecastStateIndicator` consumes a semantic `ReturnIndicator` in `ReturnRepresentation.LOG` and emits `ReturnForecastState`, which wraps canonical `ReturnMoments`.

```java
EwmaReturnForecastStateIndicator state =
        new EwmaReturnForecastStateIndicator(
                returns,
                60,
                0.97,
                EwmaReturnForecastStateIndicator.DriftMode.ZERO);
```

| Setting | Default | Effect |
| --- | --- | --- |
| `initializationBarCount` | `30` | Valid observations required before stable state. |
| `decayFactor` | `0.94` | Higher values react more slowly. |
| `driftMode` | `ZERO` | `ROLLING_MEAN` uses EWMA mean as simulated drift. |

Prefer zero drift unless a rolling drift assumption has earned its place in out-of-sample testing. The walk-forward bake-off above runs zero drift throughout and closes the high-volatility coverage gap with composition decorators rather than by switching to a rolling drift.

## Rough-Volatility State

`RoughVolatilityForecastStateIndicator` is the constructor-first rich-state path:

```java
RoughVolatilityForecastStateIndicator rough =
        new RoughVolatilityForecastStateIndicator(returns);
RoughVolatilityForecastState state = rough.getValue(index);
```

It reuses canonical EWMA moments and composes `HurstExponentIndicator` over the logarithmic volatility proxy, then applies the rough model's `[0.01, 0.49]` bound. Population dispersion of that proxy and five cumulative horizon variances complete the default state. The representation-bound `ForecastFeatureExtractors.roughVolatility()` schema exposes `[mean, volatility, roughness_hurst, vol_of_vol]` for models that intentionally use those diagnostics. See [Forecast State Estimation](Forecast-State-Estimation.md#rough-volatility-state) for advanced tuning, exact field semantics, warm-up, recovery, and when to prefer the smaller EWMA state.

## Online Change-Point State

`OnlineChangePointForecastStateIndicator` is the constructor-first regime-uncertainty path:

```java
OnlineChangePointForecastStateIndicator changePoints =
        new OnlineChangePointForecastStateIndicator(returns);
OnlineChangePointForecastState state = changePoints.getValue(index);
```

The default filter expects a 100-observation regime, retains run lengths through 252, reports five typed posterior summaries, and becomes stable after 20 consecutive valid returns. `recentChangeProbability()` aggregates complete-posterior mass over run lengths zero through five, and `recentChangeWindow()` carries that boundary with the state. It is intentionally different from `P(runLength = 0)`, which equals the constant hazard before tail truncation and can increase slightly after truncation and renormalization, but cannot respond usefully to a shift. Under canonical indexing, run length zero retains prior sufficient statistics and the current observation updates growth components.

Use `ForecastFeatureExtractors.changePoint()` for the default five-bar window or `changePoint(window)` for a window-qualified schema. Both publish `[mean, volatility, recent_change_probability, most_likely_run_length]` only when regime uncertainty and age are intentional analog dimensions. See [Forecast State Estimation](Forecast-State-Estimation.md#online-change-point-state) for prior tuning, posterior semantics, reset behavior, and failure guidance.

## Warm-Up, Recovery, and Numeric Failures

A built-in projection returns `ForecastSupport.Unavailable` with `NaN.NaN` summary values until all prerequisites are valid. It can recover at a later index after invalid inputs leave the required window.

Common unavailable causes:

- EWMA initialization or historical shock lookback is incomplete.
- Rough-volatility EWMA, roughness, or vol-of-vol windows are incomplete or contain a non-finite return.
- Online change-point valid-run warm-up is incomplete after construction, invalid input, or retained-history removal.
- State index, return representation, stability, or `ReturnMoments` metadata does not match the query.
- The price and return indicators do not share the same `BarSeries`.
- A required return, state value, or decision price is non-finite; price is non-positive.
- Factory coercion is non-finite, overflows primitive representation, or underflows a nonzero value to primitive zero.
- Any configured Monte Carlo terminal path is non-finite. The whole empirical projection is unavailable; paths are never silently dropped.
- The central fields of a lognormal approximation require an exponent magnitude above `700`. An overflowing optional tail is omitted while usable central fields remain.
- Analog history has too few fully matured neighbors, its schema differs from log-return state representation, or a feature cannot be represented as a finite primitive value.
- Rolling conformal history has fewer than the configured minimum valid scores, base forecast metadata is inconsistent, no non-median tail quantile is configured, or positive widening would contradict a zero-dispersion base summary.

Always check `isStable()` when inspecting a raw summary. Point adapters are safer for normal ta4j rule composition because unavailable values become `NaN.NaN`.

## Avoiding Look-Ahead Bias

`getValue(i)` reads only data at or before `i`; the horizon describes the future outcome, not permission to read future bars. Compare a stored forecast with its realized value only after `i + horizon` matures. Fixed seeds make repeated evaluation deterministic, and extending a series with future bars does not change an already-computed decision-index forecast.

## Choosing the API

| Need | Use | Avoid |
| --- | --- | --- |
| Exact simulated price distribution | `MonteCarloPriceForecastIndicator` | Transforming summary moments after simulation. |
| Cumulative log-return distribution | `MonteCarloReturnProjectionIndicator` | Treating returns as prices. |
| State-conditioned empirical log returns | `AnalogReturnProjectionIndicator` | Letting current features influence training standardization. |
| Abrupt regime and run-length diagnostics | `OnlineChangePointForecastStateIndicator` | Treating recent-change probability as a standalone trade signal. |
| Rolling tail calibration | `RollingConformalForecastProjectionIndicator` | Counting calibration rows as forecast support. |
| Price approximation from moments only | `LognormalApproximationPriceForecastIndicator` | Calling it empirical support. |
| Point value in a rule | `projection.median()`, `.mean()`, or `.quantile(p)` | Reimplementing unstable checks. |
| Empirical custom model output | `Forecast.ofSamples(...)` | Claiming analytic support. |
| Analytic custom model output | `Forecast.builder(...)` | Overloading `sampleCount()` with training rows. |

## Public Type Map

| Type | Package | Purpose |
| --- | --- | --- |
| `EwmaReturnForecastStateIndicator` | `forecast` | Default return-moment state estimator. |
| `RoughVolatilityForecastStateIndicator` | `forecast` | EWMA moments enriched with roughness, vol-of-vol, and cumulative horizon variance. |
| `OnlineChangePointForecastStateIndicator` | `forecast` | Bayesian run-length state with recent-change posterior mass. |
| `MonteCarloReturnProjectionIndicator` | `forecast` | Exact empirical cumulative log-return projection. |
| `AnalogReturnProjectionIndicator` | `forecast` | State-conditioned weighted empirical log-return projection. |
| `RollingConformalForecastProjectionIndicator` | `forecast` | Matured-error tail calibration that preserves base support. |
| `MonteCarloPriceForecastIndicator` | `forecast` | Exact empirical terminal-price projection. |
| `Forecast` / `ForecastSupport` | `forecast.projection` | Numeric distribution summary and provenance. |
| `ForecastProjectionIndicator` | `forecast.projection` | Horizon-aware forecast indicator with point adapters. |
| `ReturnForecastProjectionIndicator` | `forecast.projection` | Forecast projection with return semantics. |
| `LognormalApproximationPriceForecastIndicator` | `forecast.adapters` | Explicit analytic lognormal price approximation. |
| `ForecastState` / `ReturnMomentState` / `ReturnMoments` | `forecast.state` | Lifecycle and validated return-state composition. |
| `OnlineChangePointForecastState` / `RunLengthPosterior` | `forecast.state` | Immutable regime state and typed complete-posterior component summaries. |
| `ForecastFeatureSchema` / `ForecastFeatureExtractor` | `forecast.state` | Representation-bound model feature contract. |

## Related Guides

- [Forecast State Estimation](Forecast-State-Estimation.md)
- [Forecast Projection Models](Forecast-Projection-Models.md)
- [Migration and Version Compatibility](Migration-and-Version-Compatibility.md#forecast-api-correction-in-0231)
- [Indicators Inventory](Indicators-Inventory.md)
- [Walk-Forward Research](Walk-Forward-Research.md)
