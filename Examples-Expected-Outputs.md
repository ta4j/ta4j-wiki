# Examples Expected Outputs

This page defines success signals for the canonical example lane.

Building and running these examples from source requires JDK 25 or later.

## Golden lane examples

### 1) `ta4jexamples.Quickstart`

Command:

```bash
./mvnw -pl ta4j-examples exec:java -Dexec.mainClass=ta4jexamples.Quickstart
```

Success signals:
- Prints staged walkthrough sections (`[1/6]` through `[6/6]`)
- Prints trade count and key metrics summary
- In GUI mode, opens a chart window

### 2) `ta4jexamples.backtesting.TradingRecordParityBacktest`

Command:

```bash
./mvnw -pl ta4j-examples exec:java -Dexec.mainClass=ta4jexamples.backtesting.TradingRecordParityBacktest
```

Success signals:
- Logs execution-model comparisons
- Reports record-parity checks as passed

### 3) `ta4jexamples.backtesting.TradeFillRecordingExample`

Command:

```bash
./mvnw -pl ta4j-examples exec:java -Dexec.mainClass=ta4jexamples.backtesting.TradeFillRecordingExample
```

Success signals:
- Logs streamed fill ingestion
- Logs grouped order ingestion
- Logs lot-matching outcomes for multiple `ExecutionMatchPolicy` values

### 4) `ta4jexamples.backtesting.PerpetualFuturesBacktest`

Requires ta4j 0.28.1 or later and the pending [example stack](https://github.com/ta4j/ta4j/pull/1733).

For examples 4–7, first run `./mvnw -pl ta4j-core -am install -DskipTests` from the repository root of a checkout containing the corresponding pending PRs. The wrapper selects the repository's pinned Maven version; skipping tests here avoids a full core test run for example setup. Each command below compiles the examples before execution; `exec:java` alone requires previously compiled classes.

```bash
./mvnw -pl ta4j-examples compile exec:java -Dexec.mainClass=ta4jexamples.backtesting.PerpetualFuturesBacktest
```

With the bundled synthetic bars, success signals are net profit `4459.3692`, return on capital `44.593692%`, and maximum absolute drawdown `1802.03853`, in quote currency.

### 5) `ta4jexamples.backtesting.InversePerpetualFuturesBacktest`

```bash
./mvnw -pl ta4j-examples compile exec:java -Dexec.mainClass=ta4jexamples.backtesting.InversePerpetualFuturesBacktest
```

With the bundled synthetic bars, success signals are net profit `0.2982091541666667`, return on capital `59.64183083333334%`, and maximum absolute drawdown `0.2381427738095233`, in base coin.

See [Perpetual Futures Backtesting](Perpetual-Futures-Backtesting.md) for the accounting assumptions.

### 6) `ta4jexamples.backtesting.PerpetualFuturesFillRecordingExample`

Requires the pending recorded-cost branch and ta4j 0.28.1 or later.

```bash
./mvnw -pl ta4j-examples compile exec:java -Dexec.mainClass=ta4jexamples.backtesting.PerpetualFuturesFillRecordingExample
```

The offline confirmed-fill sequence logs gross profit `25`, recorded fees `6`, net recorded holding costs `4.0`, and net profit `15.0`, all in quote currency. See [Live trading](Perpetual-Futures-Live-Trading.md) for allocation and restart reconciliation.

### 7) `ta4jexamples.backtesting.PerpetualFuturesRecipes`

```bash
./mvnw -pl ta4j-examples compile exec:java -Dexec.mainClass=ta4jexamples.backtesting.PerpetualFuturesRecipes
```

With the bundled observations and 1,000 quote units of capital, spot enters 2 base units and logs fees `0.530000`, funding `0.0`, net profit `79.470000` and return on capital `7.94700%`. The perpetual enters 6 base units and logs fees `1.440000`, funding `-0.900000`, net profit `239.460000` and return on capital `23.94600%`. Both drawdown/capital fractions are `0` on this rising synthetic path. See the [Cookbook](Perpetual-Futures-Cookbook.md); these figures are not a venue-performance claim.

## Common failure patterns

| Symptom | Likely cause | Next step |
| --- | --- | --- |
| Chart does not open | Headless environment | Run on GUI-enabled environment or skip chart display checks |
| Class not found for `exec.mainClass` | Typo or moved class | Recheck class path in `ta4j-examples/README.md` |
| Data-source example fails with remote fetch error | Connectivity/rate limit/data endpoint issue | Switch to local deterministic dataset example first |
| Perpetual result differs from venue statement | Funding timing, mark price, fees, or rounding differs | [Perpetual Futures Live Trading](Perpetual-Futures-Live-Trading.md) |

## Related pages

- [Usage Examples](Usage-examples.md)
- [Troubleshooting Hub](Troubleshooting-Hub.md)
- [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md)
