# Forecast Indicators

Forecast indicators estimate a future return or price distribution from data available at a decision index. They are useful when a strategy needs a probabilistic outlook instead of a single backward-looking technical signal.

The forecast API lives mostly in `org.ta4j.core.indicators.forecast`. `LogReturnIndicator` is a normal helper indicator in `org.ta4j.core.indicators.helpers`, `EWMAIndicator` is a reusable average in `org.ta4j.core.indicators.averages`, and forecast summaries use the walk-forward prediction model via `PredictionSnapshot.Forecast`.

## When to use them

Use forecast indicators when you want to answer questions such as:

- What is the median expected close price five bars from now?
- What are the 5th and 95th percentile price outcomes for the next session?
- Is the forecast summary wide enough that a signal should be ignored?
- How does a signal perform when evaluated against a fixed future horizon?

Do not treat a forecast as a guaranteed target. A forecast is an input to risk management, strategy rules, sizing, and research. It should still be validated with realistic execution assumptions and out-of-sample tests.

## Quick Start: Price Forecast

This example builds an EWMA-volatility Monte Carlo pipeline and projects forecast prices, not returns.

```java
import org.ta4j.core.BarSeries;
import org.ta4j.core.Indicator;
import org.ta4j.core.indicators.forecast.ForecastPredictionIndicator;
import org.ta4j.core.indicators.forecast.ForecastStateIndicator;
import org.ta4j.core.indicators.forecast.LogReturnToPriceForecastIndicator;
import org.ta4j.core.indicators.forecast.MonteCarloReturnForecastIndicator;
import org.ta4j.core.indicators.helpers.ClosePriceIndicator;
import org.ta4j.core.indicators.helpers.LogReturnIndicator;
import org.ta4j.core.num.Num;

BarSeries series = ...;
ClosePriceIndicator close = new ClosePriceIndicator(series);
LogReturnIndicator returns = new LogReturnIndicator(close);

ForecastStateIndicator state = ForecastStateIndicator.ofEwma(
        returns,
        30,
        0.94,
        ForecastStateIndicator.DriftMode.ZERO);

ForecastPredictionIndicator returnForecast =
        MonteCarloReturnForecastIndicator.builder(returns, state)
                .horizon(5)
                .iterationCount(2_000)
                .lookbackBarCount(252)
                .seed(42L)
                .shockModel(MonteCarloReturnForecastIndicator.ShockModel.STANDARDIZED_EMPIRICAL)
                .volatilityUpdateMode(MonteCarloReturnForecastIndicator.VolatilityUpdateMode.CONSTANT)
                .quantiles(0.05, 0.5, 0.95)
                .build();

ForecastPredictionIndicator priceForecast =
        new LogReturnToPriceForecastIndicator(close, returnForecast);

Indicator<Num> downsideForecast = priceForecast.quantile(0.05);
Indicator<Num> medianForecast = priceForecast.median();
Indicator<Num> upsideForecast = priceForecast.quantile(0.95);

int index = series.getEndIndex();
Num downside = downsideForecast.getValue(index);
Num median = medianForecast.getValue(index);
Num upside = upsideForecast.getValue(index);
```

Use `ForecastPredictionIndicator` projection methods for strategy rules, chart overlays, and other ta4j data flows. Each projection shifts the index lookup onto a normal `Indicator<Num>` and returns `NaN` while the source forecast is unstable.

The raw `PredictionSnapshot.Forecast<Num>` summary remains useful for diagnostics and metadata. At each index, it contains:

- `decisionIndex()` / `index()`: the decision index where the forecast was made.
- `horizon()`: the configured number of bars ahead.
- `sampleCount()`: the number of simulated samples summarized.
- `isStable()`: whether the forecast is usable at this decision index.
- `mean()`, `median()`, `standardDeviation()`: summary values.
- `quantiles()`: configured quantile probabilities to values.
- `quantile(probability)`: one configured quantile value.

Only request quantile projections that were configured on `MonteCarloReturnForecastIndicator.Builder`. For example, `priceForecast.quantile(0.05)` returns useful values only if `0.05` was included in `quantiles(...)`.

## Point Projection Indicators

Many rules and indicators need one `Num` value per index. `ForecastPredictionIndicator` exposes projection methods that return normal `Indicator<Num>` instances.

```java
import org.ta4j.core.Indicator;
import org.ta4j.core.Rule;
import org.ta4j.core.num.Num;
import org.ta4j.core.rules.OverIndicatorRule;

Indicator<Num> medianForecast = priceForecast.median();
Indicator<Num> downsideForecast = priceForecast.quantile(0.05);
Indicator<Num> forecastWidth = priceForecast.standardDeviation();

Rule forecastAboveCurrentPrice = new OverIndicatorRule(medianForecast, close);
```

Projection indicators return `NaN` when the source forecast is unstable or when the requested quantile is missing. That makes projected forecasts safe to compose with normal ta4j rules and indicators, including `UnaryOperationIndicator` and `BinaryOperationIndicator`.

## Pipeline

```mermaid
graph TD
    CP["ClosePriceIndicator or another price Indicator<Num>"] --> LR["LogReturnIndicator"]
    LR --> STATE["ForecastStateIndicator.ofEwma(...)"]
    LR --> MC["MonteCarloReturnForecastIndicator.builder(...).build()"]
    STATE --> MC
    MC --> PRICE["LogReturnToPriceForecastIndicator"]
    PRICE --> PROJECT["median(), quantile(), mean(), standardDeviation()"]
```

Use this explicit pipeline when you need direct access to return forecasts, a custom price source, custom point projections, or intermediate state diagnostics. The API intentionally avoids a god factory so each stage remains reusable and testable.

`MonteCarloReturnForecastIndicator` produces a cumulative log-return forecast over the configured horizon. `LogReturnToPriceForecastIndicator` converts it to a price forecast with:

```text
forecastPrice = priceAtDecisionIndex * exp(cumulativeLogReturn)
```

## Configuration Guide

### EWMA State

`ForecastStateIndicator.ofEwma(...)` estimates rolling return state from a log-return source.

| Parameter | Default in examples | Meaning | Common tuning |
| --- | --- | --- | --- |
| `initializationBarCount` | `30` | Number of valid return observations required before state is stable. | Increase for slower, steadier estimates; decrease for faster adaptation. |
| `decayFactor` | `0.94` | EWMA persistence in `(0, 1)`. Higher values react more slowly. | Use higher values for daily data and lower values for shorter bars only after validation. |
| `driftMode` | `ForecastStateIndicator.DriftMode.ZERO` | Drift used in simulated paths. | Prefer `ZERO` as a conservative default; use `ROLLING_MEAN` only when the rolling mean has validated predictive value. |

The state output is a `ReturnForecastState` with rolling `mean`, forecast `drift`, `variance`, and `volatility`.

### Monte Carlo Forecast

`MonteCarloReturnForecastIndicator.builder(...)` controls horizon, samples, shock model, and returned quantiles.

| Builder method | Default | Meaning | Common tuning |
| --- | --- | --- | --- |
| `horizon(...)` | `1` | Number of bars ahead to forecast. | Match the holding period or evaluation label. |
| `iterationCount(...)` | `1_000` | Number of simulated paths. | Increase for smoother quantiles; reduce only for latency-sensitive live loops after measuring. |
| `lookbackBarCount(...)` | `252` | Number of historical returns used for empirical shocks. | Match the market regime window you want represented. |
| `seed(...)` | `42L` | Base random seed. | Keep fixed for reproducible research and tests. |
| `shockModel(...)` | `STANDARDIZED_EMPIRICAL` | Source of simulated return shocks. | See the shock model table below. |
| `volatilityUpdateMode(...)` | `CONSTANT` | Volatility behavior inside each simulated path. | Use `EWMA` only when path-dependent volatility is part of the model assumption. |
| `volatilityDecayFactor(...)` | `0.94` | EWMA decay used when volatility updates are enabled. | Usually match the state decay factor. |
| `quantiles(...)` | `0.05, 0.25, 0.5, 0.75, 0.95` | Forecast percentiles to include. | Configure only the percentiles your strategy or report consumes. |

### Shock Models

| Shock model | Behavior | Use when |
| --- | --- | --- |
| `MonteCarloReturnForecastIndicator.ShockModel.HISTORICAL_BOOTSTRAP` | Samples raw historical returns from the lookback window. | You want the recent empirical return distribution without rescaling by current volatility. |
| `MonteCarloReturnForecastIndicator.ShockModel.STANDARDIZED_EMPIRICAL` | Samples standardized residuals and scales them by the current EWMA state. | You want empirical tail shape with current volatility and drift. This is the default. |
| `MonteCarloReturnForecastIndicator.ShockModel.NORMAL` | Draws standard normal shocks and scales them by the current EWMA state. | You want a simple parametric baseline and accept thinner tails than many markets show. |

### Volatility Update Modes

| Mode | Behavior | Tradeoff |
| --- | --- | --- |
| `MonteCarloReturnForecastIndicator.VolatilityUpdateMode.CONSTANT` | Uses the decision-index volatility for every simulated step in a path. | Simple, reproducible, and usually the first model to validate. |
| `MonteCarloReturnForecastIndicator.VolatilityUpdateMode.EWMA` | Updates path volatility after each simulated step using `volatilityDecayFactor`. | More dynamic, but adds another assumption that must be tested. |

## Warm-Up and Unstable Values

Forecast indicators deliberately return unstable summaries until enough valid data is available.

Important warm-up rules:

- `LogReturnIndicator` is unstable for `source.getCountOfUnstableBars() + barCount` bars.
- `EWMAIndicator` is unstable for `source.getCountOfUnstableBars() + barCount - 1` bars.
- `ForecastStateIndicator.ofEwma(...)` is unstable until its EWMA mean and variance sources are stable.
- `MonteCarloReturnForecastIndicator` is unstable until both the state is stable and the configured return lookback is available.
- With the default one-bar log return and default `lookbackBarCount(252)`, the standard Monte Carlo return forecast first becomes eligible at index `252` when all returns are valid.

Unstable values can also occur after warm-up when:

- A source price is zero, negative, `NaN`, or infinite.
- A return in the required initialization window is invalid.
- The historical lookback does not contain enough valid returns.
- A price forecast cannot be converted because the decision-index price is invalid or non-positive.

Prefer projection indicators for rule and indicator composition. If you intentionally inspect raw `PredictionSnapshot.Forecast` summaries in reporting or diagnostics, check `isStable()` before reading summary values. Projection indicators return `NaN` for unstable summaries, which normal ta4j rules will treat as not satisfying comparisons.

## Avoiding Look-Ahead Bias

Forecast indicators are designed to produce `getValue(i)` using only source data available at or before index `i`. The forecast horizon describes what the summary is about; it does not allow the indicator to read future bars.

For research:

- Generate the forecast at decision index `i`.
- Compare it later with the realized value at `i + horizon`.
- Do not feed realized future returns back into the strategy rule at `i`.
- Match `horizon` to the execution and holding-period assumption you are testing.

For live trading:

- Evaluate the forecast only after the decision bar contains the data your execution model assumes.
- Prefer next-open or broker-confirmed execution unless your system truly can act on the current close.
- Keep the moving `BarSeries` large enough to retain the return lookback plus warm-up margin.

## Practical Strategy Patterns

### Median Direction Filter

Use the median point forecast as a directional filter:

```java
Indicator<Num> medianForecast = priceForecast.median();

Rule bullishForecast = new OverIndicatorRule(medianForecast, close);
```

This is intentionally minimal. In real strategies, add costs, slippage, and a required edge threshold so tiny forecast differences do not trigger trades.

### Downside Risk Filter

Use a low quantile to avoid entries when the downside tail is too close.

```java
Indicator<Num> fifthPercentilePrice =
        priceForecast.quantile(0.05);

Rule downsideAboveStop = new OverIndicatorRule(fifthPercentilePrice, plannedStopPrice);
```

`plannedStopPrice` can be any `Indicator<Num>` on the same series, such as an ATR stop, support indicator, or fixed threshold indicator.

### Forecast Width Filter

Use `priceForecast.standardDeviation()` when you want to avoid forecasts that are too uncertain, or require enough spread for a volatility strategy. The result is in the same unit as the forecast summary: log-return units for return forecasts and price units for price forecasts.

## Choosing Return or Price Space

Use return forecasts when:

- You are comparing forecasts across instruments with different price levels.
- You want cumulative log-return quantiles for research labels.
- You are building position sizing or risk logic in return space.

Use price forecasts when:

- Strategy rules compare the forecast to current price, stops, targets, support, resistance, or chart overlays.
- You want report output in user-facing price units.

`LogReturnToPriceForecastIndicator` is the bridge between the two.

## Reproducibility Notes

The Monte Carlo indicator mixes the configured seed with the decision index and horizon. That means the same seed, index, horizon, inputs, and configuration produce the same forecast independent of call order. This is important for cached indicators, tests, and chart rendering.

Do not rely on a seed to make an invalid forecast stable. Reproducibility only applies once the data and warm-up requirements are satisfied.

## Common Problems

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Projection values are `NaN` early in the series. | Warm-up and lookback requirements are not met. | Start reading after `forecast.getCountOfUnstableBars()`. |
| Quantile projection is `NaN` at a stable index. | The probability was not included in `quantiles(...)`. | Add that exact probability to `MonteCarloReturnForecastIndicator.builder(...).quantiles(...)`. |
| Point forecast is `NaN`. | The source forecast is unstable, the projection requested a missing quantile, or source data is invalid. | Check warm-up, configured quantiles, and source price/return validity. |
| Price forecast is unstable while return forecast is stable. | Decision-index price is non-positive or invalid. | Check the source price indicator and data feed. |
| Live forecasts disappear with a moving series. | The series evicted bars required by the lookback. | Increase `setMaximumBarCount` or reduce lookback after validation. |

## API Map

| Type | Package | Purpose |
| --- | --- | --- |
| `LogReturnIndicator` | `org.ta4j.core.indicators.helpers` | Normal numeric helper indicator for `log(x[i] / x[i - n])`. |
| `EWMAIndicator` | `org.ta4j.core.indicators.averages` | Reusable EWMA indicator with explicit decay and SMA initialization. |
| `ForecastStateIndicator` | `org.ta4j.core.indicators.forecast` | Converts mean and variance indicators into `ReturnForecastState`, with `ofEwma(...)` for the standard state pipeline. |
| `ForecastStateIndicator.DriftMode` | `org.ta4j.core.indicators.forecast` | Nested enum selecting zero drift or rolling-mean drift. |
| `ReturnForecastState` | `org.ta4j.core.indicators.forecast` | State record consumed by return forecast indicators. |
| `MonteCarloReturnForecastIndicator` | `org.ta4j.core.indicators.forecast` | Cumulative log-return forecast indicator with builder-owned configuration. |
| `MonteCarloReturnForecastIndicator.ShockModel` | `org.ta4j.core.indicators.forecast` | Nested enum selecting historical bootstrap, standardized empirical, or normal shocks. |
| `MonteCarloReturnForecastIndicator.VolatilityUpdateMode` | `org.ta4j.core.indicators.forecast` | Nested enum selecting constant or EWMA path volatility. |
| `ForecastPredictionIndicator` | `org.ta4j.core.indicators.forecast` | Indicator interface for forecast summaries with point projection methods. |
| `LogReturnToPriceForecastIndicator` | `org.ta4j.core.indicators.forecast` | Converts cumulative log-return forecasts to price forecasts. |
| `ForwardForecastIndicator` | `org.ta4j.core.indicators.forecast` | Adapter used by point projection methods to expose one `Num` forecast. |
| `PredictionSnapshot.Forecast` | `org.ta4j.core.walkforward` | Walk-forward prediction summary type used by forecast indicators. |
