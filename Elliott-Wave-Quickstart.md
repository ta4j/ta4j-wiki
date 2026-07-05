# Elliott Wave Quickstart

Use this page when you want the shortest path to running Elliott Wave analysis in ta4j.

For full theory, component internals, scenario scoring, and advanced usage, see [Elliott Wave Indicators](Elliott-Wave-Indicators.md).

## 1) Start with the facade (recommended)

```java
BarSeries series = ...;
int index = series.getEndIndex();

// Optional: loosen/tighten Fibonacci validation for both phase() and scenarios()
Num fibTolerance = series.numFactory().numOf(0.25);
ElliottWaveFacade facade = ElliottWaveFacade.fractal(
        series, 5, ElliottDegree.INTERMEDIATE, Optional.of(fibTolerance), Optional.empty());

ElliottPhase phase = facade.phase().getValue(index);
ElliottScenarioSet scenarios = facade.scenarios().getValue(index);
Num invalidation = facade.invalidationLevel().getValue(index);
```

Use this path when you need indicator-style access inside rules or chart overlays.

For strategy entries/exits, prefer the public rules in `org.ta4j.core.rules.elliott` (for example `ElliottScenarioConfidenceRule`, `ElliottImpulsePhaseRule`, `ElliottScenarioInvalidationRule`) wired to `facade.scenarios()` — see [Elliott Wave Indicators — Built-in scenario rules](Elliott-Wave-Indicators.md#built-in-scenario-rules-orgta4jcoreruleselliott).

## 2) Use one-shot analysis for reports

```java
ElliottWaveAnalysisRunner runner = ElliottWaveAnalysisRunner.builder()
        .degree(ElliottDegree.INTERMEDIATE)
        .logicProfile(ElliottLogicProfile.ORTHODOX_CLASSICAL) // optional 0.22.7 preset
        .build();
ElliottWaveAnalysisResult result = runner.analyze(series);
```

Use this path when you want report generation or standalone analysis steps.

<a id="run-a-live-five-outlook-snapshot"></a>

## 3) Run a live five-outlook snapshot

Use the EW Snapshot Analysis workflow when you want a shareable, current macro-cycle report for a daily live instrument.
This workflow is pending the ta4j repository change in [ta4j/ta4j#1544](https://github.com/ta4j/ta4j/pull/1544); until that PR lands, use the local command below.

1. Open the ta4j repository's **Actions** tab.
2. Select **EW Snapshot Analysis**.
3. Choose **Run workflow**.
4. Set the inputs, or keep the defaults:
   - `instrument`: `BTC/USD`
   - `exchange`: `Coinbase`
   - `lookbackDays`: `1825`

The same workflow can analyze other supported daily live instruments, for example `ETH/USD` via `Coinbase` or `AAPL` via `YahooFinance`. The run summary and artifact names are generated from the selected instrument, exchange, and lookback window.

For a local run, use `ElliottWavePresetDemo` with a daily duration:

```bash
./mvnw -pl ta4j-examples -am exec:java \
  -Dexec.mainClass=ta4jexamples.analysis.elliottwave.ElliottWavePresetDemo \
  -Dexec.args="live Coinbase BTC-USD PT1D 1825"
```

Daily live runs (`PT1D` or `PT24H`) produce the macro-cycle package: one base case plus four alternate outlooks when enough distinct scenario candidates exist. Non-daily live runs continue to use the generic indicator-suite path.

The GitHub artifact contains:

- `ew-snapshot-report.html`: an offline report with embedded chart images.
- `ew-snapshot-report.md`: the Markdown run report used for the Actions summary.
- `charts/`: base-case, alternate, and current-cycle chart images.
- `*live-scenario-outlooks.json`: machine-readable five-outlook rows.
- `*live-macro-current-cycle-summary.json`: current-cycle metadata.
- `responses/` and `used-cache-files.txt`: cached datasource responses used by the run.
- `elliott-wave-preset-demo.log`: the full CLI log.

Treat confidence and probability as ranking aids, not certainties. Invalidation levels are the risk boundaries for a count, and the alternate outlooks are intentionally kept visible so operators can monitor when the base case weakens.

## 4) Integrate into strategy logic

- Prefer confidence-aware filters instead of forcing a single hard wave count.
- Treat invalidation levels as risk controls, not guaranteed turns.
- Validate with walk-forward methods before relying on live deployment.

## 5) Verify with maintained examples

- `ta4jexamples.analysis.elliottwave.ElliottWaveIndicatorSuiteDemo`
- `ta4jexamples.analysis.elliottwave.ElliottWavePresetDemo`
- `ta4jexamples.analysis.elliottwave.backtest.HighRewardElliottWaveBacktest`

## Related pages

- [Elliott Wave Indicators](Elliott-Wave-Indicators.md)
- [Walk-Forward Research](Walk-Forward-Research.md)
- [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md)
