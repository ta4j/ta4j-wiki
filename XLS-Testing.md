# XLS Testing

## What is XLS Testing?

XLS testing is a method of creating JUnit test cases for indicators and criteria.  XLS testing reads an XLS spreadsheet of bar data columns (date, open, high, low, close, and volume) and formula columns (intermediate calculations and final calculations) and uses the final calculations as the expected results in a JUnit test case.  As a special case, a criterion spreadsheet also has a column representing an arbitrary trading record (see Criteria Spreadsheet below).  The ta4j indicator or criterion uses the same bar data to calculate the actual results.  Then, in standard JUnit style, the actual results are compared to the expected results.

## Copy-Paste-Edit Quickstart

While all of this may seem complex, examples have been provided to facilitate copy-paste-edit development of indicator and criterion test classes and unit tests.  This workflow involves
1) Copy candidate test class and spreadsheet
   - Copy from a class that is similar (if indicator test, pick indicator that takes same data in constructor)
2) In the spreadsheet, replace the calculation columns with new columns that correctly build the indicator or criterion
   - Use as many intermediate calculation columns as necessary to make the logic easy to follow with simple formulas
3) Edit the two constructor calls within the test class constructor
   - Fix the super() call to the correct ta4j criterion class, and fix the mapping from Object... params to the indicator's actual primitive type parameters
   - Fix the XLSIndicatorTest() constructor call to the correct XLS file name, criterion column number, and trading record column number
4) Modify the getCriterion() calls to the parameters to test, and add in a few "magic number" checks

A good example IndicatorTest subclass that takes Indicator data is RSIIndicatorTest.
A good example IndicatorTest subclass that takes TimeFrame data is ATRIndicatorTest.
A good example CriterionTest subclass is LinearTransactionCostCriterion.
These are all found in ta4j-core/src/test/java/org/ta4j/core subfolders.  The XLS files are found in ta4j-core/src/test/resources/org/ta4j subfolders.

Here is the RSI example, with highlights on edits required in the three steps above
[[img/RSIIndicatorTest.jpg]]

## Why XLS Testing?

A contributor who develops a new indicator might be tempted to write a unit test with an obviously wrong expected value of -1000.0, run the unit test which fails, then copy the actual value from the JUnit output into the unit test as the expected value.  This is circular logic as the expected value is defined as the actual value of the indicator.  A JUnit test case written in this manner might appear like
```
RSIIndicator rsi = new RSIIndicator(new ClosePriceIndicator(data), 14); // the ta4j indicator
assertDecimalEquals(rsi.getValue(15), 62.7451);                         // actual value compared to expected "magic number"
```
There is no indication of how 62.7451 was calculated as the expected value.  One would have to copy the data and perform the RSI calculation on paper or in a spreadsheet in order to validate this "magic value" as correct or incorrect.  This is problematic when the initial implementation of the indicator is flawed, as the flawed result is used as the expected result, which obviously matches the actual result.  So, the test passes when the implementation is incorrect.

XLS testing forces the contributor to provide an alternate implementation of their calculations in an XLS spreadsheet that may be inspected and validated.  It allows the contributor to "show their work" in a way that may be confirmed.

## Indicator Spreadsheet

An example of an XLS RSI indicator spreadsheet might be

|   | A | B | C | D | E | F | G | H | I | J | K |
|---|---|---|---|---|---|---|---|---|---|---|---|
|1| GOLD weekly prices |
|2|
|3| Param | Value |
|4| length | 13 |
|5|
|...|
|15| Date       | Open   | High  | Low   | Close | Volume    | Gain | AvgGain | Loss | AvgLoss | RSI    |
|16| 5/01/1979  | 229.35 | 229.7 | 219.5 | 224.8 | 121888889 | 0    | 0       | 0    | 0       | 0      |
|17| 12/01/1979 | 225.7  | 228   | 217.5 | 219.4 | 150522222 | 0    | 0       | 5.4  | 0.415   | 0      |
|18| 19/01/1979 | 220.15 | 237.5 | 216.6 | 237   | 152477778 | 17.6 | 1.353   | 0    | 0.383   | 77.929 |
|...|

Rows 6 - 14 are blank and not shown here, and values are show only to three decimal places for brevity.  In this example, the two sections are visible: the parameters section and three rows of the data section.  Each is preceded by its corresponding section header.

### Parameters Section

The parameters section header has "Param" in it's first cell and signals the start of the indicator parameters.  Each parameter row has a name and a value.  The name is only informational for self-documentation.  The value is referenced in the formulas in the calculation columns of the data section.  In this example, there is only one parameter named length with value 13 in cell $B$4.  This cell reference should be used in the formulas.  When this value is changed, the calculated values should change.  Other indicators may have additional parameters that would appear in subsequent rows.

### Data Section

The data section header has "Date" in it's first cell and signals the start of the indicator data and calculations.  In this example, three bars of data are shown (Jan 5, Jan 12, and Jan 19).  After the Volume column, the calculation columns begin.  These columns contains formulas but the formula results are shown above.  There are four intermediate value columns (Gain, AvgGain, Loss, AvgLoss) and a final column (RSI).  It might have been even more clear if another intermediate value column for RS (relative strength) had been added and that value used in the final RSI column!

Regardless, it's not hard to validate each intermediate calculation as well as the final calculation either by recalculating by hand, or by examining the column formulas, or both.  Logic flaws may be exposed in a way that is more apparent than in the ta4j Java implementation.

### Formulas

These are the formulas in row 16 with explanations.  Note how each of the formulas is relatively simple and easy to validate.

**Gain**  Close price increase from the previous day to the current day.  If row 16 (first row), gain is 0.  Otherwise, gain is max of close price gain and 0 (positive or zero).
```
=IF(ROW()-ROW($A$16)=0,0,MAX(E16-E15,0))
```

**AvgGain**  Modified moving average of close price increases.  If row 16 (first row), average gain is gain.  Otherwise, gain is modified moving average of average gain over period given in length-param in cell B4.
```
=IF(ROW()-ROW($A$16)=0,G16,(1-1/$B$4)*H15+(1/$B$4)*G16)
```

**Loss**  Close price decrease from the previous day to the current day.  If row 16 (first row), loss is 0.  Otherwise, loss is max of close price loss and 0 (positive or zero).
```
=IF(ROW()-ROW($A$16)=0,0,MAX(E15-E16,0))
```

**AvgLoss**  Modified moving average of close price decreases.  If row 16 (first row), average loss is loss.  Otherwise, loss is modified moving average of average loss over period given in length-param in cell B4.
```
=IF(ROW()-ROW($A$16)=0,I16,(1-1/$B$4)*J15+(1/$B$4)*I16)
```

**RSI**  Relative strength index of close price.  If average loss is 0 and if average gain is 0, relative strength index is 0.  If average loss is 0 and if average gain is not 0, relative strength index is 100.  If average loss is not 0, relative strength index is normalized relative strength.
```
=IF(J16=0,IF(H16=0,0,100),100-100/(1+H16/J16))
```


## Indicator Test Class

In standard JUnit style, to build XLS indicator unit tests an indicator test class must be developed.  One such class appears like
```
public class RSIIndicatorTest extends IndicatorTest<Indicator<Decimal>, Decimal> {

    private ExternalIndicatorTest xls;

    public RSIIndicatorTest() {
        super((data, params) -> new RSIIndicator(data, (int) params[0]));
        xls = new XLSIndicatorTest(this.getClass(), "RSI.xls", 10);
    }
```

### IndicatorTest

An XLS indicator test class must extend (or contain) the IndicatorTest class, which provides standard methods for generating ta4j indicators.  The test class constructor calls the IndicatorTest constructor with the indicator's factory lambda function.  This allows for standard construction of the ta4j indicator via IndicatorTest#getIndicator(data, params) within the unit tests.  Note that this indicator is built from Indicator<Decimal> data because that is how the RSIIndicator class is written.  Some indicators are built from BarSeries data (ATR) so in those cases the **extends** clause must be modified to
```
public class ATRIndicatorTest extends IndicatorTest<BarSeries, Decimal>
```

### ExternalIndicatorTest

The XLS indicator test class also contains an ExternalIndicatorTest object, which provides standard methods for extracting data and calculating indicators from an external calculator.  The test class constructor initializes this object to an XLSIndicatorTest object with the test class (to get the path to the file resources), XLS file name, and a column number.  The zero-based column number indicates which column in the XLS file contains the final indicator calculation values.  In this case the column number is 10 where 0 is A, so it's column K in our example above which contains the "RSI" final calculation values.

### Indicator XLS Unit Tests

Now that these objects are initialized, standardized unit tests may be created and executed like
```
    @Test
    public void xlsTest() throws Exception {
        Indicator<Decimal> xlsClose = new ClosePriceIndicator(xls.getSeries());
        Indicator<Decimal> indicator;

        indicator = getIndicator(xlsClose, 1);
        assertIndicatorEquals(xls.getIndicator(1), indicator);
        assertEquals(100.0, indicator.getValue(indicator.getBarSeries().getEndIndex()).doubleValue(), TATestsUtils.TA_OFFSET);
```
xls.getSeries() extracts the BarSeries data from the XLS spreadsheet file.  This BarSeries, along with indicator parameters, is passed to IndicatorTest#getIndicator() which returns the new Indicator<Decimal> as the actual indicator.

xls.getIndicator(params) modifies the parameters in the XLS spreadsheet file (in memory, not on disk!), re-calculates everything, and returns the new Indicator<Decimal> from the spreadsheet as the expected indicator.  Note that there must be the same number of rows (or more) in the parameters section of the XLS file as there are parameters in the params list.  In this example, params can contain up to 11 parameters.  The twelfth parameter will overwrite cell B15 which breaks the data section header!  If this example sheet is copied, the 11 rows of the parameter section should be adequate for just about any conceivable indicator.  If not, just add more rows to the parameter section, bumping down the data section.

assertIndicatorEquals(expected, actual) simply compares two indicators to ensure that they are the same size and all of their values are the same.

For good measure, a single "magic value" is also included as a fail-safe catch against accidental comparison of an indicator to itself or other misconstructed test case or class.

## Criterion Spreadsheet

An example of an XLS LTC criterion spreadsheet might be

|   | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1| GOLD weekly prices |
| 2|
| 3| Param  | Value |
| 4| amount | 1000  |
| 5| a      | 0.005 |
| 6| b      | 0.2   |
| 7|
| 8|||||||in|||entryPrice||||||newAmount|totalCost|
| 9|Date|Open|High|Low|Close|Volume|0|Buy|Sell|0|Amount|entryCost|profit|scaledAmount|exitCost|1000|0|
|10|5/01/1979|229.35|229.7|219.5|224.8|121888889|0|0|0|0|1000|0|1|1000|0|1000|0|
|11|12/01/1979|225.7|228|217.5|219.4|150522222|0|0|0|0|1000|0|1|1000|0|1000|0|
|12|19/01/1979|220.15|237.5|216.6|237|152477778|0|0|0|0|1000|0|1|1000|0|1000|0|
|13|26/01/1979|237.5|243.2|234|240.2|168800000|0|0|0|0|1000|0|1|1000|0|1000|0|
|14|2/02/1979|240.25|243.5|232|242.5|149655556|1|1|0|242.5|1000|5.2|1|1000|0|994.8|5.2|
|15|9/02/1979|242.55|257.55|240|247.3|140211111|1|0|0|242.5|994.8|0|1|994.8|0|994.8|5.2|
|16|16/02/1979|248|253.3|240.5|250.6|133288889|1|0|0|242.5|994.8|0|1|994.8|0|994.8|5.2|
|17|23/02/1979|251|258.8|248.5|255.7|107888889|0|0|1|242.5|994.8|0|1.054|1048.949|5.444|1043.505|10.644|
|...|

This criterion spreadsheet is very similar to the example indicator spreadsheet with a few key differences:
- There are three parameters (instead of one)
- There is a "state" column ("in", column G)
- The calculation columns are completely different

### Trading Record

A criterion evaluates a trading record.  There is no linear transaction cost if there is no trading record.  To calculate() any criterion, a BarSeries and a TradingRecord must be defined.  As with indicator testing, the BarSeries data is contained in columns A - F.  With this criterion the TradingRecord is represented in the "state" column (G).  A value of 0 represents "no shares held" (no open trade).  A value of 1 represents "shares held" (open trade).  A transition from 0 to 1 represents a BUY order filled at the row with the 1.  A transition from 1 to 0 represents a SELL order filled at the row with the 0.  The actual distribution of 1's and 0's does not matter, and was randomly generated for this example.

Above, a BUY was filled on Feb 2, and a SELL was filled on Feb 23.  Two additional columns, Buy (H) and Sell (I), have been added to aid interpretation and to simplify the formulas.  It is important that these columns accurately reflect transitions in the in column (G) or the calculated criterion values will not be consistent with the trading record.

### Formulas

These are the formulas in row 10 with explanations.  Note how each of the formulas is relatively simple and easy to validate.  Also note how some columns use row 9 as an "initialization row" in order to simplify formulas by allowing them to refer to previous row values.  This is used anywhere a 9 appears in a row 10 formula, such as for entryPrice.  Finally, note that the initialization value of newAmount is the value of the amount parameter in cell B4.

**entryPrice**  Entry price of the current trade.  If there was a BUY just filled, entry price is close price.  Otherwise, entry price is previous entry price.
```
=IF(H10=1,E10,J9)
```

**amount**  Cash value of the trading account available for the next trade or applied to the current trade.  Amount is previous new amount.
```
=P9
```

**entryCost**  Transaction cost of entering the current trade.  If there was not a BUY just filled, entry cost is 0.  Otherwise, entry cost is amount * a-param + b-param.
```
=IF(H10=0,0,K10*$B$5+$B$6)
```

**profit**  Profit ratio of the just-closed trade.  If there was not a SELL just filled, profit is 1.  Otherwise, profit is close price / entry price.
```
=IF(I10=0,1,E10/J10)
```

**scaledAmount**  Ending cash value of the just-closed trade prior to exit cost deduction.  Scaled amount is amount * profit.
```
=K10*M10
```

**exitCost**  Cost of exiting the just-closed trade.  If there was not a SELL order just filled, exit cost is 0.  Otherwise, exit cost is scaled amount * a-param + b-param.
```
=IF(I10=0,0,N10*$B$5+$B$6)
```

**newAmount**  New cash value of trading account after deducting entry and exit costs.  New amount is scaled amount - entry cost - exit cost.
```
=N10-L10-O10
```

**totalCost**  Total cost of all transactions.  Total cost is previous total cost + entry cost of just-opened trade + exit cost of just-closed trade.  This is the final calculation column representing the criterion value at each bar (row).
```
=Q9+L10+O10
```

## Criterion Test Class

Similar to indicators, to build XLS criterion unit tests a criterion test class must be developed.  One such class appears like
```
public class LinearTransactionCostCriterionTest extends CriterionTest {

    private ExternalCriterionTest xls;

    public LinearTransactionCostCriterionTest() throws Exception {
        super((params) -> new LinearTransactionCostCriterion((double) params[0], (double) params[1], (double) params[2]));
        xls = new XLSCriterionTest(this.getClass(), "LTC.xls", 16, 6);
    }
}   
```

### CriterionTest

An XLS criterion test class must extend (or contain) the CriterionTest class, which provides standard methods for generating ta4j criteria.  The test class constructor calls the CriterionTest constructor with the criterion's factory lambda function.  This allows for standard construction of the ta4j criterion via CriterionTest#getCriterion(params) within the unit tests.  Note that the criterion is built from parameters only (no data) because ta4j criteria are constructed from only parameters.  The data is only passed to the criterion when the AnalysisCriterion#calculate(BarSeries series, TradingRecord tradingRecord) method is called.

### ExternalCriterionTest

The XLS criterion test class also contains an ExternalCriterionTest object, which provides standard methods for extracting data and calculating criteria from an external calculator.  The test class constructor initializes this object to an XLSCriterionTest object with the test class (to get the path to the file resources), XLS file name, and two column numbers.  The zero-based column numbers indicates which column in the XLS file contains the final indicator calculation values, and which column contains the states representing the trading record.  In this case the first column number is 16 where 0 is A, so it's column Q in our example above which contains the linear transaction cost final calculation values.  The second column number is 6, so it's column G which contains the state values showing the trading record.

### Criterion XLS Unit Tests

Now that these objects are initialized, standardized unit tests may be created and executed like
```
    @Test
    public void externalData() throws Exception {
        BarSeries xlsSeries = xls.getSeries();
        TradingRecord xlsTradingRecord = xls.getTradingRecord();
        double value;

        value = getCriterion(1000d, 0.005, 0.2).calculate(xlsSeries, xlsTradingRecord);
        assertEquals(xls.getFinalCriterionValue(1000d, 0.005, 0.2).doubleValue(), value, TATestsUtils.TA_OFFSET);
        assertEquals(843.5492, value, TATestsUtils.TA_OFFSET);
    }
```
xls.getSeries() extracts the BarSeries data from the XLS spreadsheet file, just like indicator testing.  xls.getTradingRecord() extracts the TradingRecord from the file.  Criterion parameters are passed to CriterionTest#getCriterion(params) to get the ta4j AnalysisCriterion.  AnalysisCriterion#calculate(BarSeries series, TradingRecord tradingRecord) then takes the XLS BarSeries and XLS TradingRecord and returns the double final criterion value as the actual value.

xls.getFinalCriterionValue(params) modifies the parameters in the XLS spreadsheet file (in memory, not on disk!), re-calculates everything, and returns the new final criterion value from the spreadsheet as a Decimal.  Note that, as for indicator spreadsheets, there must be the same number of rows (or more) in the parameters section of the XLS file as there are parameters in the params list.  In this example, params can contain up to 5 parameters.  The sixth parameter will overwrite cell B9 which breaks the data section header!  If this example sheet is copied, the 5 rows of the parameter section should be adequate for just about any conceivable criterion.  If not, just add more rows to the parameter section, bumping down the data section.

assertEquals(expected, actual) simply compares two criteria final values to ensure that they are the same.

For good measure, a "magic value" is also included as a fail-safe catch against accidental comparison of a criterion to itself or other misconstructed test case or class.

