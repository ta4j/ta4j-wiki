# How to Contribute

ta4j has been around for years and serves a large, diverse user base. Contributions are very welcome, but long‑term maintainability takes precedence over quick wins. Please keep the sections below in mind before filing an issue or opening a PR.

## Principles

1. **Public APIs are contracts.** Moving classes between packages, renaming methods, or otherwise breaking binary/source compatibility forces every downstream user into a refactor. We only accept breaking changes when the value dramatically outweighs the disruption, and even then they must ship with deprecation shims and migration notes.
2. **Opinionated implementations belong outside the core.** ta4j aims to be widely applicable. Highly subjective “feature bundles” (e.g., metric dashboards, bespoke reporting formats, hard-coded broker behaviors) are better published as separate modules or example projects. Keep contributions focused on reusable primitives.
3. **Additive code beats churn.** New indicators, rules, serialization helpers, and documentation are great. Mechanical refactors (“just moved files around”) or stylistic changes with no behavioral impact rarely get merged.
4. **Tests tell the story.** Every change—bug fix or feature—needs focused tests demonstrating the behavior and guarding against regressions.

## Contribution checklist

1. **Start with an issue** for anything non-trivial. Use it to confirm fit with the [Roadmap](Roadmap-and-Tasks.md) and to align on scope.
2. **Fork & branch** from `master`.
   ```bash
   git clone https://github.com/<you>/ta4j.git
   cd ta4j
   git checkout -b feature/your-topic
   ```
3. **Implement + test.** Run the full build before pushing:
   ```bash
   mvn -B clean license:format formatter:format test
   ```
   Update `CHANGELOG.md` when you add, fix, or change behavior.
4. **Open the PR** against `ta4j/master`. Draft PRs are encouraged for early feedback.

## Contribution priorities

1. Items on the [Roadmap](Roadmap-and-Tasks.md).
2. Additive indicators/criteria/rules that do not change existing behavior.
3. Test coverage or documentation improvements.
4. Bug fixes (smaller, localized fixes are easier to land; large refactors should be discussed first).
5. API changes: only with clear justification, deprecation shims, and migration docs.

## Coding expectations

- Favor clarity over cleverness; write the code you’d want to debug a year from now.
- Keep PRs scoped. If you find unrelated issues, file them or send separate PRs.
- Every new public class/method needs Javadoc with `@since <version>`.
- Use primitives for indicator parameters (e.g., `int timeFrame`). Convert to `Num` inside using `series.numFactory()`.
- Do not cache `Num` instances globally—always obtain them from the relevant factory.

## Indicator contributions

Open an issue to discuss the new indicator first. Every indicator must ship with matching tests:

- `src/main/java/org/ta4j/core/indicators/.../NewIndicator.java`
- `src/test/java/org/ta4j/core/indicators/.../NewIndicatorTest.java`

## Quick tips

- Use `series.getBeginIndex()` instead of `0` when iterating a `BarSeries`.
- Remember the difference between `DecimalNum.min(...)` and `DecimalNum.minus(...)`.
- When in doubt, ask. It’s easier (and faster) to course-correct early than to rework a large PR later.
