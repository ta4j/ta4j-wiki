# Technical Indicators

Technical indicators (a.k.a. *technicals*) transform price/volume data into structured signals that power rules and strategies. ta4j currently ships with hundreds of indicator classes under `org.ta4j.core.indicators`, covering every major category plus building blocks for your own creations.

**Exhaustive list:** For a full inventory of all indicators in ta4j-core and ta4j-examples (fully qualified names, class names, short descriptions, and usage notes), see [Indicators Inventory](Indicators-Inventory.md).

| Category | Highlights | Docs |
| --- | --- | --- |
| Trend / Moving Averages | SMA, EMA, HMA, VIDYA, Jurik, Displaced variants, SuperTrend, Renko helpers. | [Moving Average Indicators](Moving-Average-Indicators.md) |
| Momentum & Oscillators | RSI family, NetMomentum (new), MACD/MACDV, MACD-V momentum states, KST, Stochastics, CMO, ROC. | This page |
| Volatility & Bands | ATR, Donchian, Bollinger, Keltner, Average True Range trailing stops. | [Bar Series & Bars](Bar-series-and-bars.md) (for ATR-based stops) |
| Volume & Breadth | OBV, VWAP/VWMA, Accumulation/Distribution, Chaikin, Volume spikes. | Indicators package |
| Market Structure (VWAP/SR/Wyckoff) | Anchored VWAP, VWAP bands/z-score, price clusters, bounce counts, KDE volume profile, Wyckoff phase detection. | [VWAP, Support/Resistance, and Wyckoff Guide](VWAP-Support-Resistance-and-Wyckoff.md) |
| Bill Williams Toolkit | Alligator (jaw/teeth/lips), FractalHigh/Low, Gator Oscillator, Market Facilitation Index. | [Bill Williams Indicators](Bill-Williams-Indicators.md) |
| Candle/Pattern | Hammer, Shooting Star, Three White Soldiers, DownTrend/UpTrend. | `indicators.candles` |
| Price Transformations | RenkoUp/Down/X (0.19), Heikin Ashi builders, `BinaryOperationIndicator`/`UnaryOperationIndicator` transforms. | `indicators.renko` |
| Oscillators | TrueStrengthIndex, SchaffTrendCycle, ConnorsRSI (0.21.0), RSI family, MACD/MACDV, KST, Stochastics, CMO, ROC. | This page |

Browse `org.ta4j.core.indicators` in your IDE for the full list—packages mirror the table above.

## Composition example

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

## Market structure workflow (VWAP + S/R + Wyckoff)

ta4j now includes a complete workflow for value, location, and phase analysis:

- Value: `VWAPIndicator`, `AnchoredVWAPIndicator`, `VWAPBandIndicator`, `VWAPZScoreIndicator`
- Location: `PriceClusterSupportIndicator`, `PriceClusterResistanceIndicator`, `BounceCountSupportIndicator`, `BounceCountResistanceIndicator`, `VolumeProfileKDEIndicator`
- Phase: `WyckoffPhaseIndicator`

Use the dedicated guide for implementation templates and tuning advice:

- [VWAP, Support/Resistance, and Wyckoff Guide](VWAP-Support-Resistance-and-Wyckoff.md)

For Donchian channels, `DonchianChannelFacade` provides fluent `lower()/upper()/middle()` numeric indicators from one constructor call; see [Indicators Inventory](Indicators-Inventory.md) for class-level details.

## Bill Williams workflow (0.22.3)

ta4j 0.22.3 added a complete Bill Williams toolkit:

- Trend context: `AlligatorIndicator` (jaw/teeth/lips with canonical 13/8, 8/5, 5/3 settings)
- Breakout structure: `FractalHighIndicator`, `FractalLowIndicator` (`2/2` windows by default)
- Momentum/participation confirmation: `GatorOscillatorIndicator`, `MarketFacilitationIndexIndicator`

Fractal indicators confirm on the current bar; use `getConfirmedFractalIndex(...)` to reference the pivot bar without introducing look-ahead bias.

## MACD-V momentum-state workflow (0.22.3)

Prefer `org.ta4j.core.indicators.macd.MACDVIndicator` for new code. The legacy `org.ta4j.core.indicators.MACDVIndicator` is deprecated and scheduled for removal in 0.24.0.

- `MACDVIndicator` in ta4j is the volume/ATR-weighted EMA-spread variant (ATR is used inside the weighting term).
- `VolatilityNormalizedMACDIndicator` is the volatility-normalized form (EMA spread divided by ATR and scaled), often referred to as the Spiroglou-style MACD-V formulation.
- They are related but not interchangeable; thresholds and interpretation can differ materially between the two.
- Use `getSignalLine(...)`, `getHistogram(...)`, and `getLineValues(...)` to expose all MACD-V lines.
- Classify MACD-V regime with `MACDVMomentumStateIndicator` and `MACDVMomentumProfile` (default thresholds: `+50/+150/-50/-150`).
- Attach state-aware rules with `inMomentumState(...)` or `MomentumStateRule`.

## Backtesting indicators

Indicators should be evaluated the same way strategies are—prefer realistic data with survivorship-bias filters. The [Usage Examples](Usage-examples.md#playing-with-indicators) page links to CSV/Chart demos where indicators are plotted alongside price bars.

## Caching & stability

- Every indicator extends `CachedIndicator`, so once a value is computed (except for the most recent bar) it is reused.
- Mutating the latest bar (common with streaming data) invalidates just that slot; the rest stays cached.
- Use `indicator.getCountOfUnstableBars()` / `indicator.isStable(index)` to understand when the values become reliable (and pass that number to `strategy.setUnstableBars(...)`).
- When using moving `BarSeries` via `setMaximumBarCount`, cached entries older than the oldest remaining bar disappear. Always guard against `NaN` if you try to access evicted indexes.

## Creating custom indicators

Sub-class `CachedIndicator<Num>` or compose existing indicators with operations. Guidelines:

- Accept dependencies via constructor injections (`Indicator<Num> base`) rather than pulling directly from a `BarSeries`.
- Respect the `Num` abstraction: use `Num` arithmetic (`plus`, `minus`, etc.) and produce values via the series `NumFactory`.
- Override `getUnstableBars()` / `isStable()` when your indicator requires warm-up bars (e.g., multi-stage EMAs).
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
