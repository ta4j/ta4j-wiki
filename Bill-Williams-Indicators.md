# Bill Williams Indicators

ta4j 0.22.3 adds a complete Bill Williams indicator stack so you can model trend context, breakout structure, and participation in one workflow.

## What this suite is (ta4j view)

In ta4j, the Bill Williams stack is implemented as composable indicators that plug directly into the standard `Indicator` + `Rule` + `Strategy` pipeline:

- trend context from `AlligatorIndicator`
- structure confirmation from `FractalHighIndicator` / `FractalLowIndicator`
- participation/expansion context from `GatorOscillatorIndicator` and `MarketFacilitationIndexIndicator`

This matters in ta4j because each component can be backtested, combined with non-Bill-Williams indicators, and ranked with the same criteria stack used elsewhere in the library.

## Included indicators

- `AlligatorIndicator` – displaced SMMAs on median price (`jaw`, `teeth`, `lips`)
- `FractalHighIndicator` / `FractalLowIndicator` – confirmed fractal pivots (default `2/2` windows)
- `GatorOscillatorIndicator` – histogram spread between alligator lines
- `MarketFacilitationIndexIndicator` – Bill Williams MFI (`(high - low) / volume`)

## Why and when this is useful

Use this suite when your ta4j strategy needs all three at once:

1. trend regime (sleeping vs trending),
2. explicit structure events (confirmed fractal breakouts),
3. participation filter (range expansion per volume).

Typical ta4j use cases:

- swing/trend-following systems that need structure-aware entries,
- breakout systems that want confirmation on fully formed bars,
- hybrid systems where Bill Williams signals gate another indicator family (for example MACD-V or VWAP rules).

Avoid relying on it alone in very low-volume instruments or ultra-short bar horizons where `(high - low) / volume` becomes unstable/noisy.

## Canonical defaults

Alligator canonical settings in ta4j follow Bill Williams defaults:

- jaw: `SMMA(13)` shifted by `8`
- teeth: `SMMA(8)` shifted by `5`
- lips: `SMMA(5)` shifted by `3`

Fractal defaults use `2` preceding + `2` following bars.

## Look-ahead safety

Fractal indicators confirm on the current bar. When a fractal is confirmed at index `i`, the pivot is earlier. Use `getConfirmedFractalIndex(i)` to retrieve the pivot index explicitly.

This avoids accidental look-ahead bias when building entry/exit rules.

In ta4j terms: `FractalHighIndicator` and `FractalLowIndicator` are `Indicator<Boolean>` implementations, so they are event/confirmation signals, not direct price levels.

## Example workflow

```java
BarSeries series = ...;

AlligatorIndicator jaw = AlligatorIndicator.jaw(series);
AlligatorIndicator teeth = AlligatorIndicator.teeth(series);
AlligatorIndicator lips = AlligatorIndicator.lips(series);

FractalHighIndicator fractalHigh = new FractalHighIndicator(series);
FractalLowIndicator fractalLow = new FractalLowIndicator(series);

GatorOscillatorIndicator gatorUpper = GatorOscillatorIndicator.upper(series);
GatorOscillatorIndicator gatorLower = GatorOscillatorIndicator.lower(series);
MarketFacilitationIndexIndicator bwMfi = new MarketFacilitationIndexIndicator(series);
```

## Strategy wiring pattern in ta4j

```java
Num zero = series.numFactory().zero();

Rule trendUp = new OverIndicatorRule(lips, teeth)
        .and(new OverIndicatorRule(teeth, jaw));
Rule confirmedFractalBreakout = new BooleanIndicatorRule(fractalHigh);
Rule participation = new OverIndicatorRule(gatorUpper, zero)
        .and(new OverIndicatorRule(bwMfi, zero));

Rule entryRule = trendUp.and(confirmedFractalBreakout).and(participation);
```

Why this pattern works in ta4j:

- `BooleanIndicatorRule` consumes fractal confirmation events directly.
- `OverIndicatorRule` keeps numeric comparisons explicit and testable.
- `Num` values come from the series factory, keeping numeric type consistency.

For realistic backtests, set unstable bars high enough to cover all dependency warm-up periods (Alligator displacement + fractal windows + any added filters).

Typical interpretation:

1. Use alligator line ordering (`lips > teeth > jaw` or inverse) for trend context.
2. Use confirmed fractals for structure breakouts and invalidation levels.
3. Use gator and BW MFI to filter weak setups with low participation.

## Practical notes

- `MarketFacilitationIndexIndicator` is not the same indicator as `MoneyFlowIndexIndicator`.
- `AlligatorIndicator` displacement is implemented without look-ahead (value at `i` reads smoothed value at `i - shift`).
- `GatorOscillatorIndicator.upper(...)` and `.lower(...)` provide the two histogram branches separately.
- For reproducible backtests, combine this toolkit with unstable-bar handling in [Backtesting](Backtesting.md).
- For broader market-structure context (VWAP + support/resistance + Wyckoff), see [VWAP, Support/Resistance, and Wyckoff Guide](VWAP-Support-Resistance-and-Wyckoff.md).
