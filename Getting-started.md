# Getting Started
Ta4j is an open source Java library for technical analysis. It provides the basic components for creation, evaluation and execution of trading strategies.

About technical analysis:

  * [Wikipedia's article on Technical analysis](http://en.wikipedia.org/wiki/Technical_analysis)
  * [Basics of Technical Analysis](http://www.investopedia.com/university/technical/) (from [Investopedia](http://www.investopedia.com/))

### Eclipse setup

Ta4j is available on Maven. You can [create a Maven project](http://www.tech-recipes.com/rx/39279/create-a-new-maven-project-in-eclipse/) in eclipse and add the ta4j dependency to the pom.xml file.
```
<dependency>
  <groupId>org.ta4j</groupId>
  <artifactId>ta4j-core</artifactId>
  <version>0.15</version>
</dependency>
```
Another way could be to [clone this git repository](https://git-scm.com/book/en/v1/Git-Basics-Getting-a-Git-Repository) or to simply download this library and add the source code to your existing eclipse project.

### Getting started with ta4j

In this quick example we will backtest a trading strategy over a price bar series.

At the beginning we just need a bar series.

```java
// Creating a bar series (from any provider: CSV, web service, etc.)
BarSeries series = CsvTradesLoader.loadBitstampSeries();
```
After creating a `BarSeries` we can add OHLC data and volume to the series:

```java
// adding open, high, low, close and volume data to the series
series.addBar(ZonedDateTime.now(), 105.42, 112.99, 104.01, 111.42, 1337);
```
See the [Bar Series and Bars section](Time-series-and-bars.html) to learn about bar series and to know how you can construct one.

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
Ta4j includes more than 130 [technical indicators](Technical-indicators.html).

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
        .or(new StopLossRule(closePrice, series.numOf(3)))
        .or(new StopGainRule(closePrice, series.numOf(2)));

// Create the strategy
Strategy strategy = new BaseStrategy(buyingRule, sellingRule);
```

Ta4j comes with a set of basic [trading rules/strategies](Trading-strategies.html) which can be combined using boolean operators.

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

// Total return of our strategy vs total return of a buy-and-hold strategy
AnalysisCriterion vsBuyAndHold = new VersusEnterAndHoldCriterion(new ReturnCriterion());
System.out.println("Our return vs buy-and-hold return: " + vsBuyAndHold.calculate(series, tradingRecord));
```

Trading strategies can be easily compared according to [a set of analysis criteria](Backtesting.html).

### Going further

Ta4j can also be used for [live trading](Live-trading.html) with more complicated [strategies](Trading-strategies.html). Check out the rest of the documentation and [the examples](Usage-examples.html).