# Live Trading

> ⚠️ **Early days:** ta4j’s live-trading story is still evolving. The APIs below are intentionally bare bones and require custom glue (data ingestion, order routing, resilience) on your side. Treat this as a starting point rather than a fully featured framework.

ta4j is not just for backtests—its abstractions map directly onto production trading bots. This page outlines how to bootstrap a live engine, keep your `BarSeries` synchronized with the exchange, and execute trades responsibly.

## Architecture overview

1. **Initialization** – load recent history to warm up indicators, build your [bar series](Bar-series-and-bars.md), and instantiate the [strategy](Trading-strategies.md).
2. **Event loop** – append/update bars, evaluate entry/exit rules at `series.getEndIndex()`, and send orders to your broker.
3. **State persistence** – serialize strategies, parameters, and trading records so the bot can restart without losing context.

## Initialization checklist

- **Fetch historical bars** (at least as many as the highest indicator lookback). Without this, the first signals may be garbage.
- **Choose a `Num` implementation** consistent with your broker’s precision (decimal for FX/crypto, double for faster equity bots).
- **Set `setMaximumBarCount(n)`** to cap memory while keeping enough bars to cover every indicator period.
- **Wire costs** – configure `TransactionCostModel` and `HoldingCostModel` on your `BarSeriesManager` or strategy runner so live metrics align with backtest assumptions.

```java
BarSeries liveSeries = new BaseBarSeriesBuilder()
        .withName("binance_eth_usd_live")
        .withNumFactory(DecimalNumFactory.getInstance())
        .build();

liveSeries.setMaximumBarCount(500);
bootstrapWithRecentBars(liveSeries, exchangeClient);

Strategy strategy = strategyFactory.apply(liveSeries);
TradingRecord tradingRecord = new BaseTradingRecord();
```

## Feeding the series

Most exchanges stream trades or candles you can convert into ta4j bars:

```java
Bar bar = liveSeries.barBuilder()
        .timePeriod(Duration.ofMinutes(1))
        .endTime(candle.closeTime())
        .openPrice(candle.open())
        .highPrice(candle.high())
        .lowPrice(candle.low())
        .closePrice(candle.close())
        .volume(candle.volume())
        .build();

liveSeries.addBar(bar);
```

When updates arrive before the bar closes:

```java
liveSeries.addTrade(liveSeries.numFactory().numOf(trade.volume()),
        liveSeries.numFactory().numOf(trade.price()));

// Or replace the last bar entirely if the exchange sends a revised candle
liveSeries.addBar(replacementBar, true);
```

## Evaluating and executing

```java
int endIndex = liveSeries.getEndIndex();
Num price = liveSeries.getBar(endIndex).getClosePrice();

if (strategy.shouldEnter(endIndex, tradingRecord)) {
    orderService.submitBuy(price, desiredQuantity());
    tradingRecord.enter(endIndex, price, desiredQuantity());
} else if (strategy.shouldExit(endIndex, tradingRecord)) {
    orderService.submitSell(price, openQuantity());
    tradingRecord.exit(endIndex, price, openQuantity());
}
```

Guidelines:

- Always check that `tradingRecord.isOpened()`/`isClosed()` lines up with your broker state. If an order is partially filled, delay updating the record until the fill completes.
- Consider using ta4j’s `TradeExecutionModel` implementations to simulate your broker’s order semantics before going live.
- Wrap the evaluation + execution block in robust error handling to avoid missing bars while recovering from exchange hiccups.

## Persistence & recovery

- **Strategy state** – Serialize strategies via `StrategySerialization.toJson(strategy)` or keep `NamedStrategy` descriptors in configuration. This ensures bots can reload the exact same logic after restarts.
- **Trading record** – Persist open positions, last processed bar timestamp, and PnL so you can resume without double-counting trades.
- **Bar snapshots** – If your infrastructure allows, periodically snapshot the latest `BarSeries` to disk or cache so warm restarts skip the backfill step.

## Monitoring & alerting

- Pipe trade events and key indicators to your logging/metrics stack—`StrategyExecutionLogging` from `ta4j-examples` is a good starting point.
- Track runtime stats (latency per bar, frequency of signals) to detect stalls early.
- Consider running a parallel backtest (e.g., via `BacktestExecutor`) on the most recent data to ensure live behavior matches expectations.

## Examples & references

- **[TradingBotOnMovingBarSeries](Usage-examples.md#bots--live-trading)** – minimal bot loop using a moving bar series.
- [Backtesting](Backtesting.md) – explains how to test cost models and execution assumptions before deploying.
- [Bar Series & Bars](Bar-series-and-bars.md) – details data ingestion, moving windows, and live updates.
