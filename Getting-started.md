# Getting Started
Ta4j is an open source Java library for technical analysis. It provides the basic components for creation, evaluation and execution of trading strategies.

About technical analysis:

  * [Wikipedia's article on Technical analysis](http://en.wikipedia.org/wiki/Technical_analysis)
  * [Basics of Technical Analysis](http://www.investopedia.com/university/technical/) (from [Investopedia](http://www.investopedia.com/))

### Install via Maven/Gradle

Ta4j is available on Maven Central.

Maven (in your `pom.xml`):
```
<dependency>
  <groupId>org.ta4j</groupId>
  <artifactId>ta4j-core</artifactId>
  <version>0.18</version>
</dependency>
```

Gradle (Groovy DSL):
```
implementation 'org.ta4j:ta4j-core:0.18'
```

You can also [clone this repository](https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository) or download the sources and add the module to your project.

### Getting started with ta4j

In this quick example we will backtest a trading strategy over a price bar series.

At the beginning we just need a bar series.

```java
// Creating a bar series (from any provider: CSV, web service, etc.)
BarSeries series = CsvTradesLoader.loadBitstampSeries();
```
Or build one manually and add bars with the series' bar builder:

```java
// Build an empty series and add bars
BarSeries series = new BaseBarSeriesBuilder().withName("mySeries").build();
Instant endTime = Instant.now();
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
See the [Bar Series and Bars section](Bar-series-and-bars.md) to learn about bar series and to know how you can construct one.

##### Using indicators

We can calculate indicator over this bar series, in order to forecast the direction of prices through the study of past market data.

```java
// Getting the close price of the bars
Num firstClosePrice = series.getBar(0).getClosePrice();
System.out.println("First close price: " + firstClosePrice.doubleValue());
// Or within an indicator:
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
// Here is the same close price:
System.out.println(firstClosePrice.isEqual(closePrice.getValue(0))); // equal to firstClosePrice

// Getting the simple moving average (SMA) of the close price over the last 5 bars
SMAIndicator shortSma = new SMAIndicator(closePrice, 5);
// Here is the 5-bars-SMA value at the 42nd index
System.out.println("5-bars-SMA value at the 42nd index: " + shortSma.getValue(42).doubleValue());

// Getting a longer SMA (e.g. over the 30 last bars)
SMAIndicator longSma = new SMAIndicator(closePrice, 30);
```
Ta4j includes more than 130 [technical indicators](Technical-indicators.md).

##### Building a trading strategy

Then we have to build our trading strategy. Strategies are made of two trading rules: one for entry (buying), the other for exit (selling).

```java
// Buying rules
// We want to buy:
//  - if the 5-bars SMA crosses over 30-bars SMA
//  - or if the price goes below a defined price (e.g $800.00)
Rule buyingRule = new CrossedUpIndicatorRule(shortSma, longSma)
        .or(new CrossedDownIndicatorRule(closePrice, 800));

// Selling rules
// We want to sell:
//  - if the 5-bars SMA crosses under 30-bars SMA
//  - or if the price loses more than 3%
//  - or if the price earns more than 2%
Rule sellingRule = new CrossedDownIndicatorRule(shortSma, longSma)
        .or(new StopLossRule(closePrice, series.numFactory().numOf(3)))
        .or(new StopGainRule(closePrice, series.numFactory().numOf(2)));

// Create the strategy
Strategy strategy = new BaseStrategy(buyingRule, sellingRule);
```

Ta4j comes with a set of basic [trading rules/strategies](Trading-strategies.md) which can be combined using boolean operators.

##### Backtesting/running our juicy strategy

The backtest step is pretty simple:

```java
// Running our juicy trading strategy...
BarSeriesManager seriesManager = new BarSeriesManager(series);
TradingRecord tradingRecord = seriesManager.run(strategy);
System.out.println("Number of positions (trades) for our strategy: " + tradingRecord.getPositionCount());
```

##### Analyzing our results

Here is how we can analyze the results of our backtest:

```java
// Getting the winning positions ratio
AnalysisCriterion winningPositionsRatio = new PositionsRatioCriterion(PositionFilter.PROFIT);
System.out.println("Winning positions ratio: " + winningPositionsRatio.calculate(series, tradingRecord));

// Getting a risk-reward ratio
AnalysisCriterion romad = new ReturnOverMaxDrawdownCriterion();
System.out.println("Return over Max Drawdown: " + romad.calculate(series, tradingRecord));

// Net return of our strategy vs net return of a buy-and-hold strategy
AnalysisCriterion vsBuyAndHold = new VersusEnterAndHoldCriterion(new NetReturnCriterion());
System.out.println("Our net return vs buy-and-hold net return: " + vsBuyAndHold.calculate(series, tradingRecord));
```

Trading strategies can be easily compared according to [a set of analysis criteria](Backtesting.md).

##### Visualizing your results

Ta4j provides powerful charting capabilities to visualize your trading strategies. You can create charts with price data, indicators, trading signals, and performance metrics.

```java
// Create a chart with trading record overlay
ChartMaker chartMaker = new ChartMaker();
chartMaker.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .display();
```

For more advanced charting, you can add indicator overlays and sub-charts:

```java
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
SMAIndicator sma = new SMAIndicator(closePrice, 50);

chartMaker.builder()
    .withSeries(series)
    .withTradingRecordOverlay(tradingRecord)
    .withIndicatorOverlay(sma)
    .withLineColor(Color.ORANGE)
    .withSubChart(new NetProfitCriterion(), tradingRecord)
    .display();
```

See the [Charting Guide](Charting.md) for comprehensive documentation on creating sophisticated trading charts.

### Going further

Ta4j can also be used for [live trading](Live-trading.md) with more complicated [strategies](Trading-strategies.md). Check out the rest of the documentation and [the examples](Usage-examples.md).