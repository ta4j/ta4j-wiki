# Stop Loss and Stop Gain Rules

ta4j now provides a full stop-rule toolkit that covers fixed %, fixed amount, trailing variants, and volatility/ATR-adaptive variants for both loss and gain exits.

Use this page as the operational guide for:

- Choosing the right stop type for your strategy style.
- Wiring stop rules into strategy exits.
- Applying stop logic safely in live trading.

## Rule families

### Fixed percentage (classic)

- `StopLossRule`
- `StopGainRule`
- `TrailingStopLossRule`
- `TrailingStopGainRule`

These use percentage distance from entry (or favorable move for trailing variants).

Best when:

- You want simple, interpretable risk limits.
- Price scale does not change dramatically over time.

### Fixed amount (flat-dollar / flat-price-distance)

- `FixedAmountStopLossRule`
- `FixedAmountStopGainRule`
- `TrailingFixedAmountStopLossRule`
- `TrailingFixedAmountStopGainRule`

These use an absolute price distance (for example: `$10` from reference).

Best when:

- Instruments trade in a stable price range.
- You size positions independently and want fixed distance exits.

### Volatility-driven

- `VolatilityStopLossRule`
- `VolatilityStopGainRule`
- `VolatilityTrailingStopLossRule`
- `VolatilityTrailingStopGainRule`
- `AverageTrueRangeStopLossRule`
- `AverageTrueRangeStopGainRule`
- `AverageTrueRangeTrailingStopLossRule`
- `AverageTrueRangeTrailingStopGainRule`

These use a dynamic threshold based on volatility indicators (typically ATR multiplied by a coefficient).

Best when:

- Volatility regimes shift frequently.
- You want stops that widen in high vol and tighten in low vol.

## Quick selection guide

- Trend-following swing systems:
  - Start with `AverageTrueRangeTrailingStopLossRule` for downside protection.
  - Pair with `TrailingStopGainRule` or `AverageTrueRangeTrailingStopGainRule` for profit capture.
- Mean-reversion systems:
  - Use tighter `StopLossRule` / `FixedAmountStopLossRule`.
  - Use non-trailing `StopGainRule` / `FixedAmountStopGainRule` at expected reversion targets.
- Intraday scalping:
  - Prefer fixed amount stops when spread/tick structure dominates.
  - Add a volatility stop fallback for regime changes.

## How to wire exits

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
ATRIndicator atr = new ATRIndicator(series, 14);

Rule riskExit = new AverageTrueRangeTrailingStopLossRule(close, atr, 2.0)
        .or(new AverageTrueRangeTrailingStopGainRule(close, atr, 3.0))
        .or(new StopLossRule(close, series.numFactory().numOf(1.5))); // hard fail-safe

Rule signalExit = new CrossedDownIndicatorRule(fast, slow);
Rule exitRule = signalExit.or(riskExit);

Strategy strategy = new BaseStrategy(entryRule, exitRule);
```

Notes:

- Keep one hard fail-safe stop even when using adaptive stops.
- Avoid stacking many correlated stop rules unless each has a distinct purpose.

## Using stop-price models for risk analytics

Several rules implement:

- `StopLossPriceModel`
- `StopGainPriceModel`

This lets you query stop prices directly (for example in risk budgeting or custom position sizing flows) without duplicating threshold math.

## Live trading usage patterns

### 1) Match your reference price to execution reality

- If broker triggers on last trade, using `ClosePriceIndicator` may be acceptable.
- If broker triggers on bid/ask or mark/index price, use a matching indicator source.
- Do not mix trigger source and backtest source silently.

### 2) Decide bar-close vs intrabar evaluation

- Bar-close only:
  - Fewer false triggers, easier reproducibility.
  - Slower reaction.
- Intrabar (tick/stream updates):
  - Faster protection.
  - More noise and higher order churn.

Pick one model explicitly and keep it consistent between research and production.

### 3) Protect against gaps and slippage

- Stops are trigger conditions, not guaranteed fills.
- Plan with slippage cushions:
  - tighter position sizing,
  - broker-native stop/stop-limit where possible,
  - exchange outage safeguards.

### 4) Avoid stop churn

- Trailing rules can move often in noisy markets.
- Add guardrails:
  - minimum update interval,
  - minimum stop delta before replace,
  - cancel/replace rate limits.

### 5) Keep a stop hierarchy

- Primary logic stop (strategy-level)
- Catastrophic fail-safe stop
- Portfolio kill-switch (max drawdown / exposure limit)

Do not rely on a single mechanism.

## Parameter tuning tips

- ATR period:
  - shorter (`7-14`) reacts quickly,
  - longer (`20-50`) is smoother and slower.
- ATR coefficient:
  - lower values stop out earlier,
  - higher values reduce churn but increase average loss size.
- Trailing lookback (`barCount` where applicable):
  - short lookback tightens quickly,
  - long lookback gives trends more room.

Practical tuning workflow:

1. Optimize for robustness first, not max return.
2. Validate on multiple volatility regimes.
3. Compare with realistic fees/slippage.
4. Stress test gap days and high-spread windows.

## Common mistakes

- Using fixed % stops on instruments with changing volatility regimes and no adaptive fallback.
- Using adaptive stops without a maximum loss cap.
- Overfitting stop parameters to one market period.
- Backtesting on close-only, then trading on tick-level without recalibration.
- Ignoring order semantics (partial fills, reduce-only, stop-limit miss risk).

## Live deployment checklist

- Confirm stop trigger source (`last`, `bid/ask`, `mark/index`) matches indicator input.
- Confirm order type behavior on your venue.
- Confirm replacement throttling and retry logic.
- Confirm persistence and restart behavior for open positions and trailing state.
- Confirm metrics/alerts for stop-trigger frequency, slippage, and rejected orders.

See also:

- [Trading Strategies](Trading-strategies.md)
- [Live Trading](Live-trading.md)
- [Backtesting](Backtesting.md)
