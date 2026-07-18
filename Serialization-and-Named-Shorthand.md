# Serialization and Named Shorthand

ta4j can persist and rebuild indicators, rules, strategies, and analysis criteria. The default JSON form is a canonical descriptor tree: it is explicit, stable, and intended for durable storage.

> **Preview status:** This page documents the companion serialization shorthand feature in [ta4j PR #1507](https://github.com/ta4j/ta4j/pull/1507), targeting ta4j 0.23.1. The named shorthand APIs are not available from the latest released ta4j artifacts or from ta4j `master` until that implementation PR is merged and released.

The PR #1507 implementation adds compact named shorthand for authoring configuration, presenting strategy choices in UIs, and round-tripping common graphs without hand-writing full descriptor JSON.

Use this guide when you want to store a strategy, pass a rule or indicator through a service boundary, load strategy presets from configuration, or let users choose named assets such as `SMA(7,21)` or `SharpeRatio`.

## Choose the Right Form

| Form | Best for | API |
| --- | --- | --- |
| Canonical descriptor JSON | Long-term storage, audit logs, exact graph persistence, and maximum compatibility | `toJson()`, `fromJson(...)`, `describe(...)` |
| Strategy JSON v2 | Human-authored strategy configuration with named rule and indicator shorthand | `Strategy.fromJson(series, json)` |
| Named expressions | UI pickers, CLI arguments, compact config values, and registry extension points | `toExpression(...)`, `fromExpression(...)` |
| Compact strategy JSON | Exporting a recognized strategy graph as a v2 config | `strategy.toCompactJson()` |

Canonical JSON remains the baseline. `strategy.toJson()` always emits the canonical descriptor form. Compact output is explicit: call `strategy.toCompactJson()` only when you want the opt-in v2 envelope.

## Strategy Quickstart

The shortest built-in strategy macro is an SMA crossover:

```java
String json = """
        {
          "version": 2,
          "strategy": "SMA(7,21)",
          "name": "Daily_SMA_Crossover"
        }
        """;

Strategy strategy = Strategy.fromJson(series, json);
String canonicalJson = strategy.toJson();
String compactJson = strategy.toCompactJson();

Strategy macroStrategy = Strategy.fromExpression(series, "SMA(7,21)");
String expression = macroStrategy.toExpression(); // "SMA(7,21)"
```

`SMA(7,21)` builds a `BaseStrategy` whose entry rule is `CrossedUpIndicatorRule(SMA(7), SMA(21))` and whose exit rule is `CrossedDownIndicatorRule(SMA(7), SMA(21))`. The strategy's unstable bar count is set to the slow SMA period.

If you need full control over entry and exit logic, write a v2 strategy with rule shorthand:

```java
String json = """
        {
          "version": 2,
          "name": "Momentum_With_Risk_Stops",
          "unstableBars": 26,
          "startingType": "BUY",
          "entryRule": "And(SmaCrossUp(12,26),Under(RSI(14),70))",
          "exitRule": "Or(SmaCrossDown(12,26),StopLoss(2.5%))"
        }
        """;

Strategy strategy = Strategy.fromJson(series, json);
```

The same fields can be expressed as objects when that is easier for generated JSON:

```json
{
  "version": 2,
  "name": "Momentum_With_Risk_Stops",
  "entryRule": {
    "type": "CrossedUpIndicatorRule",
    "args": ["SMA(12)", "SMA(26)"]
  },
  "exitRule": {
    "type": "OrRule",
    "rules": [
      { "type": "SmaCrossDown", "args": [12, 26] },
      { "type": "StopLossRule", "args": ["2.5%"] }
    ]
  }
}
```

Strategy v2 accepts these metadata fields:

| Field | Meaning |
| --- | --- |
| `version` | Required for v2, must be `2`. |
| `strategy` | Optional top-level strategy macro such as `SMA(7,21)`. If present, entry and exit rules come from the macro; do not also provide `entryRule` or `exitRule`. |
| `name` | Optional strategy name. Use `null` to intentionally preserve an unnamed strategy when compacting a macro-shaped strategy. |
| `type` | Optional, but only `BaseStrategy` or `org.ta4j.core.BaseStrategy` is accepted by v2. Use canonical JSON or a registered macro for other strategy implementations. |
| `unstableBars` | Optional non-negative integer override. |
| `startingType` | Optional `BUY` or `SELL`. |
| `entryRule`, `exitRule` | Required when `strategy` is absent. Values may be expression strings or rule objects. |

Use `Strategy.fromExpression(series, "SMA(7,21)")` when the whole strategy is a
single registered macro. Use `Strategy.fromJson(series, json)` when you need
metadata overrides, explicit entry/exit rules, or a stored v2 envelope.

## Indicators

Indicators can round-trip through canonical JSON:

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
RSIIndicator rsi = new RSIIndicator(close, 14);

String json = rsi.toJson();
Indicator<?> restored = Indicator.fromJson(series, json);
```

For compact authoring, use expressions:

```java
Indicator<?> close = Indicator.fromExpression(series, "ClosePrice");
Indicator<?> sma = Indicator.fromExpression(series, "SMA(21)");
Indicator<?> rsiOfSma = Indicator.fromExpression(series, "RSI(SMA(14),9)");

String expression = sma.toExpression(); // "SMA(21)"
```

Built-in indicator shorthand:

| Expression | Descriptor meaning |
| --- | --- |
| `ClosePrice` | `ClosePriceIndicator` |
| `ClosePriceIndicator` | `ClosePriceIndicator`, accepted for input but not preferred for compact output |
| `SMA(barCount)` | `SMAIndicator(ClosePriceIndicator, barCount)` |
| `SMA(indicator,barCount)` | `SMAIndicator(indicator, barCount)` |
| `EMA(barCount)` | `EMAIndicator(ClosePriceIndicator, barCount)` |
| `EMA(indicator,barCount)` | `EMAIndicator(indicator, barCount)` |
| `RSI(barCount)` | `RSIIndicator(ClosePriceIndicator, barCount)` |
| `RSI(indicator,barCount)` | `RSIIndicator(indicator, barCount)` |

Indicator expression export succeeds only when the registry recognizes the descriptor. If a graph includes an unsupported indicator, keep using canonical `indicator.toJson()` until you add a registry binding and formatter for that indicator.

## Rules

Rules can also round-trip through canonical JSON:

```java
Rule entry = new CrossedUpIndicatorRule(new SMAIndicator(close, 12), new SMAIndicator(close, 26));

String json = entry.toJson();
Rule restored = Rule.fromJson(series, json);
```

Expression form keeps common trading logic readable:

```java
Rule entry = Rule.fromExpression(series,
        "And(SmaCrossUp(12,26),Under(RSI(14),70))");

Rule exit = Rule.fromExpression(series,
        "Or(SmaCrossDown(12,26),StopLoss(2.5%))");
```

Built-in rule shorthand:

| Expression | Descriptor meaning |
| --- | --- |
| `SmaCrossUp(fast,slow)` | `CrossedUpIndicatorRule(SMA(fast), SMA(slow))` |
| `SmaCrossDown(fast,slow)` | `CrossedDownIndicatorRule(SMA(fast), SMA(slow))` |
| `CrossedUp(indicator,indicatorOrNumber)` | `CrossedUpIndicatorRule` |
| `CrossedDown(indicator,indicatorOrNumber)` | `CrossedDownIndicatorRule` |
| `Over(indicator,indicatorOrNumber)` | `OverIndicatorRule` |
| `Under(indicator,indicatorOrNumber)` | `UnderIndicatorRule` |
| `And(left,right)` | `AndRule` |
| `Or(left,right)` | `OrRule` |
| `StopLoss(lossPercentage)` | `StopLossRule(ClosePriceIndicator, lossPercentage)` |
| `StopGain(gainPercentage)` | `StopGainRule(ClosePriceIndicator, gainPercentage)` |

Class-style aliases such as `AndRule`, `OrRule`, `OverIndicatorRule`, `UnderIndicatorRule`, `CrossedUpIndicatorRule`, `CrossedDownIndicatorRule`, `StopLossRule`, and `StopGainRule` are accepted as input where the v2 object syntax is more natural. Compact output prefers the shorter names above when a formatter recognizes the descriptor.

## Analysis Criteria

Analysis criteria serialize through canonical descriptor JSON and can also use default named aliases:

```java
AnalysisCriterion criterion = AnalysisCriterion.fromExpression("SharpeRatio");
String json = criterion.toJson();
AnalysisCriterion restored = AnalysisCriterion.fromJson(json);
String expression = restored.toExpression(); // "SharpeRatio"
```

Built-in analysis criterion aliases map to their default constructors:

| Expression | Criterion |
| --- | --- |
| `NetProfit` | `NetProfitCriterion` |
| `GrossReturn` | `GrossReturnCriterion` |
| `NetReturn` | `NetReturnCriterion` |
| `MaximumDrawdown` | `MaximumDrawdownCriterion` |
| `ReturnOverMaxDrawdown` | `ReturnOverMaxDrawdownCriterion` |
| `SharpeRatio` | `SharpeRatioCriterion` |
| `SortinoRatio` | `SortinoRatioCriterion` |
| `TotalFees` | `TotalFeesCriterion` |
| `NumberOfPositions` | `NumberOfPositionsCriterion` |

Parameterized criteria should use canonical JSON unless you register a custom formatter that can represent every constructor argument without losing information.

## Custom Shorthand

Use `NamedAssetRegistry` when your application has its own aliases. Registries are immutable after build, and aliases are scoped by `NamedAssetKind`, so `SMA(7)` can mean an indicator while `SMA(7,21)` can mean a strategy macro.

```java
NamedAssetRegistry registry = NamedAssetRegistry.builder()
        .withDefaults()
        .registerIndicator("FastCloseSma", List.of("barCount"), args -> {
            args.requireCount(1);
            return ComponentDescriptor.builder()
                    .withType("SMAIndicator")
                    .withParameters(Map.of("barCount", args.positiveInt(0)))
                    .addComponent(ComponentDescriptor.typeOnly("ClosePriceIndicator"))
                    .build();
        })
        .build();

Indicator<?> indicator = Indicator.fromExpression(series, "FastCloseSma(5)", registry);
```

Factories receive typed `NamedAssetRegistry.Arguments` helpers:

| Helper | Use |
| --- | --- |
| `requireCount(expected)` | Fail fast when an alias receives the wrong arity. |
| `positiveInt(index)` | Read a positive bar count or lookback. |
| `intValue(index)` | Read an integer that may be zero or negative. |
| `finiteNumberText(index)` | Read a finite JSON-style number, accepting an optional trailing `%`. |
| `stringValue(index)` | Read a quoted string or bare token. |
| `indicatorDescriptor(index)` | Expand an argument as an indicator descriptor. |
| `ruleDescriptor(index)` | Expand an argument as a rule descriptor. |

Add a formatter when you also want `toExpression(...)` or `toCompactJson(...)` to emit your alias. Without a formatter, the alias is still valid for input.

If an indicator alias may be used inside numeric comparison rules such as
`Over(...)`, `Under(...)`, `CrossedUp(...)`, or `CrossedDown(...)`, it must
rebuild an indicator whose runtime values are `Num`. Boolean indicators belong
behind boolean-aware rules such as `BooleanIndicatorRule`; v2 strategy parsing
rejects non-numeric indicator aliases at the rule argument that used them.

To make application defaults automatic, implement `NamedAssetProvider` and register it with Java `ServiceLoader`:

```text
META-INF/services/org.ta4j.core.named.NamedAssetProvider
```

The file should contain the fully qualified provider class name. `NamedAssetRegistry.defaultRegistry()` loads ta4j defaults first, then provider bindings.

## Grammar and Validation

The expression grammar is intentionally strict:

- Alias names must be identifiers.
- Arguments may be nested expressions, quoted strings, bare string or enum-like tokens, finite numbers, or percentages used by stop rules.
- Whitespace around aliases and commas is ignored.
- Empty arguments, unknown aliases, unbalanced parentheses, and trailing input fail immediately.
- Built-in bar-count arguments require positive integers.
- Strategy `unstableBars` must be non-negative.
- Strategy `startingType` must be `BUY` or `SELL`.
- Malformed JSON-looking descriptor payloads fail as syntax errors. Plain labels
  remain accepted only for non-JSON text.
- Canonical descriptor numeric constructor arguments follow the same finite
  JSON-number rule as shorthand; integer constructor parameters must be exact
  integers and cannot silently truncate decimals.

When processing lists of expressions from a CLI or configuration file, do not split on commas manually. Use `NamedAssetRegistry#splitTopLevel(...)` so nested expressions and quoted strings stay intact:

```java
List<String> entries = NamedAssetRegistry.defaultRegistry()
        .splitTopLevel("SMA(7),Custom(\"a,b\",SMA(21)),RSI(14)");
```

## Round-Trip Checklist

- Use canonical JSON for audit trails and long-lived storage.
- Use v2 strategy JSON for human-authored strategy configs.
- Use expressions for compact UI, CLI, and config values.
- Use `Strategy.fromExpression(...)` / `Strategy#toExpression()` for whole
  strategy macros and `Strategy#fromJson(...)` / `Strategy#toCompactJson()` for
  v2 envelopes.
- Keep `toJson()` output canonical; use `toCompactJson()` only when compact v2 output is desired.
- Expect `toExpression(...)` to fail when no registered formatter can represent the descriptor.
- Preserve all constructor inputs in serializable fields when adding new indicator, rule, strategy, or criterion support.
- Add regression tests that compare canonical descriptors, not just object class names.
- Prefer custom registry aliases over string parsing in application code.

## Related Pages

- [Trading Strategies](Trading-strategies.md)
- [Technical Indicators](Technical-indicators.md)
- [Analysis Criteria and Risk Metrics](Analysis-Criteria-and-Risk-Metrics.md)
- [Usage Examples](Usage-examples.md)
