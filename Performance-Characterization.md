# Performance Characterization

This page defines a reproducible process for performance-oriented ta4j evaluation.

## Objectives

- Compare execution pathways under the same workload assumptions
- Understand precision/speed tradeoffs (`DecimalNum` vs `DoubleNum`)
- Capture stable baseline runs for regression monitoring

## Reproducible commands

From repository root:

```bash
mvn -pl ta4j-examples exec:java -Dexec.mainClass=ta4jexamples.backtesting.BacktestPerformanceTuningHarness
```

Optional focused benchmark lane:

```bash
mvn -pl ta4j-examples test -Dtest=CachedIndicatorBenchmark -Dta4j.runBenchmarks=true
```

## Interpretation checklist

- Hold data range and strategy set constant across runs
- Change one performance variable at a time (execution model, number type, candidate count)
- Record elapsed time, memory profile, and ranking stability
- Treat major speedups with skepticism if strategy ordering changes unexpectedly

## Number-type guidance

- Prefer `DecimalNum` for precision-sensitive or audit-heavy analysis
- Prefer `DoubleNum` when throughput dominates and floating-point tradeoffs are acceptable

## Related pages

- [Num](Num.md)
- [Backtesting](Backtesting.md)
- [Execution Decision Matrix](Execution-Decision-Matrix.md)
