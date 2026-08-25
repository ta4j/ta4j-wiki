# When Signals Align: Correlation, Lead-Lag & Event Dependence

Pearson correlation answers one question: *do two series move together in the
same direction right now?* Trading signals ask harder questions:

- *Does my indicator move **ahead of** the market, and by how many bars?*
- *Does the **shape** of my signal wave match the price wave, even when the
  timing is stretched or compressed?*
- *When events are sparse and near-coincident — a momentum zero crossing and a
  confirmed swing high — do they **actually correspond**, and how well?*
- *Does the state of a continuous indicator reduce **uncertainty** about
  whether an event fires in the next few bars?*

ta4j's correlation and event-analysis surface (`0.24.2+`) answers all four.
The four lenses ship in two phases and complement each other; this guide shows
when to use which, with the exact API.

> **Association, not causation.** Every tool on this page measures association
> between series or events. None of them proves that one signal *causes*
> another. Use them to describe and filter relationships, then validate
> causality with controlled experiments on out-of-sample data.

## Choosing a lens

| Question | Tool | Package |
|---|---|---|
| Which lag best relates two continuous indicators, and how strong is it? | `LeadLagCorrelationIndicator` | `org.ta4j.core.indicators.statistics` |
| How similar are two waves when timing may be distorted? | `DynamicTimeWarpingDistanceIndicator` | `org.ta4j.core.indicators.statistics` |
| How well do predicted events match reference events one-to-one? | `EventSynchronizationIndicator` | `org.ta4j.core.indicators.statistics.event` |
| How much does a continuous state reduce uncertainty about a future event? | `EventMutualInformationEvaluator` | `org.ta4j.core.analysis.event` |

All four are deterministic and reproducible, and each ships a committed-data
example (see [End-to-end demos](#end-to-end-demos)).

## 1. Lead/lag correlation profile (Phase 2)

`LeadLagCorrelationIndicator` scans a bounded lag range as a rolling
indicator and reports, for every bar, the signed correlation at each lag plus
one deterministic "best" lag.

```java
LeadLagCorrelationIndicator leadLag = new LeadLagCorrelationIndicator(
        momentum, close, 32, 20, LagSelectionPolicy.MAXIMUM_ABSOLUTE_CORRELATION);
LeadLagCorrelationIndicator.Profile profile = leadLag.getProfile(lastIndex);
```

### Construction

- `LeadLagCorrelationIndicator(first, second, barCount, minimumLag,
  maximumLag, selectionPolicy)` — explicit inclusive lag range.
- `LeadLagCorrelationIndicator(first, second, barCount, maximumLag,
  selectionPolicy)` — symmetric convenience; searches
  `[-maximumLag, maximumLag]`.

The sign convention matches `LaggedCorrelationIndicator`: **a positive lag
means the first indicator leads the second**.

### Selection policy

`LagSelectionPolicy` has two values:

- `MAXIMUM_CORRELATION` — the lag with the highest *signed* correlation.
- `MAXIMUM_ABSOLUTE_CORRELATION` — the lag with the highest *absolute*
  correlation; the reported correlation keeps its original sign, so a strong
  negative relationship is still reported as negative.

### The profile

`getProfile(index)` returns an immutable `Profile` anchored at `index`:

| Accessor | Meaning |
|---|---|
| `points()` | One `Point` per lag in ascending lag order — **undefined lags are retained** (correlation `NaN`, sampleCount 0), so the profile is never silently trimmed |
| `bestLags()` | Every lag tying for the best score under the policy, ascending; empty when no lag is defined |
| `selectedLag()` | One deterministic pick: smallest absolute lag, then smallest signed lag (a symmetric `[-k, k]` tie resolves to `-k`) |
| `selectedCorrelation()` | The signed correlation at the selected lag |

Each `Point` carries `lag`, `correlation` (Pearson), and `sampleCount`. A
defined correlation is guaranteed finite and within `[-1, 1]` up to rounding
tolerance. `getValue(index)` returns the selected lag's correlation directly
when you only need the scalar.

> **When to prefer the profile:** when the best lag changes over time or you
> want the whole correlation curve, read `points()`. The `getValue` scalar is
> the fastest way to feed a best-lag correlation into a strategy rule.

## 2. Dynamic time warping shape distance (Phase 2)

`DynamicTimeWarpingDistanceIndicator` computes the minimum-cost monotonic
alignment between two rolling windows — the classic way to compare **shape**
when level, scale, and timing differ.

```java
DynamicTimeWarpingDistanceIndicator dtw = new DynamicTimeWarpingDistanceIndicator(
        momentum, close, 32, DynamicTimeWarpingDistanceIndicator.Config.shapeComparison(5));
Num distance = dtw.getValue(lastIndex);
```

### Recommended configuration

`Config.shapeComparison(radius)` bundles the baseline shape-comparison setup:

- `SequenceNormalization.Z_SCORE` — removes level and scale, so the distance
  measures shape only (two constant sequences have zero shape distance
  regardless of their levels);
- `LocalDistance.SQUARED` — penalizes large local deviations more strongly;
- `WarpingWindow.sakoeChiba(radius)` — a bounded Sakoe–Chiba band;
- `PathCostNormalization.BY_PATH_LENGTH` — divides the accumulated cost by the
  path length so paths of different lengths stay comparable.

If absolute level matters, use `SequenceNormalization.NONE`;
`LocalDistance.ABSOLUTE` and `PathCostNormalization.NONE` are available for
raw-cost semantics.

### Alignment band

- `WarpingWindow.sakoeChiba(radius)` — path cells must stay within
  `radius` of the diagonal. **Radius 0 forces diagonal alignment**, so the
  warped distance is the pointwise-cost reduction of the configured
  normalization: the sum of local costs under `PathCostNormalization.NONE`,
  or their mean under `PathCostNormalization.BY_PATH_LENGTH` (the
  `Config.shapeComparison` default).
- `WarpingWindow.unconstrained()` — explicit opt-in for full warping at
  `O(W²)` time; prefer a band unless you need it.

Complexity is `O(W * min(W, 2r + 1))` time and `O(W)` memory for window `W`
and radius `r`. The value is `NaN` until the window is fully available.

## 3. Event synchronization: F1 of sparse event streams (Phase 1)

When events are sparse and near-coincident rather than timestamp-identical,
Pearson-style correlation is a poor measure. `EventSynchronizationIndicator`
scores **two Boolean event streams** over the same series with deterministic
one-to-one matching:

```java
EventSynchronizationIndicator sync = new EventSynchronizationIndicator(
        belowZeroCrosses, swingHighConfirmation, barCount, 12, 12);
Num f1 = sync.getValue(lastIndex);                       // cached scalar
EventSynchronizationIndicator.Result r = sync.getResult(lastIndex); // full diagnostics
```

### Construction

- `EventSynchronizationIndicator(predicted, reference, barCount,
  toleranceBars)` — symmetric tolerance window.
- `EventSynchronizationIndicator(predicted, reference, barCount, maxLeadBars,
  maxLagBars)` — asymmetric; a prediction may lead by at most `maxLeadBars`
  and lag by at most `maxLagBars`.

Only `Boolean.TRUE` counts as an event; `false` and `null` do not. At bar
`index`, the indicator evaluates the **closed trailing window**
`[index - barCount + 1, index]`.

### What the F1 means here

Predicted and reference events are matched with a lexicographic objective:

1. maximize the number of matched pairs;
2. among maximum-cardinality assignments, minimize the total absolute offset;
3. then minimize the worst absolute offset;
4. then prefer the lexicographically earliest sequence of pairs.

A pair is eligible when `-maxLagBars <= offset <= maxLeadBars`, where
`offset = referenceIndex - predictedIndex` — **a positive offset means the
prediction leads the reference**.

`precision`, `recall`, and `f1Score` follow the usual definitions from the
matched counts:

- both streams empty in the window → all three are `NaN`;
- exactly one stream empty → the empty side's metric is `NaN` and F1 is `0`;
- otherwise F1 is the harmonic mean, as expected.

### Window and availability semantics (read this twice)

- **Only events inside the closed window participate.** A prediction near the
  window end can never match a reference that occurs after the window end,
  even when `maxLeadBars` would permit it — the correct causal behavior for a
  rolling indicator, and what keeps training and validation windows isolated.
- The value is `NaN` until the complete window is available: the index must
  pass the combined unstable-bar boundary and the whole window must lie inside
  the series' current domain. Windows are never silently truncated.
- One-shot evaluation of an explicit `[startIndex, endIndex]` range is the
  terminal window of an indicator with `barCount = endIndex - startIndex + 1`.

### Full diagnostics

`getResult(index)` (recomputed per call — use `getValue` for the cached
scalar) exposes `Result`:

- counts: `predictedCount`, `referenceCount`, `matchedCount`,
  `falsePositives`, `falseNegatives`;
- metrics: `precision`, `recall`, `f1Score`;
- matching detail: `matches()` — chronological `Match` records with
  `predictedIndex`, `referenceIndex`, `offsetBars`;
  `unmatchedPredictedIndexes`, `unmatchedReferenceIndexes` (ascending);
- lag summaries: `exactMatchCount`, `meanSignedOffset`, `meanAbsoluteOffset`,
  `medianSignedOffset`, `minSignedOffset`, `maxSignedOffset`;
- `windowAvailable()` — whether the window was actually evaluated.

### Sparse streams only

The matcher has a hard capacity: a window whose alignment problem needs more
than 8 million cells — `(predicted events + 1) * (reference events + 1) >
8_000_000` — throws `IllegalArgumentException` from `getResult`/`getValue`,
and so does a source whose cached event history exceeds the same limit. Sparse
streams stay far below this bound; a dense stream firing on most bars inside a
large window can hit it. Keep windows sparse enough, or handle the exception.

## 4. Event-aware mutual information (Phase 2)

`EventMutualInformationEvaluator` measures how much a **continuous predictor
state** reduces uncertainty about whether a **target event** occurs in an
explicit bar window ahead of the sample:

```java
EventMutualInformationConfig config = new EventMutualInformationConfig(
        0, 3, 8, BinningStrategy.EQUAL_FREQUENCY); // current-or-next-3-bars window, 8 bins
EventMutualInformationEvaluator evaluator = new EventMutualInformationEvaluator();
EventMutualInformationResult mi = evaluator.evaluate(
        momentum, swingHighConfirmation, 0, lastIndex, config);

mi.mutualInformationNats();          // raw MI in nats
mi.targetEntropyNats();              // H(Y)
mi.normalizedMutualInformation();    // MI / H(Y), always in [0, 1]
mi.sampleCount();                    // samples actually evaluated
mi.positiveTargetCount();            // samples with >= 1 target event in window
mi.positiveTargetRate();             // positiveTargetCount / sampleCount
mi.effectiveBinCount();              // bins actually formed
```

### The target window

A predictor sample at index `i` is labeled positive when at least one target
event occurs in the inclusive bar window
`[i + targetWindowStartBars, i + targetWindowEndBars]`:

- `(0, 0)` labels the sample's own bar;
- `(1, 3)` labels the next three bars — a future-only window.

Both offsets are non-negative, and every target index must lie inside the
evaluation range: samples whose target window would cross the range boundary
are excluded. **Target windows never cross the evaluation partition boundary**
— no look-ahead into validation data.

### Binning the predictor

`predictorBinCount` (at least 2, capped at `MAX_PREDICTOR_BIN_COUNT`) requests
bins, then `BinningStrategy` decides how:

- `EQUAL_WIDTH` — divides the value range into equal-width bins, matching
  `MutualInformationIndicator`. Simple, but skewed distributions can crowd
  most samples into a few bins.
- `EQUAL_FREQUENCY` — divides the sorted samples into approximately equal
  counts. **Identical predictor values are never split across bins**, so the
  effective bin count may be smaller than requested; it is reported in
  `effectiveBinCount()`.

### Reading the result

- `mutualInformationNats` — raw MI in natural units. A constant predictor
  (one effective bin) or a constant target carries exactly zero MI.
- `normalizedMutualInformation` — `MI / H(Y)`, bounded `[0, 1]`; 1 means the
  predictor state fully determines the event.
- **Non-finite predictor samples** make the result undefined: `NaN` metrics
  with `effectiveBinCount 0`, while the factual counts stay reported. Data is
  never silently dropped.
- The result is immutable and self-validating: impossible states (negative
  counts, inconsistent rates, defined metrics on an empty range, normalized
  values outside `[0, 1]`) are rejected at construction, so deserialized or
  hand-built results are as trustworthy as evaluator output.

### Rolling needs

`EventMutualInformationEvaluator` is a one-shot evaluator over an explicit
range. For a rolling `Indicator<Num>` of equal-width mutual information, see
`MutualInformationIndicator`; for regime-conditioned correlation,
`RegimeSegmentedCorrelationIndicator`.

## End-to-end demos

Both examples run on a committed, ossified daily BTC dataset from the examples
classpath — fully reproducible, no network access:

- `ta4jexamples.analysis.EventSynchronizationExample` — scores Net Momentum
  zero crossings against causal ZigZag swing-high/swing-low confirmation
  events with `EventSynchronizationIndicator`, printing counts, precision,
  recall, F1, and the full match diagnostics with signed offsets.
- `ta4jexamples.analysis.LeadLagDtwEventAnalysisExample` — runs all three
  Phase-2 lenses on the same fixture: the TLCC profile of Net Momentum versus
  close price (window 32, lags `[-20, 20]`), the bounded DTW shape distance
  (`Config.shapeComparison(5)`, window 32), and event MI of momentum state
  against current-or-future swing confirmations (`(0, 3, 8, EQUAL_FREQUENCY)`).

> **Confirmation-time semantics (both demos):** the ZigZag Boolean indicators
> are `true` at the bar where a prior pivot becomes *confirmed* — the first
> bar at which the reversal is causally known. The historical pivot bar may be
> several bars earlier. Matching and MI operate on the confirmation indexes;
> projecting a confirmation back to its pivot index is look-ahead information
> and must never enter a fitness calculation.

## What's next: Phase 3 (CF-455)

The event-relationship program ships in phases. Phase 1 delivered event
synchronization (ta4j PR #1602); Phase 2 delivered the lead/lag profile, DTW
shape distance, and event-aware mutual information (ta4j PR #1603).

Phase 3 (Linear **CF-455**, in Backlog) integrates all four lenses into
ta4j's unified **parameter research workflow** (`ParameterResearch`, from
PR #1542), so the metrics become directly optimizable objectives:

- maximize event-synchronization F1;
- maximize an explicitly selected signed or absolute lead/lag correlation;
- minimize DTW distance (without negating it);
- maximize an explicitly selected raw or normalized event MI inside the
  declared partition.

Grid, genetic, and particle-swarm search become interchangeable search plans
behind one public seam — switching algorithms is a one-line change — with
seeded reproducibility, exact unique-evaluation budgets, and independent
holdout/walk-forward validation of the training-selected top K. This page
will grow a tuning guide when CF-455 lands.
