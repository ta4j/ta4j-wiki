# Trading Strategies

A strategy in ta4j pairs **entry** and **exit** rules to generate trades. This section explains how to model those rules, combine them into reusable strategies, and take advantage of the current 0.22.x strategy and rule APIs.

## Trading rules

Rules implement the [Specification pattern](https://en.wikipedia.org/wiki/Specification_pattern). They answer a single question: *“Is the condition satisfied at index `i` given the current trading record?”*

```java
BarSeries series = new BaseBarSeriesBuilder().withName("sample").build();
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
Num resistanceLevel = series.numFactory().numOf(120);
Num supportLevel = series.numFactory().numOf(100);

Rule breakout = new CrossedUpIndicatorRule(closePrice, resistanceLevel);
Rule pullback = new CrossedDownIndicatorRule(closePrice, supportLevel);

if (breakout.isSatisfied(index, tradingRecord)) {
    // do something with the signal
}
```

`breakout` fires on the exact bar where price closes above the resistance factor, whereas `pullback` reacts when price slips beneath support. Because every call receives the latest `TradingRecord`, you can extend these primitives into stateful policies (skip long signals when a position is already open, enforce cooling-off periods, etc.).

Key points:

- `Rule#isSatisfied(int index)` is stateless. Pass the `TradingRecord` when the rule depends on open positions or previous signals.
- Composition is fluent (`and`, `or`, `xor`, `negation`), making it easy to express “enter when fast SMA crosses slow SMA **and** RSI recovers above 40.”
- For windowed boolean composition across the last `N` bars, use `AndWithThresholdRule` / `OrWithThresholdRule` (introduced in 0.22.2). These are explicit rule classes rather than overloads on `and(...)` / `or(...)`.
- Since 0.19 you can use `VoteRule` to require agreement between multiple rules (e.g., "at least 3 out of 5 oscillators must agree"). Return-format control is handled in criteria via `ReturnRepresentation` / `ReturnRepresentationPolicy` (`@since 0.20`).
- `InSlopeRule` is satisfied when the indicator slope (current minus prior value over `nthPrevious` bars) is within configured min/max slope bounds.

## Compose richer logic

```java
Rule trendFilter = new OverIndicatorRule(sma200, sma400);
Rule momentumKick = new CrossedUpIndicatorRule(macd, signalLine);
Rule renkoBreak = new BooleanIndicatorRule(new RenkoUpIndicator(closePrice, brickSize, 2));

RSIIndicator rsi = new RSIIndicator(closePrice, 14);
Indicator<Num> netMomentum = NetMomentumIndicator.forRsi(rsi, 20);
Rule entryRule = new VoteRule(2, trendFilter, momentumKick, renkoBreak)
        .and(new OverIndicatorRule(netMomentum, series.numFactory().zero()));

Rule timedMomentumExit = new OrWithThresholdRule(
        new CrossedDownIndicatorRule(macd, signalLine),
        new InSlopeRule(netMomentum, 3, series.numFactory().numOf("-10")),
        3);
Rule exitRule = timedMomentumExit
        .or(new StopLossRule(closePrice, series.numFactory().numOf(3)))
        .or(new StopGainRule(closePrice, series.numFactory().numOf(5)));
```

This configuration fires an **entry** when at least two of the following hold on the same bar:
1. `sma200 > sma400` (trend filter says the long-term trend is up),
2. MACD crosses above its signal line (momentum confirmation), or
3. The Renko brick detector sees an upside breakout.

On top of that vote, the Net Momentum indicator must be above zero so entries only happen when breadth is positive.
The **exit** side first evaluates `timedMomentumExit`, an `OrWithThresholdRule` over a 3-bar window: it triggers when either MACD crosses below its signal line or the Net Momentum slope rule (`InSlopeRule(netMomentum, 3, -10)`) is satisfied within that same 3-bar window.
That combined rule is then OR'd with `StopLossRule(closePrice, series.numFactory().numOf(3))` and `StopGainRule(closePrice, series.numFactory().numOf(5))` as hard risk/profit boundaries.

For the full stop toolkit (fixed %, fixed amount, trailing, volatility, ATR) and live-trading usage guidance, see [Stop Loss & Stop Gain Rules](Stop-Loss-and-Stop-Gain-Rules.md).

Use numeric indicator helpers like `BinaryOperationIndicator` and `UnaryOperationIndicator` when you need on-the-fly math (ratios, differences, powers) without writing custom indicator classes—each helper still benefits from caching.

## Risk-reward and threshold-aware composition (0.22.2+)

For setups where timing and trade quality are both important, combine the newer threshold-aware rules with stop/target models:

```java
Rule minRewardToRisk = new RiskRewardRatioRule(closePrice, stopIndicator, targetIndicator, true, 2.0);
Rule stateGate = new OverOrEqualIndicatorRule(rsi, 50);
Rule notOverSold = new UnderOrEqualIndicatorRule(rsi, 30).negation();
Rule signalWindow = new OrWithThresholdRule(macdCrossUp, breakoutRule, 3);

Rule entryRule = minRewardToRisk.and(stateGate).and(notOverSold).and(signalWindow);
```

- `RiskRewardRatioRule`: rejects bars where stop/target geometry is not attractive enough.
- `OverOrEqualIndicatorRule` / `UnderOrEqualIndicatorRule`: include boundary values (`>=` / `<=`) instead of strict comparisons.
- `OrWithThresholdRule`: lets either condition satisfy within a recent bar window, reducing missed entries from one-bar misalignment.

## MACD-V momentum-state filters (0.22.3)

`org.ta4j.core.indicators.macd.MACDVIndicator` now ships with momentum-state helpers you can wire directly into rules.

```java
MACDVIndicator macdv = new MACDVIndicator(series, 12, 26, 9);
MACDVMomentumStateIndicator state = new MACDVMomentumStateIndicator(
        macdv,
        MACDVMomentumProfile.defaultProfile()); // +50/+150/-50/-150

Rule bullishState = new MomentumStateRule(state, MACDVMomentumState.RALLYING_OR_RETRACING)
        .or(new MomentumStateRule(state, MACDVMomentumState.HIGH_RISK));
Rule macdCrossUp = macdv.crossedUpSignal();
Rule entryRule = macdCrossUp.and(bullishState);
```

This pattern keeps entries aligned with MACD-V regime and avoids triggering signal-line crosses during weak/ranging states.
For a maintained end-to-end example, see `ta4jexamples.strategies.MACDVMomentumStateStrategy`.

## Time-based filters

When strategy behavior should depend on trading session structure, combine rule logic with time-based gates:

```java
DateTimeIndicator time = new DateTimeIndicator(series, Bar::getEndTime);
Rule sessionWindow = new TimeRangeRule(
        List.of(new TimeRangeRule.TimeRange(LocalTime.of(9, 30), LocalTime.of(16, 0))),
        time);
Rule entryHour = new HourOfDayRule(time, 10);
Rule entryMinute = new MinuteOfHourRule(time, 5);

Rule entryRule = signalRule.and(sessionWindow).and(entryHour).and(entryMinute);
```

These rules evaluate against UTC hour/minute values from the indicator's `Instant`. For exchange-local sessions, normalize timestamps to your target timezone before they reach the series, or provide a transformed time indicator that emits the desired session-aligned `Instant`.
These rules are useful for opening-range breakouts, avoiding illiquid session tails, and separating overnight vs regular-hours behavior.

## Build a strategy

```java
Strategy strategy = new BaseStrategy("SMA + MACDV hybrid", entryRule, exitRule);
strategy.setUnstableBars(30); // optional: indicators already report their own unstable window
```

For short-first strategies, set the starting trade type on the strategy itself:

```java
Strategy shortOnly = new BaseStrategy("Short breakdown", shortEntryRule, shortExitRule, Trade.TradeType.SELL);
```

Running it is identical regardless of complexity:

```java
BarSeriesManager manager = new BarSeriesManager(series);
TradingRecord record = manager.run(strategy);
```

`BarSeriesManager` wires your entry/exit rules to simulated orders, uses `strategy.getStartingType()` by default, applies the configured cost/execution models, and returns a `TradingRecord` containing every trade so you can plug it into analysis criteria or the charting workflow documented in [Backtesting](Backtesting.md#visualize-and-sanity-check-your-results).

The same strategy class can be used in [backtests](Backtesting.md) and [live trading](Live-trading.md) contexts.

## Parameterizing and Named strategies

For reusable presets, implement `NamedStrategy`. The new registry system keeps constructor discovery fast and supports permutations:

```java
public final class SmaCrossNamedStrategy extends NamedStrategy {
    static {
        registerImplementation(SmaCrossNamedStrategy.class);
    }

    public SmaCrossNamedStrategy(BarSeries series, int fastPeriod, int slowPeriod) {
        super(
            NamedStrategy.buildLabel(SmaCrossNamedStrategy.class,
                    String.valueOf(fastPeriod), String.valueOf(slowPeriod)),
            entryRule(series, fastPeriod, slowPeriod),
            exitRule(series, fastPeriod, slowPeriod));
    }

    public SmaCrossNamedStrategy(BarSeries series, String... params) {
        this(series, Integer.parseInt(params[0]), Integer.parseInt(params[1]));
    }

    private static Rule entryRule(BarSeries series, int fastPeriod, int slowPeriod) {
        ClosePriceIndicator close = new ClosePriceIndicator(series);
        return new CrossedUpIndicatorRule(
                new SMAIndicator(close, fastPeriod),
                new SMAIndicator(close, slowPeriod));
    }

    private static Rule exitRule(BarSeries series, int fastPeriod, int slowPeriod) {
        ClosePriceIndicator close = new ClosePriceIndicator(series);
        return new CrossedDownIndicatorRule(
                new SMAIndicator(close, fastPeriod),
                new SMAIndicator(close, slowPeriod));
    }
}

NamedStrategy.initializeRegistry("com.example.strategies");
List<Strategy> presets = NamedStrategy.buildAllStrategyPermutations(
        series,
        List.of(new String[] { "14", "50" }, new String[] { "20", "100" }),
        SmaCrossNamedStrategy::new);
```

In practice the registry maps compact labels (for example `SmaCrossNamedStrategy_14_50`) back to indicator wiring during serialization/deserialization, while permutation builders let you generate parameter grids without touching strategy logic.

This is ideal for:

- Sharing strategies between teammates or environments.
- Running parameter grids with the `BacktestExecutor`.
- Building UI pickers that let non-developers tune parameters safely.

## Serializing strategies

Use the `Strategy` convenience methods to persist and reload strategies:

```java
String json = strategy.toJson();
Strategy restored = Strategy.fromJson(series, json);
```

That JSON payload captures the full rule graph, making it safe to persist strategies between runs, transmit them over an API, or archive the configuration used for a specific backtest run. Use `rule.toJson()` and `Rule.fromJson(series, json)` when you only need to persist one rule subtree.

`NamedStrategy` variants generate compact IDs (`ToggleNamedStrategy_true_false_u3`) that you can store alongside backtest results or in configuration files.

## Execution context tips

- **Backtesting** – Inject custom `CostModel` implementations (for example `LinearTransactionCostModel`, `LinearBorrowingCostModel`) or a custom `TradeExecutionModel` into `BarSeriesManager` to simulate slippage and commissions accurately.
- **Live trading** – Feed real-time bars into a moving `BarSeries`, call `strategy.shouldEnter(index, record)` / `shouldExit(...)`, then execute trades through your broker (see [Live Trading](Live-trading.md)).
- **Diagnostics** – Mirror the approach in `ta4jexamples.logging.StrategyExecutionLogging` to trace which rule triggered each trade.

## Best practices

- Normalize indicator scales when combining oscillators with price-based rules.
- Use `strategy.setUnstableBars(...)` (optional now that indicators track `getCountOfUnstableBars()`) and/or `Indicator.isStable()` to avoid acting before indicators warm up.
- Encapsulate repeated rule snippets into helper methods or custom `Rule` implementations—readability matters when strategies grow complex.
- Keep entry/exit rules symmetric when building short strategies; for short-only operation, construct your strategy with starting type `TradeType.SELL`.
- When mixing timeframes or data sources, align them into the same `BarSeries` (or into multiple series managed by your own coordinator) to avoid implicit look-ahead.

## Maintainer rationale notes

- Clarified `InSlopeRule` semantics to match the actual implementation in `org.ta4j.core.rules.InSlopeRule` (difference vs. `PreviousValueIndicator`, optional min/max bounds).
- Kept threshold/voting composition guidance aligned with `AndWithThresholdRule` / `OrWithThresholdRule` (commit `5e5acc99`) and `VoteRule` (commit `cca0bb02`).
- Kept MACD-V regime examples aligned with `MomentumStateRule` and `MACDVMomentumStateStrategy` updates (commit `161f7656`).
- Short-first guidance follows `Strategy#getStartingType()` and `BaseStrategy(..., TradeType)` from commit `b112d34b`.
- Serialization examples now use `Strategy#toJson()`, `Strategy.fromJson(...)`, `Rule#toJson()`, and `Rule.fromJson(...)` from `org.ta4j.core.Strategy` / `org.ta4j.core.Rule` rather than only the lower-level `StrategySerialization` API introduced in commit `b62d9bad`.
