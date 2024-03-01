# The Num Interface

## What is Num?
Since release 0.12 Ta4j supports using different types for basic calculations proceeded in `Indicator` or `BarSeries`. That means you have the possibility to write your own implementation of the `Num` interface or you can choose between existing implementations. At the moment there are two existing implementations available: `PrecisionNum` (default) and `DoubleNum`. As the names suggest, the available implementations use different types (delegates) for arithmetic calculations. `DoubleNum` uses the `double` primitive and `PrecisionNum` uses the `BigDecimal` class for calculations. The following code snippets illustrate the difference:


**Plus operation of `DoubleNum`:**
```java
@Override
public Num plus(Num augend) {
    return augend.isNaN() ? NaN : new DoubleNum(delegate + ((DoubleNum)augend).delegate);
}
```

**Plus operation of `PrecisionNum`:**
```java
public Num plus(Num augend) {
    return augend.isNaN() ? NaN : new BigDecimalNum(delegate.add(((BigDecimalNum)augend).delegate, MATH_CONTEXT));
}
```
Take a look at the corresponding section in the [usage examples](Usage-examples.html) to find out how to use ``Num`` and ``BaseBarSeries``.

## Choosing the right `Num` implementation
The main purpose of supporting different data types for arithmetic operations are opposing goals in technical analysis. On the one hand performance is a critical  factor in high frequency trading or big data analysis, on the other hand crypto currencies and the general [handling of monetary values](link-to-source) require arithmetic that is **not** based on [*binary floating-point*](https://en.wikipedia.org/wiki/IEEE_754) types like `double` or `float`. For example the following simple code fragment using `double` will print an unexpected result:
```java
System.out.println(1.0 - 9*0.1)
```
The output will be `0.0999999999999999998` witch is not equal to 0.1. This is no bug, but the result of trying to represent decimal values in a binary number system. It is not possible to represent 0.1 (or any  other negative power of ten) [exactly in double or float](http://www.lahey.com/float.htm). With those data types you can only approximate such kind of decimal values. In many cases this representation may be sufficient and you would say "rounding to the last cent will give me the correct value",  but please [note that .9999 trillion dollars is approximately equal to 1 trillion dollars. Could you please deposit the difference in my bank account?](https://softwareengineering.stackexchange.com/questions/62948/what-can-be-done-to-programming-languages-to-avoid-floating-point-pitfalls)

The [right way](https://stackoverflow.com/questions/8148684/what-is-the-best-data-type-to-use-for-money-in-java-app) to solve this problem is to use `BigDecimal`, `int` or `long` for monetary calculations. **It doesn't mean though that doubles can never be used for that purpose.** Based of the fact that indicator just use monetary values as input but further calculations and results do not have a monetary dimension, Double's 53 significant bits (~16 decimal digits) are usually good enough for things that merely require accuracy.
**You have to know your application and you should study your goals and inform yourself about which kind of data type implementation works best for you.**

### PrecisionNum
The `PrecisionNum` implementation of `Num` uses [BigDecimal](https://docs.oracle.com/javase/8/docs/api/java/math/BigDecimal.html) as delgate and can represent any decimal value exact up to 32 decimal places. It can be used to do highly accurate calculations and to work with crypto currencies which representation needs a lot of decimal places. It is the default `Num` implementation if you create a `BaseBarSeries`. For some purposes that requier very fast or a lot calculations you could notice a performance bottleneck due to this implementation of `Num`.

```java
BarSeries series_1 = new BaseBarSeriesBuilder().build() // implicit initialize BarSeries with PrecisionNum
BarSeries series_2 = new BaseBarSeriesBuilder().withNumType(PrecisionNum::valueOf).build() // explicit initialize BarSeries with PrecisionNum
```


### DoubleNum

After having found out the disadvanteges about`DoubleNum`, please note that it can give your Ta4j application a heavy performance boost. You can create a `BaseBarSeries` using `DoubleNum` as follows:
```java
BarSeries series_3 = new BaseBarSeriesBuilder().withNumType(DoubleNum::valueOf).build() // explicit initialize BarSeries with DoubleNum
```
<br>

## Design and other possible implementations
If you want to write your own implementation of `Num` you just have to let your class implement the ``Num`` interface:
```java
public class MyNum implements Num {
    // Override interface functions...
}
```
For instance you could use `integer` or `long` as delegate to solve the problem of performance vs. accuracy. An existing alternative to ``BigDecimal`` could be [Decimal4j](https://github.com/tools4j/decimal4j).

Special attention requiers the following prototype of the ``Num`` interface:
```java
public Function<Number, Num> function(); // required from every class that implements Num..
```
This function must returns a [java.util.Function](https://docs.oracle.com/javase/8/docs/api/java/util/function/package-summary.html) object, that allows users and other classes of the library to convert any [Number](https://docs.oracle.com/javase/7/docs/api/java/lang/Number.html) extending class (like Double, Integer, BigDecimal, ...) into your Num implementation.

The existing implementations ``DoubleNum`` and ``BigDecimalNum`` provide static functions to convert a ``Number`` into the corresponding ``Num`` implementing class:
```java
    /**
     * Returns a {@code Num} version of the given {@code Number}.
     * Warning: This method turns the number into a string first
     * @param val the number
     * @return the {@code Num}
     */
    public static BigDecimalNum valueOf(Number val) {
        return new BigDecimalNum(val.toString());
    }
```

The `function()` should return a lamba expression of this static ``valueOf()`` function. The following code snipped shows how the ``BigDecimalNum`` class overrides the `function()` function with help of a [method reference](https://docs.oracle.com/javase/tutorial/java/javaOO/methodreferences.html):
```java
    @Override
    public Function<Number, Num> function() {
        return BigDecimalNum::valueOf;
    }
```
### Handling Num
``BarSeries`` and ``Bar`` need a reference to this ``Function`` object that enables to transform any ``Number`` to the wanted ``Num`` implementation. Because of that you have to pass this function when creating a ``Bar`` manually:
```java
// The bar object has to transform the intput into Num with help of the given function
Bar bar = new BaseBar(ZonedDateTime.now(),1,3,1,1,1,BigDecimalNum::valueOf);
```

Also the BarSeries needs this ``Function``. The easiest way to handle this is to use the SeriesBuilder and to add bar data directly to the BarSeries:
```java
BarSeries series = new BaseBarSeriesBuilder().withName("mySeries").build(); // the builder uses BigDecimalNum as default

ZonedDateTime endTime = ZonedDateTime.now();
// add bar data directly. It will be transformed automatically to Num implementation of BarSeries
series.addBar(endTime, 105.42, 112.99, 104.01, 111.42, 1337); 
series.addBar(endTime.plusDays(1), 111.43, 112.83, 107.77, 107.99, 1234);
series.addBar(endTime.plusDays(2), 107.90, 117.50, 107.90, 115.42, 4242);
```

You can determine the ``Num`` transforming ``Function`` with the builder by using the ``withNumTypeOf(function)`` function:

```java
BarSeries series = new BaseBarSeriesBuilder().withName("mySeries").withNumTypeOf(DoubleNum::valueOf).build();
```
<br>
**Please note that once instantiating a `BarSeries` with a specific `Num` implementation you cannot add data in another `Num` implementation to the `BarSeries`.**

```java
BarSeries series = new BaseBarSeriesBuilder().build().build(); // implicit initialize with PrecisionNum
series.addTrade(DoubleNum.valueOf(volume), DoubleNum.valueOf(bid)); // try to add DoubleNum values
// throws ClassCastException: org.ta4j.core.num.DoubleNum
// cannot be cast to org.ta4j.core.num.PrecisionNum
```
