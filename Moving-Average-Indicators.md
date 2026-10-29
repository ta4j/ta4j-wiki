# Summary of Moving Averages

## History of Moving Averages
Moving averages have been a cornerstone of technical analysis for decades. They were first developed in the early 20th century to help traders and analysts smooth out price data and identify trends in financial markets. Among the earliest applications was the **Simple Moving Average (SMA)**, which gained popularity due to its simplicity. Over time, more sophisticated moving averages, such as the **Exponential Moving Average (EMA)**, were introduced to address the lag associated with the SMA. Notable contributions include the work of J. Welles Wilder, who developed the **Wilder’s Moving Average** in his 1978 book, *New Concepts in Technical Trading Systems*. The development of modern computational tools has further enabled innovations like the **Zero Lag EMA (ZLEMA)** and **Displaced Moving Average (DMA)**.

---

## What Moving Averages Can Tell Us
Moving averages provide insight into market trends and price behavior by smoothing out short-term fluctuations in price data. Key takeaways include:

- **Trend Direction**: The slope of a moving average indicates the current trend. An upward slope suggests a bullish trend, while a downward slope indicates a bearish trend.
- **Support and Resistance**: Moving averages often act as dynamic support or resistance levels where prices may reverse or consolidate.
- **Market Momentum**: Comparing shorter and longer-term moving averages (e.g., 50-day vs. 200-day) can reveal momentum and potential shifts in market sentiment.

---

## How Moving Averages Are Used
Moving averages are versatile tools used in a variety of ways:

1. **Identifying Trends**:
   - Traders use moving averages to determine whether the market is trending upwards, downwards, or sideways.
   
2. **Crossover Strategies**:
   - Common strategies involve using two moving averages of different lengths. For example:
     - A **Golden Cross** occurs when a short-term moving average (e.g., 50-day) crosses above a long-term moving average (e.g., 200-day), signaling a potential uptrend.
     - A **Death Cross** occurs when a short-term moving average crosses below a long-term moving average, signaling a potential downtrend.

3. **Support and Resistance**:
   - Moving averages are often used as dynamic support/resistance levels in price charts, providing entry or exit points.

4. **Volatility Reduction**:
   - By smoothing out noise in price data, moving averages help traders focus on the overall trend rather than short-term fluctuations.

5. **Baseline for Indicators**:
   - Many technical indicators, such as Bollinger Bands, MACD, and RSI, are built using moving averages as a foundation.

---

## Moving Averages in TA4J

Package: `org.ta4j.core.indicators.averages`. The classes listed here exist in the [published 0.27.0 release](https://github.com/ta4j/ta4j/releases/tag/0.27.0) (October 19, 2026). Current `master` builds `0.27.1-SNAPSHOT`; changes after the release are not available in 0.27.0.

| Abbreviation | Full Name                                     | Indicator Name             | Moving Average Type            |
|--------------|-----------------------------------------------|----------------------------|--------------------------------|
| ATMA         | Asymmetric Triangular Moving Average          | ATMAIndicator              | Specialized Moving Average     |
| DEMA         | Double Exponential Moving Average             | DoubleEMAIndicator         | Exponential Moving Average     |
| DMA          | Displaced Moving Average                      | DMAIndicator               | Specialized Moving Average     |
| EDMA         | Exponential Displaced Moving Average          | EDMAIndicator              | Exponential Moving Average     |
| EMA          | Exponential Moving Average                    | EMAIndicator               | Exponential Moving Average     |
| EWMA         | Exponentially Weighted Moving Average         | EWMAIndicator              | Exponential Moving Average     |
| HMA          | Hull Moving Average                           | HMAIndicator               | Specialized Moving Average     |
| JMA          | Jurik Moving Average                          | JMAIndicator               | Specialized Moving Average     |
| KAMA         | Kaufman Adaptive Moving Average               | KAMAIndicator              | Adaptive Moving Average        |
| KiJunV2      | Kihon Moving Average                          | KiJunV2Indicator           | Specialized Moving Average     |
| LSMA         | Least Squares Moving Average                  | LSMAIndicator              | Polynomial-Based Moving Average|
| LWMA         | Linear Weighted Moving Average                | LWMAIndicator              | Weighted Moving Average        |
| McGinley     | McGinley Moving Average                       | MCGinleyMAIndicator        | Adaptive Moving Average        |
| MMA          | Modified Moving Average                       | MMAIndicator               | Exponential Moving Average     |
| SMA          | Simple Moving Average                         | SMAIndicator               | Simple Moving Average          |
| SGMA         | Savitzky-Golay Moving Average                 | SGMAIndicator              | Polynomial-Based Moving Average|
| SMMA         | Smoothed Moving Average                       | SMMAIndicator              | Smoothed Moving Average        |
| TEMA         | Triple Exponential Moving Average             | TripleEMAIndicator         | Exponential Moving Average     |
| TMA          | Triangular Moving Average                     | TMAIndicator               | Simple Moving Average          |
| VIDYA        | Chandes Variable Index Dynamic Moving Average | VIDYAIndicator             | Adaptive Moving Average        |
| VWMA         | Volume Weighted Moving Average                | VWMAIndicator              | Weighted Moving Average        |
| WildersMA    | Wilders Moving Average                        | WildersMAIndicator         | Smoothed Moving Average        |
| WMA          | Weighted Moving Average                       | WMAIndicator               | Weighted Moving Average        |
| ZLEMA        | Zero Lag Exponential Moving Average           | ZLEMAIndicator             | Exponential Moving Average     |

Notes:
- The 0.27.0 release contains **24 concrete moving-average indicators** in this package. `AbstractEMAIndicator` is a shared base class, not a separately usable moving average.
- For the complete API index, see [Indicators Inventory](Indicators-Inventory.md).

### EMA or EWMA?

Choose `EMAIndicator` for the familiar period-based smoothing factor `2 / (barCount + 1)`. Choose `EWMAIndicator` when you need to specify the **decay factor** directly: each new result is `previous × decayFactor + current × (1 − decayFactor)`, where `0 < decayFactor < 1`. A smaller decay factor responds more to the latest observation. For EWMA, `barCount` sets the initial simple-average seed window; it does not set the decay factor.

For example, the [0.27.0 EWMA regression test](https://github.com/ta4j/ta4j/blob/0.27.0/ta4j-core/src/test/java/org/ta4j/core/indicators/averages/EWMAIndicatorTest.java) uses inputs `1, 3, 5, 7`, seed window `3`, and decay `0.5`. The result is unavailable (`NaN`) at index `1`, `3` at index `2` (the average of the first three inputs), then `5` at index `3` (`3 × 0.5 + 7 × 0.5`). These are smoothing values, not forecasts or evidence that a trading strategy will profit.

On a bounded series, EWMA needs the complete seed window before those bars are evicted. An already-evaluated indicator can retain its history, but a newly created indicator on a pruned series cannot reconstruct removed observations. If the maximum retained window is shorter than its seed window, it cannot initialize. See [Moving series and continued indicator state](Bar-series-and-bars.md#moving-series-and-continued-indicator-state) for the distinction between continued and fresh indicators.


## Classification of Moving Averages

### 1. Simple Moving Averages
- These averages assign equal weight to all data points in the period.
- **Indicators**:
  - SMA (Simple Moving Average)
  - TMA (Triangular Moving Average)

---

### 2. Weighted Moving Averages
- These averages assign different weights to data points, typically emphasizing recent data.
- **Indicators**:
  - LWMA (Linear Weighted Moving Average)
  - WMA (Weighted Moving Average)
  - VWMA (Volume Weighted Moving Average)

---

### 3. Exponential Moving Averages
- These averages assign exponentially increasing weights to recent data.
- **Indicators**:
  - EMA (Exponential Moving Average)
  - EWMA (Exponentially Weighted Moving Average)
  - ZLEMA (Zero Lag Exponential Moving Average)
  - DEMA (Double Exponential Moving Average)
  - TEMA (Triple Exponential Moving Average)
  - EDMA (Exponential Displaced Moving Average)

---

### 4. Adaptive Moving Averages
- These averages adjust dynamically based on market conditions such as volatility or trend strength.
- **Indicators**:
  - KAMA (Kaufman Adaptive Moving Average)
  - VIDYA (Chande Variable Index Dynamic Moving Average)
  - McGinley (McGinley Moving Average)

---

### 5. Smoothed Moving Averages
- These averages reduce short-term fluctuations to produce a smoother trendline.
- **Indicators**:
  - SMMA (Smoothed Moving Average)
  - WildersMA (Wilder’s Moving Average)

---

### 6. Polynomial-Based Moving Averages
- These averages use polynomial regression or curve fitting to calculate the trend.
- **Indicators**:
  - SGMA (Savitzky-Golay Moving Average)
  - LSMA (Least Squares Moving Average)

---

### 7. Specialized Moving Averages
- These averages use unique algorithms or methodologies for specific purposes.
- **Indicators**:
  - HMA (Hull Moving Average)
  - JMA (Jurik Moving Average)
  - ATMA (Asymmetric Triangular Moving Average)
  - KiJunV2 (Kihon Moving Average)
  - DMA (Displaced Moving Average)




---

## Conclusion
Moving averages remain essential in modern technical analysis due to their simplicity, flexibility, and effectiveness in revealing market trends and dynamics.
