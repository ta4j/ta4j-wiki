# Documentation Quality Rubric

This page scores ta4j's major documentation surfaces for production-minded Java developers.

## Scoring model

Each surface is scored from `1` (poor) to `5` (world-class) across:

- **Coverage**: How completely user tasks are documented
- **Clarity**: How easy docs are to understand correctly
- **Operability**: How well docs support safe production use
- **Discoverability**: How easily users can find canonical guidance
- **Freshness**: How well docs stay current and internally consistent

## 4.5 evidence contract

A `4.5` score requires auditable evidence, not only narrative quality.

| Dimension | Required evidence for >=4.5 |
| --- | --- |
| Coverage | Canonical user path covers evaluation, implementation, validation, and operations with no missing critical step |
| Clarity | Entry docs provide unambiguous next-step guidance and decision criteria for common forks |
| Operability | Runbooks/checklists include pass/fail signals, escalation paths, and ownership boundaries |
| Discoverability | Canonical docs are reachable from both entry pages and navigation surfaces without deep searching |
| Freshness | Release-time checks and explicit review cadence verify links, commands, and API/doc alignment |

## Gap-to-artifact map (to 4.5)

| Surface | Primary gaps to 4.5 | Score-moving artifacts |
| --- | --- | --- |
| `README.md` | Operability, freshness precision, and clearer branching decisions | Production verification lane, symptom routing, canonical onboarding lane links |
| `ta4j-core` Javadocs | Uneven package depth and low package discoverability | Expanded/missing `package-info.java` coverage + consistent decision guidance |
| `ta4j-examples` docs | Operability and discoverability for runnable pathways | Golden example lane with expected outputs and failure signatures |
| `ta4j-wiki` | Entrypoint clarity and freshness enforcement evidence | Canonical onboarding sequence + governance-linked validation metadata |

## Surface scorecard

| Surface | Coverage | Clarity | Operability | Discoverability | Freshness | Weighted score |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `README.md` | 4.6 | 4.5 | 4.5 | 4.6 | 4.5 | 4.5 |
| `ta4j-core` Javadocs | 4.5 | 4.5 | 4.5 | 4.5 | 4.5 | 4.5 |
| `ta4j-examples` docs + code walkthroughs | 4.5 | 4.5 | 4.5 | 4.5 | 4.5 | 4.5 |
| `ta4j-wiki` | 4.6 | 4.5 | 4.5 | 4.6 | 4.5 | 4.5 |

Weighted score formula: `Coverage 25% + Clarity 25% + Operability 25% + Discoverability 15% + Freshness 10%`.

## Evidence by surface

### `README.md`

**Strengths**
- Strong onboarding plus explicit canonical lane from install to operations.
- Includes decision-point references, readiness checklists, and symptom routing.
- Cross-links to decision matrix, migration map, expected outputs, and performance characterization.

**Evidence references**
- `README.md` canonical onboarding lane and production checklist
- Links to runbook/checklist/troubleshooting and decision artifacts

### `ta4j-core` Javadocs

**Strengths**
- Core interfaces provide consistent semantics and decision guidance.
- Package-level coverage expanded across analysis/criteria/indicators/rules/support packages.
- Module-level API navigation now routes users from high-level use case to concrete package/type.

**Evidence references**
- `ta4j-core/README.md`
- Expanded and newly added `package-info.java` files under `org.ta4j.core`

### `ta4j-examples`

**Strengths**
- Strong runnable examples with canonical progression and explicit run prerequisites.
- Includes success signals and companion expected-output references.
- Aligned with wiki intent map and migration/operations guidance.

**Evidence references**
- `ta4j-examples/README.md` progression + verification lane
- `Usage-examples.md` intent map + expected outputs link
- `Examples-Expected-Outputs.md`

### `ta4j-wiki`

**Strengths**
- Deep coverage plus canonical onboarding lane in Home/Get Started/navigation.
- Includes reusable operational artifacts (decision matrix, runbook, migration map, expected outputs, performance characterization).
- Separates user onboarding and maintainer design surfaces while retaining discoverability.

**Evidence references**
- `Home.md`, `_Sidebar.md`, `Getting-started.md`
- `Execution-Decision-Matrix.md`, `Migration-and-Version-Compatibility.md`
- `Examples-Expected-Outputs.md`, `Performance-Characterization.md`
- `Documentation-Governance.md`

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
