# Trading Strategies

A strategy in ta4j pairs **entry** and **exit** rules to generate trades. This section explains how to model those rules, combine them into reusable strategies, and run the same logic across quick backtests, batch optimization, and live or paper adapters built on the unified `BaseTradingRecord` stack.

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
- Since 0.19 you can use `VoteRule` to require agreement between multiple rules (e.g., "at least 3 out of 5 oscillators must agree"). In 0.21.0, return representation is unified across all criteria for consistent formatting.
- `InSlopeRule` is satisfied when the slope of one indicator is within a boundary of another (e.g. for trend strength or momentum alignment).

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
        .or(new StopLossRule(closePrice, numOf(3)))
        .or(new StopGainRule(closePrice, numOf(5)));
```

This configuration fires an **entry** when at least two of the following hold on the same bar:
1. `sma200 > sma400` (trend filter says the long-term trend is up),
2. MACD crosses above its signal line (momentum confirmation), or
3. The Renko brick detector sees an upside breakout.

On top of that vote, the Net Momentum indicator must be above zero so entries only happen when breadth is positive.
The **exit** side first evaluates `timedMomentumExit`, an `OrWithThresholdRule` over a 3-bar window: it triggers when either MACD crosses below its signal line or the Net Momentum slope rule (`InSlopeRule(netMomentum, 3, -10)`) is satisfied within that same 3-bar window.
That combined rule is then OR'd with `StopLossRule(closePrice, numOf(3))` and `StopGainRule(closePrice, numOf(5))` as hard risk/profit boundaries.

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

## Build a strategy

```java
Strategy strategy = new BaseStrategy("SMA + MACDV hybrid", entryRule, exitRule);
strategy.setUnstableBars(30); // optional: indicators already report their own unstable window
```

Running it is identical regardless of complexity:

```java
BarSeriesManager manager = new BarSeriesManager(series);
TradingRecord record = manager.run(strategy);
```

`BarSeriesManager` wires your entry/exit rules to simulated orders, applies the configured cost/execution models, and returns a `TradingRecord` containing every trade so you can plug it into analysis criteria or the charting workflow documented in [Backtesting](Backtesting.md#visualize-your-backtests).

The same strategy class can be used in [backtests](Backtesting.md) and [live trading](Live-trading.md) contexts.

## Execution models and trading records

The strategy itself stays the same; the execution path around it is what changes.

```java
BaseTradingRecord providedRecord = new BaseTradingRecord(
        strategy.getStartingType(),
        ExecutionMatchPolicy.FIFO,
        new ZeroCostModel(),
        new ZeroCostModel(),
        series.getBeginIndex(),
        series.getEndIndex());

BarSeriesManager manager = new BarSeriesManager(
        series,
        new ZeroCostModel(),
        new ZeroCostModel(),
        new TradeOnCurrentCloseModel());

manager.run(strategy, providedRecord, series.numFactory().one(), series.getBeginIndex(), series.getEndIndex());
```

- Use the default `BarSeriesManager` setup when next-bar-open fills match your strategy assumptions.
- Switch to `TradeOnCurrentCloseModel` when you want closed-bar live bots and backtests to line up more closely.
- Reach for `SlippageExecutionModel` or `StopLimitExecutionModel` when you need explicit execution realism instead of idealized fills.
- Provide your own `BaseTradingRecord` when you want one record model across replays, walk-forward runs, live fills, and downstream persistence.
- In live or paper trading, the strategy should still evaluate `shouldEnter(...)` / `shouldExit(...)` against the current record, but the record itself should only be updated from confirmed fills.

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

Use `StrategySerialization` to persist and reload strategies:

```java
String json = StrategySerialization.toJson(strategy);
Strategy restored = StrategySerialization.fromJson(series, json);
```

That JSON payload captures the full rule graph, making it safe to persist strategies between runs, transmit them over an API, or archive the configuration used for a specific backtest run.

`NamedStrategy` variants generate compact IDs (`ToggleNamedStrategy_true_false_u3`) that you can store alongside backtest results or in configuration files.

## Execution context tips

- **Backtesting** – Inject custom `CostModel` implementations (for example `LinearTransactionCostModel`, `LinearBorrowingCostModel`) or a custom `TradeExecutionModel` into `BarSeriesManager` to simulate commissions, slippage, close-bar fills, or stop-limit behavior accurately.
- **Parity replays** – Use `BarSeriesManager.run(strategy, providedRecord, ...)` or `TradingRecordParityBacktest` when you want the exact same `BaseTradingRecord` configuration used across test and live-facing code.
- **Live trading** – Feed real-time bars into a moving `BarSeries`, call `strategy.shouldEnter(index, record)` / `shouldExit(...)`, send the order to your broker, then append the confirmed `TradeFill` or `Trade` back onto `BaseTradingRecord` (see [Live Trading](Live-trading.md)).
- **Diagnostics** – Mirror the approach in `ta4jexamples.logging.StrategyExecutionLogging` to trace which rule triggered each trade.

## Best practices

- Normalize indicator scales when combining oscillators with price-based rules.
- Use `strategy.setUnstableBars(...)` (optional now that indicators track `getCountOfUnstableBars()`) and/or `Indicator.isStable()` to avoid acting before indicators warm up.
- Encapsulate repeated rule snippets into helper methods or custom `Rule` implementations—readability matters when strategies grow complex.
- Keep entry/exit rules symmetric when building short strategies; for short-only operation, construct your strategy with starting type `TradeType.SELL`.
- When mixing timeframes or data sources, align them into the same `BarSeries` (or into multiple series managed by your own coordinator) to avoid implicit look-ahead.
