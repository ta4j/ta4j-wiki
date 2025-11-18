# Charting

Ta4j provides powerful charting capabilities through the `ChartWorkflow` class and its fluent `ChartBuilder` API. You can create sophisticated trading charts with candlestick data, indicators, trading records, and analysis criteria overlays.

## Overview

The charting system in ta4j-examples uses JFreeChart to render professional-quality trading charts. The API supports:

- **Candlestick (OHLCV) charts** - Traditional price action visualization
- **Indicator overlays** - Overlay indicators on price charts with automatic axis management
- **Trading record visualization** - Display buy/sell signals and position markers
- **Analysis criterion overlays** - Visualize performance metrics over time
- **Sub-charts** - Add separate panels for indicators or analysis criteria
- **Custom styling** - Control colors, line widths, and chart titles

## Getting Started

To use charting in your project, you'll need to include the `ta4j-examples` module as a dependency:

```xml
<dependency>
  <groupId>org.ta4j</groupId>
  <artifactId>ta4j-examples</artifactId>
  <version>0.19-SNAPSHOT</version>
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

The `ChartBuilder` intelligently manages Y-axes based on value ranges:

- **Primary axis**: Used for price data and indicators with overlapping value ranges
- **Secondary axis**: Automatically created for indicators with different scales (e.g., RSI 0-100 vs price)
- **Axis rejection**: Overlays with incompatible ranges are automatically rejected with a warning

This ensures your charts remain readable without manual axis configuration.

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
```

### Without File Persistence

The default constructor creates a `ChartWorkflow` without file persistence:

```java
ChartWorkflow chartWorkflow = new ChartWorkflow();
// Use save() methods with explicit paths, or display only
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

## Best Practices

1. **Use the fluent API**: The `ChartBuilder` API provides better type safety and prevents common mistakes
2. **Combine related elements**: Group overlays and sub-charts logically (e.g., price indicators together, momentum indicators together)
3. **Use sub-charts for different scales**: Indicators with vastly different scales (like RSI 0-100 vs price) work better as sub-charts
4. **Style overlays**: Use custom colors to distinguish multiple overlays on the same chart
5. **Save important charts**: Use the `save()` method to persist charts for reports or documentation

## Examples

See the following example classes for more charting patterns:

- [ADXStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/ADXStrategy.java) - Complex chart with overlays and sub-charts
- [NetMomentumStrategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/NetMomentumStrategy.java) - Analysis criterion overlay example
- [BuyAndSellSignalsToChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/BuyAndSellSignalsToChart.java) - Simple trading record visualization

