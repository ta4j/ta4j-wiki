# Fixed Window Rule Design - Product Requirements Document

## Overview

This document consolidates the design proposals for implementing fixed-window rule functionality in ta4j. The goal is to provide a rule that checks if multiple rules were ALL satisfied within a fixed time window from when an initial trigger rule was satisfied, as opposed to the existing `ChainRule` which uses resetting thresholds.

## Problem Statement

The existing `ChainRule` implements a sequential confirmation pattern where each chain rule gets a new window starting from when the previous rule was satisfied. However, there are use cases where we need a **simultaneous confirmation pattern** where all rules must be satisfied within a single fixed window measured from the initial trigger point.

### Use Case Example

A trading strategy might require:
- Initial trigger: Price crosses above a moving average
- Confirmation rules (all must be satisfied within 5 bars of the initial trigger):
  - Volume is above average
  - RSI is above 50
  - MACD is positive

All three confirmation rules must have been satisfied at some point within the 5-bar window starting from when the price crossed the moving average.

## Design Comparison

Two design approaches were considered:

### Option 1: AndWithThresholdRule (Recommended)

**Key Characteristics:**
- Simple list-based API
- Supports per-rule thresholds with a default threshold option
- No dependency on `ChainLink` abstraction
- Clear naming that distinguishes it from `ChainRule`

### Option 2: FixedWindowChainRule

**Key Characteristics:**
- Uses `ChainLink` helper class (reuses existing infrastructure)
- API similar to `ChainRule` (familiar)
- Potential confusion about threshold semantics
- Less clear distinction from `ChainRule`

**Recommendation:** `AndWithThresholdRule` is recommended due to its simpler API, clearer semantics, and explicit differentiation from `ChainRule`.

## Recommended Design: AndWithThresholdRule

### Core Behavior

- When `initialRule` triggers at index `i`, each chain rule must have been satisfied within its own threshold window `[i-threshold, i]`
- Unlike `ChainRule`, the threshold does NOT reset for each chain rule
- Each rule can have its own threshold, or use a default threshold
- All thresholds are measured from the same initial trigger point

### Helper Class: RuleWithThreshold

```java
/**
 * Pairs a Rule with its threshold (number of bars to look back).
 * This allows per-rule threshold specification.
 */
public record RuleWithThreshold(Rule rule, int threshold) {
    public RuleWithThreshold {
        Objects.requireNonNull(rule, "rule cannot be null");
        if (threshold < 0) {
            throw new IllegalArgumentException("threshold must be >= 0");
        }
    }
    
    /**
     * Convenience factory for common case where threshold equals default
     */
    public static RuleWithThreshold of(Rule rule, int threshold) {
        return new RuleWithThreshold(rule, threshold);
    }
}
```

### API Design Options

#### Option A: Varargs with RuleWithThreshold

```java
public class AndWithThresholdRule extends AbstractRule {
    
    private final Rule initialRule;
    private final List<RuleWithThreshold> chainRules;
    private final int defaultThreshold;  // Used when threshold not specified
    
    /**
     * Constructor with default threshold for all rules
     * @param initialRule The rule that must trigger first
     * @param defaultThreshold Default number of bars to look back
     * @param chainRules The rules that must ALL be satisfied within their windows
     */
    public AndWithThresholdRule(Rule initialRule, int defaultThreshold, Rule... chainRules) {
        this(initialRule, defaultThreshold, 
             Arrays.stream(chainRules)
                   .map(rule -> new RuleWithThreshold(rule, defaultThreshold))
                   .collect(Collectors.toList()));
    }
    
    /**
     * Constructor with per-rule thresholds
     * @param initialRule The rule that must trigger first
     * @param defaultThreshold Default threshold (used if not specified in RuleWithThreshold)
     * @param chainRules Rules with their individual thresholds
     */
    public AndWithThresholdRule(Rule initialRule, int defaultThreshold, RuleWithThreshold... chainRules) {
        this(initialRule, defaultThreshold, Arrays.asList(chainRules));
    }
    
    public AndWithThresholdRule(Rule initialRule, int defaultThreshold, List<RuleWithThreshold> chainRules) {
        // Validation: defaultThreshold >= 0, chainRules not empty, etc.
        this.initialRule = Objects.requireNonNull(initialRule);
        this.defaultThreshold = defaultThreshold;
        this.chainRules = List.copyOf(chainRules);
    }
}
```

#### Option B: Fluent Builder API (Recommended for Complex Cases)

```java
public class AndWithThresholdRule extends AbstractRule {
    
    private final Rule initialRule;
    private final List<RuleWithThreshold> chainRules;
    private final int defaultThreshold;
    
    /**
     * Fluent builder for constructing AndWithThresholdRule
     */
    public static class Builder {
        private Rule initialRule;
        private int defaultThreshold = -1;  // -1 means not set
        private final List<RuleWithThreshold> chainRules = new ArrayList<>();
        
        /**
         * Set the initial trigger rule
         */
        public Builder withInitialRule(Rule rule) {
            this.initialRule = Objects.requireNonNull(rule);
            return this;
        }
        
        /**
         * Set default threshold for all chain rules
         */
        public Builder withDefaultThreshold(int threshold) {
            if (threshold < 0) {
                throw new IllegalArgumentException("threshold must be >= 0");
            }
            this.defaultThreshold = threshold;
            return this;
        }
        
        /**
         * Add a chain rule with default threshold
         */
        public Builder addRule(Rule rule) {
            if (defaultThreshold < 0) {
                throw new IllegalStateException("defaultThreshold must be set before adding rules");
            }
            this.chainRules.add(new RuleWithThreshold(rule, defaultThreshold));
            return this;
        }
        
        /**
         * Add a chain rule with specific threshold
         */
        public Builder addRule(Rule rule, int threshold) {
            this.chainRules.add(new RuleWithThreshold(rule, threshold));
            return this;
        }
        
        /**
         * Add a chain rule using RuleWithThreshold
         */
        public Builder addRule(RuleWithThreshold ruleWithThreshold) {
            this.chainRules.add(ruleWithThreshold);
            return this;
        }
        
        /**
         * Build the AndWithThresholdRule
         */
        public AndWithThresholdRule build() {
            if (initialRule == null) {
                throw new IllegalStateException("initialRule must be set");
            }
            if (chainRules.isEmpty()) {
                throw new IllegalStateException("at least one chain rule must be added");
            }
            // If defaultThreshold not set, use max of all thresholds
            int effectiveDefault = defaultThreshold >= 0 
                ? defaultThreshold 
                : chainRules.stream().mapToInt(RuleWithThreshold::threshold).max().orElse(0);
            
            return new AndWithThresholdRule(initialRule, effectiveDefault, chainRules);
        }
    }
    
    public static Builder builder() {
        return new Builder();
    }
}
```

### Core Algorithm

```
isSatisfied(index, tradingRecord):
    // Step 1: Check if initial rule is satisfied at current index
    if NOT initialRule.isSatisfied(index, tradingRecord):
        return false
    
    // Step 2: For each chain rule, check if it was satisfied within its threshold window
    for each ruleWithThreshold in chainRules:
        threshold = ruleWithThreshold.threshold()
        rule = ruleWithThreshold.rule()
        
        // Calculate this rule's window [startIndex, index]
        startIndex = max(0, index - threshold)
        
        ruleSatisfiedInWindow = false
        
        // Look backwards from current index to startIndex
        for i = index down to startIndex:
            if rule.isSatisfied(i, tradingRecord):
                ruleSatisfiedInWindow = true
                break  // Found it, no need to check further
        
        // If any chain rule was NOT satisfied in its window, fail
        if NOT ruleSatisfiedInWindow:
            return false
    
    // Step 3: All chain rules were satisfied within their respective windows
    return true
```

## Usage Examples

### Example 1: Varargs with Default Threshold

```java
Rule rule = new AndWithThresholdRule(
    initialRule,
    5,  // default threshold for all
    ruleA, ruleB, ruleC  // all use threshold=5
);
```

### Example 2: Varargs with Per-Rule Thresholds

```java
Rule rule = new AndWithThresholdRule(
    initialRule,
    5,  // default threshold (used as fallback)
    RuleWithThreshold.of(ruleA, 5),  // uses threshold=5
    RuleWithThreshold.of(ruleB, 3),  // uses threshold=3
    RuleWithThreshold.of(ruleC, 2)   // uses threshold=2
);
```

### Example 3: Fluent Builder - Same Threshold

```java
Rule rule = AndWithThresholdRule.builder()
    .withInitialRule(initialRule)
    .withDefaultThreshold(5)
    .addRule(ruleA)
    .addRule(ruleB)
    .addRule(ruleC)
    .build();
```

### Example 4: Fluent Builder - Mixed Thresholds

```java
Rule rule = AndWithThresholdRule.builder()
    .withInitialRule(initialRule)
    .withDefaultThreshold(5)  // default for rules without explicit threshold
    .addRule(ruleA)           // uses default threshold=5
    .addRule(ruleB, 3)        // uses explicit threshold=3
    .addRule(ruleC, 2)        // uses explicit threshold=2
    .build();
```

### Example 5: Fluent Builder - All Explicit Thresholds

```java
Rule rule = AndWithThresholdRule.builder()
    .withInitialRule(initialRule)
    .addRule(ruleA, 5)
    .addRule(ruleB, 3)
    .addRule(ruleC, 2)
    .addRule(ruleD, 7)
    .build();
    // No default threshold needed when all are explicit
```

## Example Scenarios

### Scenario 1: Same Threshold for All Rules

```
Initial rule triggers at index 20, default threshold = 5
All rules use threshold = 5

Chain rules:
- Rule A must be satisfied somewhere in [15-20] (threshold=5)
- Rule B must be satisfied somewhere in [15-20] (threshold=5)
- Rule C must be satisfied somewhere in [15-20] (threshold=5)

All three rules must have been satisfied at some point within their windows.
```

### Scenario 2: Different Thresholds per Rule

```
Initial rule triggers at index 20

Chain rules:
- Rule A must be satisfied somewhere in [15-20] (threshold=5)
- Rule B must be satisfied somewhere in [17-20] (threshold=3)
- Rule C must be satisfied somewhere in [18-20] (threshold=2)

Each rule has its own window, all measured from the same initial trigger point.
```

## Edge Cases

1. **Window extends before series start**: `startIndex = max(0, index - threshold)`
2. **Empty chain rules list**: Should not be allowed - validation required
3. **Threshold = 0**: Window is just the current index
4. **Multiple satisfactions**: If a rule is satisfied multiple times in the window, that's fine - we just need at least one

## Comparison with ChainRule

| Aspect | ChainRule | AndWithThresholdRule |
|--------|-----------|---------------------|
| Window behavior | Resetting (each chain gets new window from previous) | Fixed (all chains share same window from initial) |
| Window calculation | `startIndex = previousTriggerIndex - threshold` | `startIndex = initialTriggerIndex - threshold` |
| Use case | Sequential confirmation pattern | Simultaneous confirmation pattern |

## Design Decisions

### Why RuleWithThreshold Record?

- **Immutable**: Records provide value semantics
- **Clear pairing**: Explicitly associates rule with its threshold
- **Type safety**: Compiler ensures both rule and threshold are provided
- **Serialization**: Records are easily serializable

### Default Threshold Behavior

- If default threshold is provided, it's used for rules without explicit thresholds
- If no default is provided but all rules have explicit thresholds, that's fine
- If some rules have thresholds and some don't, default must be provided

### Threshold Interpretation

- Each threshold is the **maximum number of bars to look back** from the initial trigger
- Window is `[index - threshold, index]` (inclusive on both ends)
- All thresholds are measured from the **same initial trigger point** (unlike ChainRule)

## Alternative Design: FixedWindowChainRule

### Overview

An alternative design that reuses the `ChainLink` infrastructure from `ChainRule` but with fixed window semantics.

### API Design

```java
public class FixedWindowChainRule extends AbstractRule {
    
    private final Rule initialRule;
    private final List<ChainLink> chainLinks;
    private final int threshold;  // Fixed threshold for all links
    
    /**
     * Constructor with single threshold for all chain links
     * @param initialRule The rule that must trigger first
     * @param threshold The fixed number of bars to look back (applies to all links)
     * @param chainLinks The chain links that must ALL be satisfied within the window
     */
    public FixedWindowChainRule(Rule initialRule, int threshold, ChainLink... chainLinks) {
        this(initialRule, threshold, Arrays.asList(chainLinks));
    }
    
    public FixedWindowChainRule(Rule initialRule, int threshold, List<ChainLink> chainLinks) {
        // Note: threshold parameter overrides any thresholds in ChainLink objects
        // OR: We ignore ChainLink thresholds and use the fixed one
    }
}
```

### Algorithm (Version 1: Single Fixed Threshold)

```
isSatisfied(index, tradingRecord):
    // Step 1: Check if initial rule is satisfied at current index
    if NOT initialRule.isSatisfied(index, tradingRecord):
        return false
    
    // Step 2: Calculate the fixed window [startIndex, index]
    startIndex = max(0, index - threshold)
    
    // Step 3: For each chain link, check if its rule was satisfied within the window
    for each chainLink in chainLinks:
        ruleSatisfiedInWindow = false
        
        // Look backwards from current index to startIndex
        for i = index down to startIndex:
            if chainLink.getRule().isSatisfied(i, tradingRecord):
                ruleSatisfiedInWindow = true
                break
        
        // If any chain link was NOT satisfied in the window, fail
        if NOT ruleSatisfiedInWindow:
            return false
    
    // Step 4: All chain links were satisfied within the window
    return true
```

### Algorithm (Version 2: Per-Link Max Distance)

```
isSatisfied(index, tradingRecord):
    // Step 1: Check if initial rule is satisfied at current index
    if NOT initialRule.isSatisfied(index, tradingRecord):
        return false
    
    // Step 2: For each chain link, check if its rule was satisfied within its max distance
    for each chainLink in chainLinks:
        linkThreshold = chainLink.getThreshold()
        startIndex = max(0, index - linkThreshold)
        
        ruleSatisfiedInWindow = false
        
        // Look backwards from current index to startIndex
        for i = index down to startIndex:
            if chainLink.getRule().isSatisfied(i, tradingRecord):
                ruleSatisfiedInWindow = true
                break
        
        // If any chain link was NOT satisfied in its window, fail
        if NOT ruleSatisfiedInWindow:
            return false
    
    // Step 3: All chain links were satisfied within their respective windows
    return true
```

### Design Decision: How to Handle ChainLink Thresholds?

#### Option A: Ignore ChainLink Thresholds
- Use a single fixed threshold parameter
- ChainLink thresholds are ignored
- Simpler, but wastes the ChainLink threshold field

#### Option B: Use ChainLink Thresholds as Max Distance
- Each ChainLink's threshold is the maximum distance from initial trigger
- More flexible, allows different rules to have different max distances
- Example: ruleA can be up to 5 bars back, ruleB can be up to 3 bars back

#### Option C: Use Maximum of All ChainLink Thresholds
- Calculate fixed window as `max(all chainLink thresholds)`
- All rules must be satisfied within the largest threshold window
- More permissive

### Pros and Cons of FixedWindowChainRule

**Pros:**
- Reuses ChainLink infrastructure
- API similar to ChainRule (familiar)
- Can leverage existing ChainLink serialization

**Cons:**
- ChainLink threshold field might be confusing/unused
- Less clear that it's different from ChainRule
- Might need to document threshold behavior clearly

## Alternative: Extend ChainRule with Mode Parameter

```java
public class ChainRule extends AbstractRule {
    public enum Mode {
        RESETTING_THRESHOLD,  // Current behavior
        FIXED_WINDOW          // New behavior
    }
    
    private final Mode mode;
    
    public ChainRule(Mode mode, Rule initialRule, ChainLink... chainLinks) {
        // ...
    }
}
```

**Pros**: Single class, backwards compatible (default to RESETTING_THRESHOLD)  
**Cons**: More complex class, might confuse users

## Recommendation Summary

**AndWithThresholdRule** is recommended because:

1. ✅ Simpler and clearer API
2. ✅ No confusion about threshold semantics
3. ✅ Explicitly different from ChainRule
4. ✅ Easier to understand and use
5. ✅ No dependency on ChainLink abstraction
6. ✅ Supports per-rule thresholds with clean default behavior
7. ✅ Multiple API styles (varargs and fluent builder) for different use cases

**FixedWindowChainRule** might be better if:
- You want API consistency with ChainRule
- You need per-rule max distance flexibility
- You want to leverage ChainLink serialization

## Implementation Considerations

### Performance

- The algorithm requires scanning backwards through the window for each rule
- For large thresholds and many rules, this could be expensive
- Consider caching rule satisfaction states if performance becomes an issue

### Testing

- Test with various threshold values (0, 1, 5, 10, etc.)
- Test with windows that extend before series start
- Test with rules that are satisfied multiple times in the window
- Test with rules that are never satisfied
- Test edge cases: empty rule list, null rules, negative thresholds

### Documentation

- Clearly explain the difference from ChainRule
- Provide examples showing when to use each
- Document threshold semantics clearly
- Include performance considerations for large thresholds

## Questions for Discussion

1. **API Preference**: Simple list of rules vs ChainLink-based?
2. **Threshold Flexibility**: Single threshold for all vs per-rule max distances?
3. **Naming**: Which name is clearer for the use case?
4. **Backwards Compatibility**: Should we extend ChainRule with a mode parameter instead?
5. **Performance**: Should we optimize for large thresholds or many rules?

## References

- Original pseudocode documents:
  - `pseudocode-AndWithThresholdRule.md`
  - `pseudocode-AndWithThresholdRule-Enhanced.md`
  - `pseudocode-FixedWindowChainRule.md`
  - `pseudocode-comparison.md`
