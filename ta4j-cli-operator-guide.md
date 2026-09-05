# ta4j-cli Operator Guide

`ta4j-cli` is the command-line entry point for bounded ta4j workflows: strategy backtests, walk-forward evaluation, parameter sweeps, indicator and rule tests, forecast runs, and performance experiments. It is local-file-first and reuses ta4j execution, serialization, forecasting, reporting, and charting APIs instead of introducing a parallel runtime.

This guide covers operators and automation: installing, running, scripting, and troubleshooting the CLI. For GPU acceleration inside ordinary Java backtests, see [Transparent Indicator Acceleration](Indicator-Acceleration.md).

## Choose The Right Command

| Command | Use it when |
| --- | --- |
| `strategy backtest` | You know the strategy definitions and want a fast deterministic answer on one dataset |
| `strategy walk-forward` | A plain backtest looks promising and you want a robustness check before promoting it |
| `strategy sweep` | You are tuning SMA crossover windows rather than evaluating defined strategy labels |
| `indicator test` | You want to sanity-check an indicator idea before investing in a reusable rule or strategy |
| `rule test` | You want a temporary strategy from compact, named, or serialized entry/exit rules |
| `forecast run` | You need Monte Carlo or analog return projections with optional conformal calibration |
| `performance run` | You need a baseline profile, hypothesis, measured candidate result, and checksum |
| `performance compare` | You need delta, scaling-shape, checksum-parity, and threshold status between two experiments |
| `catalog` | You want machine-readable discovery of the live registry |
| `completion --shell bash` | You want generated shell completion (Zsh works through `bashcompinit`) |

Root help exposes the `strategy`, `indicator`, `rule`, `forecast`, and `performance` groups; each group reveals only its focused actions and options.

## Installation

```bash
./mvnw -pl ta4j-cli -am package
```

Produces a runnable fat jar at `ta4j-cli/target/ta4j-cli-<version>-jar-with-dependencies.jar`. The default artifact is JVM-only; optional native classifier jars are built and configured as described in [Transparent Indicator Acceleration](Indicator-Acceleration.md#enabling-acceleration).

## Canonical Input

The canonical MVP input is a local OHLCV file. CSV input should include a header row and these columns in order:

1. `date`
2. `open`
3. `high`
4. `low`
5. `close`
6. `volume`

JSON input may use the existing ta4j example bar-series formats supported by `JsonFileBarSeriesDataSource`. Use `--data-file - --data-format csv` or `--data-file - --data-format json` to read bar data from stdin:

```bash
cat bars.csv | ta4j-cli strategy backtest --data-file - --data-format csv \
  --strategy 'SMA(7,21)' --reproducible --error-format json
```

## Quick Start

```bash
java -jar ta4j-cli/target/ta4j-cli-*-jar-with-dependencies.jar \
  strategy backtest \
  --data-file /absolute/path/AAPL-PT1D-20130102_20131231.csv \
  --strategy 'SMA(7,21)' \
  --criteria NetProfit,ReturnOverMaxDrawdown \
  --position-sizing balance \
  --capital 10000 \
  --output /tmp/backtest.json
```

```bash
java -jar ta4j-cli/target/ta4j-cli-*-jar-with-dependencies.jar \
  strategy walk-forward \
  --data-file /absolute/path/AAPL-PT1D-20130102_20131231.csv \
  --strategy-json-file /absolute/path/exported-strategy.json \
  --criteria GrossReturn \
  --output /tmp/walk-forward.json
```

```bash
java -jar ta4j-cli/target/ta4j-cli-*-jar-with-dependencies.jar \
  forecast run \
  --data-file /absolute/path/AAPL-PT1D-20130102_20131231.csv \
  --state-model change-point \
  --target price \
  --horizon 5 \
  --samples 2000 \
  --quantiles 0.05,0.5,0.95 \
  --output /tmp/price-forecast.json
```

## Input Conventions

- `--strategy` / `--strategies` accept compact expressions such as `SMA(7,21)` and existing `NamedStrategy` labels such as `DayOfWeekStrategy_MONDAY_FRIDAY`. Nested commas are preserved when a batch is parsed.
- `--strategy-json-file` accepts canonical `Strategy.toJson()` output or version 2 strategy JSON with expression-backed `entryRule` and `exitRule` components; `--strategies-json-file` accepts a JSON array of the same.
- `--indicator` / `--indicator-json-file` accept a compact expression such as `RSI(14)` or serialized numeric indicator JSON.
- `--entry-rule` / `--exit-rule` (and their `-json-file` variants) accept compact expressions such as `CrossedUp(SMA(7),SMA(21))` or existing `NamedRule` labels.
- `--criterion` / `--criteria` accept named expressions such as `NetProfit` and `SharpeRatio`, or a fully qualified no-argument `AnalysisCriterion` class name; `--criterion-json` / `--criteria-file` accept canonical lossless criterion descriptors.
- Strategy batches fail before execution if any input is invalid. Use `--invalid-input skip` only when a deliberate partial result is acceptable; the JSON status is then `partial`.

## Automation Contract

Every workflow response uses a versioned envelope with `schemaVersion`, `status`, `command`, and `result`. Volatile timestamps, resolved paths, artifacts, and timings live under `run`; add `--reproducible` to omit `run` and make identical executions byte-stable.

- `performance compare` reports `status: "regression"` when the candidate exceeds `--max-regression-pct` or its checksums diverge, and exits non-zero so exit-code-based automation and CI can gate on the result while the comparison artifacts remain inspectable. All other commands exit non-zero only on failure.
- Use `--error-format JSON` for structured error envelopes with usage, I/O, or software categories.
- Invalid strategy/rule/indicator inputs fail fast with a descriptive error and a non-zero exit code; no empty result artifact is produced, and an all-invalid batch fails instead of emitting empty artifacts.

## GPU Acceleration

`ta4j-cli` also owns the optional native providers used transparently by ordinary `BarSeriesManager` backtests. Launch with `-Dta4j.acceleration=auto` to allow provider discovery; omitting the property or setting `-Dta4j.acceleration=off` performs no discovery or native loading. See [Transparent Indicator Acceleration](Indicator-Acceleration.md) for classifiers, platform status, diagnostics, rollback, and benchmark evidence.

## Troubleshooting

| Symptom | Likely cause | First place to check |
| --- | --- | --- |
| Command exits non-zero with a raw stack trace | Malformed input escaping validation | [Input Conventions](#input-conventions), `--error-format JSON` |
| CSV file "unable to load" | Missing header, wrong column order, or malformed rows | [Canonical Input](#canonical-input) |
| Walk-forward and backtest disagree | Inconsistent execution flags or unstable-bar settings | [Quick Start](#quick-start) examples, `--execution-model`, `--position-sizing` |
| Identical runs produce different JSON | Volatile `run` metadata included | Add `--reproducible` |
| Performance gate never fails | `--max-regression-pct` missing, NaN, or negative | [Automation Contract](#automation-contract), `--max-regression-pct` |
| Acceleration never engages | Provider jar missing or workload unsupported | [Transparent Indicator Acceleration](Indicator-Acceleration.md#troubleshooting) |

## Related Pages

- [Transparent Indicator Acceleration](Indicator-Acceleration.md)
- [Performance Characterization](Performance-Characterization.md)
- [Backtesting](Backtesting.md)
- [Execution Decision Matrix](Execution-Decision-Matrix.md)
- [Troubleshooting Hub](Troubleshooting-Hub.md)
