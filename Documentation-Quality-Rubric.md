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
| `README.md` | 4.2 | 4.2 | 4.1 | 4.2 | 4.1 | 4.2 |
| `ta4j-core` Javadocs | 4.1 | 4.1 | 4.0 | 4.0 | 4.1 | 4.1 |
| `ta4j-examples` docs + code walkthroughs | 4.1 | 4.1 | 4.0 | 4.0 | 4.0 | 4.1 |
| `ta4j-wiki` | 4.5 | 4.2 | 4.1 | 4.2 | 4.1 | 4.3 |

Weighted score formula: `Coverage 25% + Clarity 25% + Operability 25% + Discoverability 15% + Freshness 10%`.

## Evidence by surface

### `README.md`

**Strengths**
- Strong onboarding and quick strategy setup.
- Includes explicit production-readiness checklist and canonical doc map.
- Provides decision-point links for execution path and trading-record APIs.

**Residual risks**
- Some advanced sections still require users to jump into wiki/API docs for deep operational detail.

### `ta4j-core` Javadocs

**Strengths**
- Core interfaces (`BarSeries`, `Strategy`, `Rule`, `TradingRecord`, `AnalysisCriterion`) explain key semantics.
- Added module-level entrypoint guide and expanded package-level discoverability docs.
- Added decision guidance for execution models, series types, and fill recording paths.

**Residual risks**
- Some indicator subpackage package-info pages remain concise and could be expanded further in later passes.

### `ta4j-examples`

**Strengths**
- Strong runnable examples (`Quickstart`, parity and fill-recording backtests, data-source adapters).
- Includes module-level learning tracks with prerequisites and progression.
- Adds expected success signals plus troubleshooting/runbook references.

**Residual risks**
- Not every example class has explicit expected-output assertions documented yet.

### `ta4j-wiki`

**Strengths**
- Deep coverage in backtesting, live trading, charting, and advanced indicator domains.
- Strong page-level narrative for execution model modernization.
- Includes canonical journey, runbooks, realism checklist, and troubleshooting hub in primary navigation.
- Home/sidebar now separate user onboarding flow from maintainer design artifacts.

**Residual risks**
- Governance/freshness policy quality still depends on release-review discipline and consistent enforcement.

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
