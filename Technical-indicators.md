# Technical Indicators

Technical indicators (a.k.a. *technicals*) transform price/volume data into structured signals that power rules and strategies. ta4j ships with hundreds of indicators covering major categories plus building blocks for your own creations.

**Exhaustive list:** For a full inventory of all indicators in ta4j-core and ta4j-examples (fully qualified names, class names, short descriptions, and usage notes), see [Indicators Inventory](Indicators-Inventory.md).

| Category | Highlights | Docs |
| --- | --- | --- |
| Trend / Moving Averages | SMA, EMA, HMA, VIDYA, Jurik, displaced variants, ADX/DI, Aroon, SuperTrend, and MA-derived indicators. | [Moving Average Indicators](Moving-Average-Indicators.md) |
| Momentum & Oscillators | RSI family, NetMomentum, MACD/MACD-V, MACD-V momentum states, KST, Stochastics, CMO, ROC. | This page |
| Volatility & Bands | ATR, Donchian, Bollinger, Keltner, Chandelier exits, Squeeze Pro. | [Bar Series & Bars](Bar-series-and-bars.md) |
| Volume & Breadth | OBV, VWAP/VWMA/MVWAP, Accumulation/Distribution, Chaikin family, MFI, NVI/PVI, relative-volume indicators. | [Indicators Inventory](Indicators-Inventory.md) |
| Market Structure (VWAP/SR/Wyckoff) | Anchored VWAP, VWAP bands/z-score, price clusters, bounce counts, trend lines, KDE volume profile, Wyckoff phase/cycle analysis. | [VWAP, Support/Resistance, and Wyckoff Guide](VWAP-Support-Resistance-and-Wyckoff.md) |
| Bill Williams Toolkit | Alligator (jaw/teeth/lips), FractalHigh/Low, Gator Oscillator, Market Facilitation Index. | [Bill Williams Indicators](Bill-Williams-Indicators.md) |
| Candle/Pattern | Hammer, Shooting Star, Three White Soldiers, DownTrend/UpTrend. | `indicators.candles` |
| Wave & Swing Structure | ZigZag state/pivots/recent swings and Elliott scenario/confidence/trend-bias toolchain. | [Trendlines & Swing Points](Trendlines-and-Swing-Points.md), [Elliott Wave Indicators](Elliott-Wave-Indicators.md) |
| Price Transformations / Numeric Ops | RenkoUp/Down/X (0.19), Heikin Ashi builders, `BinaryOperationIndicator`/`UnaryOperationIndicator`/`NumericIndicator`. | [Indicators Inventory](Indicators-Inventory.md) |
| Ichimoku / Pivot / Statistics | Ichimoku lines, pivot-point/reversal indicators, and statistics/regression indicators. | [Indicators Inventory](Indicators-Inventory.md) |

Browse `org.ta4j.core.indicators` in your IDE for the full list. The table above is representative; [Indicators Inventory](Indicators-Inventory.md) is the exhaustive source of truth.

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

- `BinaryOperationIndicator` / `UnaryOperationIndicator` are the preferred composition APIs. `TransformIndicator` has been removed, while `CombineIndicator` remains as a deprecated compatibility class.
- Output indicators can feed directly into rules (`new OverIndicatorRule(trendBias, numOf(1.0))`) or become inputs to other indicators.

## Market structure workflow (VWAP + S/R + Wyckoff)

ta4j now includes a complete workflow for value, location, and phase analysis:

- Value: `VWAPIndicator`, `AnchoredVWAPIndicator`, `VWAPBandIndicator`, `VWAPZScoreIndicator`
- Location: `PriceClusterSupportIndicator`, `PriceClusterResistanceIndicator`, `BounceCountSupportIndicator`, `BounceCountResistanceIndicator`, `TrendLineSupportIndicator`, `TrendLineResistanceIndicator`, `VolumeProfileKDEIndicator`
- Phase/Cycle: `WyckoffPhaseIndicator`, `WyckoffCycleFacade`

Use the dedicated guide for implementation templates and tuning advice:

- [VWAP, Support/Resistance, and Wyckoff Guide](VWAP-Support-Resistance-and-Wyckoff.md)

## Wave-structure workflow (ZigZag + Elliott)

ta4j includes a complete swing/structure toolchain for pattern-based analysis:

- Swing extraction: `ZigZagStateIndicator`, `RecentZigZagSwingHighIndicator`, `RecentZigZagSwingLowIndicator`
- Elliott interpretation: `ElliottWaveFacade`, `ElliottScenarioIndicator`, `ElliottTrendBiasIndicator`, `ElliottConfidenceScorer`

Use:
- [Trendlines & Swing Points](Trendlines-and-Swing-Points.md)
- [Elliott Wave Indicators](Elliott-Wave-Indicators.md)

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

- Most implementations use `CachedIndicator`/`RecursiveCachedIndicator`; some thin wrappers extend `AbstractIndicator` and delegate to cached components (for example `ATRIndicator`, `KRIIndicator`).
- Latest-bar values are cached with mutation-aware invalidation; when the current bar changes, only that slot is recomputed.
- Use `indicator.getCountOfUnstableBars()` for warm-up size. For per-index checks, use `index >= indicator.getCountOfUnstableBars()`; for whole-series checks, use `indicator.isStable()`.
- For strategies, pass warm-up via `strategy.setUnstableBars(...)`.
- With moving `BarSeries` (`setMaximumBarCount`), evicted bars and their cache entries are not recoverable.

## Creating custom indicators

Sub-class `CachedIndicator<Num>` or compose existing indicators with operations. Guidelines:

- Accept dependencies via constructor injections (`Indicator<Num> base`) rather than pulling directly from a `BarSeries`.
- Respect the `Num` abstraction: use `Num` arithmetic (`plus`, `minus`, etc.) and produce values via the series `NumFactory`.
- Override `getCountOfUnstableBars()` when your indicator requires warm-up bars (e.g., multi-stage EMA pipelines).
- If you need state across indices, store it in the indicator (ta4j handles thread safety by design if you limit state to the calculation path).

## Tips

- Normalize values when mixing indicators with different ranges (e.g., convert RSI to 0–1 before feeding it into a vote rule with MACD).
- When working with unconventional chart types (Renko, Heikin Ashi), prefer the dedicated builders/indicators shipped in 0.18/0.19/0.21.0—they keep the math consistent across strategies.
- Combine price- and volume-driven indicators to reduce false positives (e.g., `new AndIndicatorRule(new OverIndicatorRule(macdv, zero), new OverIndicatorRule(vwma, close))`).
- Document indicator usage inside strategies so others know the intent—especially if the indicator is non-standard or parameter-sensitive.
Technicals also need to be backtested on historic data to see how effective they would have been in predicting future prices. [Some examples](Usage-examples.md#playing-with-indicators) are available for this.

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
