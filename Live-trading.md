# Live Trading
Ta4j can also be used to build automated trading systems.

About automated trading:

  * [Wikipedia's article on Automated trading system](http://en.wikipedia.org/wiki/Automated_trading_system) and [Investopedia's definition](http://www.investopedia.com/articles/trading/11/automated-trading-systems.asp)
  * [Wikipedia's article on Algorithmic trading](http://en.wikipedia.org/wiki/Algorithmic_trading) and [Investopedia's definition](http://www.investopedia.com/terms/a/algorithmictrading.asp)

In order to build an automated trading system (a.k.a. trading bot) you have to think about two states of your program: the initialization phase and the trading phase.

### Initialization phase

In the same way than for [backtesting](Backtesting), you have to initialize the system before running it. It involves having [[created your time series|Time series and ticks]] and [[built your trading strategy|Trading strategies]] before.

Even if you will keep your series constantly updated with new ticks, you should initialize it with the most recent ticks the exchange can give you. Thus your strategy will have a more predictable/relevant behavior during the first steps of the trading phase. For instance, let's assume:

  * We have 3 ticks: `5, 10, 30` (close prices)
  * Your strategy computes a `SMA(3)`

If you start your trading phase on the 3rd tick:

  * Without initialization: `SMA(3) --> 30 / 1 = 30`
  * After your series have been initialized with last ticks: `SMA(3) --> (5 + 10 + 30) / 3 = 15`

##### Maximum bar count

Since you will continuously feed your bar series with new ticks during the trading phase, it will grow infinitely and you will encounter memory issues soon. To avoid that you have to set a maximum bar count to your series. It represents the maximum number of ticks your trading strategy needs to be run.

For instance: if your strategy relies on a SMA(200) and a RSI(2), then your maximum bar count should be 200. You may want to set it to 400 (it's more an order of magnitude than a strict value, but it has to be larger than the maximum tick count you need); it will ensure that your series will never be more than 400-ticks long (i.e. adding a new tick will be preceded with the deletion of the oldest tick).

You just have to call the `BarSeries#setMaximumTickCount(int)` method.

### Trading phase

The trading phase itself can be designed as a simple infinite loop in which you wait for a new bar from the broker/exchange before interrogating your strategy.

```java
Bar newBar = // Get the exchange new tick here...;
series.addBar(newBar);
```

**Since release 0.12 you can also add the bar data directly to your TimeSeries with the addBar(data...) functions. This is the recommended way:**
```java
series.addBar(ZonedDateTime.now(),5,10,1,9); // add data directly to the series
```

If you are receiving intertemporal price and/or trade information, you can also update the last bar of the series:
```java
series.addPrice(5) // updates the close price of the last bar (and min/max price if necessary)
series.addTrade(7, 10) // updates amount and price of the last bar
```

Since you use a moving (see above) time series, you run your strategy on this new bar: the bar index is always `series.getEndIndex()`. (Take a look at the [Num article](Num.html) to understand why `DoubleNum::valueOf` functions are needed)

```java
int endIndex = series.getEndIndex();
if (strategy.shouldEnter(endIndex)) {
    // Entering...
    tradingRecord.enter(endIndex, newTick.getClosePrice(), DoubleNum.valueOf(10));
} else if (strategy.shouldExit(endIndex)) {
    // Exiting...
    tradingRecord.exit(endIndex, newTick.getClosePrice(), DoubleNum.valueOf(10));
}
```

Note that the strategy gives you a *you-should-enter* information, then it's up to you to call the `TradingRecord#enter()`/`TradingRecord#exit()` methods with the price you'll really spend. It's justified by the fact that you may not follow your strategy on any signal; this way you can take external events into account.

This documentation has also [live trading engine examples](Usage-examples.html).
