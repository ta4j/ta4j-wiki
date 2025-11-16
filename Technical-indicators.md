# Technical Indicators

Technical indicators (a.k.a. *technicals*) transform price/volume data into structured signals that power rules and strategies. ta4j ships with 130+ indicators covering every major category plus building blocks for your own creations.

| Category | Highlights | Docs |
| --- | --- | --- |
| Trend / Moving Averages | SMA, EMA, HMA, VIDYA, Jurik, Displaced variants, SuperTrend, Renko helpers. | [Moving Average Indicators](Moving-Average-Indicators.md) |
| Momentum & Oscillators | RSI family, NetMomentum (new), MACD/MACDV, KST, Stochastics, Calm (CMO), ROC. | This page |
| Volatility & Bands | ATR, Donchian, Bollinger, Keltner, Average True Range trailing stops. | [Bar Series & Bars](Bar-series-and-bars.md) (for ATR-based stops) |
| Volume & Breadth | OBV, VWAP/VWMA, Accumulation/Distribution, Chaikin, Volume spikes. | Indicators package |
| Candle/Pattern | Hammer, Shooting Star, Three White Soldiers, DownTrend/UpTrend. | `indicators.candles` |
| Price Transformations | RenkoUp/Down/X (0.19), Heikin Ashi builders, `BinaryOperationIndicator`/`UnaryOperationIndicator` transforms. | `indicators.renko` |

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

- `BinaryOperationIndicator` / `UnaryOperationIndicator` replace the older `TransformIndicator`/`CombineIndicator` classes (removed in 0.19).
- Output indicators can feed directly into rules (`new OverIndicatorRule(trendBias, numOf(1.0))`) or become inputs to other indicators.

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
- When working with unconventional chart types (Renko, Heikin Ashi), prefer the dedicated builders/indicators shipped in 0.18/0.19—they keep the math consistent across strategies.
- Combine price- and volume-driven indicators to reduce false positives (e.g., `new AndIndicatorRule(new OverIndicatorRule(macdv, zero), new OverIndicatorRule(vwma, close))`).
- Document indicator usage inside strategies so others know the intent—especially if the indicator is non-standard or parameter-sensitive.
