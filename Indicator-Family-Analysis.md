# Indicator Family Analysis

Indicator family analysis groups indicators that behave similarly on the same `BarSeries`. Use it when a strategy or research run has too many candidate indicators and you want to avoid treating near-duplicates as independent confirmation.

It does not rank indicators by profitability or predictive power. Rank candidates with your own study first, then use family results to spot redundant signals.

## Quick Start

Create the series and indicators yourself, then pass a named map to `IndicatorFamilyManager`.

```java
BarSeries series = ...;
ClosePriceIndicator close = new ClosePriceIndicator(series);

Map<String, Indicator<Num>> indicators = new LinkedHashMap<>();
indicators.put("close", close);
indicators.put("sma20", new SMAIndicator(close, 20));
indicators.put("ema20", new EMAIndicator(close, 20));
indicators.put("rsi14", new RSIIndicator(close, 14));
indicators.put("atr14", new ATRIndicator(series, 14));

IndicatorFamilyManager manager = new IndicatorFamilyManager(series);
IndicatorFamilyResult result = manager.analyze(indicators, 0.90);
```

Use `LinkedHashMap` when result order matters. The map keys become the names shown in families and pair-similarity output.

The default manager uses a 120-bar rolling correlation window. To analyze a shorter or longer horizon, pass the window length to the constructor:

```java
IndicatorFamilyManager shortHorizonManager = new IndicatorFamilyManager(series, 40);
IndicatorFamilyResult shortHorizonResult = shortHorizonManager.analyze(indicators, 0.90);
```

## Reading Results

`IndicatorFamilyResult` contains:

- `similarityThreshold()` - the threshold used for this run.
- `stableIndex()` - the first bar index where all pairwise correlation scores are stable.
- `families()` - grouped indicators in deterministic order.
- `familyByIndicator()` - lookup from indicator name to family id.
- `pairSimilarities()` - absolute average correlation scores for every indicator pair.

Example interpretation:

```java
for (IndicatorFamilyResult.Family family : result.families()) {
    System.out.println(family.familyId() + ": " + family.indicatorNames());
}

for (IndicatorFamilyResult.PairSimilarity pair : result.pairSimilarities()) {
    if (pair.similarity() >= 0.90) {
        System.out.println(pair.firstIndicatorName() + " ~ "
                + pair.secondIndicatorName() + " = " + pair.similarity());
    }
}
```

If `sma20`, `ema20`, and `close` land in the same family, they are behaving similarly on this dataset and timeframe. If `rsi14` lands in a separate family, it is providing a different shape of information. Treat families as redundancy hints, not buy/sell recommendations.

## Threshold Tuning

Run the same indicator map at multiple thresholds:

```java
for (double threshold : List.of(0.80, 0.90, 0.97)) {
    IndicatorFamilyResult pass = manager.analyze(indicators, threshold);
    System.out.println(threshold + " -> " + pass.families().size() + " families");
}
```

- Lower thresholds create broader behavior groups.
- Higher thresholds keep only tight substitutes together.
- Large changes in family count mean the candidate set is threshold-sensitive and should be reviewed before using family membership as a hard rule.
- The constructor's correlation window controls the lookback used to calculate pair similarity; keep it aligned with the timeframe and horizon you are studying.

## Runnable Example

`ta4j-examples` includes `ta4jexamples.analysis.IndicatorFamilyAnalysisDemo`. It loads committed weekly S&P 500 data, builds a mixed indicator set, and compares thresholds `0.80`, `0.90`, and `0.97`.

Run it from the ta4j repository root:

```bash
mvn -pl ta4j-examples exec:java \
  -Dexec.mainClass=ta4jexamples.analysis.IndicatorFamilyAnalysisDemo
```

If you are running from a source checkout after changing `ta4j-core`, build or install `ta4j-core` first so `ta4j-examples` sees the current local classes.

The output lists each threshold pass, the resulting families, and the most similar indicator pairs. Start with this demo when you need an end-to-end reference for setup and interpretation.

## Practical Rules

- Use the same `BarSeries` instance for the manager and every indicator.
- Use real data from the same instrument and timeframe you plan to study.
- Include only indicators you would plausibly compare; noisy filler makes the catalog harder to read.
- Do not use family membership alone as a trading signal. It is a redundancy check for a separately ranked candidate list.
