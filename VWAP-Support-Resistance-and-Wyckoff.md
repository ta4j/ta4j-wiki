# VWAP, Support/Resistance, and Wyckoff Guide

This guide explains how to use ta4j's VWAP, support/resistance, and Wyckoff indicator families together for both backtesting and live trading.

## Why these three families belong together

- **VWAP stack** gives value context (fair value, stretch, mean reversion zones).
- **Support/resistance stack** gives location context (where reactions repeatedly happen).
- **Wyckoff stack** gives phase context (accumulation/distribution lifecycle).

Combined, they answer:

- Is price cheap or expensive versus local value?
- Is price near a meaningful reaction zone?
- Is the market in a phase where continuation or reversal is more likely?

## Indicator map

### VWAP family

- `VWAPIndicator`: rolling VWAP over `barCount`.
- `AnchoredVWAPIndicator`: VWAP that resets on a fixed anchor or dynamic anchor signal.
- `MVWAPIndicator`: moving average of VWAP.
- `VWAPDeviationIndicator`: `price - vwap`.
- `VWAPStandardDeviationIndicator`: volume-weighted standard deviation around VWAP.
- `VWAPBandIndicator`: VWAP bands (`VWAP +/- multiplier * stdDev`).
- `VWAPZScoreIndicator`: normalized deviation (`deviation / stdDev`).

### Support/resistance family

- `VolumeProfileKDEIndicator`: kernel density estimate of volume-at-price.
  - `getDensityAtPrice(index, price)`
  - `getModePrice(index)`
- `PriceClusterSupportIndicator` / `PriceClusterResistanceIndicator`:
  weighted price clustering in a rolling lookback.
- `BounceCountSupportIndicator` / `BounceCountResistanceIndicator`:
  bounce-frequency-driven zones.

### Wyckoff family

- `WyckoffPhaseIndicator`: phase inference engine (cycle + phase + confidence + latest event index).
- `WyckoffPhase`: record with cycle type, phase type, confidence, and latest event index.
- `WyckoffEventDetector`, `WyckoffStructureTracker`, `WyckoffVolumeProfile`:
  internal components used by the phase indicator.

## Quick start: compose the stacks

```java
BarSeries series = ...;
NumFactory num = series.numFactory();

ClosePriceIndicator close = new ClosePriceIndicator(series);
VolumeIndicator volume = new VolumeIndicator(series, 1);

// 1) Value context (VWAP)
VWAPIndicator vwap = new VWAPIndicator(close, volume, 20);
VWAPStandardDeviationIndicator vwapStd = new VWAPStandardDeviationIndicator(vwap);
VWAPBandIndicator upperBand = new VWAPBandIndicator(vwap, vwapStd, 2.0, VWAPBandIndicator.BandType.UPPER);
VWAPBandIndicator lowerBand = new VWAPBandIndicator(vwap, vwapStd, 2.0, VWAPBandIndicator.BandType.LOWER);
VWAPDeviationIndicator deviation = new VWAPDeviationIndicator(close, vwap);
VWAPZScoreIndicator zScore = new VWAPZScoreIndicator(deviation, vwapStd);

// 2) Location context (S/R)
PriceClusterSupportIndicator support = new PriceClusterSupportIndicator(close, volume, 150,
        num.numOf("0.25"), num.numOf("0.5"));
PriceClusterResistanceIndicator resistance = new PriceClusterResistanceIndicator(close, volume, 150,
        num.numOf("0.25"), num.numOf("0.5"));
VolumeProfileKDEIndicator profile = new VolumeProfileKDEIndicator(close, volume, 150, num.numOf("0.5"));

// 3) Phase context (Wyckoff)
WyckoffPhaseIndicator wyckoff = WyckoffPhaseIndicator.builder(series)
        .withSwingConfiguration(2, 2, 1)
        .withVolumeWindows(5, 20)
        .withTolerances(num.numOf("0.02"), num.numOf("0.05"))
        .withVolumeThresholds(num.numOf("1.6"), num.numOf("0.7"))
        .build();
```

## Backtesting how-to

See [Backtesting](Backtesting.md) for execution options. This section focuses on feature-specific patterns.

### 1) Gate unstable windows first

These indicators have meaningful warmup periods. Always compute a global unstable window and set it on the strategy.

```java
int unstableBars = Math.max(
        Math.max(zScore.getCountOfUnstableBars(), support.getCountOfUnstableBars()),
        wyckoff.getCountOfUnstableBars());

strategy.setUnstableBars(unstableBars);
```

### 2) Example entry logic (accumulation continuation)

```java
int i = series.getEndIndex();
Num price = close.getValue(i);
WyckoffPhase phase = wyckoff.getValue(i);

boolean inAccumulationAdvance = phase.cycleType() == WyckoffCycleType.ACCUMULATION
        && (phase.phaseType() == WyckoffPhaseType.PHASE_D || phase.phaseType() == WyckoffPhaseType.PHASE_E)
        && phase.confidence() >= 0.75;

boolean aboveValue = price.isGreaterThan(vwap.getValue(i));
boolean notOverextended = zScore.getValue(i).isLessThan(num.numOf("2.0"));
boolean nearSupport = price.minus(support.getValue(i)).abs().isLessThanOrEqual(num.numOf("0.5"));

if (inAccumulationAdvance && aboveValue && notOverextended && nearSupport) {
    // candidate long condition
}
```

### 3) Use location-aware exits

- Profit-taking near `upperBand` or `resistance`.
- Emergency exits when phase flips to distribution with high confidence.
- Risk exits when `zScore` exceeds your stretch threshold and momentum stalls.

### 4) Backtest usage tips

- Run sensitivity sweeps for `lookbackLength`, `bandwidth`, `tolerance`, and Wyckoff thresholds.
- Keep thresholds in `Num` to avoid precision drift when moving between `DoubleNum` and `DecimalNum`.
- Add slippage and fees; these setups often trade around congested zones where fills matter.
- Validate across trending and ranging regimes; this stack is regime-aware, so sample both.

## Live trading how-to

See [Live Trading](Live-trading.md) for ingestion/runtime architecture. This section focuses on strategy behavior.

### 1) Prefer closed-bar decisions

For production bots, evaluate entries/exits on completed bars for deterministic behavior. If you evaluate intrabar, expect more signal churn around VWAP bands and S/R boundaries.

### 2) Anchored VWAP for event resets

Use anchored VWAP when your execution model depends on event regimes.

```java
Indicator<Boolean> anchorSignal = ...; // true on session open, major news, manual resets, etc.
AnchoredVWAPIndicator anchored = new AnchoredVWAPIndicator(series, anchorSignal);
```

Recommended anchor sources:

- Session boundaries (daily/weekly open).
- Structural breaks (range breakout/breakdown).
- Operator-driven resets after macro events.

### 3) Add confidence and confluence filters

In live routing, require at least two independent confirmations to reduce noise:

- Wyckoff phase confidence threshold.
- VWAP relation (`price > vwap` for long bias, opposite for short bias).
- Price proximity to support/resistance zone.

### 4) Persist state needed for restart safety

Persist:

- Last processed bar timestamp/index.
- Last `WyckoffPhase` and transition index (`getLastPhaseTransitionIndex`).
- Active anchor state if using dynamic anchored VWAP.

This avoids duplicated triggers after restart.

### 5) Live usage tips

- Do not trade while indicators are unstable after startup or re-subscription.
- Use narrower position sizing when `zScore` is already stretched.
- Widen cooldowns during choppy ranges (high false retests around VWAP).
- Track rejected signals in logs for post-trade analysis.

## Suggested parameter baselines

Start here, then tune per instrument/timeframe.

| Component | Intraday baseline | Swing baseline |
| --- | --- | --- |
| `VWAPIndicator barCount` | 20-60 | 50-120 |
| `VWAPBand multiplier` | 1.5-2.0 | 2.0-2.5 |
| `VolumeProfileKDE lookback` | 100-200 | 150-300 |
| `VolumeProfileKDE bandwidth` | 0.25-0.75 (price-unit dependent) | 0.5-1.5 |
| `PriceCluster tolerance` | 0.1%-0.3% of price | 0.2%-0.6% of price |
| Wyckoff volume windows | 5 / 20 | 10 / 40 |

## Common mistakes

- Using these indicators without unstable-bar gating.
- Mixing incompatible scales (absolute tolerance values across very different price levels).
- Treating Wyckoff phase output as deterministic instead of probabilistic.
- Ignoring volume quality for instruments with fragmented/poor feed volume.

## Integration checklist

- [ ] Warmup bars computed from all dependencies.
- [ ] Fees/slippage configured.
- [ ] Parameter sweep completed on out-of-sample data.
- [ ] Live restart behavior tested.
- [ ] Monitoring alerts for phase flips and stretched VWAP z-scores.

## Related pages

- [Technical Indicators](Technical-indicators.md)
- [Indicators Inventory](Indicators-Inventory.md)
- [Backtesting](Backtesting.md)
- [Live Trading](Live-trading.md)
- [Usage Examples](Usage-examples.md)
