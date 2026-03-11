# Getting Started

This guide takes you from a fresh checkout to a working strategy, then shows how to choose between ta4j's three main execution styles:

1. `BarSeriesManager` for straightforward historical runs
2. `BacktestExecutor` for large batches
3. Manual loops with `BaseTradingRecord` when fills arrive asynchronously

## Prerequisites

- JDK 21 or newer
- Maven, Gradle, or an IDE that can import Maven projects
- Basic Java familiarity

If technical analysis is new to you, skim [Wikipedia](https://en.wikipedia.org/wiki/Technical_analysis) or [Investopedia](https://www.investopedia.com/university/technical/) for terminology.

## Install ta4j

If you are following the current branch directly, install the snapshot locally first:

```bash
mvn -pl ta4j-core -am install
```

Then depend on `ta4j-core`:

```xml
<dependency>
  <groupId>org.ta4j</groupId>
  <artifactId>ta4j-core</artifactId>
  <version>0.22.4-SNAPSHOT</version>
</dependency>
```

```groovy
implementation "org.ta4j:ta4j-core:0.22.4-SNAPSHOT"
```

If you are consuming a released build from Maven Central instead, replace the version with the newest released `0.22.x` number from [Release Notes](Release-notes.md).

Prefer to inspect the code? Clone [ta4j](https://github.com/ta4j/ta4j) and import the root Maven project. `ta4j-core` and `ta4j-examples` live side by side.

### Verify your environment

1. Run `mvn -pl ta4j-examples test`
2. Launch `ta4jexamples.Quickstart`
3. Confirm that you see backtest output, and a chart window when running with a GUI

## Understand The Building Blocks

| Concept | What it does | Learn more |
| --- | --- | --- |
| `BarSeries` | Holds the ordered bars used by indicators and strategies | [Bar Series & Bars](Bar-series-and-bars.md) |
| `Indicator<T extends Num>` | Derives values lazily from bars or other indicators | [Technical Indicators](Technical-indicators.md) |
| `Rule` and `Strategy` | Decide when to enter, exit, or stay flat | [Trading Strategies](Trading-strategies.md) |
| `BaseTradingRecord` | Unified trading state for backtests, live trading, and paper trading | [Backtesting](Backtesting.md), [Live Trading](Live-trading.md) |
| `BarSeriesManager` | Runs one strategy over a series | [Backtesting](Backtesting.md) |
| `BacktestExecutor` | Runs many strategies and ranks the results | [Backtesting](Backtesting.md) |
| `ConcurrentBarSeries` | Thread-safe series for multi-threaded ingestion and evaluation | [Live Trading](Live-trading.md) |

The important mental model is that ta4j no longer needs a split "backtest record" versus "live record" story for new code. `BaseTradingRecord` already covers both.

## Walkthrough: build your first strategy

We will:

1. Create a bar series
2. Build indicators and rules
3. Run a backtest
4. Inspect metrics
5. See the live-style variant

### 1. Build a bar series

```java
BarSeries series = new BaseBarSeriesBuilder()
        .withName("btc-usd-demo")
        .build();

series.barBuilder()
        .timePeriod(Duration.ofMinutes(5))
        .endTime(Instant.parse("2025-01-01T00:05:00Z"))
        .openPrice(42000)
        .highPrice(42150)
        .lowPrice(41980)
        .closePrice(42100)
        .volume(12.4)
        .add();
```

If you already have bar data, call `series.addBar(...)`. If you are aggregating raw trades, use the appropriate bar builder or a `ConcurrentBarSeries` in live flows.

### 2. Create indicators and rules

```java
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
SMAIndicator fastSma = new SMAIndicator(closePrice, 5);
SMAIndicator slowSma = new SMAIndicator(closePrice, 30);

Rule entryRule = new CrossedUpIndicatorRule(fastSma, slowSma);
Rule exitRule = new CrossedDownIndicatorRule(fastSma, slowSma)
        .or(new StopLossRule(closePrice, series.numFactory().numOf(3)))
        .or(new StopGainRule(closePrice, series.numFactory().numOf(5)));

Strategy strategy = new BaseStrategy("SMA crossover", entryRule, exitRule);
strategy.setUnstableBars(30);
```

### 3. Pick the right execution path

| Goal | Recommended path | Why |
| --- | --- | --- |
| One strategy over historical bars | `BarSeriesManager` | Minimal wiring and deterministic trade-execution models |
| Same backtest loop, but with a preconfigured record | `BarSeriesManager.run(strategy, tradingRecord, ...)` | Keep a specific `ExecutionMatchPolicy`, fee model, or record instance |
| Large parameter sweeps | `BacktestExecutor` | Batched execution, runtime reports, ranked statements |
| Live or paper execution with confirmed fills | Manual loop + `BaseTradingRecord` | Signal generation stays separate from fill recording |

For the common case, start with `BarSeriesManager`:

```java
BarSeriesManager manager = new BarSeriesManager(series);
TradingRecord record = manager.run(strategy);

System.out.printf("Closed positions: %d%n", record.getPositionCount());
System.out.printf("Current position open? %s%n", record.getCurrentPosition().isOpened());
```

If you need a specific record configuration, provide your own `BaseTradingRecord`:

```java
BaseTradingRecord record = new BaseTradingRecord(
        strategy.getStartingType(),
        ExecutionMatchPolicy.FIFO,
        new ZeroCostModel(),
        new ZeroCostModel(),
        series.getBeginIndex(),
        series.getEndIndex());

manager.run(strategy, record, series.numFactory().one(), series.getBeginIndex(), series.getEndIndex());
```

### 4. Inspect metrics

```java
AnalysisCriterion netReturn = new NetReturnCriterion();
AnalysisCriterion romad = new ReturnOverMaxDrawdownCriterion();
AnalysisCriterion openCostBasis = new OpenPositionCostBasisCriterion();

System.out.println("Net return: " + netReturn.calculate(series, record));
System.out.println("Return over max drawdown: " + romad.calculate(series, record));
System.out.println("Open position cost basis: " + openCostBasis.calculate(series, record));
```

Useful follow-up metrics:

- `TotalFeesCriterion`
- `CommissionsImpactPercentageCriterion`
- `OpenPositionUnrealizedProfitCriterion`
- `MaxConsecutiveProfitCriterion`
- `MaxConsecutiveLossCriterion`
- `BaseTradingStatement`

### 5. Live-style loop with confirmed fills

When your orders are filled asynchronously, do not mutate the record at signal time. Emit the order intent first, then update the record from the confirmed fill:

```java
BaseTradingRecord liveRecord = new BaseTradingRecord(strategy.getStartingType());
int endIndex = series.getEndIndex();
Num lastPrice = series.getBar(endIndex).getClosePrice();
Num amount = series.numFactory().one();

if (strategy.shouldEnter(endIndex, liveRecord)) {
    orderRouter.submitBuy(lastPrice, amount);
}

TradeFill fill = new TradeFill(
        endIndex,
        Instant.now(),
        lastPrice,
        amount,
        series.numFactory().zero(),
        ExecutionSide.BUY,
        "order-123",
        "decision-123");

liveRecord.recordExecutionFill(fill);
```

That is the same pattern used by downstream systems such as CF: ta4j strategies decide, brokers execute, then `BaseTradingRecord` is updated from confirmed fills.

## Next Steps

| Goal | Where to go next |
| --- | --- |
| Learn data-loading and streaming patterns | [Bar Series & Bars](Bar-series-and-bars.md) |
| Explore more indicators | [Technical Indicators](Technical-indicators.md) |
| Run larger backtests | [Backtesting](Backtesting.md) |
| Build a real bot loop | [Live Trading](Live-trading.md) |
| Run maintained examples | [Usage Examples](Usage-examples.md) |

## Compatibility Note

`LiveTradingRecord` and `ExecutionFill` still exist in the 0.22.x line so older adapters can migrate gradually, but new code should use `BaseTradingRecord` and `TradeFill`.
