# Charting

Ta4j provides powerful charting capabilities through the `ChartWorkflow` class and its fluent `ChartBuilder` API. You can create sophisticated trading charts with candlestick data, indicators, trading records, and analysis criteria overlays.

## Overview

The charting system in ta4j-examples uses JFreeChart to render professional-quality trading charts. The refactored architecture (introduced in 0.19, enhanced in 0.21.0) separates concerns into dedicated components:

- **`ChartWorkflow`** - Facade class that coordinates chart creation, display, and persistence
- **`ChartBuilder`** - Fluent API for constructing charts with type-safe stage interfaces
- **`TradingChartFactory`** - Renders JFreeChart instances from chart definitions
- **`ChartDisplayer`** - Interface for displaying charts (Swing implementation included)
- **`ChartStorage`** - Interface for persisting charts (filesystem implementation included)

The API supports:

- **Candlestick (OHLCV) charts** - Traditional price action visualization
- **Indicator overlays** - Overlay indicators on price charts with automatic axis management
- **Trading record visualization** - Display buy/sell signals and position markers
- **Analysis criterion overlays** - Visualize performance metrics over time using `AnalysisCriterionIndicator`
- **Sub-charts** - Add separate panels for indicators or analysis criteria
- **Custom styling** - Control colors, line widths, and chart titles
- **Interactive mouseover** - Hover over chart elements to see OHLC data and indicator values

## Getting Started

To use charting in your project, you'll need to include the `ta4j-examples` module as a dependency:

```xml
<dependency>
  <groupId>org.ta4j</groupId>
  <artifactId>ta4j-examples</artifactId>
  <version>${USE_LATEST_VERSION}</version>
</dependency>
```

The simplest way to create a chart is using the `ChartBuilder` fluent API:

```java
ChartWorkflow chartWorkflow = new ChartWorkflow();
chartWorkflow.builder()
    .withSeries(series)
    .display();
```

## ChartBuilder API

The `ChartBuilder` provides a fluent, stream-like API for constructing charts. It enforces valid transitions through stage interfaces and prevents accidental reuse (similar to Java Streams).

### Basic Chart Types

#### Candlestick Chart

Start with a candlestick chart using `withSeries()`:

```java
ChartWorkflow chartWorkflow = new ChartWorkflow();
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .toChart();
```

#### Indicator-Based Chart

Start with an indicator as the base:

```java
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
JFreeChart chart = chartWorkflow.builder()
    .withIndicator(closePrice)
    .toChart();
```

### Adding Overlays

Overlays are added to the current chart and share the same plot area. The builder automatically manages axis assignment based on value ranges.

#### Indicator Overlays

Add indicator overlays to visualize technical indicators on your price chart:

```java
SMAIndicator sma = new SMAIndicator(closePrice, 50);
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withIndicatorOverlay(sma)
    .toChart();
```

You can style indicator overlays with custom colors and line widths:

```java
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withIndicatorOverlay(sma)
    .withLineColor(Color.CYAN)
    .withLineWidth(2.0f)
    .toChart();
```

#### Trading Record Overlays

Display buy/sell signals and position markers:

```java
BarSeriesManager seriesManager = new BarSeriesManager(series);
TradingRecord tradingRecord = seriesManager.run(strategy);

JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .toChart();
```

Trading record overlays show:
- **Buy markers** (green triangles pointing up) at entry points
- **Sell markers** (red triangles pointing down) at exit points
- **Position bands** (colored background regions) showing when positions are open
- **Trade labels** with position numbers and prices

#### Analysis Criterion Overlays

Visualize analysis criteria (like net profit, return, etc.) over time on a secondary axis:

```java
NetProfitCriterion netProfit = new NetProfitCriterion();
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .withAnalysisCriterionOverlay(netProfit, tradingRecord)
    .toChart();
```

The `AnalysisCriterionIndicator` automatically calculates the criterion value at each bar index using a partial trading record, creating a time series visualization of performance metrics.

**How it works**: For each bar index, `AnalysisCriterionIndicator` creates a partial trading record containing only positions that have been entered (and optionally closed) up to that index, then calculates the criterion value for that partial record. This allows you to see how performance metrics evolve over time as trades are executed.

**Example use cases**:
- Track cumulative net profit over time
- Visualize return on investment as positions are opened and closed
- Monitor drawdown progression throughout the trading period
- Compare multiple criteria side-by-side using sub-charts

```java
// Visualize multiple performance metrics
NetProfitCriterion netProfit = new NetProfitCriterion();
GrossReturnCriterion grossReturn = new GrossReturnCriterion();
MaximumDrawdownCriterion maxDrawdown = new MaximumDrawdownCriterion();

chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .withAnalysisCriterionOverlay(netProfit, tradingRecord)
    .withLineColor(Color.GREEN)
    .withSubChart(grossReturn, tradingRecord)
    .withSubChart(maxDrawdown, tradingRecord)
    .display();
```

### Adding Sub-Charts

Sub-charts create separate panels below the main chart, each with its own Y-axis. This is useful for indicators with different scales or for detailed analysis.

#### Indicator Sub-Charts

```java
RSIIndicator rsi = new RSIIndicator(closePrice, 14);
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withSubChart(rsi)
    .toChart();
```

#### Trading Record Sub-Charts

Create a dedicated panel for trading visualization:

```java
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withSubChart(tradingRecord)
    .toChart();
```

#### Analysis Criterion Sub-Charts

```java
GrossReturnCriterion grossReturn = new GrossReturnCriterion();
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withSubChart(grossReturn, tradingRecord)
    .toChart();
```

### Combining Elements

You can combine multiple overlays and sub-charts in a single chart:

```java
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
SMAIndicator sma = new SMAIndicator(closePrice, 50);
RSIIndicator rsi = new RSIIndicator(closePrice, 14);
ADXIndicator adx = new ADXIndicator(series, 14);

JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .withIndicatorOverlay(sma)
    .withLineColor(Color.ORANGE)
    .withSubChart(rsi)
    .withSubChart(adx)
    .withSubChart(new NetProfitCriterion(), tradingRecord)
    .toChart();
```

### Chart Titles

Set a custom title for your chart:

```java
JFreeChart chart = chartWorkflow.builder()
    .withTitle("My Trading Strategy Analysis")
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .toChart();
```

Or set the title after configuring the base chart:

```java
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withTitle("Custom Title")
    .withTradingRecordOverlay(tradingRecord)
    .toChart();
```

### Terminal Operations

The builder supports three terminal operations that consume the builder (preventing reuse):

#### Display Chart

Display the chart in a Swing window:

```java
chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .display();
```

With a custom window title:

```java
chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .display("My Strategy Chart");
```

#### Save Chart

Save the chart as a PNG image:

```java
Optional<Path> savedPath = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .save("my-strategy-chart");
```

Save to a specific directory:

```java
Optional<Path> savedPath = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .save("charts", "my-strategy-chart");
```

Or use a `Path` object:

```java
Path chartsDir = Paths.get("output", "charts");
Optional<Path> savedPath = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .save(chartsDir, "my-strategy-chart");
```

#### Get Chart Object

Get the `JFreeChart` object for further customization:

```java
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .toChart();

// Further customize the chart if needed
chart.setTitle("Custom Title");
chartWorkflow.displayChart(chart);
```

## Automatic Axis Management

The `ChartBuilder` intelligently manages Y-axes based on value ranges, ensuring your charts remain readable without manual configuration:

- **Primary axis**: Used for price data and indicators with overlapping value ranges (e.g., close price and SMA both in the $50-100 range)
- **Secondary axis**: Automatically created for indicators with different scales (e.g., RSI 0-100 vs price $50-100)
- **Axis assignment**: The builder analyzes value ranges and assigns overlays to the appropriate axis
- **Axis rejection**: Overlays with incompatible ranges that can't fit on either axis are automatically rejected with a warning log message

**How it works**: The builder maintains an `AxisModel` that tracks the value ranges of the primary and secondary axes. When you add an overlay:
1. The builder calculates the value range of the new overlay
2. It checks if the range overlaps with the primary axis range
3. If overlapping, it's assigned to the primary axis
4. If not overlapping and a secondary axis exists, it checks compatibility with the secondary axis
5. If no secondary axis exists and ranges don't overlap, a secondary axis is created
6. Analysis criterion overlays prefer the secondary axis by default

**Example**:
```java
// RSI (0-100) will automatically use secondary axis
// SMA (price range) will use primary axis
RSIIndicator rsi = new RSIIndicator(closePrice, 14);
SMAIndicator sma = new SMAIndicator(closePrice, 50);

chartWorkflow.builder()
    .withSeries(series)  // Primary axis: price range
    .withIndicatorOverlay(sma)  // Primary axis: same range as price
    .withIndicatorOverlay(rsi)  // Secondary axis: 0-100 range
    .display();
```

## Complete Example

Here's a complete example from the ADX strategy:

```java
// Build and run strategy
BarSeries series = CsvTradesLoader.loadBitstampSeries();
Strategy strategy = ADXStrategy.buildStrategy(series);
BarSeriesManager seriesManager = new BarSeriesManager(series);
TradingRecord tradingRecord = seriesManager.run(strategy);

// Create indicators
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
SMAIndicator sma = new SMAIndicator(closePrice, 50);
ADXIndicator adx = new ADXIndicator(series, 14);
PlusDIIndicator plusDI = new PlusDIIndicator(series, 14);
MinusDIIndicator minusDI = new MinusDIIndicator(series, 14);

// Build and display chart
ChartWorkflow chartWorkflow = new ChartWorkflow();
JFreeChart chart = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .withIndicatorOverlay(sma)
    .withSubChart(adx)
    .withIndicatorOverlay(plusDI)
    .withIndicatorOverlay(minusDI)
    .withSubChart(new GrossReturnCriterion(), tradingRecord)
    .toChart();
chartWorkflow.displayChart(chart);
chartWorkflow.saveChartImage(chart, series, "adx-strategy", "ta4j-examples/log/charts");
```

## Legacy API

The `ChartWorkflow` class also provides convenience methods for common use cases. These methods are still available but the `ChartBuilder` API is recommended for new code:

```java
// Display a trading record chart
chartWorkflow.displayTradingRecordChart(series, "Strategy Name", tradingRecord);

// Create an indicator chart
JFreeChart chart = chartWorkflow.createIndicatorChart(series, indicator1, indicator2);
chartWorkflow.displayChart(chart);

// Create a dual-axis chart
JFreeChart chart = chartWorkflow.createDualAxisChart(
    series, 
    primaryIndicator, "Price (USD)",
    secondaryIndicator, "RSI"
);
```

## ChartWorkflow Configuration

### With File Persistence

Create a `ChartWorkflow` that automatically saves charts to a directory:

```java
ChartWorkflow chartWorkflow = new ChartWorkflow("output/charts");
// Charts will be saved to output/charts when using save() methods
Optional<Path> savedPath = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .save();  // Uses the configured directory
```

### Without File Persistence

The default constructor creates a `ChartWorkflow` without file persistence:

```java
ChartWorkflow chartWorkflow = new ChartWorkflow();
// Use save() methods with explicit paths, or display only
Optional<Path> savedPath = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .save("output/charts", "my-chart");  // Explicit directory required
```

### Custom Configuration

You can also inject custom implementations for advanced use cases:

```java
TradingChartFactory customFactory = new TradingChartFactory();
ChartDisplayer customDisplayer = new SwingChartDisplayer();
ChartStorage customStorage = new FileSystemChartStorage(Paths.get("custom/path"));

ChartWorkflow chartWorkflow = new ChartWorkflow(customFactory, customDisplayer, customStorage);
```

## Package Structure

The charting system is organized into several packages for better maintainability:

- `ta4jexamples.charting.builder` - `ChartBuilder` and `ChartPlan` for fluent chart construction
- `ta4jexamples.charting.compose` - `TradingChartFactory` for rendering charts
- `ta4jexamples.charting.display` - `ChartDisplayer` interface and `SwingChartDisplayer` implementation
- `ta4jexamples.charting.storage` - `ChartStorage` interface and `FileSystemChartStorage` implementation
- `ta4jexamples.charting.workflow` - `ChartWorkflow` facade class
- `ta4jexamples.charting.renderer` - Custom renderers like `BaseCandleStickRenderer`

For most users, only `ChartWorkflow` and `ChartBuilder` need to be imported directly.

## Interactive Features

### Mouseover Data Display

When displaying charts in Swing, you can hover over chart elements to see detailed information:

- **Candlestick bars**: Shows date, open, high, low, close, and volume
- **Indicator lines**: Shows date and indicator value

The mouseover display appears in a label at the top of the chart window. The hover delay can be configured via the `ta4j.chart.hoverDelay` system property (default: 100ms).

```java
// Configure hover delay (in milliseconds)
System.setProperty("ta4j.chart.hoverDelay", "200");

chartWorkflow.builder()
    .withSeries(series)
    .display();
```

### Chart Display Size

The chart display size is automatically calculated based on your screen size, scaled by a factor (default: 75%). You can configure this via the `ta4j.chart.displayScale` system property:

```java
// Set display scale (0.1 to 1.0)
System.setProperty("ta4j.chart.displayScale", "0.9");

chartWorkflow.builder()
    .withSeries(series)
    .display();
```

## Best Practices

1. **Use the fluent API**: The `ChartBuilder` API provides better type safety and prevents common mistakes. It enforces valid transitions through stage interfaces, similar to Java Streams.

2. **Combine related elements**: Group overlays and sub-charts logically (e.g., price indicators together, momentum indicators together). This makes charts easier to read and interpret.

3. **Use sub-charts for different scales**: Indicators with vastly different scales (like RSI 0-100 vs price) work better as sub-charts. The automatic axis management will handle this, but explicit sub-charts give you more control.

4. **Style overlays**: Use custom colors to distinguish multiple overlays on the same chart. The builder provides a default color palette, but you can override it:

```java
chartWorkflow.builder()
    .withSeries(series)
    .withIndicatorOverlay(sma1)
    .withLineColor(Color.CYAN)
    .withIndicatorOverlay(sma2)
    .withLineColor(Color.MAGENTA)
    .display();
```

5. **Save important charts**: Use the `save()` method to persist charts for reports or documentation. Charts are saved as JPEG images by default.

6. **Use analysis criterion overlays for performance tracking**: Visualize how your strategy's performance metrics evolve over time using `AnalysisCriterionIndicator`. This is especially useful for understanding drawdown patterns and profit accumulation.

7. **Leverage ChartPlan for reuse**: The `toPlan()` method returns a `ChartPlan` that can be reused or serialized:

```java
ChartPlan plan = chartWorkflow.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .toPlan();

// Later, render the same chart
JFreeChart chart = chartWorkflow.render(plan);
chartWorkflow.displayChart(chart);
```

## Advanced Examples

### Example 1: Multi-Criteria Performance Dashboard

Create a comprehensive performance dashboard with multiple analysis criteria:

```java
BarSeries series = CsvTradesLoader.loadBitstampSeries();
Strategy strategy = MyStrategy.buildStrategy(series);
BarSeriesManager manager = new BarSeriesManager(series);
TradingRecord record = manager.run(strategy);

ChartWorkflow workflow = new ChartWorkflow();
workflow.builder()
    .withTitle("Strategy Performance Dashboard")
    .withSeries(series)
    .withTradingRecordOverlay(record)
    // Performance metrics as overlays on main chart
    .withAnalysisCriterionOverlay(new NetProfitCriterion(), record)
    .withLineColor(Color.GREEN)
    // Additional metrics as sub-charts
    .withSubChart(new GrossReturnCriterion(), record)
    .withSubChart(new MaximumDrawdownCriterion(), record)
    .withSubChart(new InPositionPercentageCriterion(), record)
    .display();
```

### Example 2: Indicator Comparison Chart

Compare multiple indicators with proper styling:

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
SMAIndicator sma20 = new SMAIndicator(close, 20);
SMAIndicator sma50 = new SMAIndicator(close, 50);
EMAIndicator ema12 = new EMAIndicator(close, 12);

ChartWorkflow workflow = new ChartWorkflow();
workflow.builder()
    .withSeries(series)
    .withIndicatorOverlay(sma20)
    .withLineColor(Color.BLUE)
    .withLineWidth(1.5f)
    .withIndicatorOverlay(sma50)
    .withLineColor(Color.ORANGE)
    .withLineWidth(2.0f)
    .withIndicatorOverlay(ema12)
    .withLineColor(Color.CYAN)
    .withLineWidth(1.0f)
    .withTradingRecordOverlay(record)
    .display();
```

### Example 3: Strategy Comparison

Compare two strategies side-by-side by saving charts:

```java
TradingRecord strategy1Record = manager.run(strategy1);
TradingRecord strategy2Record = manager.run(strategy2);

ChartWorkflow workflow = new ChartWorkflow("output/comparison");

// Strategy 1 chart
workflow.builder()
    .withTitle("Strategy 1: Moving Average Crossover")
    .withSeries(series)
    .withTradingRecordOverlay(strategy1Record)
    .withSubChart(new NetProfitCriterion(), strategy1Record)
    .save("strategy1-comparison");

// Strategy 2 chart
workflow.builder()
    .withTitle("Strategy 2: RSI Mean Reversion")
    .withSeries(series)
    .withTradingRecordOverlay(strategy2Record)
    .withSubChart(new NetProfitCriterion(), strategy2Record)
    .save("strategy2-comparison");
```

### Example 4: Real-Time Style Customization

Create a chart with extensive customization:

```java
ChartWorkflow workflow = new ChartWorkflow();
JFreeChart chart = workflow.builder()
    .withTitle("Custom Trading Analysis")
    .withSeries(series)
    .withTradingRecordOverlay(record)
    .withIndicatorOverlay(sma)
    .withLineColor(new Color(0x03DAC6))  // Custom teal color
    .withLineWidth(2.5f)
    .withSubChart(rsi)
    .withSubChart(new NetProfitCriterion(), record)
    .toChart();

// Further customize the JFreeChart if needed
chart.getTitle().setFont(new Font("Arial", Font.BOLD, 18));

workflow.displayChart(chart, "My Custom Chart");
```

## Example Classes

See the following example classes in the ta4j-examples project for more charting patterns:

- [ADXStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/ADXStrategy.java) - Complex chart with overlays and sub-charts
- [NetMomentumStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/NetMomentumStrategy.java) - Analysis criterion overlay example
- [BuyAndSellSignalsToChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/BuyAndSellSignalsToChart.java) - Simple trading record visualization
- [CashFlowToChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/CashFlowToChart.java) - Cash flow visualization example

## Troubleshooting

### Chart Not Displaying

If charts don't display, check:
- You're not in a headless environment (no display available)
- Swing dependencies are included in your classpath
- The chart window might be behind other windows

### Overlays Not Appearing

If overlays don't appear:
- Check the console/logs for warning messages about axis incompatibility
- Ensure indicators are attached to the same `BarSeries` as the chart
- Verify that trading records contain trades within the series range

### Performance Issues

For large datasets:
- Consider using sub-charts instead of many overlays
- Reduce the number of indicators displayed simultaneously
- Use the `save()` method instead of `display()` for batch processing

