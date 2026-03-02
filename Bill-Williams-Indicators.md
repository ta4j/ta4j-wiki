# Bill Williams Indicators

ta4j 0.22.3 adds a complete Bill Williams indicator stack so you can model trend context, breakout structure, and participation in one workflow.

## Included indicators

- `AlligatorIndicator` – displaced SMMAs on median price (`jaw`, `teeth`, `lips`)
- `FractalHighIndicator` / `FractalLowIndicator` – confirmed fractal pivots (default `2/2` windows)
- `GatorOscillatorIndicator` – histogram spread between alligator lines
- `MarketFacilitationIndexIndicator` – Bill Williams MFI (`(high - low) / volume`)

## Canonical defaults

Alligator canonical settings in ta4j follow Bill Williams defaults:

- jaw: `SMMA(13)` shifted by `8`
- teeth: `SMMA(8)` shifted by `5`
- lips: `SMMA(5)` shifted by `3`

Fractal defaults use `2` preceding + `2` following bars.

## Look-ahead safety

Fractal indicators confirm on the current bar. When a fractal is confirmed at index `i`, the pivot is earlier. Use `getConfirmedFractalIndex(i)` to retrieve the pivot index explicitly.

This avoids accidental look-ahead bias when building entry/exit rules.

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

Typical interpretation:

1. Use alligator line ordering (`lips > teeth > jaw` or inverse) for trend context.
2. Use confirmed fractals for structure breakouts and invalidation levels.
3. Use gator and BW MFI to filter weak setups with low participation.

## Practical notes

- `MarketFacilitationIndexIndicator` is not the same indicator as `MoneyFlowIndexIndicator`.
- For reproducible backtests, combine this toolkit with unstable-bar handling in [Backtesting](Backtesting.md).
- For broader market-structure context (VWAP + support/resistance + Wyckoff), see [VWAP, Support/Resistance, and Wyckoff Guide](VWAP-Support-Resistance-and-Wyckoff.md).
