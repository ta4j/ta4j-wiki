# Technical Indicators

Technical indicators (a.k.a. *technicals*) transform price/volume data into structured signals that power rules and strategies. ta4j currently ships with hundreds of indicator classes under `org.ta4j.core.indicators`, covering every major category plus building blocks for your own creations.

**Exhaustive list:** For a full inventory of all indicators in ta4j-core and ta4j-examples (fully qualified names, class names, short descriptions, and usage notes), see [Indicators Inventory](Indicators-Inventory.md).

| Category | Highlights | Docs |
| --- | --- | --- |
| Trend / Moving Averages | SMA, EMA, HMA, VIDYA, Jurik, Displaced variants, SuperTrend, Renko helpers. | [Moving Average Indicators](Moving-Average-Indicators.md) |
| Momentum & Oscillators | RSI family, NetMomentum, MACD/MACDV, MACD-V momentum states, KST, Stochastics, CMO, ROC. | This page |
| Regime & signal quality | TrendScore, TrendConclusion, Compression, EntryEdge, EdgeDecaySlope, StretchZScore. | This page |
| State estimation & robust smoothing | Kalman filtering, correntropy outlier rejection, measurement-weight and residual diagnostics. | This page |
| Advanced correlation | Kendall tau, Spearman, lagged/distance/regime-segmented correlation, mutual information. | [Indicators Inventory §11](Indicators-Inventory.md#11-statistics--numeric) |
| Forecasting | Provenance-aware Num forecasts, canonical return moments, exact Monte Carlo paths, state-conditioned analogs, rolling conformal calibration, schemas, point projections, and an explicit analytic lognormal approximation. | [Forecast Indicators](Forecast-Indicators.md), [Forecast Projection Models](Forecast-Projection-Models.md) |
| Volatility & Bands | ATR, Donchian, Bollinger, Keltner, Average True Range trailing stops. | [Bar Series & Bars](Bar-series-and-bars.md) (for ATR-based stops) |
| Volume & Breadth | OBV, VWAP/VWMA, Accumulation/Distribution, Chaikin, Force Index, Ease of Movement, Klinger Volume Oscillator. | Indicators package |
| Market Structure (VWAP/SR/Wyckoff) | Anchored VWAP, VWAP bands/z-score, price clusters, bounce counts, KDE volume profile, Wyckoff phase/cycle detection. | [VWAP, Support/Resistance, and Wyckoff Guide](VWAP-Support-Resistance-and-Wyckoff.md) |
| Bill Williams Toolkit | Alligator (jaw/teeth/lips), FractalHigh/Low, Gator Oscillator, Market Facilitation Index. | [Bill Williams Indicators](Bill-Williams-Indicators.md) |
| Candle/Pattern | CandleBody/CandleRange geometry, adaptive morphology, Hammer, Piercing Line, stars, Three Black Crows / White Soldiers. | This page |
| Price Transformations | RenkoUp/Down/X (0.19), Heikin Ashi builders, `BinaryOperationIndicator`/`UnaryOperationIndicator` transforms. | `indicators.renko` |
| Oscillators | TrueStrengthIndex, SchaffTrendCycle, ConnorsRSI (0.21.0), RSI family, MACD/MACDV, KST, Stochastics, CMO, ROC. | This page |

Browse `org.ta4j.core.indicators` in your IDE for the full list—packages mirror the table above.

## Composition example

```mermaid
graph TD
    BS[BarSeries] -->|input| CP[ClosePriceIndicator]
    CP -->|input| FAST[SMAIndicator fast 9]
    CP -->|input| SLOW[SMAIndicator slow 50]
    FAST -->|operand 1| DIV[BinaryOperationIndicator.division]
    SLOW -->|operand 2| DIV
    DIV -->|output| TB[trendBias Indicator]
```

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
SMAIndicator fast = new SMAIndicator(close, 9);
SMAIndicator slow = new SMAIndicator(close, 50);
MACDVIndicator macdv = new MACDVIndicator(series, 12, 26, 9);
NetMomentumIndicator netMomentum = new NetMomentumIndicator(series, 14);

Indicator<Num> trendBias = BinaryOperationIndicator.division(fast, slow);
Indicator<Num> blendedMomentum = BinaryOperationIndicator.add(macdv.getMacd(), netMomentum);
```

- `BinaryOperationIndicator` / `UnaryOperationIndicator` are the preferred numeric composition APIs for new code; `CombineIndicator` remains available in `org.ta4j.core.indicators.helpers`.
- Output indicators can feed directly into rules (`new OverIndicatorRule(trendBias, numOf(1.0))`) or become inputs to other indicators.

## Serialization and shorthand

Indicators can be persisted with canonical JSON:

```java
String json = rsi.toJson();
Indicator<?> restored = Indicator.fromJson(series, json);
```

The companion ta4j PR #1507, targeting 0.23.1, also lets common indicators be authored through named expressions:

```java
Indicator<?> sma = Indicator.fromExpression(series, "SMA(21)");
Indicator<?> rsiOfSma = Indicator.fromExpression(series, "RSI(SMA(14),9)");
```

See [Serialization and Named Shorthand](Serialization-and-Named-Shorthand.md) for the full preview guide to strategy, rule, indicator, and analysis-criterion serialization in that PR.

## Candlestick patterns (0.24.2 development)

What does a ta4j candlestick pattern actually tell you? In current development code, it tells you about **candle morphology**. Trend, confirmation, volume, and trading context belong to the caller unless a legacy compatibility class says otherwise.

The latest stable release is **0.24.1**; the repository currently builds **0.24.2-SNAPSHOT**. The geometry primitives and pattern semantics below are 0.24.2 development APIs and should not be copied into code that must compile against 0.24.1.

### Mental model: geometry → baseline → morphology → context

Start with measurements that have an unambiguous meaning:

| Quantity | ta4j type | Definition |
| --- | --- | --- |
| Body magnitude | `CandleBodyIndicator` | `abs(close - open)` |
| Upper shadow | `UpperShadowIndicator` | `high - max(open, close)` |
| Lower shadow | `LowerShadowIndicator` | `min(open, close) - low` |
| Full candle range | `CandleRangeIndicator` | `high - low` |

`CandleRangeIndicator` is not true range: true range also considers the previous close, while candle range uses only the current bar. These geometry indicators have no lookback warm-up themselves and produce non-negative measurements for valid OHLC data.

Patterns that need body-size, shadow-size, or “near” classifications compare geometry with a **causal baseline built from preceding candles only**. The current bar never contributes to the threshold used to classify itself. The shared default baseline is five prior candles. Pure geometry patterns such as engulfing do not invent a baseline they do not need.

| Shared classification | Current endpoint |
| --- | --- |
| Long body | `body > precedingAverageBody` |
| Short body | `body < 0.5 * precedingAverageBody` |
| Doji | `body <= rangeFactor * precedingAverageRange` (`rangeFactor = 0.1` by default) |
| Short shadow / “near” test | `measurement <= 0.1 * precedingAverageRange` |

The distinction between strict and inclusive endpoints is intentional. Long/short-body tests and pattern gaps/reversal crossings are strict; containment and penetration endpoints are inclusive. Pattern-specific Javadocs remain the authority for the complete formula. One notable exception is `ThreeBlackCrowsIndicator`: the second and third crows must open strictly inside the preceding crow's body, while the first crow's open only needs to be strictly below the preceding bar's high.

### The 60-second path: add context explicitly

A named pattern is not a complete reversal model. For example, `PiercingLineIndicator` reports two-candle morphology only. If your interpretation requires a preceding downtrend, compose that condition explicitly and make sure the trend window ends **before** the two pattern candles.

The following is a focused fragment from the tested [`NamedPatternContextExample`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/research/NamedPatternContextExample.java); use that class for the complete runnable example:

```java
Indicator<Num> close = new ClosePriceIndicator(series);
PiercingLineIndicator piercing = new PiercingLineIndicator(series);

// A two-bar shift ends both context inputs immediately before the pattern starts.
Indicator<Num> closeBeforePattern = new PreviousValueIndicator(close, 2);
Indicator<Num> averageBeforePattern =
        new PreviousValueIndicator(new SMAIndicator(close, 20), 2);

Rule priorDowntrend = new UnderIndicatorRule(closeBeforePattern, averageBeforePattern);
Rule reversalCandidate = new BooleanIndicatorRule(piercing).and(priorDowntrend);

int firstReliableIndex = series.getBeginIndex()
        + Math.max(piercing.getCountOfUnstableBars(),
                averageBeforePattern.getCountOfUnstableBars());
```

**What to notice:** the pattern does not secretly inspect ADX or trend state; shifting by the pattern width prevents the context model from learning from the candles it is supposed to contextualize; and `Rule` does **not** enforce indicator warm-up for you. Gate evaluation at or after the latest unstable boundary of every component. In the deterministic example, `firstReliableIndex` is `21`, and the final bar satisfies the piercing morphology, the prior-downtrend rule, and their conjunction.

The same separation works in the other direction: use [`CandleMorphologyExample`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/research/CandleMorphologyExample.java) when you need a deliberately custom shape assembled from body/range/shadow primitives rather than pretending it is a canonical named pattern.

### Migrating pattern code to 0.24.2

The candle-foundation work is a behavioral migration, not just a refactor. Re-check parameter meaning and surrounding context even when old code still compiles.

| Area | 0.24.2 guidance |
| --- | --- |
| Body size | `RealBodyIndicator` is deprecated. It is the legacy signed `close - open`; use `CandleBodyIndicator` for magnitude and `Bar#isBullish()` / `Bar#isBearish()` for direction. |
| Doji | Defaults to a five-candle prior **range** baseline with `rangeFactor = 0.1`. The custom constructor remains `(BarSeries, int, double)`, but the `double` now means a factor of prior average **range**, not the old factor of average body height. Source code can therefore compile while changing meaning. |
| Hammer / Hanging Man / Inverted Hammer / Shooting Star / bullish and bearish Marubozu | Ratio-style configuration has been replaced by the shared adaptive profile. Use the default constructor or the current `(series, averagePeriod)` form. |
| Engulfing | Current engulfing indicators are pure two-body containment geometry and take only `BarSeries`; old threshold/configuration tuning is gone. |
| Harami / Kicker families | Threshold/configuration tuning now uses the shared adaptive profile; use the default or current `(series, averagePeriod)` form. |
| `PiercingLineIndicator` / `DarkCloudCoverIndicator` | Default to a five-candle long-body baseline and `0.5` penetration. Custom tuning is `(series, averagePeriod, penetration)`. Their gap tests are strict and penetration endpoints inclusive. |
| Morning / Evening Star | Default to a five-candle baseline and `0.5` penetration; custom tuning is `(series, averagePeriod, penetration)`. Trend context is no longer hidden in the pattern. |
| Three Inside / Three Black Crows / Three White Soldiers | Legacy ratio/factor tuning has been replaced by the shared adaptive average-period model. Trend context is caller-owned. |
| `DarkCloudIndicator` / `PiercingIndicator` | Deprecated compatibility classes. Migrate to `DarkCloudCoverIndicator` / `PiercingLineIndicator`, but do not treat them as aliases: the old classes retain divergent formulas and embedded `UpTrendIndicator` / `DownTrendIndicator` gates. |

A `false` pattern value during warm-up means “not confirmable at this index,” not evidence for the opposite pattern. Use each indicator's `getCountOfUnstableBars()`; pattern width and baseline period both matter. For example, the current `PiercingLineIndicator` reports `averagePeriod + 1`, while `MorningStarIndicator` reports `averagePeriod + 2`.

### Data and interpretation limits

The 0.24.2 development branch tightens `BaseBar` validation so contradictory high/low values relative to open and close are rejected. If an upgrade exposes invalid bars, fix the source feed rather than weakening candlestick calculations.

A pattern name is still only a description of geometry under ta4j's documented thresholds. It is not evidence of profitability or a universal textbook definition. Compose regime, trend, volume, support/resistance, risk, or confirmation only when your hypothesis needs them, and validate the resulting strategy with realistic out-of-sample/backtest assumptions.

For a live candle that is still changing, the morphology may change until the bar closes. See [Live Candle vs Closed Candle](Live-Candle-vs-Closed-Candle-Evaluation.md) before deciding whether a strategy may act on the mutable current bar.

For exact formulas and endpoint semantics, see the current [`org.ta4j.core.indicators.candles` package documentation](https://github.com/ta4j/ta4j/blob/master/ta4j-core/src/main/java/org/ta4j/core/indicators/candles/package-info.java) and the individual pattern Javadocs.

## Robust Kalman smoothing (0.24.2 development)

Kalman filters estimate a latent current state from noisy observations. They are **same-index smoothers**, not forward forecasts: `getValue(i)` uses information available through index `i`. The latest stable release is **0.24.1**; the correntropy API below is on the **0.24.2 development branch**.

Choose the estimator by the noise problem you actually have:

| Need | Prefer | Why |
| --- | --- | --- |
| Ordinary recursive smoothing where large residuals should still influence the estimate | `KalmanFilterIndicator` | Standard linear Kalman update; simple and inexpensive. |
| Outlier-prone measurements where isolated spikes should lose influence | `CorrentropyKalmanFilterIndicator` | Maximum-correntropy update applies a redescending measurement weight and can reject extreme observations. |
| Inspect why the robust estimate ignored or accepted a measurement | `measurementWeight()` and `residual()` | Weight reports measurement acceptance in `[0, 1]`; residual reports `source - robustEstimate`. |

### The 60-second path

The complete runnable owner is [`CorrentropyKalmanExample`](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/forecast/CorrentropyKalmanExample.java). Its core composition is:

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
ATRIndicator atr = new ATRIndicator(series, 14);

NumericIndicator atrVariance = NumericIndicator.of(atr).squared();
KalmanNoiseIndicator processNoise = new KalmanNoiseIndicator(
        atrVariance.multipliedBy(0.0625).max(1e-8));
KalmanNoiseIndicator measurementNoise = new KalmanNoiseIndicator(
        atrVariance.multipliedBy(0.25).max(1e-8));

CorrentropyKalmanFilterIndicator robust =
        new CorrentropyKalmanFilterIndicator(
                close,
                processNoise,
                measurementNoise,
                series.numFactory().numOf(2.0));

CorrentropyKalmanWeightIndicator weight = robust.measurementWeight();
Indicator<Num> residual = robust.residual();
```

Those ATR coefficients are an **illustrative recipe from the compiled example, not calibrated defaults**. Real deployments should derive process variance `Q` and measurement variance `R` from the source's own scale and validate them against a benchmark.

### Read the parameters in the right units

`Q` and `R` are **variances**, so for a price source they are in price-squared units. `KalmanNoiseIndicator` enforces finite, strictly positive values; it does not make an arbitrary positive indicator a meaningful variance estimate.

The correntropy kernel bandwidth `sigma` is different: it is **dimensionless**. The filter whitens the state and measurement errors by their covariance scales before applying the Gaussian kernel. A bandwidth such as `2.0` therefore means “two standardized error units,” not two dollars or two percent. Smaller bandwidths reject departures more aggressively; larger bandwidths behave more like the ordinary Kalman update. Treat bandwidth as a robustness parameter to validate, not a universal magic number.

### Weight is evidence, not probability

`robust.measurementWeight()` exposes the measurement-side kernel weight at the accepted fixed-point solution. A value near `1` means the observation was broadly consistent with the accepted state; `0` means the measurement was rejected by the redescending kernel. It is not a calibrated probability that the observation is correct.

`robust.residual()` returns `measurement - robustEstimate`. Composing residual magnitude with the weight can help distinguish ordinary tracking error from observations the robust filter actively discounted. The example demonstrates this as diagnostic evidence only, not as a trading strategy.

### Warm-up, failures, and recovery

The robust filter's unstable-bar count is the maximum of its source, `Q`, and `R` inputs. Respect `getCountOfUnstableBars()` before consuming the estimate or its diagnostics.

A non-finite source value, non-finite or non-positive `Q`/`R`, a non-converging fixed-point update, or an invalid numerical state makes the estimate, weight, and residual unavailable (`NaN`) **for that index**. The filter preserves its last initialized valid state internally, so a later valid index can recover instead of permanently poisoning the recursion.

There is one important redescending-kernel caveat: during a sustained extreme move, repeated near-zero measurement weights can keep the estimate pinned near its last trusted level. That zero-gain persistence is expected behavior, not proof that the market price is “wrong.” If the source has genuinely changed regimes, an overly aggressive bandwidth or noise model can reject the new level for too long.

### How to evaluate it

Compare the classic and correntropy filters on the same source and the same economically meaningful `Q`/`R` model. Inspect estimate error, residuals, measurement weights, and recovery after isolated outliers **and** sustained shifts. A robust smoother has earned its complexity only if those diagnostics and downstream out-of-sample results improve for the actual data regime.

## Market structure workflow (VWAP + S/R + Wyckoff)

ta4j now includes a complete workflow for value, location, and phase analysis:

- Value: `VWAPIndicator`, `AnchoredVWAPIndicator`, `VWAPBandIndicator`, `VWAPZScoreIndicator`
- Location: `PriceClusterSupportIndicator`, `PriceClusterResistanceIndicator`, `BounceCountSupportIndicator`, `BounceCountResistanceIndicator`, `VolumeProfileKDEIndicator`
- Phase: `WyckoffPhaseIndicator`
- Cycle context: `WyckoffCycleFacade`, `WyckoffCycleAnalysisRunner`, `WyckoffEventDetector`

Use the dedicated guide for implementation templates and tuning advice:

- [VWAP, Support/Resistance, and Wyckoff Guide](VWAP-Support-Resistance-and-Wyckoff.md)

For Donchian channels, `DonchianChannelFacade` provides fluent `lower()/upper()/middle()` numeric indicators from one constructor call; see [Indicators Inventory](Indicators-Inventory.md) for class-level details.

## Bill Williams workflow (0.22.3)

ta4j 0.22.3 added a complete Bill Williams toolkit:

- Trend context: `AlligatorIndicator` (jaw/teeth/lips with canonical 13/8, 8/5, 5/3 settings)
- Breakout structure: `FractalHighIndicator`, `FractalLowIndicator` (`2/2` windows by default)
- Momentum/participation confirmation: `GatorOscillatorIndicator`, `MarketFacilitationIndexIndicator`

Fractal indicators confirm on the current bar; use `getConfirmedFractalIndex(...)` to reference the pivot bar without introducing look-ahead bias.

## Volume pressure workflow (0.22.4)

ta4j's volume package includes price/volume pressure oscillators that complement OBV, A/D, MFI, and VWAP:

- `ForceIndexIndicator` multiplies close-to-close price change by volume and smooths the result with EMA (default `13`).
- `EaseOfMovementIndicator` measures how easily price moves through the bar range relative to volume and smooths the one-period EMV with SMA (default `14`, default volume divisor `100,000,000`).
- `KlingerVolumeOscillatorIndicator` applies the Klinger volume-force formula and returns the short/long EMA spread (default `34/55`).

Use them as participation or divergence filters; avoid treating them as standalone entries when volume quality is poor.

## Regime and signal-quality workflow (0.22.7)

ta4j 0.22.7 adds composite regime and edge-scoring indicators for strategy gating:

- **Trend pressure:** `TrendScoreIndicator` (−100 to +100) combines EMA alignment, MACD histogram state, and signed ADX strength/change.
- **Trend cooldown:** `TrendConclusionIndicator` (0–100) estimates whether a prior trend has likely cooled (ADX fade, MACD mean reversion, price recenter, compression).
- **Contraction:** `CompressionIndicator` (0–100) scores tightening regimes from inverted ATR, Bollinger width, and Donchian width percentile ranks.
- **Signal edge:** `EntryEdgeIndicator` reports realized entry edge in basis points using only matured forward returns (no look-ahead).
- **Edge trajectory:** `EdgeDecaySlopeIndicator` tracks whether edge is improving or decaying over a lookback window.
- **Stretch:** `StretchZScoreIndicator` normalizes deviation between any source/reference pair (close vs SMA, price vs VWAP, etc.).

Pair edge indicators with `EdgeHealthyRule` and loss hygiene with `LossTriggeredCooldownRule` (see [Trading Strategies](Trading-strategies.md) and [Stop Loss & Stop Gain Rules](Stop-Loss-and-Stop-Gain-Rules.md)).

## Forecast workflow (0.23.1)

The 0.23.1 foundation deliberately corrects the forecast API first released in 0.23.0. See the migration guide before upgrading forecast code.

ta4j's forecast package adds prediction-valued indicators for forward-looking research and strategy filters:

- `LogReturnIndicator` creates reusable log-return inputs from close prices or any numeric source indicator.
- `ReturnIndicator` marks indicators that semantically produce returns in a declared representation.
- `EWMAIndicator` provides reusable explicit-decay smoothing for forecast and non-forecast workflows.
- `EwmaReturnForecastStateIndicator` estimates canonical `ReturnMoments` from a log-return `ReturnIndicator`.
- `RoughVolatilityForecastStateIndicator` composes those moments with bounded log-variogram roughness, log-volatility vol-of-vol, and cumulative horizon variance diagnostics.
- `OnlineChangePointForecastStateIndicator` composes MAP regime moments with deterministic Bayesian run-length summaries and recent-change posterior mass.
- `MonteCarloPriceForecastIndicator` transforms every simulated terminal return path before calculating exact empirical price summaries.
- `MonteCarloReturnProjectionIndicator` simulates cumulative log-return distributions for return-space workflows or advanced tuning.
- `LognormalApproximationPriceForecastIndicator` explicitly fits a coherent analytic lognormal distribution when terminal samples are unavailable.
- `ForecastProjectionIndicator` declares `getHorizon()` and exposes point projections for normal ta4j rule composition.
- `ForecastSupport` distinguishes unavailable, empirical-count, and named analytic output.
- `ForecastFeatureSchema` binds primitive feature names, units, version, order, and return representation.
- `ForecastFeatureExtractors.roughVolatility()` publishes the fixed `[mean, volatility, roughness_hurst, vol_of_vol]` shape for intentional rich-state model composition.
- `ForecastFeatureExtractors.changePoint()` publishes the default five-bar `[mean, volatility, recent_change_probability, most_likely_run_length]` shape; `changePoint(window)` binds custom aggregation windows into the schema identity.

Forecast indicators do not read future bars while producing `getValue(i)`. Use the configured horizon only when evaluating the forecast against later realized outcomes. See [Forecast Indicators](Forecast-Indicators.md) for setup, tuning, warm-up behavior, and strategy examples.

## Advanced correlation workflow (0.22.7)

Beyond Pearson/`CorrelationCoefficientIndicator`, ta4j now ships:

- `KendallTauIndicator` and `SpearmanRankCorrelationIndicator` for rank-based association.
- `LaggedCorrelationIndicator` for lead/lag analysis between two series.
- `DistanceCorrelationIndicator` for non-linear dependence (prefer modest windows; O(n²) per index).
- `MutualInformationIndicator` for binned mutual information (interpret as discretized MI for the configured bin count).
- `RegimeSegmentedCorrelationIndicator` for Pearson correlation over bars where a Boolean regime is active.

Use `SampleType` and `getCountOfUnstableBars()` when mixing rolling statistics with strategy warm-up.

## MACD-V momentum-state workflow (0.22.3)

Prefer `org.ta4j.core.indicators.macd.MACDVIndicator` for new code. The legacy `org.ta4j.core.indicators.MACDVIndicator` is deprecated and scheduled for removal in 0.24.0.

- `MACDVIndicator` in ta4j is the volume/ATR-weighted EMA-spread variant (ATR is used inside the weighting term).
- `VolatilityNormalizedMACDIndicator` is the volatility-normalized form (EMA spread divided by ATR and scaled), often referred to as the Spiroglou-style MACD-V formulation.
- They are related but not interchangeable; thresholds and interpretation can differ materially between the two.
- Use `getSignalLine(...)`, `getHistogram(...)`, and `getLineValues(...)` to expose all MACD-V lines.
- Classify MACD-V regime with `MACDVMomentumStateIndicator` and `MACDVMomentumProfile` (default thresholds: `+50/+150/-50/-150`).
- Attach state-aware rules with `inMomentumState(...)` or `MomentumStateRule`.

## Backtesting indicators

Indicators should be evaluated the same way strategies are—prefer realistic data with survivorship-bias filters. The [Usage Examples](Usage-examples.md) page links to CSV/Chart demos where indicators are plotted alongside price bars.

## Caching & stability

- Every indicator extends `CachedIndicator`, so once a value is computed (except for the most recent bar) it is reused.
- Mutating the latest bar (common with streaming data) invalidates just that slot; the rest stays cached.
- Compare the current index with `indicator.getCountOfUnstableBars()` before trusting early values, or pass that number to `strategy.setUnstableBars(...)`.
- When using moving `BarSeries` via `setMaximumBarCount`, cached entries older than the oldest remaining bar disappear. Always guard against `NaN` if you try to access evicted indexes.

## Creating custom indicators

Sub-class `CachedIndicator<Num>` or compose existing indicators with operations. Guidelines:

- Accept dependencies via constructor injections (`Indicator<Num> base`) rather than pulling directly from a `BarSeries`.
- Respect the `Num` abstraction: use `Num` arithmetic (`plus`, `minus`, etc.) and produce values via the series `NumFactory`.
- Override `getCountOfUnstableBars()` when your indicator requires warm-up bars (e.g., multi-stage EMAs).
- If you need state across indices, store it in the indicator (ta4j handles thread safety by design if you limit state to the calculation path).

## Tips

- Normalize values when mixing indicators with different ranges (e.g., convert RSI to 0–1 before feeding it into a vote rule with MACD).
- When working with unconventional chart types (Renko, Heikin Ashi), prefer the dedicated builders/indicators shipped in 0.18/0.19/0.21.0—they keep the math consistent across strategies.
- Combine price- and volume-driven indicators to reduce false positives (e.g., `new AndIndicatorRule(new OverIndicatorRule(macdv, zero), new OverIndicatorRule(vwma, close))`).
- Document indicator usage inside strategies so others know the intent—especially if the indicator is non-standard or parameter-sensitive.
### Visualizing indicators

You can visualize indicators on charts using the [ChartBuilder API](Charting.md). Indicators can be displayed as overlays on price charts or as separate sub-charts:

```java
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
SMAIndicator sma = new SMAIndicator(closePrice, 50);

ChartWorkflow chartWorkflow = new ChartWorkflow();
chartWorkflow.builder()
    .withSeries(series)
    .withIndicatorOverlay(sma)
    .withLineColor(Color.ORANGE)
    .display();
```

### Caching mechanism

Some indicators need recursive calls and/or values from the previous bars in order to calculate their last value. For that reason, a caching mechanism has been implemented for all the indicators provided by ta4j. This system avoids calculating the same value twice. Therefore, if a value has been already calculated it is retrieved from cache the next time it is requested. **Values for the last Bar will not be cached**. This allows you to modify the last bar of the BarSeries by adding price/trades to it and to recalculate results with indicators.

**Warning!** If a maximum bar count has been set for the related bar Series, then the results calculated for evicted bars are evicted too. They also cannot be recomputed since the related bars have been removed. That being said, moving bar Series should not be used when you need to access long-term past bars.
