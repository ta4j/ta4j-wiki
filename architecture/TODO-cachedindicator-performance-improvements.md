CachedIndicator / RecursiveCachedIndicator performance TODO
===========================================================

Context
- Area: `ta4j-core/src/main/java/org/ta4j/core/indicators/CachedIndicator.java` and `RecursiveCachedIndicator.java`.
- Current pain points: O(n) evictions on sliding windows, heavy synchronization for read-heavy workloads, avoidable allocations, repeated last-bar recomputation, and iterative prefill overhead for recursive indicators.

Quick wins (small, contained changes)
- Make eviction O(1): replace the `ArrayList` + `subList(0, nbResultsToRemove).clear()` pattern with a fixed-size ring buffer that tracks `firstCachedIndex` and `highestResultIndex`. Keep capacity aligned to `maximumBarCount`, advance head/tail on overflow, and compute cache slot via `(index - firstCachedIndex) % capacity`. This removes per-bar copies when `maximumBarCount` is set.
- Reduce allocation churn: `increaseLengthTo` currently builds `Collections.nCopies(...)` lists on every append. Switch to `ensureCapacity` + `results.add(null)` (or direct array writes in the ring buffer) to avoid transient list allocation for the common “advance by 1 bar” case.
- Allow cached last bar when unchanged: right now `index == endIndex` always recalculates. Add a lightweight “last-bar version” (e.g., last `Bar` reference + `lastBar.getTrades()` count or a monotonic `Bar` mutation counter) so repeated queries on an unchanged in-progress bar reuse the cached value, but invalidate when the bar mutates.
- Trim synchronization on cache hits: move from `synchronized` on the whole `getValue` to a read-optimized lock (`ReentrantReadWriteLock` or `StampedLock`). Pattern: optimistic read for hits; if a slot is empty, escalate to write lock to compute exactly once. Keep `invalidateCache`/`invalidateFrom` under the write lock.
- Tighten recursive prefill: `prefillMissingValues` currently walks every index with repeated `super.getValue` calls (re-entering locks and series lookups). Provide a direct iterative fill helper that stays under one write lock and writes consecutive values from `highestResultIndex + 1` up to `targetIndex - 1`, stopping early on NaN if applicable.

Larger refactor path
- Unify storage + concurrency: implement a dedicated `CachedBuffer<T>` with (a) ring buffer storage, (b) `firstCachedIndex` and `highestResultIndex`, (c) stamped/read-write locking, (d) an atomic/volatile slot array to enable optimistic reads. `CachedIndicator` delegates storage to this helper; `RecursiveCachedIndicator` can ask the buffer to “prefill up to N” without re-entering public `getValue`.
- API for recursive indicators: consider exposing `prefillUntil(int index, IntFunction<T> calculator)` internally so recursive indicators can precompute gaps iteratively. This eliminates the arbitrary `RECURSION_THRESHOLD` and avoids recursion depth issues entirely.
- Pluggable invalidation: make `invalidateFrom` update `firstCachedIndex`/`highestResultIndex` in the buffer and clear slots lazily, avoiding full `clear()` unless necessary.

Implementation notes
- Preserve current semantics: maintain “compute once per index” and no look-ahead bias. Keep `highestResultIndex` monotonic and respect `removedBarsCount` offsetting when bars roll off.
- Be careful with NaN handling: ring buffer indices should still allow `null` as “not computed”; propagate NaN from `calculate` exactly as today.
- Logging: retain existing trace logs, but prefer logging the absolute series index rather than buffer slot to keep diagnostics clear.

Testing/verification to add
- Eviction: add a test with `maximumBarCount` small (e.g., 3) that advances >10 bars and asserts no recomputation and correct values after wrap-around.
- Concurrency: multi-threaded hit test similar to `CountingIndicator`, ensuring only one computation per index under the new locking scheme.
- Last-bar cache: verify that repeated `getValue(endIndex)` without bar mutation reuses cached value; after mutating the last bar, recomputation happens.
- Recursive fill: construct a small recursive indicator (e.g., ZLEMA) with a large gap request to ensure no stack overflow and that values are filled via the iterative helper.

Definition of done
- All above behaviors covered by tests; `CachedIndicator` and `RecursiveCachedIndicator` free of O(n) eviction; reduced allocations in steady state; lock contention minimized for cache hits; mandatory script `./scripts/run-full-build-quiet.sh` passes green.
