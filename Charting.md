# Charting with ChartMaker

The `ChartMaker` class in the `ta4j-examples` module provides a fluent builder API for creating, displaying, and saving trading charts. It supports multiple chart types and flexible combinations of trading records, indicators, and analysis overlays.

## Overview

`ChartMaker` uses a builder pattern that separates chart creation from actions (display, save). This design provides:

- **Clear separation of concerns**: Creation methods return `JFreeChart` instances, action methods operate on built charts
- **Composable API**: Create once, perform multiple actions (display, save)
- **Flexible combinations**: Mix trading records, indicators, and analysis overlays as needed
- **Consistent naming**: All methods follow predictable patterns

## Chart Types

### Trading Record Charts
Display OHLC candlestick data with buy/sell markers and position bands from a `TradingRecord`.

### Indicator Charts
Show OHLC data with indicators displayed as separate subplots below the main chart.

### Analysis Charts
Display OHLC data with analysis overlays (e.g., moving averages) on the main plot.

### Dual-Axis Charts
Show two indicators on separate Y-axes (left and right) for comparison.

## Fluent Builder API

The builder API provides a clean, composable way to create charts:

```java
ChartMaker chartMaker = new ChartMaker();

// Build a chart with trading record, indicators, and analysis
ChartHandle handle = chartMaker.builder()
    .withTradingRecord(series, strategyName, tradingRecord)
    .withIndicators(rsi, macd)
    .addAnalysis(AnalysisType.MOVING_AVERAGE_20)
    .withTitle("My Custom Chart")
    .build();

// Perform actions on the built chart
handle.display()
    .save("/path/to/save", "my-chart");
```

### Configuration Methods

- **`withTradingRecord(series, strategyName, tradingRecord)`** – Creates a trading record chart base
- **`withAnalysis(series, analysisTypes...)`** – Creates an analysis chart base
- **`withDualAxis(series, primary, primaryLabel, secondary, secondaryLabel)`** – Creates a dual-axis chart
- **`addAnalysis(analysisTypes...)`** – Adds analysis overlays to existing charts (trading record or analysis charts)
- **`withIndicators(indicators...)`** – Adds indicators (as subplots for OHLC charts, as series for dual-axis)
- **`withTitle(String title)`** – Sets a custom chart title (optional, overrides auto-generated)

### Action Methods (on ChartHandle)

- **`display()`** / **`display(String windowTitle)`** – Displays the chart in a Swing window
- **`save(String directory, String filename)`** – Saves to specified directory with filename
- **`save(Path directory, String filename)`** – Same as above with Path
- **`save(String filename)`** – Saves using constructor directory or current directory
- **`saveToDirectory(String/Path directory)`** – Saves with auto-generated filename

## Usage Examples

### Trading Record with Indicators

```java
ChartMaker chartMaker = new ChartMaker();
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
RSIIndicator rsi = new RSIIndicator(closePrice, 14);
SMAIndicator sma = new SMAIndicator(closePrice, 50);

chartMaker.builder()
    .withTradingRecord(series, strategy.getName(), tradingRecord)
    .withIndicators(rsi, sma)
    .build()
    .display()
    .save("target/charts", "strategy-with-indicators");
```

### Analysis Chart with Indicators

```java
chartMaker.builder()
    .withAnalysis(series, AnalysisType.MOVING_AVERAGE_20, AnalysisType.MOVING_AVERAGE_50)
    .withIndicators(rsi)
    .withTitle("Price Analysis")
    .build()
    .display();
```

### Dual-Axis Chart with Additional Indicators

```java
chartMaker.builder()
    .withDualAxis(series, rsi, "RSI", macd, "MACD")
    .withIndicators(volume)
    .build()
    .display();
```

### Trading Record with Analysis Overlays

```java
chartMaker.builder()
    .withTradingRecord(series, strategyName, tradingRecord)
    .addAnalysis(AnalysisType.MOVING_AVERAGE_20, AnalysisType.MOVING_AVERAGE_50)
    .withIndicators(rsi)
    .build()
    .display()
    .save("target/charts", "complete-analysis");
```

### Simple Trading Record Chart

```java
chartMaker.builder()
    .withTradingRecord(series, strategyName, tradingRecord)
    .build()
    .display();
```

## Chart Type Compatibility

| Chart Type | Can Add Indicators? | Can Add Trading Record? | Can Add Analysis? |
|------------|---------------------|-------------------------|-------------------|
| **Trading Record** | ✅ Yes (as subplots) | N/A (self) | ✅ Yes (overlay) |
| **Analysis** | ✅ Yes (as subplots) | ✅ Yes (markers) | ✅ Yes (multiple types) |
| **Dual-Axis** | ⚠️ Limited (as series) | ❌ No | ❌ No |

## Saving Charts

Charts can be saved in several ways:

```java
// Save with explicit directory and filename
handle.save("/path/to/charts", "my-strategy");

// Save with filename only (uses constructor directory or current directory)
ChartMaker chartMaker = new ChartMaker("target/charts");
handle.save("my-strategy");

// Save to directory with auto-generated filename
handle.saveToDirectory("/path/to/charts");
```

If no save directory is configured via the constructor, charts are saved to the current directory by default.

## Constructor Options

```java
// Display only (no persistence)
ChartMaker chartMaker = new ChartMaker();

// With default save directory
ChartMaker chartMaker = new ChartMaker("target/charts");
```

## Legacy API

The original `ChartMaker` methods (`createTradingRecordChart()`, `displayTradingRecordChart()`, etc.) remain available for backward compatibility. The builder API is recommended for new code as it provides better separation of concerns and composability.

## See Also

- [Backtesting](Backtesting.md) – Learn how to generate `TradingRecord` instances for charting
- [Usage Examples](Usage-examples.md) – Browse runnable charting examples
- [Technical Indicators](Technical-indicators.md) – Understand the indicators you can plot

