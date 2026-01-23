# Bar Series and Bars

Everything in ta4j is grounded in a `BarSeries`: an ordered list of `Bar` objects containing OHLCV (open, high, low, close, volume) data for consistent time spans. Indicators, rules, and strategies read from the series; backtests and live trading both operate on it.

## Bars 101

Each `Bar` represents the market action during a time window and captures:

- **Open/High/Low/Close prices**
- **Volume** (or amount, depending on the bar builder)
- **Time period** (`Duration`)
- **Begin and end timestamps** (stored as `Instant` since 0.18)

Bars are immutable once added to a series (except for the latest bar which may be updated in-place while a period is in progress).

## Building series for backtesting

```java
BarSeries series = new BaseBarSeriesBuilder()
        .withName("btc_daily")
        .build();

Instant endTime = Instant.parse("2024-01-02T00:00:00Z");
series.addBar(series.barBuilder()
        .timePeriod(Duration.ofDays(1))
        .endTime(endTime)
        .openPrice(105.42)
        .highPrice(112.99)
        .lowPrice(104.01)
        .closePrice(111.42)
        .volume(1337)
        .build());
```

Options to consider:

- **Builders** – `TimeBarBuilder`, `TickBarBuilder`, `VolumeBarBuilder`, and the new `AmountBarBuilder` aggregate trades into bars by elapsed time, tick count, volume, or quote currency size respectively.
- **Begin vs. end timestamps** – Since 0.18 you can build bars anchored on begin time (`timePeriod` + `beginTime`) or end time. Use whichever matches your data source.
- **Split series** – `series.getSubSeries(start, end)` and `series.split(...)` are handy for walk-forward tests or training/testing splits.
- **Data Sources** – The `ta4j-examples` module includes ready-made data sources for loading historical data from APIs (Yahoo Finance, Coinbase) and files (CSV, JSON). See [Data Sources](Data-Sources.md) for comprehensive documentation.

## Working with live data

```java
BarSeries liveSeries = new BaseBarSeriesBuilder()
        .withName("eth_usd_live")
        .build();

Bar latest = liveSeries.barBuilder()
        .timePeriod(Duration.ofMinutes(1))
        .endTime(Instant.now())
        .openPrice(100.0)
        .highPrice(101.0)
        .lowPrice(99.5)
        .closePrice(100.7)
        .volume(42)
        .build();

liveSeries.addBar(latest);
```

As intrabar updates stream in:

```java
liveSeries.addPrice(100.9);          // updates close + high/low if needed
liveSeries.addTrade(liveSeries.numFactory().numOf(100),
        liveSeries.numFactory().numOf(2)); // updates volume + close
liveSeries.addBar(updatedBar, true); // replace the last bar entirely
```

Best practices:

- **Prime the series** with recent historical bars before going live so indicators have enough context.
- **Set maximum bar count** via `setMaximumBarCount(int)` to cap memory usage. This turns the series into a moving window—be careful not to reference bars older than `getBeginIndex()`.
- **Threading** – For single-threaded scenarios, `BaseBarSeries` is sufficient. For concurrent read/write access, use `ConcurrentBarSeries` (see below).

## Concurrent bar series for multi-threaded scenarios

Since 0.22.2, `ConcurrentBarSeries` provides thread-safe access for scenarios where multiple threads need to read from or write to a bar series simultaneously. This is essential for live trading systems where one thread ingests market data while another thread evaluates strategies.

### Creating a concurrent series

```java
ConcurrentBarSeries concurrentSeries = new ConcurrentBarSeriesBuilder()
        .withName("btc_usd_concurrent")
        .withNumFactory(DecimalNumFactory.getInstance())
        .withBarBuilderFactory(new TimeBarBuilderFactory(true))
        .withMaxBarCount(1000)  // Optional: limit memory usage
        .build();
```

### Streaming trade ingestion

The recommended approach for real-time data feeds is to use `ingestTrade()` methods, which let the configured `BarBuilder` handle bar rollovers automatically:

```java
// Simple trade ingestion (no side/liquidity data)
concurrentSeries.ingestTrade(
    Instant.now(),
    tradeVolume,
    tradePrice
);

// With side and liquidity classification (for RealtimeBar support)
concurrentSeries.ingestTrade(
    Instant.now(),
    tradeVolume,
    tradePrice,
    RealtimeBar.Side.BUY,           // Optional: BUY or SELL
    RealtimeBar.Liquidity.TAKER     // Optional: MAKER or TAKER
);
```

The `ingestTrade()` methods automatically:
- Aggregate trades into bars using the configured `BarBuilder`
- Handle bar rollovers when thresholds are met (time period, volume, tick count, etc.)
- Update the latest bar in-place or append new bars as needed
- Maintain thread safety throughout the operation

### Streaming bar ingestion

For scenarios where you receive pre-aggregated bars (e.g., from WebSocket candle feeds), use `ingestStreamingBar()`:

```java
Bar newBar = concurrentSeries.barBuilder()
        .timePeriod(Duration.ofMinutes(1))
        .endTime(Instant.now())
        .openPrice(100.0)
        .highPrice(101.0)
        .lowPrice(99.5)
        .closePrice(100.7)
        .volume(42)
        .build();

StreamingBarIngestResult result = concurrentSeries.ingestStreamingBar(newBar);
// result.action() indicates: APPENDED, REPLACED_LAST, or REPLACED_HISTORICAL
// result.index() is the affected series index
```

The method automatically handles:
- **APPENDED**: New bar added to the end
- **REPLACED_LAST**: Latest bar replaced (for corrections)
- **REPLACED_HISTORICAL**: Historical bar replaced (for reconciliation)

### RealtimeBar for side/liquidity analytics

`RealtimeBar` extends `Bar` with optional side and liquidity breakdowns, useful for analyzing market microstructure:

```java
// RealtimeBar tracks buy/sell and maker/taker breakdowns
RealtimeBar bar = (RealtimeBar) concurrentSeries.getLastBar();

if (bar.hasSideData()) {
    Num buyVolume = bar.getBuyVolume();
    Num sellVolume = bar.getSellVolume();
    long buyTrades = bar.getBuyTrades();
    long sellTrades = bar.getSellTrades();
}

if (bar.hasLiquidityData()) {
    Num makerVolume = bar.getMakerVolume();
    Num takerVolume = bar.getTakerVolume();
    long makerTrades = bar.getMakerTrades();
    long takerTrades = bar.getTakerTrades();
}
```

Note: Side and liquidity data are optional—exchanges may not provide this information for every trade. When unavailable, the corresponding getters return zero values.

### Thread safety guarantees

`ConcurrentBarSeries` uses `ReentrantReadWriteLock` to provide:
- **Multiple concurrent readers**: Read operations (getters, indicator evaluation) can proceed in parallel
- **Exclusive writers**: Write operations (bar ingestion, modifications) are serialized
- **Safe iteration**: All read methods return defensive copies or use read locks internally

Example concurrent usage:

```java
// Thread 1: Ingest trades from WebSocket
executorService.submit(() -> {
    while (running) {
        Trade trade = websocket.receiveTrade();
        concurrentSeries.ingestTrade(trade.getTime(), trade.getVolume(), trade.getPrice());
    }
});

// Thread 2: Evaluate strategy
executorService.submit(() -> {
    while (running) {
        int endIndex = concurrentSeries.getEndIndex();
        if (strategy.shouldEnter(endIndex, tradingRecord)) {
            // Execute trade...
        }
    }
});

// Thread 3: Calculate indicators
executorService.submit(() -> {
    while (running) {
        int endIndex = concurrentSeries.getEndIndex();
        Num rsiValue = rsiIndicator.getValue(endIndex);
        // Use indicator value...
    }
});
```

### Serialization

`ConcurrentBarSeries` supports Java serialization and preserves:
- Bar data
- `NumFactory` configuration
- `BarBuilderFactory` configuration
- Maximum bar count settings

Transient locks are reinitialized on deserialization, and the trade bar builder is recreated lazily on the next ingestion call.

### When to use ConcurrentBarSeries

Use `ConcurrentBarSeries` when:
- Multiple threads need concurrent read access (e.g., parallel strategy evaluation)
- One thread ingests data while others read (e.g., live trading bots)
- You need thread-safe bar ingestion from WebSocket feeds
- You want to leverage side/liquidity analytics with `RealtimeBar`

Use `BaseBarSeries` when:
- Single-threaded access is sufficient (most backtesting scenarios)
- You want maximum performance without synchronization overhead
- You're working with historical data that doesn't change

## Choosing a `Num` representation

`BarSeries` delegates number creation through a `NumFactory`. Use `DecimalNumFactory` for high precision (default) or `DoubleNumFactory` for performance-sensitive scenarios. See [Num](Num.md) for guidance plus tips on mixing integer-based quantities (contracts) with price-based values.

## Troubleshooting data issues

- **Missing timestamps** – `BarSeriesUtils.findMissingBars(series, false)` surfaces potential gaps so you can backfill or ignore known market closures.
- **Revised data** – Exchanges occasionally restate candles; call `BarSeriesUtils.replaceBarIfChanged(series, newBar)` to swap the affected bar in place.
- **Irregular intervals** – Aggregate trades into constant-duration bars using `TimeBarBuilder`/`VolumeBarBuilder` or `BarSeriesUtils.aggregateBars(...)` to keep indicators accurate.
- **Currency conversions** – Preprocess your data so a single `BarSeries` remains homogeneous (one instrument / quote currency). If you need spreads between instruments, build multiple series and feed each indicator the relevant one.
