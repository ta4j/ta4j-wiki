# Charting Quickstart

Use this page when your goal is simple: render a strategy result quickly and verify signals visually.

For full API coverage, advanced configuration, and styling details, see [Charting](Charting.md).

## 1) Build a base chart

```java
ChartWorkflow chartWorkflow = new ChartWorkflow();
JFreeChart chart = chartWorkflow.builder()
        .withSeries(series)
        .toChart();
```

## 2) Add strategy signals

```java
TradingRecord record = new BarSeriesManager(series).run(strategy);

JFreeChart chart = chartWorkflow.builder()
        .withSeries(series)
        .withTradingRecordOverlay(record)
        .toChart();
```

## 3) Add indicator overlays

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
SMAIndicator sma = new SMAIndicator(close, 50);

JFreeChart chart = chartWorkflow.builder()
        .withSeries(series)
        .withIndicatorOverlay(sma)
        .toChart();
```

## 4) Handle market-time gaps

Use `TimeAxisMode.BAR_INDEX` when you want evenly spaced bars (for markets with weekends/holidays):

```java
JFreeChart chart = chartWorkflow.builder()
        .withTimeAxisMode(TimeAxisMode.BAR_INDEX)
        .withSeries(series)
        .toChart();
```

## 5) Troubleshoot quickly

- No chart window: likely headless environment; write chart files instead.
- Signals look wrong: compare with [Backtesting](Backtesting.md) execution assumptions first.
- Indicator line looks shifted: verify warmup/unstable bars and source indicator wiring.

## Related pages

- [Charting](Charting.md)
- [Usage Examples](Usage-examples.md)
- [Troubleshooting Hub](Troubleshooting-Hub.md)
