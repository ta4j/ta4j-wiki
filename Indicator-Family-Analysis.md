# Indicator Family Analysis

Indicator family analysis groups indicators that behave similarly on the same `BarSeries`. Use it when a strategy or research run has too many candidate indicators and you want to avoid treating near-duplicates as independent confirmation.

It does not rank indicators by profitability or predictive power. Rank candidates with your own study first, then use family results to spot redundant signals.

## Quick Start

Create the series and indicators yourself, then pass a named map to `IndicatorFamilyManager`. The manager intentionally does not scan packages or build indicators for you; explicit construction keeps the analysis catalog readable and reproducible.

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

Use `LinkedHashMap` when result order matters. The map keys become the names shown in families and pair-similarity output. The threshold is a `Number` and is converted through the series' `NumFactory`.

The default manager uses `CorrelationCoefficientIndicator(..., SampleType.POPULATION)` over a 120-bar rolling window. To analyze a shorter or longer horizon, pass the window length to the constructor:

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
- `pairSimilarities()` - pair evidence for every indicator pair.

Example interpretation:

```java
Num threshold = series.numFactory().numOf("0.90");

for (IndicatorFamilyResult.Family family : result.families()) {
    System.out.println(family.familyId()
            + " representative=" + family.representativeIndicatorName()
            + " averageInternalSimilarity=" + family.averageInternalSimilarity()
            + " minimumInternalSimilarity=" + family.minimumInternalSimilarity()
            + " members=" + family.indicatorNames());
}

for (IndicatorFamilyResult.PairSimilarity pair : result.pairSimilarities()) {
    if (pair.similarity().isGreaterThanOrEqual(threshold)) {
        System.out.println(pair.firstIndicatorName() + " ~ "
                + pair.secondIndicatorName()
                + " absoluteAverage=" + pair.similarity()
                + " signedAverage=" + pair.signedAverageSimilarity()
                + " latestSigned=" + pair.latestSignedSimilarity()
                + " samples=" + pair.sampleCount());
    }
}
```

If `sma20`, `ema20`, and `close` land in the same family, they are behaving similarly on this dataset and timeframe. If `rsi14` lands in a separate family, it is providing a different shape of information. Treat families as redundancy hints, not buy/sell recommendations.

Family membership uses absolute average similarity, so directly inverse indicators can group together. Use the signed fields to tell substitutes from inverse substitutes:

- `similarity()` is the absolute average similarity used for grouping.
- `signedAverageSimilarity()` preserves direction across the sampled window.
- `latestSignedSimilarity()` shows the most recent valid similarity sample.
- `minimumSignedSimilarity()` and `maximumSignedSimilarity()` show whether the relationship was stable or regime-sensitive.
- `sampleCount()` shows how much valid evidence was available.

Family cohesion fields help detect weak transitive chains. A family can exist because `A` is close to `B` and `B` is close to `C`, even if `A` and `C` are not close. In that case `minimumInternalSimilarity()` will be much lower than the threshold-like intuition you might expect from a tight cluster.

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

## Custom Similarity Metrics

The default population correlation is the best built-in default for same-window linear redundancy. `PearsonCorrelationIndicator` is not a clearer default because it represents the same general statistic for stable windows and is not materially better for this use case.

If you need a different metric, inject a `BiFunction<Indicator<Num>, Indicator<Num>, Indicator<Num>>`. The returned indicator is the signed similarity stream for that pair.

```java
int window = 80;
IndicatorFamilyManager manager = new IndicatorFamilyManager(series,
        (first, second) -> new CorrelationCoefficientIndicator(
                first, second, window, SampleType.POPULATION));
```

Custom metrics must:

- Use the same `BarSeries` as the manager.
- Return signed values in `[-1, 1]`.
- Return `NaN` or invalid values for samples that should be skipped.

When no valid samples exist, pair similarity is reported as zero. Future metrics that may be useful include Spearman rank correlation, Kendall tau, lag-aware cross-correlation, distance correlation, mutual information, and regime-segmented correlation, but they are not default ta4j implementations today.

## Parallel Analysis

Pair scoring is sequential by default because ta4j indicators are not required to be thread-safe. If your series, indicators, and metric factory are safe for concurrent reads, opt into bounded pair-level parallelism:

```java
IndicatorFamilyManager manager = new IndicatorFamilyManager(series, 120, 4);
```

The manager precomputes pair requests, executes at most the requested number of pair analyses at once, and returns deterministic pair and family order. Avoid this constructor when indicators cache mutable state without concurrency guarantees.

## Runnable Example

`ta4j-examples` includes `ta4jexamples.analysis.IndicatorFamilyAnalysisDemo`. It loads committed weekly S&P 500 data, builds a mixed 20-30 indicator set, and compares thresholds `0.80`, `0.90`, and `0.97`.

Run it from the ta4j repository root:

```bash
mvn -pl ta4j-examples exec:java \
  -Dexec.mainClass=ta4jexamples.analysis.IndicatorFamilyAnalysisDemo
```

If you are running from a source checkout after changing `ta4j-core`, build or install `ta4j-core` first so `ta4j-examples` sees the current local classes.

The output lists each threshold pass, the resulting families, representative indicators, cohesion metrics, and most similar indicator pairs. It also includes an examples-level broad baseline catalog that explicitly instantiates additional numeric indicators and reports skipped categories such as boolean signal indicators, state indicators, and context-heavy or high-cost indicators.

## Practical Rules

- Use the same `BarSeries` instance for the manager and every indicator.
- Use real data from the same instrument and timeframe you plan to study.
- Include only indicators you would plausibly compare; noisy filler makes the catalog harder to read.
- Review signed pair metrics before treating inverse substitutes as interchangeable.
- Review family cohesion metrics before treating a large family as a tight cluster.
- Do not use family membership alone as a trading signal. It is a redundancy check for a separately ranked candidate list.
