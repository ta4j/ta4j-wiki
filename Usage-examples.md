# Usage Examples
These examples demonstrate different aspects of the Ta4j API. Each example can be separately compiled and executed as a Java main program.

##### Quickstart example

  * [Ta4j quickstart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/Quickstart.java)

##### Time series and Num

  * [How to build a time series with differen Num implementation and more](https://github.com/ta4j/ta4j/blob/develop/ta4j-examples/src/main/java/ta4jexamples/timeSeries/BuildTimeSeries.java)
  * [How to build a time series from trades](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/loaders/CsvTradesLoader.java)
  * [How to build a time series from ticks](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/loaders/CsvTicksLoader.java)
  * [DoubleNum vs BigDecimalNum](https://github.com/ta4j/ta4j/blob/develop/ta4j-examples/src/main/java/ta4jexamples/num/DoubleNumVsBigDecimalNum.java)

##### Playing with indicators

  * [How to create a CSV from indicators](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/IndicatorsToCsv.java)
  * [How to display time series and indicators with JFreeChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/IndicatorsToChart.java)
  * [How to produce the traditional candlestick chart with JFreeChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/indicators/CandlestickChart.java)

##### Trading strategies

  * How to build and run a trading strategy
    * [Example with a CCI correction strategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/CCICorrectionStrategy.java)
    * [Example with a moving momentum strategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/MovingMomentumStrategy.java)
    * [Example with a 2-period RSI strategy](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/strategies/RSI2Strategy.java)
  * [Walk forward optimization](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/walkforward/WalkForward.java)

##### Trading bots

  * [Dummy trading bot example](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/bots/TradingBotOnMovingTimeSeries.java)

##### Logging

  * [How to trace a strategy execution with Logback](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/logging/StrategyExecutionLogging.java)

##### Analysis

  * [How to display the cash flow of a strategy with JFreeChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/CashFlowToChart.java)
  * [Overall trading strategy analysis](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/StrategyAnalysis.java)
  * [How to display the buy/sell signals of a strategy with JFreeChart](https://github.com/ta4j/ta4j/blob/master/ta4j-examples/src/main/java/ta4jexamples/analysis/BuyAndSellSignalsToChart.java)