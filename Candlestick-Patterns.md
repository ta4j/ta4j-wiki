# Candlestick geometry and patterns

Candlestick patterns are easiest to reason about when you separate **geometry** from **interpretation**. A candle has a body, an upper shadow, a lower shadow, and a full high-to-low range; bullish or bearish direction is a separate property of the bar.

This page describes the current ta4j candlestick model on the development branch. The latest stable release is **0.24.1**; the `CandleBodyIndicator` / `CandleRangeIndicator` foundation and the related pattern-threshold overhaul target **0.24.2** and are not available in 0.24.1.

## The four geometric building blocks

For a well-formed OHLC bar:

| Quantity | ta4j type | Definition |
| --- | --- | --- |
| Body magnitude | `CandleBodyIndicator` | `abs(close - open)` |
| Upper shadow | `UpperShadowIndicator` | `high - max(open, close)` |
| Lower shadow | `LowerShadowIndicator` | `min(open, close) - low` |
| Full candle range | `CandleRangeIndicator` | `high - low` |

These quantities are non-negative for valid OHLC data. `CandleRangeIndicator` is **not** true range: true range also considers the previous close, while candle range uses only the current bar.

Direction belongs to the bar itself. Use `Bar#isBullish()` or `Bar#isBearish()` when direction matters instead of encoding direction into a geometry measurement.

## Migrating from `RealBodyIndicator`

`RealBodyIndicator` is deprecated on the current development branch. Despite its old name, it returns the **signed** close-to-open change:

`close - open`

That makes it positive for bullish candles and negative for bearish candles. Code that treated it as body *size* could therefore behave differently for otherwise identical bullish and bearish candles.

Use:

- `CandleBodyIndicator` when you mean body magnitude;
- `Bar#isBullish()` / `Bar#isBearish()` when you mean direction;
- `RealBodyIndicator` only when you intentionally need the legacy signed close-to-open quantity.

This separation is useful beyond candlestick patterns: it lets ratios and thresholds compare like quantities without accidentally mixing magnitude and direction.

## How pattern thresholds work

Many pattern names—"long body", "short body", "doji", "long shadow", "near"—are relative descriptions, not universal price constants. Current development code therefore evaluates pattern geometry against **recent preceding candles** rather than fixed absolute thresholds.

The shared candlestick threshold model is causal: the candle being classified does not contribute to its own baseline. A baseline at index `i` is computed from the preceding window only, so pattern detection does not look ahead.

The recommended internal profile uses a five-candle prior window by default and compares current geometry with recent average body or range. The exact support object is package-private implementation detail; users normally configure and consume the public pattern indicators rather than constructing threshold machinery directly.

### Warm-up matters

A relative threshold needs enough preceding candles to establish its baseline. Pattern indicators therefore have an unstable period before a full history window is available. Respect `getCountOfUnstableBars()` when backtesting or evaluating patterns near the beginning of a series.

A `false` pattern result during warm-up should not be interpreted as evidence that the opposite pattern is present; it may simply mean the pattern is not yet confirmable.

## A useful mental model

Treat a candlestick pattern as two layers:

1. **Geometry:** what are the body, shadows, range, and direction?
2. **Context:** is that geometry unusual relative to recent candles, and does the surrounding market structure make the named pattern meaningful?

The first layer is deterministic measurement. The second is classification and interpretation. Keeping them separate makes composition easier and reduces the temptation to treat a named pattern as a complete trading signal.

For example, a hammer-like candle describes geometry. Whether it represents useful rejection or reversal evidence depends on context such as preceding trend, volatility, liquidity, confirmation, and the strategy's broader rules.

## Using pattern indicators responsibly

Candlestick indicators are best used as **features or conditions**, not standalone evidence of profitability. Common compositions include:

- a pattern plus a trend or regime filter;
- a pattern near a structural level such as support/resistance;
- a pattern combined with volume or volatility context;
- a pattern as one rule inside a strategy that is then tested with realistic execution assumptions.

Do not assume a familiar pattern name implies identical thresholds across libraries or textbooks. In ta4j, inspect constructor parameters, unstable bars, and current Javadocs when exact semantics matter.

## Data-quality boundary

Current development code also tightens OHLC validation: bars with contradictory high/low values relative to open and close are rejected. This protects candle geometry from producing negative or nonsensical shadows and ranges.

If previously accepted data now fails construction after upgrading, inspect the source feed rather than weakening candlestick calculations. At minimum, a valid candle must have a high no lower than its open/close and a low no higher than its open/close.

## Version notes

- **0.24.1:** latest stable release as of this page update; the new candlestick foundation is not yet part of this release.
- **0.24.2 development:** introduces `CandleBodyIndicator` and `CandleRangeIndicator`, deprecates `RealBodyIndicator` for magnitude/direction use cases, tightens OHLC validation, and moves pattern classification toward shared causal recent-history thresholds.

When writing reusable examples or libraries, avoid silently mixing 0.24.2-development APIs into code intended to compile against 0.24.1.

## Related pages

- [Indicators Inventory](Indicators-Inventory.md) — exhaustive indicator reference.
- [Technical Indicators](Technical-indicators.md) — indicator composition, caching, and general usage.
- [Bar Series & Bars](Bar-series-and-bars.md) — bar-series fundamentals.
- [Live Candle vs Closed Candle](Live-Candle-vs-Closed-Candle-Evaluation.md) — live-bar evaluation semantics, which matter when a candle can still change before close.
