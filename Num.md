# The Num Interface

## What is Num?
`Num` is ta4j’s numeric abstraction. Every indicator, criterion, and `BarSeries` uses it so you can swap numeric backends without rewriting trading logic. A `NumFactory` is tied to each `BarSeries`; it produces instances of the chosen implementation and guarantees consistent arithmetic throughout the series.

Built-in implementations:

- `DecimalNum` (default): backed by `BigDecimal`, configurable precision and rounding.
- `DoubleNum`: thin wrapper around `double` for maximum throughput.

Take a look at the [usage examples](Usage-examples.md) to see `Num` and `BaseBarSeries` in action.

## Choosing the right `Num`
Every calculation faces the precision vs. speed trade-off:

- **DecimalNum** stores values as `BigDecimal`. You can configure the default precision/rounding via `DecimalNum.configureDefaultMathContext(...)` or request a factory with a specific precision/rounding mode (`DecimalNumFactory.getInstance(new MathContext(34, RoundingMode.HALF_EVEN))`). Higher precision reduces rounding error but increases CPU cost, GC pressure, and memory footprint because BigDecimal allocates new objects for every arithmetic call.
- **DoubleNum** uses binary floating point. It’s fast and allocation-free but inherits IEEE-754 quirks. For example:

  ```java
  System.out.println(1.0 - 9 * 0.1); // prints 0.09999999999999998
  ```

  That error comes from representing 0.1 in base-2. For many indicators (ratios, normalized oscillators) the approximation is acceptable; for money-like calculations it usually isn’t.

Pick DecimalNum when you care about exact decimals (crypto pairs, high-value assets, long test runs). Pick DoubleNum when latency matters more than an ulp of precision. You can also add your own implementation by extending `Num` and providing a `NumFactory`.

```java
BarSeries lightningFast = new BaseBarSeriesBuilder()
        .withName("fast_series")
        .withNumFactory(DoubleNumFactory.getInstance())
        .build();
```

### Configuring Decimal precision

```java
// Use 32-digit precision globally (default is 16, HALF_UP)
DecimalNum.configureDefaultPrecision(32);

// or supply a custom factory for one series with custom rounding
BarSeries highPrecisionSeries = new BaseBarSeriesBuilder()
        .withName("btc_usdt")
        .withNumFactory(DecimalNumFactory.getInstance(new MathContext(40, RoundingMode.HALF_EVEN)))
        .build();

// reset to library defaults later if needed
DecimalNum.resetDefaultPrecision();
```

Increasing precision protects against rounding errors when you chain many indicators, but every arithmetic call becomes more expensive. Benchmark both settings if you’re pushing millions of bars or large strategy grids.

## Handling Num from your code
Every `BarSeries` exposes its factory via `series.numFactory()`. Use it whenever you need a literal so the value matches the series’ numeric type:

```java
Num three = series.numFactory().numOf(3);
series.addTrade(three, series.numFactory().numOf(10.5)); // accepts Number and converts internally
```

Create bars with the series’ `barBuilder()`; all numeric inputs are converted using the same factory:

```java
Bar bar = series.barBuilder()
        .timePeriod(Duration.ofMinutes(1))
        .endTime(Instant.now())
        .openPrice(100.0)
        .highPrice(101.0)
        .lowPrice(99.5)
        .closePrice(100.7)
        .volume(42)
        .build();
series.addBar(bar);
```

**Important:** A `BarSeries` has a fixed numeric backend. Mixing different `Num` types on the same series (e.g., creating a `DoubleNum` literal and feeding it into a `DecimalNum` series) will throw or produce undefined behavior—always go through `numFactory()`.

## Implementing your own Num
If you need a custom numeric type (decimal128, fixed-point integers, GPU-backed tensors, etc.), implement the `Num` interface plus a matching `NumFactory`. As long as the factory can produce `zero()`, `one()`, and `numOf(...)`, the rest of ta4j will treat it like any other `Num`.
