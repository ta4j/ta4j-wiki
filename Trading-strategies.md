# Trading Strategies

A strategy in ta4j pairs **entry** and **exit** rules to generate trades. This section explains how to model those rules, combine them into reusable strategies, and take advantage of features introduced in 0.19 and enhanced in 0.21.0.

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
- Since 0.19 you can use `VoteRule` to require agreement between multiple rules (e.g., "at least 3 out of 5 oscillators must agree"). Return formatting can be controlled globally via `ReturnRepresentationPolicy` or per criterion via `ReturnRepresentation`.
- `InSlopeRule` is satisfied when an indicator slope falls within configured numeric bounds (e.g. for trend strength or momentum alignment).
- `HourOfDayRule` and `MinuteOfHourRule` let you gate entries/exits to explicit time windows without custom calendar code.

## Compose richer logic

```java
Rule trendFilter = new OverIndicatorRule(sma200, sma400);
Rule momentumKick = new CrossedUpIndicatorRule(macd, signalLine);
Rule renkoBreak = new BooleanIndicatorRule(new RenkoUpIndicator(series, brickSize));

Indicator<Num> netMomentum = new NetMomentumIndicator(series);
Rule entryRule = new VoteRule(2, trendFilter, momentumKick, renkoBreak)
        .and(new OverIndicatorRule(netMomentum, series.numFactory().zero()));

Rule exitRule = new CrossedDownIndicatorRule(macd, signalLine)
        .or(new StopLossRule(closePrice, numOf(3)))
        .or(new StopGainRule(closePrice, numOf(5)));
```

This configuration fires an **entry** when at least two of the following hold on the same bar:
1. `sma200 > sma400` (trend filter says the long-term trend is up),
2. MACD crosses above its signal line (momentum confirmation), or
3. The Renko brick detector sees an upside breakout.

On top of that vote, the Net Momentum indicator must be above zero so entries only happen when breadth is positive.  
The **exit** rule triggers if MACD crosses below its signal line, price falls 3% from the entry (`StopLossRule`), or price rallies 5% (`StopGainRule`).

For the full stop toolkit (fixed %, fixed amount, trailing, volatility, ATR) and live-trading usage guidance, see [Stop Loss & Stop Gain Rules](Stop-Loss-and-Stop-Gain-Rules.md).

Use numeric indicator helpers like `BinaryOperationIndicator` and `UnaryOperationIndicator` when you need on-the-fly math (ratios, differences, powers) without writing custom indicator classes—each helper still benefits from caching.

## Threshold composition and risk guards (0.22.2+)

Recent ta4j releases added rule primitives that let you express lookback-window conjunction/disjunction and explicit reward-to-risk gating without custom rule classes.

```java
Rule trigger = new CrossedUpIndicatorRule(fast, slow);
Rule momentum = new OverOrEqualIndicatorRule(rsi, numOf(50));
Rule trend = new OverOrEqualIndicatorRule(closePrice, sma200);

// Entry is valid if BOTH rules have been satisfied at least once in the last 3 bars.
Rule entryRule = new AndWithThresholdRule(trigger, momentum.and(trend), 3);

Indicator<Num> stopPrice = new ConstantIndicator<>(series, numOf(95));
Indicator<Num> targetPrice = new ConstantIndicator<>(series, numOf(110));
Rule rrFloor = new RiskRewardRatioRule(closePrice, stopPrice, targetPrice, true, numOf(2.0));

// Exit is valid if EITHER condition has been satisfied at least once in the last 2 bars.
Rule protectiveExit = new OrWithThresholdRule(
        new UnderOrEqualIndicatorRule(closePrice, stopPrice),
        new OverOrEqualIndicatorRule(closePrice, targetPrice),
        2
).and(rrFloor);
```

Use these when:

- You want two logical branches to be considered satisfied if they occur anywhere inside a rolling window (`AndWithThresholdRule` / `OrWithThresholdRule`).
- You need inclusive comparisons (`>=` or `<=`) with `OverOrEqualIndicatorRule` / `UnderOrEqualIndicatorRule` to avoid strict inequality misses at exact levels.
- You want entries or exits gated by a minimum projected reward-to-risk ratio via `RiskRewardRatioRule`.

Compared with `VoteRule`, threshold rules evaluate two pre-composed branches over a lookback window, so they are often clearer for "condition A and condition B happened recently" logic.

For Elliott-wave workflows, ta4j also ships scenario-aware rules in `org.ta4j.core.rules.elliott` (for example `ElliottScenarioValidRule`, `ElliottScenarioDirectionRule`, `ElliottScenarioRiskRewardRule`, `ElliottTrendBiasRule`, `ElliottImpulsePhaseRule`) so you can gate entries by wave validity, direction, and risk/reward state.

> Rationale (drift sync): Elliott scenario and trend-bias rule coverage expanded in commit `bebb758e`.

> Rationale (drift sync): threshold/window rules and serialization/time rule additions came in commit `b62d9bad`, including `AndWithThresholdRule`, `OrWithThresholdRule`, `HourOfDayRule`, and `MinuteOfHourRule`.

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

## Build a strategy

```java
Strategy strategy = new BaseStrategy("SMA + MACDV hybrid", entryRule, exitRule);
strategy.setUnstableBars(30); // optional: indicators already report their own unstable window
```

You can also choose short-first execution by defining the strategy starting type:

```java
Strategy shortFirst = new BaseStrategy(
        "short breakout",
        entryRule,
        exitRule,
        Trade.TradeType.SELL);
```

Running it is identical regardless of complexity:

```java
BarSeriesManager manager = new BarSeriesManager(series);
TradingRecord record = manager.run(strategy);
```

`BarSeriesManager` wires your entry/exit rules to simulated orders, applies the configured cost/execution models, and returns a `TradingRecord` containing every trade so you can plug it into analysis criteria or ChartMaker visualizations.

> Rationale (drift sync): `Strategy#getStartingType()` and `BaseStrategy(..., TradeType startingType)` are now first-class, and `org.ta4j.core.backtest.BarSeriesManager#run(Strategy)` defaults to `strategy.getStartingType()` (commit `b112d34b`).

The same strategy class can be used in [backtests](Backtesting.md) and [live trading](Live-trading.md) contexts.

## Parameterizing and Named strategies

For reusable presets, implement `NamedStrategy`. The new registry system keeps constructor discovery fast and supports permutations:

```java
public final class SmaCrossNamedStrategy extends NamedStrategy {
    public SmaCrossNamedStrategy(BarSeries series, int fastPeriod, int slowPeriod) {
        super(buildLabel(
                SmaCrossNamedStrategy.class,
                String.valueOf(fastPeriod),
                String.valueOf(slowPeriod)),
                entryRule(series, fastPeriod, slowPeriod),
                exitRule(series, fastPeriod, slowPeriod));
    }

    public SmaCrossNamedStrategy(BarSeries series, String... parameters) {
        this(series, Integer.parseInt(parameters[0]), Integer.parseInt(parameters[1]));
    }

    private static Rule entryRule(BarSeries series, int fastPeriod, int slowPeriod) {
        ClosePriceIndicator close = new ClosePriceIndicator(series);
        SMAIndicator fast = new SMAIndicator(close, fastPeriod);
        SMAIndicator slow = new SMAIndicator(close, slowPeriod);
        return new CrossedUpIndicatorRule(fast, slow);
    }

    private static Rule exitRule(BarSeries series, int fastPeriod, int slowPeriod) {
        ClosePriceIndicator close = new ClosePriceIndicator(series);
        SMAIndicator fast = new SMAIndicator(close, fastPeriod);
        SMAIndicator slow = new SMAIndicator(close, slowPeriod);
        return new CrossedDownIndicatorRule(fast, slow);
    }
}

NamedStrategy.initializeRegistry(SmaCrossNamedStrategy.class.getPackageName());
Strategy preset = new SmaCrossNamedStrategy(series, "14", "50");
Optional<Class<? extends NamedStrategy>> registered = NamedStrategy.lookup("SmaCrossNamedStrategy");
```

In practice the registry maps friendly identifiers (like `fast14_slow50`) back to indicator wiring, so front-ends, parameter sweeps, or config files can request a preset without touching the Java source.

> Rationale (drift sync): `RenkoUpIndicator` is an `Indicator<Boolean>` (`org.ta4j.core.indicators.renko.RenkoUpIndicator`), so it must be wrapped (for example with `BooleanIndicatorRule`) before `VoteRule` use. `NamedStrategy.lookup(...)` returns `Optional<Class<? extends NamedStrategy>>` (no `.instantiate(...)` API) in `org.ta4j.core.strategy.named.NamedStrategy`; registry/lookup behavior came from commits `eaeecdb2` and `87d6a227`.

This is ideal for:

- Sharing strategies between teammates or environments.
- Running parameter grids with the `BacktestExecutor`.
- Building UI pickers that let non-developers tune parameters safely.

## Serializing strategies

Use `StrategySerialization` to persist and reload strategies:

```java
String json = StrategySerialization.toJson(strategy);
Strategy restored = StrategySerialization.fromJson(series, json);
```

That JSON payload captures the full rule graph, making it safe to persist strategies between runs, transmit them over an API, or archive the configuration used for a specific backtest run.

`NamedStrategy` variants generate compact IDs (`ToggleNamedStrategy_true_false_u3`) that you can store alongside backtest results or in configuration files.

## Execution context tips

- **Backtesting** – Inject custom `TransactionCostModel`, `HoldingCostModel`, or `TradeExecutionModel` into `BarSeriesManager` to simulate slippage and commissions accurately.
- **Live trading** – Feed real-time bars into a moving `BarSeries`, call `strategy.shouldEnter(index, record)` / `shouldExit(...)`, then execute trades through your broker (see [Live Trading](Live-trading.md)).
- **Diagnostics** – Mirror the approach in `ta4jexamples.logging.StrategyExecutionLogging` to trace which rule triggered each trade.

## Best practices

- Normalize indicator scales when combining oscillators with price-based rules.
- Use `strategy.setUnstableBars(...)` (optional now that indicators track `getCountOfUnstableBars()`) and/or `Indicator.isStable()` to avoid acting before indicators warm up.
- Encapsulate repeated rule snippets into helper methods or custom `Rule` implementations—readability matters when strategies grow complex.
- Keep entry/exit rules symmetric when building short strategies, or keep separate long/short `Strategy` instances and run them with the desired `TradeType`.
- When mixing timeframes or data sources, align them into the same `BarSeries` (or into multiple series managed by your own coordinator) to avoid implicit look-ahead.
