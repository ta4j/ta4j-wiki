# PRD + ARD — TA4J Elliott Wave Engine Enhancements (feature/ew-analysis-improvements)

**Branch scope:** `ta4j/ta4j` → `feature/ew-analysis-improvements`
**Goal:** Turn the improvement recommendations into a testable PRD, plus an architecture + codebase mapping plan aligned to TA4J’s current Elliott Wave package (swing processing, scenario generation, scoring, projections, examples).

---

## PRD

### 1) Title + 1-line summary
**Title:** Adaptive, Modular Elliott Wave Analysis & Trading Extensions for TA4J  
**Summary:** Improve Elliott Wave accuracy and usability by adding volatility-adaptive swing detection, time-based alternation scoring, pattern-aware confidence modeling, modular/puggable architecture, optional trade-advisor utilities, and configurable/expanded pattern coverage.

---

### 2) Context / problem
TA4J’s Elliott Wave package already provides:
- swing processing (`ElliottSwingIndicator`, `ElliottSwingCompressor`)
- wave state tracking (`ElliottPhaseIndicator`, `ElliottInvalidationIndicator`)
- fib/channel/confluence analysis (`ElliottRatioIndicator`, `ElliottChannelIndicator`, `ElliottConfluenceIndicator`, `ElliottFibonacciValidator`)
- scenario + confidence (`ElliottScenario`, `ElliottScenarioSet`, `ElliottConfidence`, `ElliottConfidenceScorer`, `ScenarioType`)


However, the current system can be materially improved in five areas you called out:
1. Swing detection adaptivity + alternation logic (including time/duration alternation).
2. Confidence scoring flexibility (dynamic weights, more factors like momentum/volume).
3. Architecture modularization (clean pluggable pipeline, better live-signal ergonomics).
4. Live-trading utilities (risk/reward, scaling, advisor objects).
5. Pattern coverage + pattern-set customization (diagonals, complex corrections, etc.).

---

### 3) Goals + non-goals

#### Goals
- **Accuracy:** reduce mislabels caused by volatility changes and micro-noise swings.
- **Explainability:** confidence output indicates *which* rules passed/failed (diagnostic).
- **Extensibility:** pattern-aware scoring + user-pluggable swing detectors and profiles.
- **Strategy friendliness:** easier to convert “scenario” into “trade decision” with helpers.
- **Multi-timeframe readiness:** avoid design dead-ends that block MTF aggregation later.

#### Non-goals
- Building a full execution engine inside TA4J.
- Promising profitability.
- Replacing all heuristics with ML (ML is optional “Later”).

---

### 4) Users/personas + key use cases

#### Personas
- **Quant/Algo trader:** wants programmatic, explainable wave scenarios for bots.
- **Technical analyst:** wants scenario ranking, alternation cues, fib validation diagnostics.
- **Strategy developer:** wants a stable API surface and “batteries included” helpers.

#### Key use cases
- Identify and rank impulse/correction scenarios for an instrument/timeframe.
- Validate counts with *time* alternation and volatility-aware swings.
- Integrate scenario confidence into rules (enter Wave 3, exit on invalidation, etc.).
- (Later) Align degrees across timeframes (e.g., hourly Wave 3 inside daily Wave 3).

---

### 5) Requirements

#### MVP — Functional

##### A) Enhanced swing detection & swing compression
1. **Volatility-adaptive ZigZag threshold**
   - Support dynamic threshold driven by ATR/volatility regime so pivots don’t disappear in high-volatility periods.
2. **Composite swing confirmation**
   - Allow confirming pivots via multiple detectors (e.g., Fractal(5) AND ZigZag(%)) before accepting a swing.
3. **Noise swing filtering**
   - Add minimum-magnitude rules (e.g., ignore swings < X% of the largest swing in window) to prevent “jitter waves.”
4. **Time-aware alternation inputs**
   - Ensure swings retain bar-index/time metadata needed for duration comparisons downstream.

##### B) Alternation scoring: add *time/duration* dimension
- Extend alternation scoring beyond depth/pattern to include:
  - bar-count comparison Wave 2 vs Wave 4 (and analogous ABC subwaves where applicable)
  - awarding points for classic alternation: “sharp/brief vs sideways/long”
- Output: a sub-score + diagnostic fields (barsW2, barsW4, ratio, pass/fail thresholds).

##### C) Richer confidence modeling (dynamic & multi-factor)
1. **Pattern-aware weight profiles**
   - Confidence scoring can select weights by `ScenarioType` (Impulse vs Triangle etc.).
2. **Granular fib relationships**
   - Break “fib proximity” into individually scored relationships (W2 retrace, W3 extension, W4 retrace, W5 targets, A/B/C relations) using existing validator-style continuous scoring.
3. **Extensible factor framework**
   - New factors can be added without rewriting the scorer; each factor contributes:
     - score (0..1)
     - weight
     - diagnostics (computed values, thresholds, deltas)

##### D) Architectural refactor & modularization
- Provide a higher-level “analyzer” orchestration class that:
  - accepts series + configuration
  - returns plain result objects (scenarios, confidence breakdown, projections)
  - does **not** require plotting/CLI
- Ensure each stage is swappable via interface/factory:
  - Swing detection
  - Swing compression
  - Scenario generation
  - Confidence scoring
  - Projections

##### E) Pattern coverage and customization
- Add configuration to enable/disable pattern types for scenario generation (performance + user preference).

#### MVP — Non-functional
- Deterministic results for identical inputs/config.
- Backwards compatible defaults (existing examples keep working).
- No material performance regression on common dataset sizes.

---

#### Later — Functional
- Momentum + volume factors in confidence:
  - Wave 3 momentum/volume expansion vs Wave 1
  - Wave 5 divergence vs Wave 3 (RSI/MACD)
- Market-regime-aware tolerances (looser fib proximity in high-vol regimes).
- Multi-timeframe “scenario aggregation” and consensus.
- Additional patterns:
  - Leading/ending diagonals
  - Double zigzag / W-X-Y (complex corrections)

---

### 6) Proposed solution

#### Pipeline (conceptual)
1. Detect candidate swing points (one or more detectors).
2. Optionally “confirm” swings via composite rules.
3. Compress/normalize swings to target degree.
4. Generate scenarios for enabled patterns.
5. Score each scenario with pattern-aware confidence profiles.
6. Compute invalidation + targets + (later) R/R advisory.

#### Java API sketch (ta4j-style)
```java
ElliottWaveAnalyzer analyzer = ElliottWaveAnalyzer.builder()
    .swingDetector(SwingDetectors.composite(
        SwingDetectors.fractal(5),
        SwingDetectors.adaptiveZigZag(adaptiveCfg)
    ))
    .swingCompression(CompressionProfiles.primaryDegree())
    .scenarioGenerator(ScenarioGenerators.defaultEnabled())
    .confidenceModel(ConfidenceProfiles.defaultByScenarioType())
    .build();

ElliottAnalysisResult result = analyzer.analyze(series);
ElliottScenario base = result.scenarios().base();
```

---

### 7) Constraints, edge cases, dependencies
- Elliott Wave remains probabilistic; multiple plausible scenarios must remain first-class.
- Volatility adaptation must avoid “overfitting” swings to recent noise.
- Composite swing confirmation can reduce swing count too aggressively; must be configurable.

---

### 8) Success metrics + telemetry
- Offline (dev): agreement with curated expert-labeled wave datasets (where available).
- Backtesting: improved hit-rate of “high-confidence” scenarios vs low-confidence buckets.
- Diagnostics: lower incidence of “noise” waves being assigned structural wave numbers.

---

### 9) Rollout/release plan + backward compatibility
1. Introduce new APIs as additive (`ElliottWaveAnalyzer`, factor framework, profiles).
2. Keep existing `ElliottWaveFacade` usage working; optionally implement facade via analyzer internally.
3. Ship new examples (and/or update existing examples) to show:
   - adaptive swings
   - time alternation scoring output
   - per-pattern confidence profiles

---

### 10) Risks + mitigations
- **Complexity creep:** mitigate with sensible defaults + profile presets.
- **Perf regression:** mitigate with benchmarks and optional composite checks.
- **User confusion:** mitigate with docs showing “confidence breakdown” and examples.

---

### 11) Open questions
- Should “signals/events” be in-core or an extension module?
- What minimal set of additional patterns is worth supporting in TA4J core?

---

### 12) Acceptance criteria + test plan
- Unit tests verify:
  - adaptive ZigZag threshold changes pivot selection under volatility changes.
  - time alternation score increases when W2 and W4 durations differ materially.
  - confidence profiles differ by `ScenarioType` and affect ranking.
- Golden tests (snapshot-style) for a fixed dataset:
  - scenario ordering stable for given config
  - confidence breakdown fields present and consistent

---

## ARD — Architecture + Codebase Mapping (feature/ew-analysis-improvements)

### A) Current Elliott Wave surface (what exists today)
The Elliott Wave feature set includes (at minimum) the following conceptual components and classes (per TA4J release notes and documentation):  
- **Swing processing:** `ElliottSwingIndicator`, `ElliottSwingCompressor`, `ElliottSwingMetadata`  
- **Scenario + confidence:** `ElliottScenario`, `ElliottScenarioSet`, `ScenarioType`, `ElliottConfidence`, `ElliottConfidenceScorer`  
- **Validation/projections:** `ElliottRatioIndicator`, `ElliottChannelIndicator`, `ElliottConfluenceIndicator`, `ElliottFibonacciValidator`  
- **State/invalidation:** `ElliottPhaseIndicator`, `ElliottInvalidationIndicator`, `ElliottPhase`  

Examples exist under `ta4j-examples` such as `ElliottWaveAnalysis`, `BTCUSDElliottWaveAnalysis`, etc.

> Mapping note: the exact package paths may differ slightly in-branch, but TA4J’s Elliott Wave implementation is clearly structured around these components. 

---

### B) Proposed package layout (additive, minimal disruption)

#### 1) `ta4j-core`: Elliott Wave analysis package
Target root (existing):  
- `ta4j-core/src/main/java/org/ta4j/core/analysis/elliottwave/` *(or current equivalent in-branch)*

Add subpackages (if they don’t already exist) to formalize the pipeline:

- `...elliottwave.swing`
  - `SwingDetector` (new interface)
  - `AdaptiveZigZagSwingDetector` (new)
  - `CompositeSwingDetector` (new)
  - `SwingFilter` / `MinMagnitudeSwingFilter` (new)
  - Adapters around existing `RecentSwingIndicator` implementations (existing concept: fractal/zigzag)

- `...elliottwave.compression`
  - `ElliottSwingCompressor` (existing)
  - `CompressionProfile` (new) + presets

- `...elliottwave.scenario`
  - `ScenarioGenerator` (new interface)
  - `DefaultScenarioGenerator` (wrap existing generation logic)
  - `PatternSet` (new: enabled patterns bitset/enumset)
  - uses `ScenarioType` (existing)

- `...elliottwave.confidence`
  - `ConfidenceModel` (new: selects profile by `ScenarioType`)
  - `ConfidenceProfile` (new: weights + factor set)
  - `ConfidenceFactor` (new: score+diagnostics)
  - `ElliottConfidenceScorer` remains, but can be refactored to “compose factors.”
  - Add `TimeAlternationFactor` (new; uses bar counts)
  - Add `FibRelationshipFactorSet` (new; decomposed scoring using validator methods)

- `...elliottwave.projection`
  - projection calculators (existing target logic likely lives near `ElliottScenario` today)
  - add optional `RiskRewardCalculator avoidance` (MVP optional; see “Live utilities” below)

- `...elliottwave.api` (or keep in root)
  - `ElliottWaveAnalyzer` (new orchestrator)
  - `ElliottAnalysisResult` (new immutable output)
  - Option: re-implement/bridge `ElliottWaveFacade` to call analyzer internally (keep facade stable).

#### 2) `ta4j-examples`: example modernization + new examples
Target root:
- `ta4j-examples/src/main/java/ta4jexamples/analysis/elliottwave/`

Add/Update:
- Update existing `ElliottWaveAnalysis` example to print **confidence breakdown** including time alternation data.
- Add `ElliottWaveAdaptiveSwingAnalysis` example demonstrating:
  - ATR-adaptive zigzag threshold
  - composite confirmation (fractal + zigzag)
- Add `ElliottWavePatternProfileDemo` showing pattern-specific profiles and their effect on ranking.

---

### C) Design decisions (to keep it TA4J-native)
1. **Preserve “multiple scenarios” as core output** (`ElliottScenarioSet` stays).
2. **Favor immutable records/POJOs** for outputs (`ElliottConfidence`, `ElliottScenario`, `ElliottScenarioSet` are already record-like).
3. **Use continuous scoring (0..1) for factors** (consistent with `ElliottFibonacciValidator` proximity scoring approach).
4. **Keep defaults simple**: current weights remain the default profile unless overridden, to avoid breaking user expectations.

---

### D) Concrete implementation checklist (mapped to code areas)

#### D1) Swing adaptivity
- [ ] Add `SwingDetector` interface + adapters around existing `RecentSwingIndicator` style detectors.
- [ ] Implement `AdaptiveZigZagSwingDetector` (config: ATR period, min/max threshold, smoothing).  
- [ ] Implement `CompositeSwingDetector` (policy: AND/OR; reconcile pivot disagreements).  
- [ ] Implement `MinMagnitudeSwingFilter` (relative-to-largest-swing or ATR-based).  
- [ ] Add unit tests with synthetic volatility regime shifts.

#### D2) Time alternation scoring
- [ ] Extend internal swing metadata to always include bar indices / durations (if not already tracked).  
- [ ] Add `TimeAlternationFactor`:
  - inputs: swing index positions of W2 and W4
  - outputs: `barsW2`, `barsW4`, `ratio`, `score`
- [ ] Ensure confidence output exposes these diagnostics.

#### D3) Confidence model refactor
- [ ] Introduce `ConfidenceFactor` framework.  
- [ ] Convert existing scorer subparts into factors:
  - fib proximity (existing), time proportions (existing), alternation (existing), channel adherence (existing), structure completeness (existing)
- [ ] Add per-pattern `ConfidenceProfile` map keyed by `ScenarioType`.
- [ ] Add granular fib relationships (factor set uses `ElliottFibonacciValidator` scoring functions).

#### D4) Analyzer orchestration
- [ ] Add `ElliottWaveAnalyzer` builder and `ElliottAnalysisResult`.  
- [ ] Optionally wire `ElliottWaveFacade` to use analyzer behind the scenes (no API break).

#### D5) Pattern set configuration
- [ ] Add `PatternSet` config and route into scenario generation selection.
- [ ] Add tests that ensure disabled patterns are never produced.

#### D6) Examples
- [ ] Update `ElliottWaveAnalysis` to show:
  - base + alternative scenarios
  - confidence breakdown + time alternation diagnostics  

---

### E) Minimal API additions (proposed)
```java
public interface SwingDetector {
    RecentSwings detect(BarSeries series, SwingDetectorConfig config);
}

public interface ConfidenceFactor {
    String name();
    FactorResult score(ElliottContext ctx, ElliottScenario scenario);
}

public final class ElliottWaveAnalyzer {
    // builder with swingDetector, compression, generator, confidence model
    public ElliottAnalysisResult analyze(BarSeries series);
}
```

---

### F) Compatibility notes
- Keep the existing indicator-based flow usable for users who prefer “poll each bar.”
- The analyzer is an additive orchestration layer; it should not force a new usage pattern.

---

## References
- Branch root: `feature/ew-analysis-improvements`
- Elliott Wave package class inventory + scoring weights + scenario types
- Example usage coverage for ElliottWaveAnalysis and related examples 
