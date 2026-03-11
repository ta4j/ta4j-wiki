# Live Trading

ta4j gives you the strategy, series, and trading-record primitives for live systems. It does **not** replace your exchange adapter, order router, risk controls, or persistence layer, but it now lets you use the same `BaseTradingRecord` class across historical, paper, and live execution paths.

## What ta4j Handles, And What You Still Own

ta4j gives you:

- `BarSeries` and `ConcurrentBarSeries` for market state
- indicators, rules, and `Strategy` evaluation
- `BaseTradingRecord` for position and fill state
- criteria and statements for reporting

You still own:

- historical backfill and websocket ingestion
- order routing and retry logic
- account reconciliation
- persistence, recovery, and operational alerting

## Choose The Live Execution Path

| Situation | Recommended path | Why |
| --- | --- | --- |
| Single-threaded bot with synchronous fills | `BaseBarSeries` + `BaseTradingRecord` | Simple loop, minimal moving pieces |
| Multi-threaded ingestion and evaluation | `ConcurrentBarSeries` + `BaseTradingRecord` | Thread-safe reads and writes |
| Partial fills, fee capture, broker order IDs, or reconciliation | `BaseTradingRecord.recordFill(...)` or `recordExecutionFill(new TradeFill(...))` | Preserve the exact fill stream |
| Legacy adapter that still exposes `LiveTradingRecord` or `ExecutionFill` | Keep temporarily, migrate when practical | Compatibility only in 0.22.x |

For new code, start with `BaseTradingRecord`. `LiveTradingRecord` is a deprecated compatibility facade over the same underlying model.

## Initialize Market State And Trading State

Single-threaded setup:

```java
BarSeries series = new BaseBarSeriesBuilder()
        .withName("eth-usd-live")
        .build();

BaseTradingRecord tradingRecord = new BaseTradingRecord(
        strategy.getStartingType(),
        ExecutionMatchPolicy.FIFO,
        RecordedTradeCostModel.INSTANCE,
        new ZeroCostModel(),
        null,
        null);
```

Concurrent setup:

```java
ConcurrentBarSeries series = new ConcurrentBarSeriesBuilder()
        .withName("eth-usd-live")
        .withMaxBarCount(1000)
        .build();

BaseTradingRecord tradingRecord = new BaseTradingRecord(
        strategy.getStartingType(),
        ExecutionMatchPolicy.FIFO,
        RecordedTradeCostModel.INSTANCE,
        new ZeroCostModel(),
        null,
        null);
```

Use `RecordedTradeCostModel` when your broker already tells you the actual fee for each fill. That is the pattern the CF live stack uses.

## Feed The Series

If you have raw trades, let `ConcurrentBarSeries` aggregate them:

```java
series.ingestTrade(
        trade.timestamp(),
        trade.volume(),
        trade.price());
```

If your venue sends completed or partial candles, ingest bars directly:

```java
Bar candle = series.barBuilder()
        .timePeriod(Duration.ofMinutes(1))
        .endTime(candleCloseTime)
        .openPrice(open)
        .highPrice(high)
        .lowPrice(low)
        .closePrice(close)
        .volume(volume)
        .build();

series.ingestStreamingBar(candle);
```

## Evaluate On Bar Close, Record On Fill

This is the most important live-trading rule in the current stack:

- Strategy evaluation answers "should I try to trade?"
- The trading record answers "what actually filled?"

Do not mutate the record when you merely emit an order intent if your exchange can reject, partially fill, or delay that order.

```java
int endIndex = series.getEndIndex();
Num lastPrice = series.getBar(endIndex).getClosePrice();
Num amount = series.numFactory().one();

if (strategy.shouldEnter(endIndex, tradingRecord)) {
    orderRouter.submitBuy(lastPrice, amount);
} else if (strategy.shouldExit(endIndex, tradingRecord)) {
    orderRouter.submitSell(lastPrice, amount);
}
```

### Walkthrough: broker-confirmed fills with `BaseTradingRecord`

<a id="walkthrough-livetradingrecord-with-partial-fills-and-cost-basis"></a>

When the broker confirms a fill, write that fill into the record. You can use either a prebuilt `BaseTrade` or the lighter `TradeFill` DTO.

Using `BaseTrade`:

```java
BaseTrade fill = new BaseTrade(
        0,
        Instant.now(),
        series.numFactory().numOf("42100"),
        series.numFactory().numOf("0.50"),
        series.numFactory().numOf("4.21"),
        ExecutionSide.BUY,
        "order-123",
        "decision-123");

tradingRecord.recordFill(fill);
```

Using `TradeFill`:

```java
TradeFill fill = new TradeFill(
        endIndex,
        Instant.now(),
        series.numFactory().numOf("42100"),
        series.numFactory().numOf("0.50"),
        series.numFactory().numOf("4.21"),
        ExecutionSide.BUY,
        "order-123",
        "decision-123");

tradingRecord.recordExecutionFill(fill);
```

Both paths preserve metadata such as side, fee, order ID, and correlation ID.

## Open-Position Metrics And Reconciliation

Because `BaseTradingRecord` now exposes lot-aware views directly, you can inspect open positions and live PnL without switching to a separate record type:

```java
OpenPosition netOpenPosition = tradingRecord.getNetOpenPosition();
List<OpenPosition> lots = tradingRecord.getOpenPositions();

AnalysisCriterion costBasis = new OpenPositionCostBasisCriterion();
AnalysisCriterion unrealizedPnL = new OpenPositionUnrealizedProfitCriterion();

System.out.println("Cost basis: " + costBasis.calculate(series, tradingRecord));
System.out.println("Unrealized PnL: " + unrealizedPnL.calculate(series, tradingRecord));
```

This is also the surface used by downstream systems for dashboards and snapshots.

## CF Integration Pattern

CF is a concrete example of how the unified ta4j live stack fits into a fuller trading system:

- `Ta4jStrategyEngine` and `MarketInputStrategyEngine` evaluate ta4j strategies on closed bars.
- `MarketInputsFactory` publishes `ConcurrentBarSeries` instances and a shared `TradingRecord` into the input graph.
- `LiveTradingRecordFillListener` writes confirmed execution fills into `BaseTradingRecord`.
- `PaperTradingLedger` uses the same `BaseTradingRecord` update path during paper execution.
- `LiveTradingRecordSnapshotCodec` persists snapshots but restores unified `BaseTradingRecord` instances.
- `TradingRecordPerformanceSnapshotProvider` calculates ta4j criteria such as total fees and open-position cost basis from that same record.

The important practical result is that CF no longer needs one record type for backtests and another for live execution. The same ta4j trading record now survives through decisioning, fills, persistence, and analytics.

## Persistence And Recovery

At minimum, persist:

- the strategy or strategy descriptor
- the latest processed bar or timestamp
- the serialized trading-record snapshot
- any broker-side identifiers needed to de-duplicate orders after restart

If you rebuild the series on startup, make sure its bar index alignment still matches the recovered fills before you resume strategy evaluation.

## Examples And References

- **[TradingBotOnMovingBarSeries](Usage-examples.md#bots--live-trading)** - Minimal manual bot loop
- **[Backtesting](Backtesting.md)** - Historical and replay-style execution patterns
- **[Bar Series & Bars](Bar-series-and-bars.md)** - Bar ingestion and aggregation details
- **[Usage Examples](Usage-examples.md)** - Runnable examples in `ta4j-examples`

## Compatibility Note

`LiveTradingRecord` and `ExecutionFill` are still present in 0.22.x so older integrations can migrate without a sudden compile break, but the recommended path for new live code is `BaseTradingRecord` plus `TradeFill` or `BaseTrade`.
