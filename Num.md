# The Num Interface

## What is Num?
Ta4j supports different numeric backends for calculations in `Indicator` and `BarSeries`. You can choose an existing implementation or provide your own.

Current built-in implementations:

- `DecimalNum` (default): uses `BigDecimal` for precision
- `DoubleNum`: uses primitive `double` for performance

Both implement `Num` and are selected via a `NumFactory` on your `BarSeries`.


Take a look at the [usage examples](Usage-examples.html) to see `Num` and `BaseBarSeries` in action.

## Choosing the right `Num` implementation
The main purpose of supporting different data types for arithmetic operations are opposing goals in technical analysis. On the one hand performance is a critical  factor in high frequency trading or big data analysis, on the other hand crypto currencies and the general [handling of monetary values](link-to-source) require arithmetic that is **not** based on [*binary floating-point*](https://en.wikipedia.org/wiki/IEEE_754) types like `double` or `float`. For example the following simple code fragment using `double` will print an unexpected result:
```java
System.out.println(1.0 - 9*0.1)
```
The output will be `0.0999999999999999998` witch is not equal to 0.1. This is no bug, but the result of trying to represent decimal values in a binary number system. It is not possible to represent 0.1 (or any  other negative power of ten) [exactly in double or float](http://www.lahey.com/float.htm). With those data types you can only approximate such kind of decimal values. In many cases this representation may be sufficient and you would say "rounding to the last cent will give me the correct value",  but please [note that .9999 trillion dollars is approximately equal to 1 trillion dollars. Could you please deposit the difference in my bank account?](https://softwareengineering.stackexchange.com/questions/62948/what-can-be-done-to-programming-languages-to-avoid-floating-point-pitfalls)

The [right way](https://stackoverflow.com/questions/8148684/what-is-the-best-data-type-to-use-for-money-in-java-app) to solve this problem is to use `BigDecimal`, `int` or `long` for monetary calculations. **It doesn't mean though that doubles can never be used for that purpose.** Based of the fact that indicator just use monetary values as input but further calculations and results do not have a monetary dimension, Double's 53 significant bits (~16 decimal digits) are usually good enough for things that merely require accuracy.
**You have to know your application and you should study your goals and inform yourself about which kind of data type implementation works best for you.**

### DecimalNum
`DecimalNum` uses [BigDecimal](https://docs.oracle.com/javase/8/docs/api/java/math/BigDecimal.html) for high precision calculations. It is the default when creating a `BaseBarSeries`.

```java
// Default (DecimalNum)
BarSeries s1 = new BaseBarSeriesBuilder().withName("series").build();

// Explicit (DecimalNum)
BarSeries s2 = new BaseBarSeriesBuilder()
    .withNumFactory(DecimalNumFactory.getInstance())
    .build();
```


### DoubleNum

`DoubleNum` favors speed over precision. Use it when approximate decimal arithmetic is sufficient.

```java
BarSeries s3 = new BaseBarSeriesBuilder()
    .withNumFactory(DoubleNumFactory.getInstance())
    .build();
```
<br>

## Design and other possible implementations
If you want to write your own implementation of `Num`, implement the `Num` interface and provide a corresponding `NumFactory` so a `BarSeries` can create numbers and bars consistently.

### Handling Num
`BarSeries` exposes its factory via `series.numFactory()`. Use it to create values that match the series' numeric type:
```java
Num three = series.numFactory().numOf(3);
series.addTrade(100, 10.5); // accepts Number and converts via numFactory()
```

Create bars with the series' `barBuilder()`; numeric inputs are converted using the same factory:
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
<br>
**Note:** A `BarSeries` has a fixed numeric type. Do not mix different `Num` types on the same series.
