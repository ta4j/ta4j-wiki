# BarSeries Base/Quote Symbol Metadata (TODO PRD)

## Overview

Add optional symbol metadata to `BarSeries` so a series can explicitly carry its
instrument identity without coupling ta4j to any external exchange library.
This PRD proposes two new fields:

- `baseSymbol` (e.g., `BTC`, `AAPL`)
- `quoteSymbol` (e.g., `USD`, `USDT`, `EUR`)

These values are simple `String` fields stored on the series (not on each bar),
and are intended to be optional and purely informational.

## Goals

- Provide explicit series-level instrument identity without external dependencies.
- Preserve the current `BarSeries` name semantics (no forced renaming).
- Keep changes backward-compatible (null/absent values are valid).
- Ensure metadata flows through builders, sub-series, and serialization.

## Non-Goals

- No parsing or validation against exchange-specific schemas.
- No automatic inference from `BarSeries#getName()`.
- No per-bar symbol metadata.
- No hard dependency on XChange or any other market library.

## Proposed API

### BarSeries (interface)

Add two optional getters:

```java
String getBaseSymbol();
String getQuoteSymbol();
```

Default behavior: `null` if not set.

### BaseBarSeries

Add fields:

```java
private final String baseSymbol;
private final String quoteSymbol;
```

### Builders

Extend the builders to capture metadata:

- `BaseBarSeriesBuilder`
  - `withBaseSymbol(String baseSymbol)`
  - `withQuoteSymbol(String quoteSymbol)`
  - (Optional convenience) `withSymbolPair(String base, String quote)`
- `ConcurrentBarSeriesBuilder`
  - Same methods, delegated to the base builder.
- Any other builder that creates a `BarSeries` should forward these values.

### Serialization

`BaseBarSeries` and `ConcurrentBarSeries` serialization should include the new
fields so round-trips preserve them.

## Design Decisions

1. **Strings, not types**: Strings avoid coupling to external symbol types.
2. **Optional**: Null is valid; no migration required.
3. **No inference**: Do not parse symbols out of the series name.
4. **Series-level**: Bars remain data points, not metadata containers.

## Implementation Plan

1. **Add getters to `BarSeries`**
   - Update interface and any implementations.
2. **Add fields to `BaseBarSeries`**
   - Thread through constructors.
3. **Update builders**
   - Add `withBaseSymbol`/`withQuoteSymbol` (and optional `withSymbolPair`).
   - Pass into `BaseBarSeries` constructors.
4. **Propagate to sub-series**
   - Ensure `getSubSeries(...)` retains metadata.
5. **Serialization updates**
   - Ensure any serialization logic (Java or JSON) preserves fields.
6. **Documentation**
   - Update javadocs in `BarSeries` and `BaseBarSeriesBuilder`.
7. **Tests**
   - Add unit tests for builder, sub-series, and serialization round-trip.

## File Impact (Expected)

- `ta4j-core/src/main/java/org/ta4j/core/BarSeries.java`
- `ta4j-core/src/main/java/org/ta4j/core/BaseBarSeries.java`
- `ta4j-core/src/main/java/org/ta4j/core/BaseBarSeriesBuilder.java`
- `ta4j-core/src/main/java/org/ta4j/core/ConcurrentBarSeries.java`
- `ta4j-core/src/main/java/org/ta4j/core/ConcurrentBarSeriesBuilder.java`
- Tests under `ta4j-core/src/test/java/org/ta4j/core/...`

## Backward Compatibility

- Existing code continues to work with `null` symbols.
- No breaking changes to constructors if defaults are applied in builders.
- The new getters are additive.

## Testing Strategy

- **Builder metadata**: Create a series via builder and assert symbols.
- **Sub-series propagation**: `getSubSeries()` preserves symbols.
- **Serialization**: Java serialization round-trip retains symbols.
- **Null handling**: Explicitly verify `null` is allowed and does not fail.

## Acceptance Criteria

- `BarSeries` exposes base/quote symbol getters.
- Builders set and preserve symbols.
- Sub-series retains symbols.
- Serialization round-trip retains symbols.
- All tests pass.

## Open Questions

- Should `withSymbolPair(base, quote)` be included for convenience?
- Should symbols be normalized (e.g., uppercase) or stored verbatim?

