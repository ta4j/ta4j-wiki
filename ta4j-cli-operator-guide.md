# ta4j-cli and GPU Acceleration Operator Guide

This guide is for operators and production users of `ta4j-cli` and transparent
GPU acceleration. It covers installation, configuration, verification,
troubleshooting, and rollback. Feature-level API documentation lives in the
[Indicator Acceleration](Indicator-Acceleration.md) page and the in-repo
[`ta4j-cli/README.md`](https://github.com/ta4j/ta4j/blob/master/ta4j-cli/README.md).

## Overview

`ta4j-cli` is the command-line entry point for bounded ta4j workflows:
strategy backtests, walk-forward evaluation, parameter sweeps, indicator and
rule tests, forecast runs, and performance experiments. It is local-file-first
and reuses ta4j execution, serialization, forecasting, reporting, and charting
APIs.

The same artifact also owns the optional native acceleration providers.
An ordinary `BarSeriesManager` backtest can batch eligible Monte Carlo price
forecasts through a Metal, CUDA, or OpenCL provider without changing the
strategy, indicator, executor, or trading-record API. `Indicator#getValue(int)`
remains the scalar correctness oracle.

## Installation

### JVM-only jar

```bash
./mvnw -pl ta4j-cli -am package
```

Produces a runnable fat jar at `ta4j-cli/target/ta4j-cli-<version>-jar-with-dependencies.jar`.

### Native classifier jars (GPU acceleration)

The default `ta4j-cli` jar is JVM-only. Optional native classifiers:

```bash
./mvnw -pl ta4j-cli -am -Pmetal-macos-aarch64 package
./mvnw -pl ta4j-cli -am -Pcuda-linux-x86_64 package
./mvnw -pl ta4j-cli -am -Popencl-linux-x86_64 package
./mvnw -pl ta4j-cli -am -Popencl-linux-aarch64 package
```

```powershell
mvnw.cmd -pl ta4j-cli -am -Pcuda-windows-x86_64 package
```

Place the classifier jar on the application classpath alongside `ta4j-core`.
Packaged libraries carry SHA-256 sidecars and are extracted atomically below
`~/.ta4j/native/`. Absolute developer builds can be supplied with
`ta4j.acceleration.metal.library`, `ta4j.acceleration.cuda.library`, or
`ta4j.acceleration.opencl.library`.

## GPU Acceleration Operation

### Runtime policy

```text
# Default; no provider discovery or native loading
-Dta4j.acceleration=off

# Select a qualified GPU when it is expected to beat scalar execution
-Dta4j.acceleration=auto
```

Omitting the property is identical to `off`. Values other than `off` and
`auto` are rejected. There are no production `cpu`, `metal`, `cuda`, or
`hybrid` modes; backend forcing is reserved for package-private qualification
tests.

### Platform matrix

| Platform | Backend | Status |
|---|---|---|
| macOS arm64 | Metal | Correctness- and performance-qualified (M5 Max, 2.23x on the checked 4,096-bar workload) |
| Windows x86_64 | CUDA | Correctness-qualified (RTX 5090, CUDA 13.3, compute capability 12.0); `auto` conservatively retains scalar execution pending a stronger crossover model |
| Linux x86_64 | CUDA | Packaging present; hardware qualification open |
| Linux x86_64 / aarch64 | OpenCL | Correctness-qualified through the PoCL Docker validation matrix; auto-selection gated to GPU devices with >= 16,777,216 path-steps and >= 2 GiB device memory |

### Fallback semantics

`auto` discovers providers lazily only after a supported indicator is reached.
Provider absence, an unsupported graph or numeric factory, stale input, memory
limits, or native failure cause complete scalar recomputation. No partial GPU
result is ever published.

### Diagnostics

Set logging for `org.ta4j.core.internal.acceleration.AccelerationRuntime` to
`DEBUG` to see the selected backend, typed decision code, native status,
timings, and fallback detail.

### Verification

A fixed seed reproduces the same integer random stream in every lane. Cross-lane
numeric summaries (Metal FP32 vs CUDA FP64) are checked within the documented
tolerance; stability, sample counts, quantiles, and trading decisions must
still agree.

### Rollback

Use `-Dta4j.acceleration=off`, omit `ta4j-cli`, or use the JVM-only artifact
for complete rollback. `-Dta4j.forecast.rngVersion=0` restores the pre-0.23.1
legacy random stream, during which transparent acceleration is disabled.

## CLI Operation

### Commands

- `strategy backtest` — run concrete strategies against one local dataset, emit bounded JSON performance reports.
- `strategy walk-forward` — rolling train/test evaluation with per-fold out-of-sample results.
- `strategy sweep` — rank a bounded SMA crossover parameter grid.
- `indicator test` — turn a compact or serialized numeric indicator into a lightweight exploratory strategy.
- `rule test` — temporary strategy from compact, named, or serialized entry/exit rules with backtest + walk-forward reports.
- `forecast run` — EWMA, rough-volatility, or change-point return state with Monte Carlo or analog projections, optional conformal calibration, and terminal-price forecasts.
- `performance run` / `performance compare` — named optimization experiments and delta comparisons.
- `catalog` — machine-readable live registry discovery.
- `completion --shell bash` — generated shell completion (Zsh via `bashcompinit`).

### Canonical input

Local OHLCV files. CSV needs a header row and columns in order:
`date`, `open`, `high`, `low`, `close`, `volume`. JSON may use the existing
ta4j example bar-series formats. `--data-file - --data-format csv|json` reads
bar data from stdin, which enables pipelines:

```bash
cat bars.csv | ta4j-cli strategy backtest --data-file - --data-format csv --strategy 'SMA(7,21)' --reproducible --error-format json
```

### Automation contract

Every workflow response uses a versioned envelope with `schemaVersion`,
`status`, `command`, and `result`. Volatile timestamps, resolved paths,
artifacts, and timings live under `run`; `--reproducible` omits `run` and makes
identical executions byte-stable. Use `--error-format JSON` for structured
error envelopes with usage, I/O, or software categories. Invalid inputs fail
before execution; `--invalid-input skip` produces a `partial` status only when
a deliberate partial result is acceptable.

### Exit codes and failure behavior

- Successful commands emit JSON (file or stdout) and exit 0.
- Invalid strategy/rule/indicator inputs fail fast with a descriptive error and a non-zero exit code; no empty result artifact is produced.
- All-invalid batches fail instead of emitting empty artifacts.

## Troubleshooting

| Symptom | Check |
|---|---|
| Acceleration never engages | Confirm `-Dta4j.acceleration=auto` is set, the classifier jar is on the classpath, the workload is an eligible `DoubleNum` Monte Carlo forecast, and `AccelerationRuntime` DEBUG logs show discovery. |
| Native library load error | Verify the classifier matches the OS/arch, SHA-256 sidecar checks pass, and `~/.ta4j/native/` is writable. On restricted JVMs add `--enable-native-access=ALL-UNNAMED`. |
| OpenCL device not selected | Confirm the device is a GPU ICD with >= 16,777,216 path-steps and >= 2 GiB device memory; CPU ICDs (e.g. PoCL) only run the internal qualification path. |
| Results differ across lanes | FP32 Metal vs FP64 CUDA summaries are compared within documented tolerance; decisions, quantiles, and stability must match. |
| Walk-forward/backtest mismatch | Verify shared execution flags (`--execution-model`, `--position-sizing`, `--capital`, `--commission`) and unstable-bar settings are consistent. |
