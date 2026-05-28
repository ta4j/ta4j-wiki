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
        .logicProfile(ElliottLogicProfile.ORTHODOX_CLASSICAL) // optional 0.22.7 preset
        .build();
ElliottWaveAnalysisResult result = runner.analyze(series);
```

Use this path when you want report generation or standalone analysis steps.

## 3) Integrate into strategy logic

- Prefer confidence-aware filters instead of forcing a single hard wave count.
- Treat invalidation levels as risk controls, not guaranteed turns.
- Validate with walk-forward methods before relying on live deployment.

## 4) Verify with maintained examples

- `ta4jexamples.analysis.elliottwave.ElliottWaveIndicatorSuiteDemo`
- `ta4jexamples.analysis.elliottwave.ElliottWavePresetDemo`
- `ta4jexamples.analysis.elliottwave.backtest.HighRewardElliottWaveBacktest`

## Related pages

- [Elliott Wave Indicators](Elliott-Wave-Indicators.md)
- [Walk-Forward Research](Walk-Forward-Research.md)
- [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md)
