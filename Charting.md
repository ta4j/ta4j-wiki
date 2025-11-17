# Charting with ChartMaker

The `ChartMaker` class in the `ta4j-examples` module provides a fluent builder API for creating, displaying, and saving trading charts. It supports multiple chart types and flexible combinations of trading records, indicators, and analysis criteria.

## Overview

`ChartMaker` uses a builder pattern that separates chart creation from actions (display, save). This design provides:

- **Clear separation of concerns**: Creation methods return `JFreeChart` instances, action methods operate on built charts
- **Composable API**: Create once, perform multiple actions (display, save)
- **Flexible combinations**: Mix trading records, indicators, and analysis criteria as needed
- **Consistent naming**: All methods follow predictable patterns

## Chart Types

### Trading Record Charts
Display OHLC candlestick data with buy/sell markers and position bands from a `TradingRecord`. Can optionally include indicators as subplots and analysis criteria on a dual-axis.

### Indicator-Only Charts
Show indicators as separate subplots without OHLC candlesticks. Can optionally include analysis criteria on a dual-axis.

### Dual-Axis Charts
Automatically created when an analysis criterion is specified. Shows the base chart (price or indicators) on the left axis and the analysis criterion on the right axis.

## Fluent Builder API

The builder API provides a clean, composable way to create charts:

```java
ChartMaker chartMaker = new ChartMaker();

// Build a chart with trading record, indicators, and analysis criterion
ChartHandle handle = chartMaker.builder()
    .withTradingRecord(series, strategyName, tradingRecord)
    .addIndicators(rsi, macd)
    .withAnalysisCriterion(series, tradingRecord, new MaximumDrawdownCriterion(), "Max Drawdown")
    .withTitle("My Custom Chart")
    .build();

// Perform actions on the built chart
handle.display()
    .save("/path/to/save", "my-chart");
```

### Configuration Methods

- **`withTradingRecord(series, strategyName, tradingRecord)`** – Creates a trading record chart base
- **`withIndicators(series, indicators...)`** – Creates an indicator-only chart base (no OHLC candlesticks)
- **`addIndicators(indicators...)`** – Adds indicators as subplots to trading record charts
- **`withAnalysisCriterion(series, tradingRecord, criterion)`** – Adds an analysis criterion visualization (creates dual-axis chart). Label is inferred from the criterion class name. Only one criterion per chart.
- **`withAnalysisCriterion(series, tradingRecord, criterion, label)`** – Same as above but with an explicit label (optional).
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
    .addIndicators(rsi, sma)
    .build()
    .display()
    .save("target/charts", "strategy-with-indicators");
```

### Trading Record with Analysis Criterion

```java
import org.ta4j.core.criteria.NumberOfPositionsCriterion;

// Label is automatically inferred as "NumberOfPositions"
chartMaker.builder()
    .withTradingRecord(series, strategyName, tradingRecord)
    .withAnalysisCriterion(series, tradingRecord, new NumberOfPositionsCriterion())
    .withTitle("Strategy Performance")
    .build()
    .display();

// Or provide an explicit label
chartMaker.builder()
    .withTradingRecord(series, strategyName, tradingRecord)
    .withAnalysisCriterion(series, tradingRecord, new NumberOfPositionsCriterion(), "Number of Positions")
    .build()
    .display();
```

### Indicator-Only Chart

```java
chartMaker.builder()
    .withIndicators(series, rsi, macd, volume)
    .withTitle("Technical Indicators")
    .build()
    .display();
```

### Indicator-Only Chart with Analysis Criterion

```java
// Label is automatically inferred as "GrossReturn"
chartMaker.builder()
    .withIndicators(series, rsi, macd)
    .withAnalysisCriterion(series, tradingRecord, new GrossReturnCriterion())
    .build()
    .display();
```

### Trading Record with Indicators and Analysis Criterion

```java
// Label is automatically inferred as "MaximumDrawdown"
chartMaker.builder()
    .withTradingRecord(series, strategyName, tradingRecord)
    .addIndicators(rsi, sma)
    .withAnalysisCriterion(series, tradingRecord, new MaximumDrawdownCriterion())
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

| Chart Type | Can Add Indicators? | Can Add Analysis Criterion? |
|------------|---------------------|-----------------------------|
| **Trading Record** | ✅ Yes (via `addIndicators()` as subplots) | ✅ Yes (creates dual-axis) |
| **Indicator-Only** | N/A (indicators are the base) | ✅ Yes (creates dual-axis) |

**Note**: Only one analysis criterion can be added per chart. Analysis criteria are visualized as time series showing their value at each bar index.

## Analysis Criteria

Analysis criteria from `org.ta4j.core.criteria` can be visualized on charts. The criterion value is calculated at each bar index using a partial trading record (containing only trades up to that index), allowing you to see how the criterion evolves over time.

If you don't provide an explicit label, it will be automatically inferred from the criterion class name by removing the "Criterion" suffix. For example:
- `ExpectancyCriterion` → "Expectancy"
- `MaximumDrawdownCriterion` → "MaximumDrawdown"
- `NumberOfPositionsCriterion` → "NumberOfPositions"

Common analysis criteria include:
- `NumberOfPositionsCriterion` – Number of closed positions
- `GrossReturnCriterion` – Gross return percentage
- `MaximumDrawdownCriterion` – Maximum drawdown
- `NumberOfWinningPositionsCriterion` – Number of winning positions
- `ExpectancyCriterion` – Expected value per trade
- And many more in `org.ta4j.core.criteria`

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
