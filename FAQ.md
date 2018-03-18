# ta4j FAQ #

## Why does my `Indicator` not match someone else's values? ##

If you are using an `Indicator` that uses an exponential moving average (EMA) such as `EMAIndicator` or `RSIIndicator` then you will have to understand data length dependence and convergence.  The short answer is that you need to "seed" your `Indicator` with several hundred `Bars` of data prior to the indices for which you seek the values or those values will have relatively large error.   

Since EMA's use the prior value in their calculation, the values depend on how many prior values you have.  Related, there is some question as to how to initialize the first value of an EMA.  The first problem is generally solved by including at least 200 `Bars` of `TimeSeries` data prior to the indices for which you are interested.  The second problem is currently solved by setting the first EMA value to the first data value:
```
@Override
protected Num calculate(int index) {
    if (index == 0) {
        return indicator.getValue(0);
    }
```
If a different solution to initialization is required, then the `EMAIndicator` may be extended to a subclass with a different solution to `if (index == 0)`.

* [Exponential moving average](https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average) at Wikipedia
* [Examining the EMA](https://www.fidelity.com/bin-public/060_www_fidelity_com/documents/ExaminingEMA.pdf) at Fidelity
* [Cutler's RSI](https://en.wikipedia.org/wiki/Relative_strength_index#Cutler's_RSI) at Wikipedia
* [StochRSI ta4j vs tradingview](https://github.com/ta4j/ta4j/issues/147#issuecomment-364556354) at Github

Note that due to the volume of questions of this nature, you are highly encourage to fully educate yourself on these issues prior to being engaged in a conversation about them.
