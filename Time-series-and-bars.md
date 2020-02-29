# Time Series and Bars
A `TimeSeries` contains the aggregated data of a security/commodity into fixed intervals. Each interval ending is represented by a Bar.

A `Bar` contains aggregated data of a security/commodity during a time period. "Aggregated" means that the Tick object does not contain direct exchange data. It merges all the orders operated during the time period and extract:

  * an open price
  * a high price
  * a low price
  * a close price
  * a volume

A Bar is the basic building block of a TimeSeries. Then the time series is used for backtesting or live trading.

> Since release 0.12 the TimeSeries and Bars supports different data types for storing the data and calculating.
> Since release 0.12 the bar creation and management has moved to the TimeSeries. That means it is possible to add the data of a bar directly to the TimeSeries via #addBar(...) functions

### Time series for backtesting

In order to backtest a strategy you need to fill a time series with past data. To do that you just have to create a TimeSeries and add data to it. The following example shows how to create a `BaseTimeSeries` with help of the ``SeriesBuilder`` and how to add data to the series:

```java
TimeSeries series = new BaseTimeSeries.SeriesBuilder().withName("my_2017_series").build();

ZonedDateTime endTime = ZonedDateTime.now();
series.addBar(endTime, 105.42, 112.99, 104.01, 111.42, 1337);
series.addBar(endTime.plusDays(1), 111.43, 112.83, 107.77, 107.99, 1234);
series.addBar(endTime.plusDays(2), 107.90, 117.50, 107.90, 115.42, 4242);
    //...

```

[Those examples](Usage-examples.html) show how to load time series in order to backtest strategies over them.

For this use case, the TimeSeries class provides helper methods to split the series into sub-series, run a trading strategy, etc.

### Time series for live trading

Live trading involves building a time series for current prices. In this use case you just have to initialize your series.

```java
TimeSeries series = new BaseTimeSeries("my_live_series");
```

Then for each tick/bar received from the broker/exchange you have to add it to your series:

```java
series.addBar(ZonedDateTime.now(), 105.42, 112.99, 104.01, 111.42, 1337));
```

Or if you are receiving interperiodic prices and want to add it to the last bar:

```java
series.addPrice(105.44); // will update the close price of the last bar (and min/max price if necessary)
```

The `TimeSeries#addTrade(Number, Number)` function allows you to update the last `Bar` of the series with price and volume data:

```java
series.addTrade(price, volume);
```

You can use the `TimeSeries#addBar(Bar, boolean)` function, thats `replaces` the last `Bar` of the series if the `boolean` flag is `true`.

```java
series.addBar(bar, true) // last bar will be replaced
```

In this mode, we strongly advise you to:

  * initialize your series with the last data from the exchange (as it's described above for backtesting). It ensures your trading strategy will get enough data to be relevant.
  * call the `TimeSeries#setMaximumTickCount(int)` method on your series. It ensures that your memory consumption won't increase infinitely.

**Warning!** Setting a maximum tick count to the series will turn it into a *moving* time series. In this mode trying to get a removed tick will return the first tick found (i.e. the oldest still in memory). It may involve approximations but only for old ticks.