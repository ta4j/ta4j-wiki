# Technical Indicators

Indicators process a `BarSeries` and produce values (`Num`, `Boolean`, or custom structures) for each bar index. They are the building blocks of trading rules, visual overlays, and analysis reports.

For a complete class-by-class lookup across core and examples, see [Indicators Inventory](Indicators-Inventory.md).

---

## Core Indicator Interface

All indicators implement `Indicator<T>`:

```java
public interface Indicator<T> {
    BarSeries getBarSeries();
    T getValue(int index);
    int getCountOfUnstableBars();
}
```

- **`getValue(int index)`** returns the calculated value for the given bar index.
- **`getBarSeries()`** links the indicator to its underlying data.
- **`getCountOfUnstableBars()`** reports the warm-up window required before output stabilizes.

---

## Indicator Hierarchy

```
Indicator<T>
  └── AbstractIndicator<T>
        ├── CachedIndicator<T>
        │     └── RecursiveCachedIndicator<T>
        └── Helper / Uncached Indicators
```

### `AbstractIndicator<T>`
Base class storing the `BarSeries` reference. Most custom indicators extend `CachedIndicator` or `RecursiveCachedIndicator` rather than `AbstractIndicator` directly.

### `CachedIndicator<T>`
Caches calculated values per bar index using thread-safe internal locking (`ReentrantReadWriteLock`). On bounded moving series, caches handle head advances safely while preserving un-evicted history.

### `RecursiveCachedIndicator<T>`
Extends `CachedIndicator` for indicators whose value at index `i` depends on index `i - 1` (e.g., EMA, RSI, ATR, Kalman filters). Computes missing lookback values iteratively under a single write lock to avoid stack overflow on deep history.

---

## Moving Average Family

Moving averages live under `org.ta4j.core.indicators.averages`:

| Indicator | Class | Key Characteristics |
|---|---|---|
| **SMA** | `SMAIndicator` | Equal-weight moving average over $N$ bars |
| **EMA** | `EMAIndicator` | Exponential weighting ($2 / (N + 1)$ multiplier); continues across head advances on moving series |
| **MMA / Wilder** | `MMAIndicator`, `WildersMAIndicator` | Modified moving average ($1 / N$ smoothing) for RSI, ADX |
| **WMA / LWMA** | `WMAIndicator`, `LWMAIndicator` | Linear-weighted moving average |
| **VWMA** | `VWMAIndicator` | Volume-weighted moving average |
| **HMA** | `HMAIndicator` | Hull moving average — significantly reduces lag |
| **KAMA** | `KAMAIndicator` | Kaufman adaptive MA — adjusts weight based on efficiency ratio |
| **VIDYA** | `VIDYAIndicator` | Chande variable-index dynamic MA — adjusts by CMO volatility |
| **ZLEMA** | `ZLEMAIndicator` | Zero-lag EMA |
| **LSMA** | `LSMAIndicator` | Least-squares moving average (linear regression endpoint) |

See [Moving Average Indicators](Moving-Average-Indicators.md) for detailed mathematical formulas and code examples.

---

## Volatility & Channel Indicators

- **`ATRIndicator`**: Average True Range (MMA of True Range).
- **Bollinger Bands** (`BollingerBandsMiddleIndicator`, `BollingerBandsUpperIndicator`, `BollingerBandsLowerIndicator`, `BollingerBandWidthIndicator`, `PercentBIndicator`): Standard deviation channels.
- **Keltner Channels** (`KeltnerChannelMiddleIndicator`, `KeltnerChannelUpperIndicator`, `KeltnerChannelLowerIndicator`): ATR-based channels.
- **Donchian Channels** (`DonchianChannelUpperIndicator`, `DonchianChannelLowerIndicator`, `DonchianChannelMiddleIndicator`, `DonchianChannelFacade`): $N$-bar high/low channels.
- **`ChopIndicator`**: Choppiness index (defaults to percentage 0–100; supports 0–1 decimal output).
- **`SqueezeProIndicator`**: Bollinger-vs-Keltner compression tiers and LazyBear detrended-price momentum.
- **`CompressionIndicator`**: Composite contraction score (0–100) from ATR, Bollinger width, and Donchian width percentile ranks.

---

## Momentum & Oscillators

- **`RSIIndicator`**: Relative Strength Index with robust NaN handling during warm-up.
- **`StochasticIndicator` / `StochasticOscillatorKIndicator` / `StochasticOscillatorDIndicator`**: Fast/Slow Stochastic.
- **`MACDIndicator`**: Moving Average Convergence Divergence ($EMA_{fast} - EMA_{slow}$).
- **`VolatilityNormalizedMACDIndicator`**: Volatility-normalized MACD-V ($(EMA_{fast} - EMA_{slow}) / ATR$).
- **`CorrentropyKalmanFilterIndicator`**: Maximum-correntropy-criterion (MCC) robust Kalman filter that downweights or rejects extreme measurement outliers.
- **`CusumIndicator` & `EwmaVarianceIndicator`**: Statistical process control indicators for drift detection and dynamic control limits.
- **`CCIIndicator`**, **`WilliamsRIndicator`**, **`AwesomeOscillatorIndicator`**, **`ConnorsRSIIndicator`**, **`SchaffTrendCycleIndicator`**: Standard momentum suite.

---

## Relationship, Lead/Lag & Event Dependence

- **`LeadLagCorrelationIndicator`**: Scans an inclusive lag range to identify leading/lagging relationships between series.
- **`DynamicTimeWarpingDistanceIndicator`**: Bounded dynamic time warping (DTW) shape distance with z-score normalization and Sakoe–Chiba band constraints.
- **`EventSynchronizationIndicator`**: Rolling F1 score for matching two sparse Boolean event streams within asymmetric tolerances.
- **`EventMutualInformationEvaluator`**: Non-rolling evaluator measuring predictor information about target events in future bar windows.

See [Correlation, Lead-Lag & Event Dependence](Correlation-Lead-Lag-Event-Analysis.md) for full usage patterns.

---

## Candlestick Foundation

Candlestick pattern indicators live under `org.ta4j.core.indicators.candles`:

- **Primitives**: `CandleBodyIndicator` ($|close - open|$), `CandleRangeIndicator` ($high - low$), `UpperShadowIndicator`, `LowerShadowIndicator`.
- **Single-bar**: `DojiIndicator`, `HammerIndicator`, `HangingManIndicator`, `InvertedHammerIndicator`, `ShootingStarIndicator`, `BullishMarubozuIndicator`, `BearishMarubozuIndicator`.
- **Multi-bar**: `BullishEngulfingIndicator`, `BearishEngulfingIndicator`, `BullishHaramiIndicator`, `BearishHaramiIndicator`, `MorningStarIndicator`, `EveningStarIndicator`, `PiercingLineIndicator`, `DarkCloudCoverIndicator`, `ThreeWhiteSoldiersIndicator`, `ThreeBlackCrowsIndicator`.

Pattern indicators share a cached adaptive body/shadow sizing model based on recent average range.

---

## Moving Series & Head Advances

When using bounded series (`setMaximumBarCount`), bar eviction advances the series `beginIndex`. In ta4j:

- **EMA-family indicators** (`EMAIndicator`, `ATRIndicator`, `SMMAIndicator`, `WildersMAIndicator`) continue recurrences across head advances without re-seeding at every step.
- **Swing detectors** (`ElliottSwingIndicator`, `FractalSwingDetector`) reconcile retained bars and discard invalid historical pivots when head advances occur.
- **Indicators with cumulative state** clear stale cache entries cleanly upon head advance.

---

## Fluent Indicator Chaining with `NumericIndicator`

`NumericIndicator` allows fluent mathematical composition without creating explicit custom classes:

```java
NumericIndicator close = NumericIndicator.of(new ClosePriceIndicator(series));
NumericIndicator sma20 = NumericIndicator.of(new SMAIndicator(close, 20));

// Fluent combination
Indicator<Num> spread = close.minus(sma20).abs();
Indicator<Num> normalizedSpread = spread.dividedBy(sma20);
Indicator<Num> powered = close.pow(0.5); // exponentiation via pow(Number)
```

---

## Practice Proactive Testing

When writing custom indicators, test warm-up bounds, NaN inputs, and series eviction:

```java
@Test
void customIndicatorHandlesWarmupAndNaN() {
    BarSeries series = new BaseBarSeriesBuilder().build();
    // Populate test bars...
    Indicator<Num> indicator = new CustomIndicator(series, 14);

    // Check unstable bar count
    assertEquals(14, indicator.getCountOfUnstableBars());

    // Unstable period returns NaN or expected warm-up value
    assertTrue(Num.isNaNOrNull(indicator.getValue(0)));

    // Stable index produces valid value
    assertTrue(Num.isValid(indicator.getValue(15)));
}
```

---

## Related Pages

- [Indicators Inventory](Indicators-Inventory.md) - Exhaustive reference of all indicator classes
- [Moving Average Indicators](Moving-Average-Indicators.md) - Deep dive into moving averages
- [Highs and Lows](Highs-and-Lows.md) - Swing points and ZigZag detectors
- [Correlation, Lead-Lag & Event Dependence](Correlation-Lead-Lag-Event-Analysis.md) - Lead/lag and DTW analysis
- [Forecast Indicators](Forecast-Indicators.md) - Forward-looking return/price projections
