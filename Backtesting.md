# Backtesting

In financial analysis, backtesting seeks to estimate the performance of a strategy if it had been employed during a past period.

About backtesting:

  * [Wikipedia's article on Backtesting](http://en.wikipedia.org/wiki/Backtesting)
  * [Investopedia's definition](http://www.investopedia.com/terms/b/backtesting.asp)

Backtesting is the main use case of ta4j.

### Running your backtest

Once you constructed [your bar series](Bar-series-and-bars.md) and [your trading strategy](Trading-strategies.md), you can backtest the strategy by just calling:

```java
BarSeries series = ...
BarSeriesManager seriesManager = new BarSeriesManager(series);
Strategy myStrategy = ...

TradingRecord tradingRecord = seriesManager.run(myStrategy);
```

That's it! You get a `TradingRecord` object which is the record of the resulting trading session (basically a list of trades/orders).
By providing different strategies to the `BarSeriesManager#run(Strategy)` methods, you get different `TradingRecord` objects and you can compare them according to analysis criteria.

### Analyzing strategies

Let's assume you backtested `strategy1` and `strategy2` over a `series`. You get two `TradingRecord` objects: `record1` and `record2`.

In order to get the profitability ratio of each strategy you have to give those records to an analysis criterion:

```java
AnalysisCriterion criterion = new TotalProfitCriterion();
criterion.calculate(series, record1); // Returns the result for strategy1
criterion.calculate(series, record2); // Returns the result for strategy2
```

If you just want to get the best strategy according to an analysis criterion you just have to call:

```java
BarSeriesManager seriesManager = new BarSeriesManager(series);
Strategy bestStrategy = criterion.chooseBest(seriesManager, Arrays.asList(strategy1, strategy2));
```

Ta4j comes with several analysis criteria which are all listed [in the Javadoc](https://oss.sonatype.org/service/local/repositories/releases/archive/org/ta4j/ta4j-core/0.17/ta4j-core-0.17-javadoc.jar/!/org/ta4j/core/criteria/package-summary.html).
### Walk-forward optimization

Ta4j allows you to perform a well-known *Walk-forward* optimization. An example can be found [here](Usage-examples.md).
