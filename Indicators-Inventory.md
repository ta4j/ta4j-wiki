# Indicators Inventory

This page is an **exhaustive inventory** of all indicators in **ta4j-core** and **ta4j-examples**, with fully qualified names, class names, short codebase descriptions, and minimal usage guidance. It is intended as a reference and a base for future expansion (detailed use cases, example code, and cross-references).

For an overview of indicator categories and composition patterns, see [Technical Indicators](Technical-indicators.md). For moving averages in depth, see [Moving Average Indicators](Moving-Average-Indicators.md). For Elliott Wave indicators, see [Elliott Wave Indicators](Elliott-Wave-Indicators.md).

---

## Table of contents

1. [Helpers (price, volume, transforms)](#1-helpers-price-volume-transforms)
2. [Moving averages](#2-moving-averages)
3. [Volatility & bands](#3-volatility--bands)
4. [Momentum & oscillators](#4-momentum--oscillators)
5. [Trend (ADX, Aroon, Ichimoku, SuperTrend, etc.)](#5-trend-adx-aroon-ichimoku-supertrend-etc)
6. [Volume](#6-volume)
7. [Candlestick & pattern](#7-candlestick--pattern)
8. [Support / resistance & pivots](#8-support--resistance--pivots)
9. [Swing & zigzag](#9-swing--zigzag)
10. [Elliott Wave](#10-elliott-wave)
11. [Statistics & numeric](#11-statistics--numeric)
12. [Renko](#12-renko)
13. [Analysis (PnL, returns, cash flow)](#13-analysis-pnl-returns-cash-flow)
14. [Charting (ta4j-examples)](#14-charting-ta4j-examples)

---

## 1. Helpers (price, volume, transforms)

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.helpers` | **ClosePriceIndicator** | Returns the close price of a bar. |
| `org.ta4j.core.indicators.helpers` | **OpenPriceIndicator** | Returns the open price of a bar. |
| `org.ta4j.core.indicators.helpers` | **HighPriceIndicator** | Returns the high price of a bar. |
| `org.ta4j.core.indicators.helpers` | **LowPriceIndicator** | Returns the low price of a bar. |
| `org.ta4j.core.indicators.helpers` | **TypicalPriceIndicator** | Typical price (high + low + close) / 3. |
| `org.ta4j.core.indicators.helpers` | **MedianPriceIndicator** | Median price (high + low) / 2. |
| `org.ta4j.core.indicators.helpers` | **TRIndicator** | True Range: max(high−low, |high−prevClose|, |low−prevClose|). |
| `org.ta4j.core.indicators.helpers` | **VolumeIndicator** | Returns the volume of a bar. |
| `org.ta4j.core.indicators.helpers` | **ClosePriceDifferenceIndicator** | Difference between current and previous close (extends DifferenceIndicator). |
| `org.ta4j.core.indicators.helpers` | **ClosePriceRatioIndicator** | Ratio of current close to previous close. |
| `org.ta4j.core.indicators.helpers` | **DifferenceIndicator** | Difference between two indicators or consecutive values. |
| `org.ta4j.core.indicators.helpers` | **DifferencePercentageIndicator** | Percentage difference between two indicators. |
| `org.ta4j.core.indicators.helpers` | **GainIndicator** | Positive price changes (gains) from the source indicator. |
| `org.ta4j.core.indicators.helpers` | **LossIndicator** | Absolute value of negative price changes (losses). |
| `org.ta4j.core.indicators.helpers` | **HighestValueIndicator** | Highest value of the source indicator over a bar count. |
| `org.ta4j.core.indicators.helpers` | **LowestValueIndicator** | Lowest value of the source indicator over a bar count. |
| `org.ta4j.core.indicators.helpers` | **PreviousValueIndicator** | Value of the source indicator at the previous index. |
| `org.ta4j.core.indicators.helpers` | **SumIndicator** | Sum of the source indicator over a bar count. |
| `org.ta4j.core.indicators.helpers` | **AverageIndicator** | Average (mean) of the source indicator over a bar count. |
| `org.ta4j.core.indicators.helpers` | **RunningTotalIndicator** | Running sum of the source indicator. |
| `org.ta4j.core.indicators.helpers` | **CombineIndicator** | Combines two indicators with a binary operator (e.g. add, subtract). |
| `org.ta4j.core.indicators.helpers` | **ConstantIndicator** | Constant value at every index. |
| `org.ta4j.core.indicators.helpers` | **FixedNumIndicator** | Fixed numeric value; useful for testing or thresholds. |
| `org.ta4j.core.indicators.helpers` | **FixedBooleanIndicator** | Fixed boolean value. |
| `org.ta4j.core.indicators.helpers` | **FixedIndicator** | Wraps a single value as an indicator over the series length. |
| `org.ta4j.core.indicators.helpers` | **BooleanTransformIndicator** | Converts a numeric indicator to boolean via a threshold or condition. |
| `org.ta4j.core.indicators.helpers` | **CrossIndicator** | Detects crosses between two indicators (e.g. cross up/down). |
| `org.ta4j.core.indicators.helpers` | **ConvergenceDivergenceIndicator** | Convergence/divergence between two indicators. |
| `org.ta4j.core.indicators.helpers` | **CloseLocationValueIndicator** | CLV: where close sits in the bar range (-1 to 1). |
| `org.ta4j.core.indicators.helpers` | **DateTimeIndicator** | Returns the end time of each bar (or equivalent) as a numeric value. |
| `org.ta4j.core.indicators.helpers` | **PercentageChangeIndicator** | Percentage change of the source indicator over a period. |
| `org.ta4j.core.indicators.helpers` | **PercentRankIndicator** | Percent rank of the current value within a look-back window. |
| `org.ta4j.core.indicators.helpers` | **StreakIndicator** | Consecutive up or down streaks from the source indicator. |
| `org.ta4j.core.indicators.helpers` | **AmountIndicator** | Wraps a fixed amount (e.g. for position sizing). |
| `org.ta4j.core.indicators.helpers` | **NumIndicator** | Wraps a Num value as an indicator. |
| `org.ta4j.core.indicators.helpers` | **TradeCountIndicator** | Number of trades in the bar (when available). |
| `org.ta4j.core.indicators.helpers` | **UnstableIndicator** | Returns NaN for indices within the unstable period; used for warm-up. |

**Short usage (per-indicator expansion)**  
- **What it is:** As in the table (e.g. close price, true range, running sum).  
- **Theory:** N/A for raw price/volume; for transforms, standard TA (e.g. True Range for volatility).  
- **When to use:** As building blocks for other indicators and rules (e.g. ClosePrice → SMA, RSI; TR → ATR).  
- **When not to use:** When a higher-level indicator (e.g. ATR, RSI) already encapsulates the logic.  
- *Future: use cases, example code.*

---

## 2. Moving averages

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.averages` | **SMAIndicator** | Simple moving average. |
| `org.ta4j.core.indicators.averages` | **EMAIndicator** | Exponential moving average; smoothing 2/(n+1); robust NaN handling and unstable period. |
| `org.ta4j.core.indicators.averages` | **MMAIndicator** | Modified moving average (Wilder-style); used in RSI, ADX. |
| `org.ta4j.core.indicators.averages` | **WildersMAIndicator** | Wilder's smoothing; same as MMA for RSI/ADX. |
| `org.ta4j.core.indicators.averages` | **WMAIndicator** | Linear weighted moving average. |
| `org.ta4j.core.indicators.averages` | **LWMAIndicator** | Linear weighted moving average (alternate implementation). |
| `org.ta4j.core.indicators.averages` | **VWMAIndicator** | Volume-weighted moving average. |
| `org.ta4j.core.indicators.averages` | **SMMAIndicator** | Smoothed moving average. |
| `org.ta4j.core.indicators.averages` | **DoubleEMAIndicator** | Double exponential moving average. |
| `org.ta4j.core.indicators.averages` | **TripleEMAIndicator** | Triple exponential moving average. |
| `org.ta4j.core.indicators.averages` | **HMAIndicator** | Hull moving average (reduces lag). |
| `org.ta4j.core.indicators.averages` | **JMAIndicator** | Jurik moving average; smooth response with reduced lag. |
| `org.ta4j.core.indicators.averages` | **KAMAIndicator** | Kaufman adaptive moving average; adapts to volatility. |
| `org.ta4j.core.indicators.averages` | **MCGinleyMAIndicator** | McGinley dynamic; reduces lag and adapts to market speed. |
| `org.ta4j.core.indicators.averages` | **VIDYAIndicator** | Chande VIDYA; smoothing adjusted by CMO (volatility). |
| `org.ta4j.core.indicators.averages` | **TMAIndicator** | Triangular moving average; double-smoothed SMA. |
| `org.ta4j.core.indicators.averages` | **LSMAIndicator** | Least squares moving average (linear regression over window). |
| `org.ta4j.core.indicators.averages` | **SGMAIndicator** | Savitzky–Golay moving average; polynomial smoothing. |
| `org.ta4j.core.indicators.averages` | **DMAIndicator** | Displaced moving average; EMA shifted in time. |
| `org.ta4j.core.indicators.averages` | **EDMAIndicator** | Exponential displaced moving average. |
| `org.ta4j.core.indicators.averages` | **ZLEMAIndicator** | Zero-lag exponential moving average. |
| `org.ta4j.core.indicators.averages` | **ATMAIndicator** | Asymmetric triangular moving average. |
| `org.ta4j.core.indicators.averages` | **KiJunV2Indicator** | Kihon (Ichimoku-style) midpoint of high-low range over period. |

**Short usage**  
- **What it is:** Smoothing of price (or other series) over a window; type varies (simple, exponential, weighted, adaptive).  
- **Theory:** Averages reduce noise and lag; EMAs weight recent data more; adaptive MAs (KAMA, VIDYA, McGinley) adjust to volatility or speed.  
- **When to use:** Trend identification, crossover strategies, dynamic support/resistance, and as inputs to MACD, Bollinger, etc.  
- **When not to use:** In very fast scalping without tuning; or when lag is unacceptable and a faster variant (e.g. HMA, ZLEMA) is preferred.  
- *Future: use cases, example code.*  
- See also: [Moving Average Indicators](Moving-Average-Indicators.md).

---

## 3. Volatility & bands

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators` | **ATRIndicator** | Average True Range; MMA of True Range. |
| `org.ta4j.core.indicators.bollinger` | **BollingerBandsUpperIndicator** | Upper Bollinger Band (middle + k × std dev). |
| `org.ta4j.core.indicators.bollinger` | **BollingerBandsLowerIndicator** | Lower Bollinger Band (middle − k × std dev). |
| `org.ta4j.core.indicators.bollinger` | **BollingerBandsMiddleIndicator** | Middle line (e.g. SMA of close). |
| `org.ta4j.core.indicators.bollinger` | **BollingerBandWidthIndicator** | Band width (upper − lower) or normalized. |
| `org.ta4j.core.indicators.bollinger` | **PercentBIndicator** | %B: where price is within the bands (0–1 scale). |
| `org.ta4j.core.indicators.keltner` | **KeltnerChannelMiddleIndicator** | Keltner middle (e.g. EMA). |
| `org.ta4j.core.indicators.keltner` | **KeltnerChannelUpperIndicator** | Keltner upper band (middle + multiplier × ATR). |
| `org.ta4j.core.indicators.keltner` | **KeltnerChannelLowerIndicator** | Keltner lower band. |
| `org.ta4j.core.indicators.donchian` | **DonchianChannelUpperIndicator** | Highest high over the period. |
| `org.ta4j.core.indicators.donchian` | **DonchianChannelLowerIndicator** | Lowest low over the period. |
| `org.ta4j.core.indicators.donchian` | **DonchianChannelMiddleIndicator** | Midpoint of Donchian channel. |
| `org.ta4j.core.indicators` | **ChandelierExitLongIndicator** | Chandelier Exit (long): highest high minus ATR-based offset. |
| `org.ta4j.core.indicators` | **ChandelierExitShortIndicator** | Chandelier Exit (short): lowest low plus ATR-based offset. |
| `org.ta4j.core.indicators` | **ChopIndicator** | Choppiness Index (0–100); measures trend vs range. |
| `org.ta4j.core.indicators` | **UlcerIndexIndicator** | Ulcer Index; depth and duration of drawdowns. |
| `org.ta4j.core.indicators` | **SqueezeProIndicator** | Squeeze Pro; momentum in low volatility (e.g. Bollinger vs Keltner). |

**Short usage**  
- **What it is:** ATR measures volatility; Bollinger/Keltner/Donchian define channels; Chandelier/Chop/Ulcer/SqueezePro add exit or regime context.  
- **Theory:** Volatility expands in trends and contracts in consolidation; bands and ATR-based stops adapt to current volatility.  
- **When to use:** Stops (ATR, Chandelier), breakout/mean-reversion (bands, %B), and filtering (Chop, SqueezePro).  
- **When not to use:** When volatility input (e.g. ATR) is not yet stable (respect unstable bars).  
- *Future: use cases, example code.*

---

## 4. Momentum & oscillators

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators` | **RSIIndicator** | Relative Strength Index; Welles Wilder formula (gain/loss smoothing). |
| `org.ta4j.core.indicators` | **StochasticRSIIndicator** | Stochastic of RSI: (RSI − min RSI) / (max RSI − min RSI) over period. |
| `org.ta4j.core.indicators` | **StochasticIndicator** | Stochastic oscillator (K and D style). |
| `org.ta4j.core.indicators` | **StochasticOscillatorKIndicator** | Stochastic %K. |
| `org.ta4j.core.indicators` | **StochasticOscillatorDIndicator** | Stochastic %D (smoothed %K). |
| `org.ta4j.core.indicators` | **MACDIndicator** | MACD (APO): short EMA − long EMA. |
| `org.ta4j.core.indicators` | **MACDVIndicator** | MACD with volume weighting. |
| `org.ta4j.core.indicators` | **PPOIndicator** | Percentage Price Oscillator (MACD as % of longer EMA). |
| `org.ta4j.core.indicators` | **ROCIndicator** | Rate of change (price change over period). |
| `org.ta4j.core.indicators` | **CMOIndicator** | Chande Momentum Oscillator. |
| `org.ta4j.core.indicators` | **NetMomentumIndicator** | Net momentum (e.g. gains minus losses over period). |
| `org.ta4j.core.indicators` | **WilliamsRIndicator** | Williams %R (overbought/oversold oscillator). |
| `org.ta4j.core.indicators` | **CCIIndicator** | Commodity Channel Index. |
| `org.ta4j.core.indicators` | **KRIIndicator** | Klinger Volume Oscillator (simplified or full). |
| `org.ta4j.core.indicators` | **AwesomeOscillatorIndicator** | Awesome Oscillator (median price, 5 vs 34 period). |
| `org.ta4j.core.indicators` | **AccelerationDecelerationIndicator** | AC: acceleration/deceleration of momentum. |
| `org.ta4j.core.indicators` | **TrueStrengthIndexIndicator** | TSI: double-smoothed momentum. |
| `org.ta4j.core.indicators` | **SchaffTrendCycleIndicator** | Schaff Trend Cycle; MACD + stochastic-style normalization. |
| `org.ta4j.core.indicators` | **ConnorsRSIIndicator** | Connors RSI (streak + RSI components). |
| `org.ta4j.core.indicators` | **FisherIndicator** | Fisher transform (normalizes price to Gaussian-like). |
| `org.ta4j.core.indicators` | **RAVIIndicator** | Range Action Verification Index; optional absolute value. |
| `org.ta4j.core.indicators` | **IntraDayMomentumIndexIndicator** | Intraday momentum index. |
| `org.ta4j.core.indicators` | **CoppockCurveIndicator** | Coppock Curve (long-term momentum). |
| `org.ta4j.core.indicators` | **KSTIndicator** | Know Sure Thing (weighted ROC sum). |
| `org.ta4j.core.indicators` | **DPOIndicator** | Detrended Price Oscillator. |
| `org.ta4j.core.indicators` | **DistanceFromMAIndicator** | Distance of price from a moving average. |
| `org.ta4j.core.indicators` | **KalmanFilterIndicator** | Kalman filter on price (smoothing/estimation). |
| `org.ta4j.core.indicators` | **RWIHighIndicator** | RWI high (range expansion). |
| `org.ta4j.core.indicators` | **RWILowIndicator** | RWI low. |
| `org.ta4j.core.indicators` | **MassIndexIndicator** | Mass Index (range expansion for reversals). |
| `org.ta4j.core.indicators` | **ParabolicSarIndicator** | Parabolic SAR (trailing stop / trend). |

**Short usage**  
- **What it is:** Oscillators and momentum measures (RSI, Stochastic, MACD, ROC, CCI, etc.) from price and optionally volume.  
- **Theory:** Momentum leads or confirms price; overbought/oversold and divergence often used for reversals or filters.  
- **When to use:** Entry/exit signals, divergence, trend confirmation, and blending with trend/volume (e.g. NetMomentum + MACD).  
- **When not to use:** In strong trends without trend filter; or when period is too short (noisy).  
- *Future: use cases, example code.*

---

## 5. Trend (ADX, Aroon, Ichimoku, SuperTrend, etc.)

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.adx` | **ADXIndicator** | Average Directional Index; strength of trend. |
| `org.ta4j.core.indicators.adx` | **DXIndicator** | Directional Movement index (raw). |
| `org.ta4j.core.indicators.adx` | **PlusDIIndicator** | +DI (plus directional indicator). |
| `org.ta4j.core.indicators.adx` | **MinusDIIndicator** | −DI. |
| `org.ta4j.core.indicators.adx` | **PlusDMIndicator** | +DM (plus directional movement). |
| `org.ta4j.core.indicators.adx` | **MinusDMIndicator** | −DM. |
| `org.ta4j.core.indicators.aroon` | **AroonUpIndicator** | Aroon Up (periods since highest high). |
| `org.ta4j.core.indicators.aroon` | **AroonDownIndicator** | Aroon Down (periods since lowest low). |
| `org.ta4j.core.indicators.aroon` | **AroonOscillatorIndicator** | Aroon Up − Aroon Down. |
| `org.ta4j.core.indicators.ichimoku` | **IchimokuTenkanSenIndicator** | Tenkan-sen (conversion line). |
| `org.ta4j.core.indicators.ichimoku` | **IchimokuKijunSenIndicator** | Kijun-sen (base line). |
| `org.ta4j.core.indicators.ichimoku` | **IchimokuSenkouSpanAIndicator** | Senkou Span A (leading span A). |
| `org.ta4j.core.indicators.ichimoku` | **IchimokuSenkouSpanBIndicator** | Senkou Span B (leading span B). |
| `org.ta4j.core.indicators.ichimoku` | **IchimokuChikouSpanIndicator** | Chikou Span (lagging span). |
| `org.ta4j.core.indicators.ichimoku` | **IchimokuLineIndicator** | Generic Ichimoku line (configurable). |
| `org.ta4j.core.indicators.supertrend` | **SuperTrendIndicator** | SuperTrend: ATR-based dynamic support/resistance; flips between upper/lower band. |
| `org.ta4j.core.indicators.supertrend` | **SuperTrendUpperBandIndicator** | SuperTrend upper band. |
| `org.ta4j.core.indicators.supertrend` | **SuperTrendLowerBandIndicator** | SuperTrend lower band. |
| `org.ta4j.core.indicators.trend` | **UpTrendIndicator** | Boolean: price in uptrend (e.g. above MA). |
| `org.ta4j.core.indicators.trend` | **DownTrendIndicator** | Boolean: price in downtrend. |

**Short usage**  
- **What it is:** ADX/DI measure trend strength and direction; Aroon and Ichimoku add structure; SuperTrend gives a single trend line.  
- **Theory:** Trend strength (ADX) filters choppy markets; Ichimoku and SuperTrend provide levels and direction.  
- **When to use:** Filtering entries (e.g. only when ADX &gt; 25), trend-following exits (SuperTrend), and multi-timeframe structure (Ichimoku).  
- **When not to use:** In ranging markets (ADX low) for trend-only strategies; SuperTrend can whipsaw in chop.  
- *Future: use cases, example code.*

---

## 6. Volume

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.volume` | **OnBalanceVolumeIndicator** | OBV: cumulative volume signed by close direction. |
| `org.ta4j.core.indicators.volume` | **AccumulationDistributionIndicator** | A/D: cumulative volume weighted by CLV. |
| `org.ta4j.core.indicators.volume` | **ChaikinMoneyFlowIndicator** | CMF: volume-weighted money flow over period. |
| `org.ta4j.core.indicators.volume` | **ChaikinOscillatorIndicator** | Chaikin Oscillator (A/D short − long EMA). |
| `org.ta4j.core.indicators.volume` | **MoneyFlowIndexIndicator** | MFI: volume-weighted RSI-style oscillator. |
| `org.ta4j.core.indicators.volume` | **VWAPIndicator** | Volume-weighted average price (from open). |
| `org.ta4j.core.indicators.volume` | **MVWAPIndicator** | Moving VWAP (VWAP over a rolling window). |
| `org.ta4j.core.indicators.volume` | **NVIIndicator** | Negative Volume Index. |
| `org.ta4j.core.indicators.volume` | **PVIIndicator** | Positive Volume Index. |
| `org.ta4j.core.indicators.volume` | **IIIIndicator** | Intraday Intensity Index. |
| `org.ta4j.core.indicators.volume` | **ROCVIndicator** | Rate of change of volume. |
| `org.ta4j.core.indicators.volume` | **RelativeVolumeStandardDeviationIndicator** | Volume relative to average (e.g. in standard deviations). |
| `org.ta4j.core.indicators.volume` | **TimeSegmentedVolumeIndicator** | Volume segmented by time (e.g. intraday buckets). |
| `org.ta4j.core.indicators` | **PVOIndicator** | Percentage Volume Oscillator (short − long volume MA). |

**Short usage**  
- **What it is:** Volume-based indicators: OBV, A/D, Chaikin, MFI, VWAP, PVI/NVI, III, ROCV, relative volume, PVO.  
- **Theory:** Volume confirms price moves; accumulation/distribution and VWAP help assess institutional flow and fair value.  
- **When to use:** Confirming breakouts, divergence with price, and VWAP as reference for execution.  
- **When not to use:** When volume data is missing or unreliable (e.g. some instruments or bars).  
- *Future: use cases, example code.*

---

## 7. Candlestick & pattern

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.candles` | **DojiIndicator** | True when bar is doji (open ≈ close). |
| `org.ta4j.core.indicators.candles` | **RealBodyIndicator** | Size of real body (|close − open|). |
| `org.ta4j.core.indicators.candles` | **UpperShadowIndicator** | Upper shadow (high − max(open, close)). |
| `org.ta4j.core.indicators.candles` | **LowerShadowIndicator** | Lower shadow (min(open, close) − low). |
| `org.ta4j.core.indicators.candles` | **HammerIndicator** | Hammer pattern (long lower shadow, small body). |
| `org.ta4j.core.indicators.candles` | **HangingManIndicator** | Hanging Man (hammer-like at top). |
| `org.ta4j.core.indicators.candles` | **InvertedHammerIndicator** | Inverted hammer. |
| `org.ta4j.core.indicators.candles` | **ShootingStarIndicator** | Shooting star. |
| `org.ta4j.core.indicators.candles` | **BullishEngulfingIndicator** | Bullish engulfing (current body engulfs previous). |
| `org.ta4j.core.indicators.candles` | **BearishEngulfingIndicator** | Bearish engulfing. |
| `org.ta4j.core.indicators.candles` | **BullishHaramiIndicator** | Bullish harami. |
| `org.ta4j.core.indicators.candles` | **BearishHaramiIndicator** | Bearish harami. |
| `org.ta4j.core.indicators.candles` | **BullishMarubozuIndicator** | Bullish marubozu (full body, no/small shadows). |
| `org.ta4j.core.indicators.candles` | **BearishMarubozuIndicator** | Bearish marubozu. |
| `org.ta4j.core.indicators.candles` | **MorningStarIndicator** | Morning star (three-candle reversal). |
| `org.ta4j.core.indicators.candles` | **EveningStarIndicator** | Evening star. |
| `org.ta4j.core.indicators.candles` | **DarkCloudIndicator** | Dark cloud cover. |
| `org.ta4j.core.indicators.candles` | **PiercingIndicator** | Piercing line. |
| `org.ta4j.core.indicators.candles` | **BullishKickerIndicator** | Bullish kicker (gap + opposite body). |
| `org.ta4j.core.indicators.candles` | **BearishKickerIndicator** | Bearish kicker. |
| `org.ta4j.core.indicators.candles` | **ThreeWhiteSoldiersIndicator** | Three white soldiers. |
| `org.ta4j.core.indicators.candles` | **ThreeBlackCrowsIndicator** | Three black crows. |
| `org.ta4j.core.indicators.candles` | **ThreeInsideUpIndicator** | Three inside up. |
| `org.ta4j.core.indicators.candles` | **ThreeInsideDownIndicator** | Three inside down. |

**Short usage**  
- **What it is:** Single- or multi-candle pattern detectors returning boolean (or equivalent) at each bar.  
- **Theory:** Price action patterns (engulfing, harami, stars, etc.) are used for reversal or continuation signals.  
- **When to use:** As entry/exit conditions or filters combined with trend/volume.  
- **When not to use:** Alone in low-liquidity or highly noisy data; combine with other confirmation.  
- *Future: use cases, example code.*

---

## 8. Support / resistance & pivots

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.supportresistance` | **TrendLineSupportIndicator** | Support level from trend line (e.g. swing lows). |
| `org.ta4j.core.indicators.supportresistance` | **TrendLineResistanceIndicator** | Resistance level from trend line. |
| `org.ta4j.core.indicators.pivotpoints` | **PivotPointIndicator** | Standard pivot point (and optionally R1/R2/S1/S2). |
| `org.ta4j.core.indicators.pivotpoints` | **DeMarkPivotPointIndicator** | DeMark pivot points. |
| `org.ta4j.core.indicators.pivotpoints` | **StandardReversalIndicator** | Reversal level from standard pivots. |
| `org.ta4j.core.indicators.pivotpoints` | **DeMarkReversalIndicator** | DeMark reversal levels. |
| `org.ta4j.core.indicators.pivotpoints` | **FibonacciReversalIndicator** | Fibonacci-based reversal levels from pivots. |
| `org.ta4j.core.indicators` | **SwingPointMarkerIndicator** | Marks swing high/low points (e.g. for trend lines). |

**Short usage**  
- **What it is:** Trend-line-based support/resistance and pivot-based (standard, DeMark, Fibonacci) levels.  
- **Theory:** Pivots and trend lines define key levels for intraday or swing trading.  
- **When to use:** Day/session pivots, break/retest strategies, and trend-line bounces.  
- **When not to use:** When bar series is not aligned to session (e.g. session-based pivots on non-session data).  
- *Future: use cases, example code.*  
- See also: [Trendlines & Swing Points](Trendlines-and-Swing-Points.md).

---

## 9. Swing & zigzag

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators` | **RecentSwingHighIndicator** | Price of the most recent confirmed swing high. |
| `org.ta4j.core.indicators` | **RecentSwingLowIndicator** | Price of the most recent confirmed swing low. |
| `org.ta4j.core.indicators` | **RecentSwingIndicator** | Generic recent swing (e.g. value at last swing). |
| `org.ta4j.core.indicators` | **RecentFractalSwingHighIndicator** | Most recent fractal swing high (Bill Williams style). |
| `org.ta4j.core.indicators` | **RecentFractalSwingLowIndicator** | Most recent fractal swing low. |
| `org.ta4j.core.indicators.zigzag` | **ZigZagPivotHighIndicator** | True at ZigZag pivot high bars. |
| `org.ta4j.core.indicators.zigzag` | **ZigZagPivotLowIndicator** | True at ZigZag pivot low bars. |
| `org.ta4j.core.indicators.zigzag` | **ZigZagStateIndicator** | ZigZag state (e.g. current segment direction and levels). |
| `org.ta4j.core.indicators.zigzag` | **RecentZigZagSwingHighIndicator** | Most recent ZigZag swing high price. |
| `org.ta4j.core.indicators.zigzag` | **RecentZigZagSwingLowIndicator** | Most recent ZigZag swing low price. |

**Short usage**  
- **What it is:** Swing high/low and ZigZag pivots; “recent” variants expose the last confirmed swing level.  
- **Theory:** Swing points define structure; ZigZag filters small moves and highlights significant reversals.  
- **When to use:** Trend lines, invalidation levels, and structure for Elliott or other pattern logic.  
- **When not to use:** When look-back or threshold is too small (noisy pivots).  
- *Future: use cases, example code.*

---

## 10. Elliott Wave

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.elliott` | **ElliottSwingIndicator** | List of Elliott swings (structure) at each index. |
| `org.ta4j.core.indicators.elliott` | **ElliottWaveCountIndicator** | Elliott wave count (e.g. current wave number). |
| `org.ta4j.core.indicators.elliott` | **ElliottChannelIndicator** | Elliott channel (e.g. trend channel for wave). |
| `org.ta4j.core.indicators.elliott` | **ElliottRatioIndicator** | Elliott ratio (e.g. Fibonacci ratios between waves). |
| `org.ta4j.core.indicators.elliott` | **ElliottProjectionIndicator** | Projected level (e.g. target from wave structure). |
| `org.ta4j.core.indicators.elliott` | **ElliottInvalidationLevelIndicator** | Price level that invalidates current count. |
| `org.ta4j.core.indicators.elliott` | **ElliottInvalidationIndicator** | Boolean: current count invalidated. |
| `org.ta4j.core.indicators.elliott` | **ElliottPhaseIndicator** | Current Elliott phase (e.g. impulse/corrective). |
| `org.ta4j.core.indicators.elliott` | **ElliottScenarioIndicator** | Set of possible Elliott scenarios at index. |
| `org.ta4j.core.indicators.elliott` | **ElliottConfluenceIndicator** | Confluence score (e.g. agreement across scenarios). |
| `org.ta4j.core.indicators.elliott` | **ElliottTrendBiasIndicator** | Aggregate directional bias across Elliott wave scenarios (bullish/bearish/neutral). |
| `org.ta4j.core.indicators.elliott` | **ElliottWaveAnalyzer** | Orchestrates Elliott Wave analysis with pluggable swing detectors and confidence profiles; returns ElliottAnalysisResult. |
| `org.ta4j.core.indicators.elliott` | **ElliottScenarioSet** | Immutable container of ranked alternative Elliott scenarios (base case + alternatives). |
| `org.ta4j.core.indicators.elliott` | **PatternSet** | Configures which Elliott scenario pattern types are enabled (impulse, corrective zigzag, etc.). |

### 10.1. Elliott swing detection (org.ta4j.core.indicators.elliott.swing)

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.elliott.swing` | **SwingDetector** | Interface: detects swing pivots and constructs swing sequences for a bar index. |
| `org.ta4j.core.indicators.elliott.swing` | **SwingDetectorResult** | Record: detected pivots and derived swings for a given index. |
| `org.ta4j.core.indicators.elliott.swing` | **SwingDetectors** | Factory helpers for fractal, adaptive ZigZag, and composite swing detectors. |
| `org.ta4j.core.indicators.elliott.swing` | **FractalSwingDetector** | Swing detector backed by fractal swing high/low (fixed lookback/lookforward window). |
| `org.ta4j.core.indicators.elliott.swing` | **ZigZagSwingDetector** | Swing detector backed by ZigZag state (reversal threshold or ATR-based). |
| `org.ta4j.core.indicators.elliott.swing` | **AdaptiveZigZagSwingDetector** | ZigZag swing detector that adapts reversal threshold to volatility (ATR-based). |
| `org.ta4j.core.indicators.elliott.swing` | **AdaptiveZigZagConfig** | Record: ATR period, multiplier, min/max threshold, smoothing for adaptive ZigZag. |
| `org.ta4j.core.indicators.elliott.swing` | **CompositeSwingDetector** | Combines multiple swing detectors with AND/OR pivot agreement policy. |
| `org.ta4j.core.indicators.elliott.swing` | **MinMagnitudeSwingFilter** | SwingFilter that drops swings below a relative magnitude of the largest swing. |
| `org.ta4j.core.indicators.elliott.swing` | **SwingFilter** | Interface: post-processes swing lists (e.g. remove noise, apply constraints). |
| `org.ta4j.core.indicators.elliott.swing` | **SwingPivot** | Record: confirmed swing pivot (index, price, type high/low). |
| `org.ta4j.core.indicators.elliott.swing` | **SwingPivotType** | Enum: pivot classification (high/low). |
| `org.ta4j.core.indicators.elliott.swing` | **SwingDetectorSupport** | Helper for building ElliottSwing lists from detector results. |

### 10.2. Elliott confidence (org.ta4j.core.indicators.elliott.confidence)

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.elliott.confidence` | **ConfidenceModel** | Interface: supplies confidence profile for a scenario. |
| `org.ta4j.core.indicators.elliott.confidence` | **ConfidenceProfile** | Weights and factors for confidence scoring (Fibonacci, time, alternation, channel, completeness). |
| `org.ta4j.core.indicators.elliott.confidence` | **ConfidenceProfiles** | Default and scenario-type–aware confidence models. |
| `org.ta4j.core.indicators.elliott.confidence` | **ElliottConfidenceBreakdown** | Per-scenario confidence breakdown (factor scores and category). |
| `org.ta4j.core.indicators.elliott.confidence` | **ConfidenceFactor** | Interface: single confidence factor (e.g. Fibonacci, channel). |
| `org.ta4j.core.indicators.elliott.confidence` | **ChannelAdherenceFactor** | Scores how well price adheres to projected channel. |
| `org.ta4j.core.indicators.elliott.confidence` | **FibonacciRelationshipFactor** | Scores Fibonacci proximity of swing ratios. |
| `org.ta4j.core.indicators.elliott.confidence` | **ScenarioTypeConfidenceModel** | Confidence model that selects profiles by ScenarioType. |
| `org.ta4j.core.indicators.elliott.confidence` | **StructureCompletenessFactor** | Scores wave structure completeness. |
| `org.ta4j.core.indicators.elliott.confidence` | **TimeAlternationFactor** | Scores wave 2/4 alternation with time diagnostics. |
| `org.ta4j.core.indicators.elliott.confidence` | **TimeProportionFactor** | Scores time proportion conformance. |

**Short usage**  
- **What it is:** Elliott Wave structure (swings, count, channel, ratios, projection, invalidation, phase, scenarios, confluence); trend bias across scenarios; pluggable analyzer with swing detectors and confidence profiles.  
- **Theory:** Elliott Wave Theory models market structure in impulsive and corrective waves with Fibonacci relationships.  
- **When to use:** When applying Elliott-based rules or targets; use confluence, invalidation, and trend bias for robustness; use ElliottWaveAnalyzer for one-shot analysis with custom detectors.  
- **When not to use:** When wave rules or degree are not clearly defined; interpretation is subjective.  
- *Future: use cases, example code.*  
- See also: [Elliott Wave Indicators](Elliott-Wave-Indicators.md).

---

## 11. Statistics & numeric

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.statistics` | **StandardDeviationIndicator** | Standard deviation of source over period. |
| `org.ta4j.core.indicators.statistics` | **VarianceIndicator** | Variance of source over period. |
| `org.ta4j.core.indicators.statistics` | **MeanDeviationIndicator** | Mean absolute deviation. |
| `org.ta4j.core.indicators.statistics` | **CovarianceIndicator** | Covariance between two indicators. |
| `org.ta4j.core.indicators.statistics` | **CorrelationCoefficientIndicator** | Correlation between two series. |
| `org.ta4j.core.indicators.statistics` | **PearsonCorrelationIndicator** | Pearson correlation. |
| `org.ta4j.core.indicators.statistics` | **SimpleLinearRegressionIndicator** | Moving simple linear regression (slope/intercept). |
| `org.ta4j.core.indicators.statistics` | **StandardErrorIndicator** | Standard error of regression (or estimate). |
| `org.ta4j.core.indicators.statistics` | **SigmaIndicator** | Z-score (value in standard deviations from mean). |
| `org.ta4j.core.indicators.statistics` | **PeriodicalGrowthRateIndicator** | Period-over-period growth rate (e.g. annualized). |
| `org.ta4j.core.indicators.numeric` | **BinaryOperationIndicator** | Binary operation (add, subtract, multiply, divide, min, max) on two indicators. |
| `org.ta4j.core.indicators.numeric` | **UnaryOperationIndicator** | Unary operation (negate, abs, log, etc.) on one indicator. |
| `org.ta4j.core.indicators.numeric` | **NumericIndicator** | Wraps a numeric expression (e.g. from indicator arithmetic) as an indicator. |

**Short usage**  
- **What it is:** Variance, std dev, correlation, regression, z-score, growth rate; numeric combinators (binary/unary).  
- **Theory:** Statistics describe distribution and relationship between series; operations allow custom formulas.  
- **When to use:** Volatility (std dev), normalization (z-score), and composing indicators (Binary/Unary).  
- **When not to use:** When period is too short for stable statistics.  
- *Future: use cases, example code.*

---

## 12. Renko

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.indicators.renko` | **RenkoUpIndicator** | Renko “up” brick signal or value. |
| `org.ta4j.core.indicators.renko` | **RenkoDownIndicator** | Renko “down” brick. |
| `org.ta4j.core.indicators.renko` | **RenkoXIndicator** | Renko brick size or generic Renko value. |

**Short usage**  
- **What it is:** Renko-based indicators for brick direction or size (used with Renko bar series).  
- **Theory:** Renko filters noise by fixed price move; indicators align with brick logic.  
- **When to use:** Trend and breakout on Renko charts.  
- **When not to use:** When bars are not Renko or brick size is inconsistent.  
- *Future: use cases, example code.*

---

## 13. Analysis (PnL, returns, cash flow)

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `org.ta4j.core.analysis` | **PerformanceIndicator** | Interface for performance indicators derived from trading records (equity curve, open-position handling). |
| `org.ta4j.core.analysis` | **CashFlow** | Cash flow series from a strategy over the bar series (implements Indicator&lt;Num&gt;). |
| `org.ta4j.core.analysis` | **Returns** | Returns (e.g. per-bar or compounded) from a strategy; implements Indicator&lt;Num&gt;. |
| `org.ta4j.core.analysis` | **CumulativePnL** | Cumulative P&amp;L over the bar series for given position(s); implements Indicator&lt;Num&gt;. |
| `org.ta4j.core.analysis` | **InvestedInterval** | Boolean indicator: true when invested (position open) at the bar. |

**Short usage**  
- **What it is:** Strategy result series (cash flow, returns, cumulative PnL) and invested flag.  
- **Theory:** Used for performance attribution, equity curve, and “only when invested” analytics.  
- **When to use:** Backtest analysis, reporting, and conditioning other logic on being in the market.  
- **When not to use:** As entry/exit signals (they reflect past trades).  
- *Future: use cases, example code.*

---

## 14. Charting (ta4j-examples)

| FQN | Class | Description (from codebase) |
|-----|-------|-----------------------------|
| `ta4jexamples.charting.annotation` | **BarSeriesLabelIndicator** | Sparse bar-index labels for chart annotations; getValue returns label Y (e.g. price) at labeled indices and NaN elsewhere; labels() for text. |
| `ta4jexamples.charting` | **ChannelBoundaryIndicator** | Wraps a channel (e.g. PriceChannel); extracts upper, lower, or median boundary for chart overlay; forwards Num when source is already Num. |

**Short usage**  
- **What it is:** Charting helpers: annotation labels and channel-boundary extraction for display.  
- **Theory:** Presentation only; no trading logic.  
- **When to use:** Plotting labels and channel lines in ta4j-examples charting.  
- **When not to use:** In core strategy logic (they live in examples).  
- *Future: use cases, example code.*  
- See also: [Charting](Charting.md).

---

## Summary

- **ta4j-core** provides 200+ indicators across helpers, averages, volatility, momentum, trend, volume, candles, pivots, swing, Elliott, statistics, renko, and analysis.  
- **ta4j-examples** adds charting-oriented indicators (labels, channel boundary).  
- All entries above use the **fully qualified name** and **class name** and a **short description as in the ta4j codebase**.  
- Each category includes a **short usage** block (what it is, theory, when to use, when not to use) and **room for expansion** (use cases, example code).  

For composition patterns and caching, see [Technical Indicators](Technical-indicators.md). For new indicators or rules, use the **ta4j-functionality-finder** workflow to avoid duplication and reuse building blocks.
