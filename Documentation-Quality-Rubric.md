# Documentation Quality Rubric

This page scores ta4j's major documentation surfaces for production-minded Java developers.

## Scoring model

Each surface is scored from `1` (poor) to `5` (world-class) across:

- **Coverage**: How completely user tasks are documented
- **Clarity**: How easy docs are to understand correctly
- **Operability**: How well docs support safe production use
- **Discoverability**: How easily users can find canonical guidance
- **Freshness**: How well docs stay current and internally consistent

## Surface scorecard

| Surface | Coverage | Clarity | Operability | Discoverability | Freshness | Weighted score |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `README.md` | 4.0 | 4.0 | 3.0 | 3.0 | 3.0 | 3.4 |
| `ta4j-core` Javadocs | 3.5 | 4.0 | 3.5 | 2.5 | 4.0 | 3.5 |
| `ta4j-examples` docs + code walkthroughs | 4.0 | 4.0 | 3.5 | 2.5 | 3.5 | 3.5 |
| `ta4j-wiki` | 4.5 | 4.0 | 3.5 | 3.5 | 3.5 | 3.8 |

Weighted score formula: `Coverage 25% + Clarity 25% + Operability 25% + Discoverability 15% + Freshness 10%`.

## Evidence by surface

### `README.md`

**Strengths**
- Strong onboarding and quick strategy setup.
- Good examples for data sourcing, backtesting, and live-style record updates.

**Gaps**
- Contains stale placeholders and generic wiki links where precise links are needed.
- Includes at least one broken example reference.
- Operational checklists are still too thin for production users.

### `ta4j-core` Javadocs

**Strengths**
- Core interfaces (`BarSeries`, `Strategy`, `Rule`, `TradingRecord`, `AnalysisCriterion`) explain key semantics.
- New execution and analysis APIs include practical notes.

**Gaps**
- No module-level architecture narrative in `ta4j-core`.
- Package docs are uneven in depth and practical guidance.
- Decision support is weak (for example, when to choose one execution or numeric model over another).

### `ta4j-examples`

**Strengths**
- Strong runnable examples (`Quickstart`, parity and fill-recording backtests, data-source adapters).
- Good code readability and practical logging.

**Gaps**
- Missing module-level index page for progression and intent-based discovery.
- No explicit beginner-to-production learning path.
- Setup and expected output verification guidance is inconsistent across examples.

### `ta4j-wiki`

**Strengths**
- Deep coverage in backtesting, live trading, charting, and advanced indicator domains.
- Strong page-level narrative for execution model modernization.

**Gaps**
- Audience boundaries are blurred (user docs and maintainers' architecture artifacts share one space).
- Troubleshooting is fragmented across multiple pages.
- End-to-end journey orchestration is implied rather than explicitly canonical.

## World-class target thresholds

For ta4j to be world-class for production-minded Java developers, each surface should reach at least:

- **Coverage**: `4.5+`
- **Clarity**: `4.5+`
- **Operability**: `4.5+`
- **Discoverability**: `4.5+`
- **Freshness**: `4.5+`

Priority focus areas to close the gap:

1. Canonical journey docs and operational runbooks
2. Discoverability upgrades (clear ownership and reading order)
3. Integrity checks for links, referenced examples, and docs-to-release synchronization
