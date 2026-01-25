Trendline scoring weights: support negative biases
==================================================

Context
- Area: `ta4j-core/src/main/java/org/ta4j/core/indicators/supportresistance/AbstractTrendLineIndicator`.
- Current rules: `ScoringWeights` fields (`touchCountWeight`, `touchesExtremeWeight`, `outsideCountWeight`, `averageDeviationWeight`, `anchorRecencyWeight`) must each be in `[0, 1]` and must sum to `1.0`. Factor scores are all in `[0, 1]`; composite score is the weighted sum. Tie-breaks prefer higher score, then higher touchCount, then fewer outsideCount, etc.
- Need: Allow users to *penalize* factors (negative weights) instead of only rewarding them (e.g., prefer fewer touches or encourage more outside swings for contrarian setups).

Proposed design
- Allow any finite double per weight (positives reward, negatives penalize). Reject NaN/Infinity.
- Replace “sum to 1.0” with sign-preserving L1 normalization so scale does not distort scoring: `sumAbs = Σ |w_i|`; if `sumAbs == 0`, reject or fallback to defaults. Normalized `w_i' = w_i / sumAbs`. This keeps effective magnitudes comparable and confines composite scores to `[-1, 1]`.
- Factor scores remain the same:
  - `touchScore = touchCount / totalSwings`
  - `extremeScore = touchesExtreme ? 1 : 0`
  - `outsideScore = 1 - min(outsideCount, totalSwings) / totalSwings`
  - `proximityScore = 1 - normalizedDeviation` (0–1)
  - `recencyAnchorScore` already normalized 0–1
- New composite: `score = wt * touchScore + wx * extremeScore + wo * outsideScore + wd * proximityScore + wr * recencyAnchorScore` using normalized weights (signs preserved). Higher scores still win; negatives invert the incentive.
- Tie-breaks: today they always favor more touches and fewer outside swings. With negative weights this can conflict. Options:
  1) Drop tie-breaks and rely solely on weighted score, or
  2) Make tie-breaks sign-aware (if weight < 0, reverse the preference for that dimension). Pick one and document.
- Serialization/descriptors: persist raw (pre-normalized) weights; normalization is runtime only so JSON round-trips preserve intent.
- Defaults/presets: keep current positive presets; add an example negative preset only if we have a clear use case.

Validation and API changes
- `validateWeights`: allow negatives; reject NaN/Infinity; error when `sumAbs == 0`.
- Builder methods unchanged; docstrings updated to mention that negatives penalize factors.
- Javadoc/wiki: note score range `[-1, 1]` post-normalization and clarify negative weight semantics.

Testing to add
- Normalization: weights `[-2, 1, 1, 0, 0]` normalize to `[-0.5, 0.25, 0.25, 0, 0]`; composite reflects inverted touch bias.
- Zero/NaN/Infinity rejection.
- Tie-break behavior aligns with chosen strategy (no tie-breaks or sign-aware tie-breaks).
- Regression tests proving existing default weights produce identical scores as before.
- Descriptor round-trip with negative values retains exact inputs.

Pitfalls / concerns
- If tie-breaks remain sign-agnostic, they can override a user’s negative preference—avoid by removing or making them sign-aware.
- Guard against `sumAbs` underflow for extremely small weights; use an epsilon when checking zero.
- Make sure any client UIs/JSON readers do not clamp weights to `[0, 1]`.
- Document that extreme negative weights can push scores toward -1; this is intentional but should be explicit to users.

Definition of done
- Scoring math updated with sign-preserving L1 normalization and negative weight support.
- Tie-break policy decided and implemented consistently with weight signs.
- Validation, Javadoc, and wiki updated; descriptors persist raw weights.
- New tests cover negative weights, zero-sum rejection, tie-break behavior, and compatibility with existing defaults.
