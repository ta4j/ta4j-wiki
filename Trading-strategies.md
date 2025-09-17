# Trading Strategies
A trading strategy is a set of rules designating the conditions that must be met for trade entries and exits to occur.

About trading strategies:

  * [Wikipedia's article on Trading strategy](http://en.wikipedia.org/wiki/Trading_strategy)
  * [Investopedia's definition](http://www.investopedia.com/terms/t/trading-strategy.asp)

In ta4j a trading strategy is made of trading rules.

### Trading rules

Trading rules are designed according to the [specification pattern](http://en.wikipedia.org/wiki/Specification_pattern). They can be combined and chained together using boolean logic:

```java
Rule entryRule = new CrossedUpIndicatorRule(shortSma, longSma)
    .or(new CrossedDownIndicatorRule(closePrice, 800));
```

Ta4j provides a set of basic rules. They are all implementations of the Rule interface and they can be used to build both entry and exit rules.

```java
Rule exitRule = new CrossedDownIndicatorRule(shortSma, longSma)
    .or(new StopLossRule(closePrice, series.numFactory().numOf(3)))
    .or(new StopGainRule(closePrice, series.numFactory().numOf(2)));
```

##### Checking rule condition

Using ta4j, you can check if an entry/exit condition is met by calling the `Rule#isSatisfied(int, TradingRecord)` method. You just have to give:

  * the bar index for which you want to check the condition
  * the `TradingRecord` object (for rules with a complex logic, i.e. using trading history and previous results)

### Trading strategies

A trading strategy is just a pair of rules designed to achieve a profitable return over a bar series. It is made of an entry rule and an exit rule.

```java
Strategy myStrategy = new BaseStrategy(entryRule, exitRule);
```

It can be [backtested](Backtesting.md) over a bar series:

```java
BarSeries series = ...
BarSeriesManager seriesManager = new BarSeriesManager(series);

TradingRecord tradingRecord = seriesManager.run(myStrategy);
```

Or used for [live trading](Live-trading.md), as it's done in [the bot examples](Usage-examples.md#trading-bots).
