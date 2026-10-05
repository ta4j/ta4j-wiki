# Highs and Lows

Ta4j provides paired recent-swing indicators for local fractals, reversal-distance ZigZag, adaptive ZigZag, rounded slope changes, bounded price prominence, and multi-detector consensus. All confirmed indicators are causal: a query at index `i` only uses bars through `i`, even when the reported pivot belongs to an earlier bar.

First-class ta4j indicators are named `*Indicator`. Swing configuration records such as `AdaptiveZigZagConfig`, `SlopeChangeConfig`, and `ProminenceSwingConfig`, plus detector helpers such as `SwingDetector` and `SwingDetectors`, live under `org.ta4j.core.analysis.elliott.swing` and are not indicators themselves.

## Start with the default

Use `RecentSwingIndicators.defaultFor(series)` unless the strategy has a reason to prefer another definition:

```java
RecentSwingIndicators.Pair swings = RecentSwingIndicators.defaultFor(series);
RecentSwingIndicator highs = swings.highs();
RecentSwingIndicator lows = swings.lows();

int endIndex = series.getEndIndex();
Num recentHigh = highs.getValue(endIndex);
int highBar = highs.getLatestSwingIndex(endIndex);
int confirmedAt = highs.getLatestSwingConfirmationIndex(endIndex);
```

The canonical default is an OHLC-aware ATR(14) ZigZag:

- Intrabar highs and lows locate the extremes.
- Close prices confirm movement away from an extreme.
- The reversal distance scales with volatility through ATR.
- High and low indicators share one `ZigZagStateIndicator`.

This is the best general balance of causal operation, noise filtering, scale independence, and variable confirmation time. Named constructors and methodology-specific behavior remain unchanged; choosing the canonical default does not silently convert Bill Williams, Wyckoff, or explicitly fractal workflows to ZigZag.

## Method guide

| Method | Factory | Confirmation | Prefer it when |
| --- | --- | --- | --- |
| ATR ZigZag | `defaultFor(series)` or `zigZag(series)` | Price reverses from an OHLC extreme by ATR(14) using close confirmation | You need one robust default across instruments and bar durations |
| Fractal | `fractal(series)` | Three lower/higher bars on each side by default | Fixed latency and visually local extrema matter |
| Adaptive ZigZag | `adaptiveZigZag(series)` or `adaptiveZigZag(series, config)` | Smoothed ATR threshold is crossed | Volatility regimes change enough to justify smoothing and clamps |
| Slope change | `slopeChange(series)` | Rolling regression slope reverses and persists | Turns are rounded rather than sharp |
| Prominence | `prominence(series)` | A local extreme stands at least one ATR beyond bounded surrounding baselines, with three right-side bars | You want fewer, structurally salient extrema without requiring a full ZigZag reversal |
| Consensus | `consensus(series)` | Two of fractal, adaptive ZigZag, and slope change agree within two bars | False positives cost more than latency or computation |

`ProminenceSwingConfig.defaults()` uses a 20-bar bounded baseline search, three confirmation bars, ATR(14), and one ATR of minimum prominence. Prominence is distinct from local-window dominance: a bar can be a fractal but still be rejected as insignificant relative to its surrounding baselines. This follows the standard topographic idea of [peak prominence](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.peak_prominences.html), implemented here with bounded causal evidence.

The default consensus is deliberately not the global default. It is sparser, more expensive, and can hide a weak component when the remaining voters agree. Use it when agreement itself is part of the strategy thesis.

## Confirmed and forming points

`RecentSwingIndicator` remains confirmed-only and non-repainting. The paired API separately exposes the developing terminal extreme:

```java
RecentSwingIndicators.Pair swings = RecentSwingIndicators.defaultFor(series);

RecentSwingIndicators.SwingPoint latestHigh =
        swings.latestHigh(series.getEndIndex()).orElseThrow();

if (latestHigh.confirmation() == RecentSwingIndicators.Confirmation.PROVISIONAL) {
    // Useful for display, monitoring, or forming-structure diagnostics.
    // It can move or disappear before confirmation.
}
```

`formingPoint(index)` starts after the latest confirmed high or low, follows the next alternating leg, and returns its most extreme high or low with `confirmationIndex == -1`. If the last bar sets that extreme, it is visible immediately. Once the selected methodology confirms it, `latestHigh(...)` or `latestLow(...)` returns the same pivot as `CONFIRMED` with the exact confirmation index.

Do not treat a provisional point as a confirmed entry or exit signal without accepting repaint risk. Keeping this status separate avoids a constructor flag that would silently change the meaning of `getValue`, `getLatestSwingIndex`, and `getSwingPointIndexesUpTo`.

## Custom detectors and composites

The detector family can be adapted to regular recent high/low indicators:

```java
SwingDetector detector = SwingDetectors.consensus(
        2,
        2,
        SwingDetectors.prominence(),
        SwingDetectors.slopeChange(7),
        SwingDetectors.adaptiveZigZag(AdaptiveZigZagConfig.defaults()));

RecentSwingIndicators.Pair swings =
        RecentSwingIndicators.fromDetector(series, detector);
```

`SwingDetector.detectPivots(series, index)` provides the confirmed pivot view without requiring Elliott degree metadata. Detector-backed recent indicators preserve `SwingPivot.price()` for pivots detected through the current series end, so a custom detector can report a pivot level that differs from the bar's high or low source. The custom high/low price-source overload still defines the shared bar series and acts as the fallback for bars that are not known detector pivots. `RecentSwingIndicators.Pair.method()` records the factory provenance; arbitrary detector adapters report `CUSTOM`.

## ETH/USD reference behavior

The analysis harness uses ossified Coinbase ETH/USD fixtures at `PT5M`, `PT15M`, `PT1H`, `PT4H`, and `PT1D`. On the hourly fixture, the candle beginning `2026-07-22T16:00:00Z` (12 PM EDT) has close `1949.30` and high `1955.87`.

Every method reports that candle as the latest confirmed swing high before the fixture ends:

| Method | Confirmation delay from the hourly high |
| --- | ---: |
| ATR ZigZag | 1 bar |
| Adaptive ZigZag | 1 bar |
| Fractal | 3 bars |
| Slope change | 3 bars |
| Prominence | 3 bars |
| Consensus | 3 bars |

The methods should not produce identical histories. On the hourly fixture, high/low counts were:

| Method | Highs | Lows |
| --- | ---: | ---: |
| ATR ZigZag | 17 | 18 |
| Fractal | 11 | 13 |
| Adaptive ZigZag | 13 | 13 |
| Slope change | 7 | 7 |
| Prominence | 7 | 5 |
| Consensus | 7 | 7 |

These differences are interpretation, not errors: ZigZag reacts to reversal magnitude, fractals to fixed neighborhoods, slope change to direction persistence, prominence to structural relief, and consensus to agreement. The regression suite additionally verifies that each method produces highs and lows on all five tested durations.

Run the comparison from a ta4j source checkout:

```bash
./mvnw -pl ta4j-examples -am install
./mvnw -pl ta4j-examples \
  -Dexec.mainClass=ta4jexamples.analysis.TrendLineAndSwingPointAnalysis \
  -Dexec.args="--no-display --no-save" \
  exec:java
```

## Causal and live-series guarantees

- Historical queries are filtered by confirmation index. Discovering a pivot at a later bar cannot leak it into an earlier query.
- Replacing or revising the live terminal bar rewinds affected swing tracking instead of leaving a stale confirmation.
- Dynamic ZigZag thresholds formed during indicator warm-up adopt the first finite positive threshold and pin it to that candidate; an early ATR `NaN` cannot freeze the state indefinitely.
- Confirmed pivot indexes can be earlier than their confirmation indexes. Store both when auditing signal timing.
- Use high/low price sources when identifying price extremes. A close-based series answers a different question and would report `1949.30`, not the hourly wick high `1955.87`, for the ETH example.

## What is not a separate method

- Directional-change detection is already expressible by ZigZag with a fixed, percentage-derived, ATR, or custom reversal threshold.
- Donchian channels and rolling highest/lowest indicators expose levels but do not confirm turning points.
- Session pivot points derive reference levels from prior-session OHLC; they are not recent empirical swing extrema.

This keeps the toolkit small: add a methodology only when it supplies meaning that cannot already be composed from the existing reversal, neighborhood, slope, prominence, and consensus building blocks.
