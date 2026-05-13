# Documentation Governance

This page defines the minimum quality bar and release-time controls for ta4j documentation.

## Documentation quality bar

User-facing documentation should satisfy:

- **Coverage**: installation, strategy building, backtesting, live operations, and troubleshooting are all documented with runnable references
- **Clarity**: canonical paths and decision points are explicit
- **Operability**: production checklists and failure handling are documented
- **Discoverability**: key pages are reachable from `Home` and `_Sidebar`
- **Freshness**: docs remain aligned with current APIs and examples

Use [Documentation Quality Rubric](Documentation-Quality-Rubric.md) for scored audits.

4.5 bar policy:

- Scores at `>=4.5` must be supported by explicit evidence in the rubric's evidence contract.
- Score updates must include a short justification note tied to changed artifacts/checks.

## Canonical ownership model

- `README.md`: entrypoint and high-level orientation
- `ta4j-examples/README.md`: runnable progression and example discovery
- Wiki:
  - [Canonical User Journey](Canonical-User-Journey.md): end-to-end flow
  - [Backtesting](Backtesting.md), [Live Trading](Live-trading.md): execution usage guidance
  - [Live Trading Runbook](Live-Trading-Runbook.md), [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md), [Troubleshooting Hub](Troubleshooting-Hub.md): production operations

Owner roles:

- **Feature author** owns doc updates for changed APIs/examples in the same change set.
- **Release reviewer** enforces the release-note-to-docs delta checklist.
- **Maintainer on duty** refreshes scorecard and freshness status before a release cut.

## Release-time documentation checks

Release preparation must validate:

1. **Link integrity** for user-facing docs
2. **Example-reference integrity** (linked files/classes exist)
3. **Command integrity where feasible** (`-Dexec.mainClass` targets real classes)
4. **No unresolved TODO markers** in core user entry docs

Automation:

- [`scripts/docs-integrity-check.sh`](https://github.com/ta4j/ta4j/blob/master/scripts/docs-integrity-check.sh) (in the `ta4j` repository)
- [`prepare-release.yml`](https://github.com/ta4j/ta4j/blob/master/.github/workflows/prepare-release.yml) runs this check before versioning and release-note commits
- Canonical docs gate includes entry docs, runbooks/checklists, decision matrix, migration map, expected outputs, and performance characterization pages

Required release checkpoint:

- Release PR is not ready until docs integrity passes and the release-note-to-docs delta checklist is complete.

## Release-note to docs delta checklist

For each release PR, reviewers must confirm:

- [ ] `CHANGELOG.md` entries are reflected in affected user docs
- [ ] New/changed API surface has corresponding wiki or README guidance
- [ ] Added/renamed examples are reflected in `ta4j-examples/README.md` and relevant wiki links
- [ ] Removed/deprecated APIs are called out with migration direction
- [ ] Any changed execution semantics are reflected in backtesting/live docs

## Freshness cadence

- Run a rubric refresh before each minor/patch release
- Re-run docs integrity checks in every release-prep workflow
- Track recurring user confusion patterns and resolve them in docs, not only in chat/issues

Freshness SLA for primary user docs (`README`, `ta4j-examples/README`, `Home`, `Getting-started`, `Backtesting`, `Live-trading`):

- **Change-window SLA**: update docs within the same PR when behavior/API changes.
- **Release SLA**: no unresolved TODO markers or broken references at release prepare time.
- **Navigation SLA**: new high-value pages must be linked from `Home` or `_Sidebar` before merge.

Dimension-to-evidence review checklist (required before scoring >=4.5):

- [ ] Coverage evidence: canonical path includes build, backtest, live, and incident handling references
- [ ] Clarity evidence: entry pages define exact next-step routing for primary user intents
- [ ] Operability evidence: checklist/runbook includes validation signals and escalation flow
- [ ] Discoverability evidence: canonical artifacts are visible in both entry copy and nav menus
- [ ] Freshness evidence: integrity checks and release checklist cover all canonical docs
- [ ] Canonical artifact set exists and passes integrity checks before release preparation

## Consolidation baseline snapshot (2026-05-13)

This snapshot records overlap metrics before the "documentation surface-area consolidation" rollout.

### Baseline metrics

- Wiki top-level pages (`*.md`, excluding `_Footer.md`): `38`
- Wiki sidebar links: `48` total / `44` local targets / `38` unique local targets
- Wiki sidebar duplicate targets: `6`
  - `Backtesting.md`
  - `Live-Candle-vs-Closed-Candle-Evaluation.md`
  - `Live-Trading-Runbook.md`
  - `Live-trading.md`
  - `Troubleshooting-Hub.md`
  - `Usage-examples.md`
- Root `README.md` wiki links: `30` total / `18` unique destinations
- `ta4j-examples/README.md` wiki links: `11` total / `9` unique destinations

### Baseline overlap and consistency findings

- Execution-choice guidance appears in multiple entry pages (`Home`, `Getting-started`, `Backtesting`) instead of one canonical decision surface.
- Onboarding and "where to go next" guidance is duplicated across root/module READMEs plus wiki entry pages.
- Wiki-link style is inconsistent in repo docs:
  - `.github/CONTRIBUTING.md` currently points to `github.com/ta4j/ta4j-wiki/wiki/...`
  - Other docs mostly point to `ta4j.github.io/ta4j-wiki/...`
- Runtime baseline wording is inconsistent:
  - Root docs and contributing docs state Java/JDK 25+
  - `ta4j-examples/README.md` states JDK 21+

### Target metrics

- Sidebar duplicate targets: `6` -> `<=1`
- Root `README.md` wiki link repetition (total vs unique gap): reduce by at least `40%`
- Execution-choice decision tables: consolidate to a single canonical page
- Broken links after each phase: `0`

## Consolidation progress snapshot (2026-05-13)

Latest post-change metrics:

- Wiki top-level pages: `40` (increased temporarily due quickstart/reference split plus one deprecation stub)
- Wiki sidebar links: `41` total / `37` local targets / `37` unique local targets
- Wiki sidebar duplicate targets: `0` (target met)
- Root `README.md` wiki links: `25` total / `17` unique destinations (total references reduced from baseline)
- Execution-choice table ownership: consolidated to [`Execution-Decision-Matrix.md`](Execution-Decision-Matrix.md)
- Link-integrity status:
  - `scripts/docs-integrity-check.sh`: pass
  - Wiki local-link smoke check: `missing_links 0`

Notes:

- The temporary page-count increase is intentional for phase-3 split-by-intent (`Charting`/`Elliott` quickstarts) and deprecation-safe routing (`Alternative-libraries` stub).
- Future cleanup can remove stubs after the cooling window and collapse quickstarts if discoverability data shows no benefit.
