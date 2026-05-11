# Examples Expected Outputs

This page defines success signals for the canonical example lane.

## Golden lane examples

### 1) `ta4jexamples.Quickstart`

Command:

```bash
mvn -pl ta4j-examples exec:java -Dexec.mainClass=ta4jexamples.Quickstart
```

Success signals:
- Prints staged walkthrough sections (`[1/6]` through `[6/6]`)
- Prints trade count and key metrics summary
- In GUI mode, opens a chart window

### 2) `ta4jexamples.backtesting.TradingRecordParityBacktest`

Command:

```bash
mvn -pl ta4j-examples exec:java -Dexec.mainClass=ta4jexamples.backtesting.TradingRecordParityBacktest
```

Success signals:
- Logs execution-model comparisons
- Reports record-parity checks as passed

### 3) `ta4jexamples.backtesting.TradeFillRecordingExample`

Command:

```bash
mvn -pl ta4j-examples exec:java -Dexec.mainClass=ta4jexamples.backtesting.TradeFillRecordingExample
```

Success signals:
- Logs streamed fill ingestion
- Logs grouped order ingestion
- Logs lot-matching outcomes for multiple `ExecutionMatchPolicy` values

## Common failure patterns

| Symptom | Likely cause | Next step |
| --- | --- | --- |
| Chart does not open | Headless environment | Run on GUI-enabled environment or skip chart display checks |
| Class not found for `exec.mainClass` | Typo or moved class | Recheck class path in `ta4j-examples/README.md` |
| Data-source example fails with remote fetch error | Connectivity/rate limit/data endpoint issue | Switch to local deterministic dataset example first |

## Related pages

- [Usage Examples](Usage-examples.md)
- [Troubleshooting Hub](Troubleshooting-Hub.md)
- [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md)
