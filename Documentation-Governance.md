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

- `scripts/docs-integrity-check.sh`
- `prepare-release.yml` runs this check before versioning and release-note commits

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
