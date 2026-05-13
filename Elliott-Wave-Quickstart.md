# Elliott Wave Quickstart

Use this page when you want the shortest path to running Elliott Wave analysis in ta4j.

For full theory, component internals, scenario scoring, and advanced usage, see [Elliott Wave Indicators](Elliott-Wave-Indicators.md).

## 1) Start with the facade (recommended)

```java
BarSeries series = ...;
int index = series.getEndIndex();

ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);

ElliottPhase phase = facade.phase().getValue(index);
ElliottScenarioSet scenarios = facade.scenarios().getValue(index);
Num invalidation = facade.invalidationLevel().getValue(index);
```

Use this path when you need indicator-style access inside rules or chart overlays.

## 2) Use one-shot analysis for reports

```java
ElliottWaveAnalysisRunner runner = ElliottWaveAnalysisRunner.defaultRunner();
ElliottWaveAnalysis analysis = runner.analyze(series, series.getEndIndex());
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
