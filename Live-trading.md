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

### Choosing a trading record

- **`BaseTradingRecord`**: Simple list of positions (one entry + one exit per position). Use for backtests or live bots where every fill is treated as a single trade and you do not need per-lot cost basis or unrealized PnL. `BarSeriesManager.run(strategy)` returns a `BaseTradingRecord`.
- **`LiveTradingRecord`**: Supports partial fills, multiple lots per position, configurable execution matching (e.g. FIFO), and optional cost models. Use when you need cost basis, unrealized PnL, or a position book for live reconciliation. Thread-safe for concurrent ingestion and evaluation. See release notes for `Position`, `OpenPosition`, `Trade`, `PositionBook`, and related criteria (`OpenPositionCostBasisCriterion`, `OpenPositionUnrealizedProfitCriterion`).

### Walkthrough: LiveTradingRecord with partial fills and cost basis

When your broker reports partial fills or you want per-lot cost basis and unrealized PnL, use `LiveTradingRecord` instead of `BaseTradingRecord`. The following examples show the same API for simple enter/exit, then how to record individual fills and read the position book.

**1. Simple enter/exit (same as BaseTradingRecord)**

You can use `enter(index, price, amount)` and `exit(index, price, amount)` exactly like `BaseTradingRecord`. Each call records a single fill; the record stays compatible with all criteria and with `BarSeriesManager` if you drive it manually.

```java
LiveTradingRecord record = new LiveTradingRecord(Trade.TradeType.BUY);
Num price = series.getBar(endIndex).getClosePrice();
Num amount = series.numFactory().numOf(1);

if (strategy.shouldEnter(endIndex, record)) {
    record.enter(endIndex, price, amount);
} else if (strategy.shouldExit(endIndex, record)) {
    record.exit(endIndex, price, amount);
}
```

**2. Partial fills and position book**

When you receive fills from the broker one-by-one, record each fill with `recordFill(ExecutionFill)`. Use `ExecutionSide.BUY` / `ExecutionSide.SELL` and optional fee, order id, and correlation id. The record applies FIFO (or your configured `ExecutionMatchPolicy`) and maintains open lots.

```java
LiveTradingRecord record = new LiveTradingRecord(
    Trade.TradeType.BUY,
    ExecutionMatchPolicy.FIFO,
    new ZeroCostModel(),
    new ZeroCostModel(),
    null, null);

NumFactory num = series.numFactory();

// Two buy fills (e.g. from broker)
record.recordFill(new ExecutionFill(
    Instant.now(), num.numOf(100.0), num.numOf(0.5), num.zero(),
    ExecutionSide.BUY, "order-1", null));
record.recordFill(new ExecutionFill(
    Instant.now(), num.numOf(101.0), num.numOf(0.5), num.zero(),
    ExecutionSide.BUY, "order-2", null));

// Open position: two lots, average cost and total amount available
List<OpenPosition> openPositions = record.getOpenPositions();
OpenPosition net = record.getNetOpenPosition();
// net.amount(), net.averageEntryPrice(), net.costBasis(), etc.

// Exit (e.g. one full exit at current price – FIFO matches against first lot)
record.recordFill(new ExecutionFill(
    Instant.now(), num.numOf(102.0), num.numOf(1.0), num.zero(),
    ExecutionSide.SELL, "order-3", null));
```

**3. Cost basis and unrealized PnL with criteria**

After you have a `BarSeries` and a `LiveTradingRecord` (from live fills or from a custom backtest loop), you can measure cost basis and unrealized PnL with the same criteria used for analysis:

```java
BarSeries series = ...;   // your bar series
LiveTradingRecord record = ...;  // populated via enter/exit or recordFill
int endIndex = series.getEndIndex();

AnalysisCriterion costBasis = new OpenPositionCostBasisCriterion();
AnalysisCriterion unrealizedPnL = new OpenPositionUnrealizedProfitCriterion();

System.out.println("Open position cost basis: " + costBasis.calculate(series, record));
System.out.println("Unrealized PnL: " + unrealizedPnL.calculate(series, record));
```

Use `record.snapshot()` to capture a point-in-time view of positions and trades for persistence or auditing.

## Feeding the series

### Using ConcurrentBarSeries (recommended for live trading)

For live trading with concurrent access, `ConcurrentBarSeries` provides thread-safe trade ingestion:

#### Streaming trade ingestion

The recommended approach is to use `ingestTrade()` methods, which automatically aggregate trades into bars:

```java
// Simple trade ingestion
concurrentSeries.ingestTrade(
    trade.getTime(),
    trade.getVolume(),
    trade.getPrice()
);

// With side and liquidity classification (for RealtimeBar analytics)
concurrentSeries.ingestTrade(
    trade.getTime(),
    trade.getVolume(),
    trade.getPrice(),
    trade.getSide() == TradeSide.BUY ? RealtimeBar.Side.BUY : RealtimeBar.Side.SELL,
    trade.getLiquidity() == TradeLiquidity.TAKER ? RealtimeBar.Liquidity.TAKER : RealtimeBar.Liquidity.MAKER
);
```

The `ingestTrade()` methods automatically:
- Aggregate trades into bars using the configured `BarBuilder`
- Handle bar rollovers when thresholds are met
- Update the latest bar in-place or append new bars
- Maintain thread safety throughout

#### Streaming bar ingestion

For pre-aggregated candles (e.g., from WebSocket feeds):

```java
Bar candle = concurrentSeries.barBuilder()
        .timePeriod(Duration.ofMinutes(1))
        .endTime(candleData.closeTime())
        .openPrice(candleData.open())
        .highPrice(candleData.high())
        .lowPrice(candleData.low())
        .closePrice(candleData.close())
        .volume(candleData.volume())
        .build();

StreamingBarIngestResult result = concurrentSeries.ingestStreamingBar(candle);
// result.action() indicates: APPENDED, REPLACED_LAST, or REPLACED_HISTORICAL
```

### Using BaseBarSeries (single-threaded)

For single-threaded scenarios, you can still use the traditional approach:

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

### Single-threaded evaluation

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

### Multi-threaded evaluation with ConcurrentBarSeries

With `ConcurrentBarSeries`, you can safely evaluate strategies in a separate thread while another thread ingests data:

```java
// Thread 1: Ingest trades (runs continuously)
executorService.submit(() -> {
    while (running) {
        Trade trade = websocket.receiveTrade();
        concurrentSeries.ingestTrade(
            trade.getTime(),
            trade.getVolume(),
            trade.getPrice(),
            trade.getSide(),
            trade.getLiquidity()
        );
    }
});

// Thread 2: Evaluate strategy (runs on a schedule or trigger)
executorService.submit(() -> {
    while (running) {
        int endIndex = concurrentSeries.getEndIndex();
        if (endIndex < 0) continue; // No bars yet
        
        Num price = concurrentSeries.getBar(endIndex).getClosePrice();
        
        if (strategy.shouldEnter(endIndex, tradingRecord)) {
            orderService.submitBuy(price, desiredQuantity());
            tradingRecord.enter(endIndex, price, desiredQuantity());
        } else if (strategy.shouldExit(endIndex, tradingRecord)) {
            orderService.submitSell(price, openQuantity());
            tradingRecord.exit(endIndex, price, openQuantity());
        }
        
        Thread.sleep(100); // Or use a scheduled executor
    }
});
```

Guidelines:

- Always check that `tradingRecord.isOpened()`/`isClosed()` lines up with your broker state. If an order is partially filled, delay updating the record until the fill completes.
- Consider using ta4j’s `TradeExecutionModel` implementations to simulate your broker’s order semantics before going live.
- Wrap the evaluation + execution block in robust error handling to avoid missing bars while recovering from exchange hiccups.
- With `ConcurrentBarSeries`, multiple threads can safely read from the series concurrently (e.g., parallel strategy evaluation, indicator calculation).
- Use `ConcurrentBarSeries` when you need thread-safe access; it provides read/write locks internally.

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
