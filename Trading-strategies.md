# Trading Strategies

A strategy in ta4j pairs **entry** and **exit** rules to generate trades. This section explains how to model those rules, combine them into reusable strategies, and take advantage of new features introduced in 0.19.

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
- Since 0.19 you can use `VoteRule` to require agreement between multiple rules (e.g., “at least 3 out of 5 oscillators must agree”).

## Compose richer logic

```java
Rule trendFilter = new OverIndicatorRule(sma200, sma400);
Rule momentumKick = new CrossedUpIndicatorRule(macd, signalLine);
Rule renkoBreak = new RenkoUpIndicator(series, brickSize);

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

Use numeric indicator helpers like `BinaryOperationIndicator` and `UnaryOperationIndicator` when you need on-the-fly math (ratios, differences, powers) without writing custom indicator classes—each helper still benefits from caching.

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

`BarSeriesManager` wires your entry/exit rules to simulated orders, applies the configured cost/execution models, and returns a `TradingRecord` containing every trade so you can plug it into analysis criteria or ChartMaker visualizations.

The same strategy class can be used in [backtests](Backtesting.md) and [live trading](Live-trading.md) contexts.

## Parameterizing and Named strategies

For reusable presets, implement `NamedStrategy`. The new registry system keeps constructor discovery fast and supports permutations:

```java
public final class SmaCrossNamedStrategy extends NamedStrategy {
    @Override
    protected Strategy build(BarSeries series) {
        ClosePriceIndicator close = new ClosePriceIndicator(series);
        SMAIndicator fast = new SMAIndicator(close, parameters().getInt("fastPeriod"));
        SMAIndicator slow = new SMAIndicator(close, parameters().getInt("slowPeriod"));
        return new BaseStrategy(entryRule(fast, slow), exitRule(fast, slow));
    }
}

NamedStrategy.initializeRegistry(SmaCrossNamedStrategy.class.getPackageName());
Strategy preset = NamedStrategy.lookup("SmaCrossNamedStrategy_fast14_slow50").instantiate(series);
```

In practice the registry maps friendly identifiers (like `fast14_slow50`) back to indicator wiring, so front-ends, parameter sweeps, or config files can request a preset without touching the Java source.

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
- Keep entry/exit rules symmetric when building short strategies, or wrap separate long/short strategies via `CombinedBuySellStrategy`.
- When mixing timeframes or data sources, align them into the same `BarSeries` (or into multiple series managed by your own coordinator) to avoid implicit look-ahead.
