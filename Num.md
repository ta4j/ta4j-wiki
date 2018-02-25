# Num (in progress..)

## What is Num?
Since release 0.12 Ta4j supports using different types for basic calculations proceeded in `Indicator` or `TimeSeries`. That means you have the possibility to write your own implementation of the `Num` interface or you can choose between existing implementations. At the moment there are two existing implementations available: `BigDecimalNum` (default) and `DoubleNum`. As the names suggest, the available implementations use different types (delegates) for arithmetic calculations. `DoubleNum` uses the `double` primitive and `BigDecimalNum` uses the `BigDecimal` class for calculations. The following code snippets illustrate the difference:


**Plus operation of `DoubleNum`:**
```java
@Override
public Num plus(Num augend) {
    return augend.isNaN() ? NaN : new DoubleNum(delegate + ((DoubleNum)augend).delegate);
}
```

**Plus operation of `BigDecimalNum`:**
```java
public Num plus(Num augend) {
    return augend.isNaN() ? NaN : new BigDecimalNum(delegate.add(((BigDecimalNum)augend).delegate, MATH_CONTEXT));
}
```
Take a look at the corresponding section in the [usage examples](Usage-examples.html) to find out how to use ``Num`` and ``BaseTimeSeries``.

## Choosing the right `Num` implementation
The main purpose of supporting different data types for arithmetic operations are opposing goals in technical analysis. On the one hand performance is a critical  factor in high frequency trading or big data analysis, on the other hand crypto currencies and the general [handling of monetary values](link-to-source) require arithmetic that is **not** based on [*binary floating-point*](https://en.wikipedia.org/wiki/IEEE_754) types like `double` or `float`. For example the following simple code fragment using `double` will print an unexpected result:
```java
System.out.println(1.0 - 9*0.1)
```
The output will be `0.0999999999999999998` witch is not equal to 0.1. This is no bug, but the result of trying to represent decimal values in a binary number system. It is not possible to represent 0.1 (or any  other negative power of ten) [exactly in double or float](http://www.lahey.com/float.htm). With those data types you can only approximate such kind of decimal values. In many cases this representation may be sufficient and you would say "rounding to the last cent will give me the correct value",  but please [note that .9999 trillion dollars is approximately equal to 1 trillion dollars. Could you please deposit the difference in my bank account?](https://softwareengineering.stackexchange.com/questions/62948/what-can-be-done-to-programming-languages-to-avoid-floating-point-pitfalls)

The [right way](https://stackoverflow.com/questions/8148684/what-is-the-best-data-type-to-use-for-money-in-java-app) to solve this problem is to use `BigDecimal`, `int` or `long` for monetary calculations. **It doesn't mean though that doubles can never be used for that purpose.** Based of the fact that indicator just use monetary values as input but further calculations and results do not have a monetary dimension, Double's 53 significant bits (~16 decimal digits) are usually good enough for things that merely require accuracy.
**You have to know your application and you should study your goals and inform yourself about which kind of data type implementation works best for you.**

### BigDecimalNum
The `BigDecimalNum` implementation of `Num` uses [BigDecimal](https://docs.oracle.com/javase/8/docs/api/java/math/BigDecimal.html) as delgate and can represent any decimal value exact up to 32 decimal places. It can be used to do highly accurate calculations and to work with crypto currencies which representation needs a lot of decimal places. It is the default `Num` implementation if you create a `BaseTimeSeries`. For some purposes that requier very fast or a lot calculations you could notice a performance bottleneck due to this implementation of `Num`

```
TimeSeries series_1 = BaseTimeSeries.SeriesBuilder().build() // implicit initialize TimeSeries with BigDecimalNum
TimeSeries series_2 = BaseTimeSeries.SeriesBuilder.withNumType(BigDecimalNum::valueOf).build() // explicit initialize TimeSeries with BigDecimalNum
```


### DoubleNum

After having found out the disadvanteges about`DoubleNum`, please note that it can give your Ta4j application a heavy performance boost. You can create a `BaseTimeSeries` using `DoubleNum` as follows:
```
TimeSeries series_3 = BaseTimeSeries.SeriesBuilder.withNumType(DoubleNum::valueOf).build() // explicit initialize TimeSeries with DoubleNum
```


## Other possible implementations
The primitives `integer` or `long` could also used as delegate to solve the problem of performance vs. accuracy.
(in progess)

## Writing a custom Num implementation
(in progess)