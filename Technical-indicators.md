# Technical Indicators

Technical indicators (a.k.a. *technicals*) are used to analyze short-term price movements and to help identify good entry and exit points for the stock. They provide metrics whose values are derived from a bar Series or other indicators.

About technical indicators:

  * [Wikipedia's article on Technical indicators](http://en.wikipedia.org/wiki/Technical_indicator)
  * [Investopedia's definition](http://www.investopedia.com/terms/t/technicalindicator.asp)

In ta4j, all technical indicators implement the `Indicator` interface. So a list of all the indicators provided can be found [in the Javadoc](https://oss.sonatype.org/service/local/repositories/releases/archive/org/ta4j/ta4j-core/0.11/ta4j-core-0.11-javadoc.jar/!/index.html).

### Backtesting indicators

Technicals also need to be backtested on historic data to see how effective they would have been to predict future prices. [Some examples](Usage-examples.html) are available in this sense.

### Caching mechanism

Some indicators need recursive calls and/or values from the previous bars in order to calculate their last value. For that reason, a caching mechanism has been implemented for all the indicators provided by ta4j. This system avoids calculating the same value twice. Therefore, if a value has been already calculated it is retrieved from cache the next time it is requested. **Values for the last Bar will not be cached**. This allows you to modify the last bar of the BarSeries by adding price/trades to it and to recalculate results with indicators.

**Warning!** If a maximum bar count has been set for the related bar Series, then the results calculated for evicted bars are evicted too. They also cannot be recomputed since the related bars have been removed. That being said, moving bar Series should not be used when you need to access long-term past bars.
