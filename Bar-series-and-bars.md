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
- **Json/CSV loaders** – The `ta4j-examples` module includes ready-made loaders such as `CsvTradesLoader` and `AdaptiveJsonBarsSerializer` (handles Coinbase/Binance JSON).

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
- **Threading** – Create/update the series on the same thread that evaluates strategies to avoid synchronization issues.

## Choosing a `Num` representation

`BarSeries` delegates number creation through a `NumFactory`. Use `DecimalNumFactory` for high precision (default) or `DoubleNumFactory` for performance-sensitive scenarios. See [Num](Num.md) for guidance plus tips on mixing integer-based quantities (contracts) with price-based values.

## Troubleshooting data issues

- **Missing timestamps** – `BarSeriesUtils.findMissingBars(series, false)` surfaces potential gaps so you can backfill or ignore known market closures.
- **Revised data** – Exchanges occasionally restate candles; call `BarSeriesUtils.replaceBarIfChanged(series, newBar)` to swap the affected bar in place.
- **Irregular intervals** – Aggregate trades into constant-duration bars using `TimeBarBuilder`/`VolumeBarBuilder` or `BarSeriesUtils.aggregateBars(...)` to keep indicators accurate.
- **Currency conversions** – Preprocess your data so a single `BarSeries` remains homogeneous (one instrument / quote currency). If you need spreads between instruments, build multiple series and feed each indicator the relevant one.
