# Elliott Wave Indicators

A comprehensive guide to using ta4j's Elliott Wave analysis tools, from basic concepts to advanced trading strategies.

## Table of Contents

1. [Introduction to Elliott Wave Theory](#introduction-to-elliott-wave-theory)
2. [Overview of ta4j's Elliott Wave Implementation](#overview-of-ta4js-elliott-wave-implementation)
3. [Core Components](#core-components)
4. [Getting Started](#getting-started)
   - [Example Classes](#example-classes)
   - [Using ElliottWaveFacade (Recommended)](#using-elliottwavefacade-recommended)
5. [Scenario-Based Analysis](#scenario-based-analysis)
6. [Confidence Scoring](#confidence-scoring)
7. [Working with Alternative Wave Counts](#working-with-alternative-wave-counts)
8. [Price Projections and Targets](#price-projections-and-targets)
9. [Invalidation Levels](#invalidation-levels)
10. [Intermediate Usage Patterns](#intermediate-usage-patterns)
11. [Advanced Topics](#advanced-topics)
12. [Best Practices](#best-practices)
13. [Integration with Trading Strategies](#integration-with-trading-strategies)

---

## Introduction to Elliott Wave Theory

Elliott Wave Theory, developed by Ralph Nelson Elliott in the 1930s, is a form of technical analysis that identifies recurring patterns in market price movements. The theory posits that market prices move in predictable wave patterns that reflect investor psychology.

### Basic Wave Structure

Elliott Wave patterns consist of two main types of waves:

- **Impulsive Waves (1-2-3-4-5)**: These waves move in the direction of the main trend. In a bull market, waves 1, 3, and 5 move upward, while waves 2 and 4 are corrective downward movements.
- **Corrective Waves (A-B-C)**: These waves move against the main trend, representing temporary reversals or consolidations.

### Key Principles

1. **Wave Degrees**: Elliott waves exist at multiple timeframes simultaneously, from grand supercycle (decades) down to sub-minuette (minutes). Each degree is labeled using a specific notation system.
2. **Fibonacci Relationships**: Wave amplitudes often relate to each other through Fibonacci ratios (e.g., 0.382, 0.618, 1.618), providing targets for retracements and extensions.
3. **Wave Rules**: Specific rules govern wave formation:
   - Wave 2 cannot retrace more than 100% of Wave 1
   - Wave 3 cannot be the shortest of the three impulse waves (1, 3, 5)
   - Wave 4 cannot overlap with Wave 1 (except in diagonal triangles)
   - Wave 5 must exceed Wave 3's extreme (in standard impulses)

### The Problem of Multiple Wave Counts

A fundamental challenge in Elliott Wave analysis is that **any given price action can often support multiple valid wave interpretations**. Two experienced analysts looking at the same chart may arrive at different counts—and both may be technically valid according to Elliott Wave rules.

This ambiguity is not a flaw in the theory; it reflects the inherent uncertainty in market forecasting. Ta4j addresses this challenge directly through:

- **Scenario-based analysis**: Generating multiple plausible wave counts simultaneously
- **Confidence scoring**: Quantifying how well each interpretation aligns with Elliott Wave principles
- **Consensus detection**: Identifying when multiple interpretations agree on market direction
- **Invalidation tracking**: Providing specific price levels that would disprove each count

---

## Overview of ta4j's Elliott Wave Implementation

ta4j provides a comprehensive suite of indicators for Elliott Wave analysis, designed to work seamlessly with the rest of the ta4j ecosystem. The implementation follows Elliott Wave principles while providing flexibility for different trading styles and timeframes.

### Design Philosophy

The Elliott Wave indicators in ta4j are built on several key principles:

1. **Swing-Based Foundation**: All Elliott Wave analysis starts with swing detection—identifying alternating pivot highs and lows in price action.
2. **Modular Architecture**: Components are designed to work independently or together, allowing you to build custom analysis workflows.
3. **Scenario-Aware**: Rather than outputting a single "correct" wave count, the system generates multiple ranked alternatives with confidence scores.
4. **Validation-Driven**: Wave identification includes validation against Elliott Wave rules and Fibonacci relationships.
5. **Degree-Aware**: The system supports multiple wave degrees, allowing analysis across different timeframes.
6. **Resilient to Edge Cases**: Indicators gracefully handle insufficient data, returning `NaN` values rather than throwing exceptions.

### Component Hierarchy

The Elliott Wave system in ta4j follows a layered architecture:

```
BarSeries
    ↓
Swing Detection (Fractal/ZigZag)
    ↓
ElliottSwingIndicator (alternating swings)
    ↓
┌─────────────────────────────────────────────────────────┐
│  Deterministic Analysis Layer                           │
├─────────────────────────────────────────────────────────┤
│ • ElliottPhaseIndicator      (single phase output)      │
│ • ElliottRatioIndicator      (Fibonacci ratios)         │
│ • ElliottWaveCountIndicator  (swing counting)           │
│ • ElliottConfluenceIndicator (signal aggregation)       │
│ • ElliottChannelIndicator    (price channels)           │
│ • ElliottInvalidationIndicator (boolean invalidation)   │
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────┐
│  Scenario-Based Analysis Layer                          │
├─────────────────────────────────────────────────────────┤
│ • ElliottScenarioIndicator   (ranked alternatives)      │
│ • ElliottConfidenceScorer    (confidence calculation)   │
│ • ElliottScenarioGenerator   (scenario exploration)     │
│ • ElliottProjectionIndicator (Fibonacci targets)        │
│ • ElliottInvalidationLevelIndicator (price levels)      │
└─────────────────────────────────────────────────────────┘
```

### When to Use Each Layer

**Use the Deterministic Analysis Layer when:**
- You need a single, definitive wave count for automated trading rules
- Simplicity is preferred over nuance
- You're building indicators that feed into other calculations

**Use the Scenario-Based Analysis Layer when:**
- You want to understand the range of plausible interpretations
- You need confidence metrics for risk management
- You want to track multiple wave counts simultaneously
- You need explicit invalidation price levels for stop placement

---

## Core Components

### Data Model Records

#### ElliottSwing

Immutable representation of a single swing between two pivots:

```java
ElliottSwing swing = swings.get(0);
int startBar = swing.fromIndex();       // Bar index where swing starts
int endBar = swing.toIndex();           // Bar index where swing ends
Num startPrice = swing.fromPrice();     // Price at swing start
Num endPrice = swing.toPrice();         // Price at swing end
ElliottDegree degree = swing.degree();  // Wave degree (MINOR, INTERMEDIATE, etc.)

boolean rising = swing.isRising();      // true if toPrice >= fromPrice
Num amplitude = swing.amplitude();      // Absolute price displacement
int barCount = swing.length();          // Number of bars covered
```

#### ElliottSwingMetadata

Utility class providing a validated snapshot of swing statistics:

```java
List<ElliottSwing> swings = swingIndicator.getValue(index);
ElliottSwingMetadata metadata = ElliottSwingMetadata.of(swings, series.numFactory());

// Check validity
if (metadata.isValid()) {
    // Access swing statistics
    int count = metadata.size();
    Num highest = metadata.highestPrice();  // Highest price across all swings
    Num lowest = metadata.lowestPrice();    // Lowest price across all swings
    
    // Access swing subsets
    List<ElliottSwing> first5 = metadata.leading(5);      // First 5 swings
    List<ElliottSwing> last3 = metadata.trailing(3);      // Last 3 swings
    List<ElliottSwing> middle = metadata.subList(2, 5);   // Swings 2-4
    
    // Access individual swings
    ElliottSwing first = metadata.swing(0);
}
```

`ElliottSwingMetadata` validates that all swings contain valid (non-null, non-NaN) prices and provides convenient methods for accessing swing subsets and statistics.

#### ElliottPhase

Enumeration of wave phases with helper methods:

```java
ElliottPhase phase = ElliottPhase.WAVE3;

phase.isImpulse();          // true for WAVE1-WAVE5
phase.isCorrective();       // true for CORRECTIVE_A/B/C
phase.completesStructure(); // true for WAVE5 and CORRECTIVE_C
phase.impulseIndex();       // 1-5 for impulse waves, -1 otherwise
phase.correctiveIndex();    // 1-3 for corrective waves, -1 otherwise
```

#### ElliottRatio

Captures Fibonacci-style ratios between swings:

```java
ElliottRatio ratio = ratioIndicator.getValue(index);

if (ratio.isValid()) {
    Num value = ratio.value();     // The calculated ratio (e.g., 0.618)
    RatioType type = ratio.type(); // RETRACEMENT, EXTENSION, or NONE
}
```

#### ElliottChannel

Projected price channel with support/resistance boundaries:

```java
ElliottChannel channel = channelIndicator.getValue(index);

if (channel.isValid()) {
    Num upper = channel.upper();   // Resistance boundary
    Num lower = channel.lower();   // Support boundary
    Num mid = channel.median();    // Channel midline
    Num width = channel.width();   // Channel width
    
    // Check if price is within channel (with optional tolerance)
    boolean inChannel = channel.contains(price, tolerance);
}
```

### Core Indicators

#### ElliottSwingIndicator

The foundation of all Elliott Wave analysis. Detects alternating swing highs and lows:

```java
// Fractal-based detection (fixed window)
ElliottSwingIndicator swings = new ElliottSwingIndicator(series, 5, ElliottDegree.INTERMEDIATE);

// ZigZag-based detection (volatility-adaptive)
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(series, ElliottDegree.INTERMEDIATE);

// Get swings up to current bar
List<ElliottSwing> swingList = swings.getValue(index);
```

#### ElliottPhaseIndicator

Tracks the current wave phase by analyzing swing patterns:

```java
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swingIndicator);

ElliottPhase currentPhase = phase.getValue(index);

// Check structure confirmation
if (phase.isImpulseConfirmed(index)) {
    List<ElliottSwing> impulseSwings = phase.impulseSwings(index);
}

if (phase.isCorrectiveConfirmed(index)) {
    List<ElliottSwing> correctiveSwings = phase.correctiveSwings(index);
}
```

#### ElliottRatioIndicator

Calculates Fibonacci ratios between consecutive swings:

```java
ElliottRatioIndicator ratios = new ElliottRatioIndicator(swingIndicator);

ElliottRatio ratio = ratios.getValue(index);

// Check proximity to key Fibonacci levels
Num target = series.numFactory().numOf(0.618);
Num tolerance = series.numFactory().numOf(0.02);
if (ratios.isNearLevel(index, target, tolerance)) {
    // Near golden ratio retracement
}
```

#### ElliottChannelIndicator

Projects price channels based on recent swing structure:

```java
ElliottChannelIndicator channels = new ElliottChannelIndicator(swingIndicator);
ElliottChannel channel = channels.getValue(index);
```

#### ElliottConfluenceIndicator

Aggregates multiple Elliott Wave signals into a confluence score:

```java
ElliottConfluenceIndicator confluence = new ElliottConfluenceIndicator(
    priceIndicator, ratioIndicator, channelIndicator);

Num score = confluence.getValue(index);  // Score from 0 to 5

// Check if minimum confluence threshold is met
if (confluence.isConfluent(index)) {
    // Multiple indicators align
}
```

---

## Getting Started

### Example Classes

ta4j provides several example classes that demonstrate Elliott Wave analysis with real market data:

#### ElliottWaveAnalysis

The main example class that demonstrates comprehensive Elliott Wave analysis with chart visualization. It can be used in two ways:

**Command-line usage:**
```bash
# Load default dataset (ossified BTC-USD data)
java ElliottWaveAnalysis

# Load from external data source (4-6 arguments)
java ElliottWaveAnalysis [dataSource] [ticker] [barDuration] [startEpoch] [endEpoch]
java ElliottWaveAnalysis [dataSource] [ticker] [barDuration] [degree] [startEpoch] [endEpoch]
```

**Arguments:**
- `dataSource`: "YahooFinance" or "Coinbase" (case-insensitive)
- `ticker`: Symbol (e.g., "BTC-USD", "AAPL", "^GSPC")
- `barDuration`: ISO-8601 duration (e.g., "PT1D" for daily, "PT4H" for 4-hour, "PT5M" for 5-minute)
- `degree`: Elliott degree (optional; if omitted, auto-selected based on bar duration and count)
- `startEpoch`: Start time as Unix epoch seconds
- `endEpoch`: End time as Unix epoch seconds (optional, defaults to now)

**Programmatic usage:**
```java
BarSeries series = // ... load your bar series
ElliottWaveAnalysis analysis = new ElliottWaveAnalysis();
analysis.analyze(series, ElliottDegree.PRIMARY, 0.25);
```

The `analyze()` method performs complete Elliott Wave analysis including:
- Swing detection and wave counting
- Phase identification (impulse and corrective waves)
- Fibonacci ratio validation
- Channel projections
- Scenario-based analysis with confidence scoring
- Chart visualization with wave pivot labels

Charts are saved to `temp/charts/` and displayed if running in a non-headless environment.

#### Asset-Specific Examples

For quick analysis of specific assets, use the dedicated example classes:

**BTCUSDElliottWaveAnalysis** - Bitcoin (BTC-USD) analysis using Coinbase data:
```bash
java BTCUSDElliottWaveAnalysis
```
Loads 365 days of daily Bitcoin data from Coinbase and performs analysis using the PRIMARY degree.

**ETHUSDElliottWaveAnalysis** - Ethereum (ETH-USD) analysis using Coinbase data:
```bash
java ETHUSDElliottWaveAnalysis
```
Loads daily Ethereum data from Coinbase starting from a specific timestamp.

**SP500ElliottWaveAnalysis** - S&P 500 Index (^GSPC) analysis using Yahoo Finance data:
```bash
java SP500ElliottWaveAnalysis
```
Loads 365 days of daily S&P 500 index data from Yahoo Finance with auto-selected degree.

These example classes demonstrate simple usage patterns and can be modified to analyze different time periods or use different degrees.

### Using ElliottWaveFacade (Recommended)

The simplest way to get started is with `ElliottWaveFacade`, which creates and coordinates all Elliott Wave indicators with a shared swing source:

```java
BarSeries series = // your bar series (minimum ~60 bars recommended)

// Create a complete Elliott Wave analysis facade
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);

int index = series.getEndIndex();

// Deterministic analysis
ElliottPhase phase = facade.phase().getValue(index);
ElliottRatio ratio = facade.ratio().getValue(index);
ElliottChannel channel = facade.channel().getValue(index);
boolean confluent = facade.confluence().isConfluent(index);

// Wave counting
int waveCount = facade.waveCount().getValue(index);              // All swings
int filteredCount = facade.filteredWaveCount().getValue(index);  // Filtered (if compressor configured)

// Scenario-based analysis
Optional<ElliottScenario> baseCase = facade.primaryScenario(index);
List<ElliottScenario> alternatives = facade.alternativeScenarios(index);
String summary = facade.scenarioSummary(index);  // Human-readable summary

// Price projections and invalidation
Num projection = facade.projection().getValue(index);
Num invalidationPrice = facade.invalidationLevel().getValue(index);

// Consensus and confidence
boolean hasConsensus = facade.hasScenarioConsensus(index);
ElliottPhase consensusPhase = facade.scenarioConsensus(index);
Num confidence = facade.confidenceForPhase(index, ElliottPhase.WAVE3);
```

### Factory Methods

`ElliottWaveFacade` provides several factory methods for different swing detection approaches:

```java
// Fractal-based with symmetric window (5 bars before and after pivot)
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);

// Fractal-based with asymmetric window
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 3, 5, ElliottDegree.INTERMEDIATE);

// ZigZag-based with ATR(14) reversal threshold
ElliottWaveFacade facade = ElliottWaveFacade.zigZag(series, ElliottDegree.INTERMEDIATE);

// From custom swing indicator
ElliottWaveFacade facade = ElliottWaveFacade.from(customSwingIndicator, closePriceIndicator);
```

All factory methods support optional custom configuration:

```java
// Custom Fibonacci tolerance and swing compressor
Num customTolerance = series.numFactory().numOf(0.25);
ElliottSwingCompressor compressor = new ElliottSwingCompressor(series); // 1% of price, 2 bars minimum

// Fractal with custom configuration
ElliottWaveFacade facade = ElliottWaveFacade.fractal(
    series, 5, ElliottDegree.INTERMEDIATE, 
    Optional.of(customTolerance), 
    Optional.of(compressor)
);

// ZigZag with custom configuration
ElliottWaveFacade facade = ElliottWaveFacade.zigZag(
    series, ElliottDegree.INTERMEDIATE,
    Optional.of(customTolerance),
    Optional.of(compressor)
);

// From custom swing indicator with configuration
ElliottWaveFacade facade = ElliottWaveFacade.from(
    customSwingIndicator, 
    closePriceIndicator,
    Optional.of(customTolerance),
    Optional.of(compressor)
);
```

When a custom Fibonacci tolerance is provided, the phase indicator uses a custom `ElliottFibonacciValidator` with that tolerance instead of the default (0.05). When a compressor is provided, `filteredWaveCount()` uses it to filter swings before counting; otherwise, `filteredWaveCount()` returns the same as `waveCount()`.

---

## Scenario-Based Analysis

### Understanding ElliottScenarioSet

The `ElliottScenarioIndicator` returns an `ElliottScenarioSet` for each bar, containing all plausible wave interpretations ranked by confidence:

```java
ElliottScenarioIndicator scenarios = facade.scenarios();
ElliottScenarioSet scenarioSet = scenarios.getValue(index);

// Check if scenarios exist
if (scenarioSet.isEmpty()) {
    // Not enough data for analysis
    return;
}

// Get the base case (highest confidence) scenario
Optional<ElliottScenario> baseCase = scenarioSet.base();

// Get all alternatives (excluding base case)
List<ElliottScenario> alternatives = scenarioSet.alternatives();

// Get all scenarios including base case
List<ElliottScenario> all = scenarioSet.all();

// Get scenario counts
int total = scenarioSet.size();
int highConfidence = scenarioSet.highConfidenceCount();  // >= 0.7 confidence
int lowConfidence = scenarioSet.lowConfidenceCount();    // < 0.3 confidence
```

### Filtering Scenarios

You can filter scenarios by phase or pattern type:

```java
ElliottScenarioSet scenarioSet = scenarios.getValue(index);

// Get only impulse scenarios
ElliottScenarioSet impulseScenarios = scenarioSet.byType(ScenarioType.IMPULSE);

// Get scenarios predicting a specific phase
ElliottScenarioSet wave3Scenarios = scenarioSet.byPhase(ElliottPhase.WAVE3);

// Get scenarios that remain valid at a given price
Num testPrice = series.numFactory().numOf(100.0);
ElliottScenarioSet validScenarios = scenarioSet.validAt(testPrice);

// Get scenarios that would be invalidated at a given price
List<ElliottScenario> invalidated = scenarioSet.invalidatedBy(testPrice);
```

### Consensus Detection

Check whether multiple interpretations agree:

```java
ElliottScenarioSet scenarioSet = scenarios.getValue(index);

// Get consensus phase (agreed upon by all high-confidence scenarios)
ElliottPhase consensus = scenarioSet.consensus();
if (consensus != ElliottPhase.NONE) {
    System.out.println("All high-confidence scenarios agree: " + consensus);
}

// Check for strong consensus
if (scenarioSet.hasStrongConsensus()) {
    // Either single high-confidence scenario or large confidence spread
    System.out.println("High conviction in base case scenario");
}

// Calculate confidence spread between base case and secondary
double spread = scenarioSet.confidenceSpread();
if (spread > 0.3) {
    System.out.println("Base case scenario is significantly more confident");
}
```

### The ElliottScenario Record

Each scenario contains comprehensive information about a wave interpretation:

```java
ElliottScenario scenario = baseCase.get();

// Identity and classification
String id = scenario.id();                    // Unique identifier
ElliottPhase phase = scenario.currentPhase(); // Current wave (WAVE3, CORRECTIVE_B, etc.)
ScenarioType type = scenario.type();          // IMPULSE, CORRECTIVE_ZIGZAG, etc.
ElliottDegree degree = scenario.degree();     // Wave degree

// Structure information
List<ElliottSwing> swings = scenario.swings(); // The swings backing this interpretation
int waveCount = scenario.waveCount();          // Number of waves identified
int startIndex = scenario.startIndex();        // Bar where this structure begins

// Confidence metrics
ElliottConfidence confidence = scenario.confidence();
Num score = scenario.confidenceScore();        // Aggregate score (0.0 - 1.0)
boolean highConf = scenario.isHighConfidence(); // >= 0.7
boolean lowConf = scenario.isLowConfidence();   // < 0.3

// Trading information
Num invalidation = scenario.invalidationPrice(); // Price that invalidates this count
Num target = scenario.primaryTarget();           // Primary Fibonacci target
List<Num> targets = scenario.fibonacciTargets(); // All calculated targets

// Direction
boolean hasDirection = scenario.hasKnownDirection(); // Check if direction is known
if (hasDirection) {
    boolean bullish = scenario.isBullish();        // Based on first wave direction
    boolean bearish = scenario.isBearish();
}

// Check if price would invalidate this scenario
if (scenario.isInvalidatedBy(currentPrice)) {
    System.out.println("This wave count is no longer valid");
}

// Check if current phase expects completion soon
if (scenario.expectsCompletion()) {
    System.out.println("Wave structure approaching completion");
}
```
<｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
read_file

### Scenario Types

The `ScenarioType` enum classifies the pattern structure:

| Type | Description | Expected Waves |
|------|-------------|----------------|
| `IMPULSE` | Five-wave motive structure (1-2-3-4-5) | 5 |
| `CORRECTIVE_ZIGZAG` | Sharp A-B-C where C exceeds A | 3 |
| `CORRECTIVE_FLAT` | A-B-C where B retraces most of A | 3 |
| `CORRECTIVE_TRIANGLE` | Five-wave contracting/expanding pattern (A-B-C-D-E) | 5 |
| `CORRECTIVE_COMPLEX` | Double/triple combinations | Varies |
| `UNKNOWN` | Pattern could not be determined | 0 |

```java
ScenarioType type = scenario.type();

if (type.isImpulse()) {
    // Trading with the trend
} else if (type.isCorrective()) {
    // Counter-trend or consolidation
}

int expected = type.expectedWaveCount(); // 5 for impulse, 3 for zigzag/flat
```

---

## Confidence Scoring

### How Confidence is Calculated

The `ElliottConfidenceScorer` evaluates each scenario against five weighted factors:

| Factor | Weight | Description |
|--------|--------|-------------|
| Fibonacci Proximity | 35% | How closely swing ratios match canonical Fibonacci levels (0.382, 0.618, 1.618, etc.) |
| Time Proportions | 20% | Whether wave durations follow expected relationships (e.g., wave 3 typically longest) |
| Alternation Quality | 15% | Degree of pattern/depth alternation between waves 2 and 4 |
| Channel Adherence | 15% | Whether price stays within projected channel boundaries |
| Structure Completeness | 15% | How many expected waves are confirmed |

### The ElliottConfidence Record

Each scenario includes detailed confidence breakdown:

```java
ElliottConfidence confidence = scenario.confidence();

// Overall score (weighted combination)
Num overall = confidence.overall();
double percentage = confidence.asPercentage();  // 0-100

// Individual factor scores (each 0.0 - 1.0)
Num fibScore = confidence.fibonacciScore();       // Fibonacci alignment
Num timeScore = confidence.timeProportionScore(); // Time relationships
Num altScore = confidence.alternationScore();     // Wave 2/4 alternation
Num chanScore = confidence.channelScore();        // Channel adherence
Num compScore = confidence.completenessScore();   // Structure completeness

// Primary reason for the confidence level
String reason = confidence.primaryReason();  // e.g., "Strong Fibonacci conformance"

// Identify the weakest factor
String weakness = confidence.weakestFactor(); // e.g., "Wave alternation"

// Threshold checks
boolean valid = confidence.isValid();              // Non-null and not NaN
boolean high = confidence.isHighConfidence();      // >= 0.7
boolean low = confidence.isLowConfidence();        // < 0.3
boolean meetsThreshold = confidence.isAboveThreshold(0.5); // Custom threshold
```

### Interpreting Confidence Levels

| Confidence | Interpretation | Recommended Action |
|------------|----------------|-------------------|
| 0.7 - 1.0 | High confidence | Trade with conviction; use tighter stops |
| 0.5 - 0.7 | Moderate confidence | Wait for confirmation or reduce position size |
| 0.3 - 0.5 | Low confidence | Consider alternative scenarios; wide stops |
| 0.0 - 0.3 | Very low confidence | Avoid trading; wave structure is unclear |

### Custom Confidence Weights

You can create a scorer with custom weights to emphasize factors important to your strategy:

```java
// Create custom scorer with different emphasis
ElliottConfidenceScorer customScorer = new ElliottConfidenceScorer(
    series.numFactory(),
    0.50,  // fibonacciWeight - emphasize Fibonacci alignment
    0.15,  // timeWeight
    0.10,  // alternationWeight
    0.15,  // channelWeight
    0.10   // completenessWeight
);

// Use custom scorer with generator
ElliottScenarioGenerator generator = new ElliottScenarioGenerator(
    series.numFactory(), 
    0.15,  // minConfidence threshold
    5      // maxScenarios to return
);
```

---

## Working with Alternative Wave Counts

### Why Multiple Counts Matter

In practice, you'll often encounter situations where price action supports multiple valid interpretations. For example:

- **Impulse vs. Correction**: Is this sharp move wave 3 of an impulse, or wave C of a correction?
- **Degree Uncertainty**: Is this a minor wave 4 or an intermediate wave 2?
- **Pattern Classification**: Is this a zigzag or a flat correction?

The scenario-based system helps you:
1. See all plausible interpretations at once
2. Understand which interpretation is most likely (base case)
3. Plan for alternative outcomes
4. Know when the market will resolve the ambiguity (via invalidation levels)

### Practical Example: Handling Ambiguity

```java
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);
int index = series.getEndIndex();

ElliottScenarioSet scenarioSet = facade.scenarios().getValue(index);

System.out.println(scenarioSet.summary());
// Example output: "3 scenario(s): Base case=WAVE3 (72.5%), 2 alternative(s), consensus=WAVE3"

Optional<ElliottScenario> baseCase = scenarioSet.base();
if (baseCase.isPresent()) {
    ElliottScenario bc = baseCase.get();
    
    System.out.println("Base case interpretation:");
    System.out.println("  Phase: " + bc.currentPhase());
    System.out.println("  Type: " + bc.type());
    System.out.println("  Confidence: " + String.format("%.1f%%", bc.confidence().asPercentage()));
    System.out.println("  Invalidation: " + bc.invalidationPrice());
    System.out.println("  Primary target: " + bc.primaryTarget());
}

// Consider alternatives
List<ElliottScenario> alternatives = scenarioSet.alternatives();
if (!alternatives.isEmpty()) {
    System.out.println("\nAlternative interpretations:");
    for (ElliottScenario alt : alternatives) {
        System.out.println("  " + alt.type() + " " + alt.currentPhase() + 
            " (" + String.format("%.1f%%", alt.confidence().asPercentage()) + ")");
    }
}

// Check consensus
if (scenarioSet.hasStrongConsensus()) {
    System.out.println("\nStrong consensus - high conviction trade opportunity");
} else if (scenarioSet.consensus() != ElliottPhase.NONE) {
    System.out.println("\nModerate consensus on phase: " + scenarioSet.consensus());
} else {
    System.out.println("\nNo consensus - market structure is ambiguous");
}
```

### Monitoring Alternative Scenarios Over Time

Track how scenarios evolve as new bars arrive:

```java
// Track the evolution of scenarios
ElliottScenarioIndicator scenarios = facade.scenarios();

for (int i = 0; i < series.getBarCount(); i++) {
    ElliottScenarioSet set = scenarios.getValue(i);
    
    Optional<ElliottScenario> baseCase = set.base();
    if (baseCase.isPresent()) {
        ElliottScenario bc = baseCase.get();
        
        System.out.println(String.format("Bar %d: %s (%.1f%%) - %d alternatives",
            i,
            bc.currentPhase(),
            bc.confidence().asPercentage(),
            set.alternatives().size()));
    }
}
```

---

## Price Projections and Targets

### Using ElliottProjectionIndicator

The projection indicator calculates Fibonacci-based price targets for the base case scenario:

```java
ElliottProjectionIndicator projection = facade.projection();

// Get base case target for current bar
Num baseCaseTarget = projection.getValue(index);
if (Num.isValid(baseCaseTarget)) {
    System.out.println("Base case target: " + baseCaseTarget);
}

// Get all Fibonacci targets for the base case scenario
List<Num> allTargets = projection.allTargets(index);
for (Num target : allTargets) {
    System.out.println("  Target: " + target);
}

// Calculate targets for a specific swing sequence and phase
ElliottScenario scenario = scenarioSet.base().get();
List<ElliottSwing> swings = scenario.swings();
ElliottPhase phase = scenario.currentPhase();
List<Num> customTargets = projection.calculateTargets(swings, phase);
```

### Understanding Projection Logic

Targets are calculated based on the current wave phase:

**Impulse Wave Projections:**

| Current Phase | Target Wave | Calculation |
|---------------|-------------|-------------|
| WAVE2 | Wave 3 | Wave 2 end + (Wave 1 amplitude × 1.0/1.618/2.618) |
| WAVE4 | Wave 5 | Wave 4 end + (Wave 1 amplitude × 0.618/1.0/1.618) |

**Corrective Wave Projections:**

| Current Phase | Target Wave | Calculation |
|---------------|-------------|-------------|
| CORRECTIVE_B | Wave C | Wave B end ± (Wave A amplitude × 0.618/1.0/1.618) |

### Calculating Custom Projections

You can also calculate projections for any swing sequence and phase:

```java
ElliottProjectionIndicator projection = facade.projection();

// Get swings from a specific scenario
ElliottScenario scenario = scenarioSet.base().get();
List<ElliottSwing> swings = scenario.swings();
ElliottPhase phase = scenario.currentPhase();

// Calculate targets for this specific structure
List<Num> targets = projection.calculateTargets(swings, phase);
```

---

## Invalidation Levels

### The Importance of Invalidation

Every Elliott Wave count has specific price levels that would invalidate it. Knowing these levels is crucial for:

- **Stop placement**: Setting stops just beyond invalidation levels
- **Scenario transition**: Knowing when to switch from primary to alternative count
- **Risk management**: Understanding exactly where the analysis is wrong

### Using ElliottInvalidationLevelIndicator

```java
ElliottInvalidationLevelIndicator invalidation = facade.invalidationLevel();

// Get invalidation price for base case scenario
Num invalidationPrice = invalidation.getValue(index);

if (Num.isValid(invalidationPrice)) {
    System.out.println("Base case invalidation at: " + invalidationPrice);
}
```

### Invalidation Modes

The indicator supports three modes for different risk tolerances:

```java
import org.ta4j.core.indicators.elliott.ElliottInvalidationLevelIndicator.InvalidationMode;

// PRIMARY mode (default): Use base case scenario's invalidation
ElliottInvalidationLevelIndicator primary = 
    new ElliottInvalidationLevelIndicator(scenarioIndicator, InvalidationMode.PRIMARY);

// CONSERVATIVE mode: Use tightest invalidation across high-confidence scenarios
// (First scenario invalidated = consider exiting)
ElliottInvalidationLevelIndicator conservative = 
    new ElliottInvalidationLevelIndicator(scenarioIndicator, InvalidationMode.CONSERVATIVE);

// AGGRESSIVE mode: Use widest invalidation across all scenarios
// (All scenarios must be invalidated before exiting)
ElliottInvalidationLevelIndicator aggressive = 
    new ElliottInvalidationLevelIndicator(scenarioIndicator, InvalidationMode.AGGRESSIVE);
```

| Mode | Description | Use Case |
|------|-------------|----------|
| `PRIMARY` | Invalidation level from the highest-confidence scenario | Standard trading with single scenario focus |
| `CONSERVATIVE` | Tightest stop across high-confidence scenarios | Protective trading when multiple valid counts exist |
| `AGGRESSIVE` | Widest stop (all scenarios must fail) | Position trades where you want maximum room |

### Checking Invalidation Status

```java
ElliottInvalidationLevelIndicator invalidation = facade.invalidationLevel();
Num currentPrice = series.getBar(index).getClosePrice();

// Check if current price invalidates the base case scenario
boolean isInvalid = invalidation.isInvalidated(index, currentPrice);

// Get distance from current price to invalidation
Num distance = invalidation.distanceToInvalidation(index, currentPrice);
// Positive = still valid, Negative = invalidated
```

### Boolean Invalidation Indicator

For simple true/false invalidation checking without price levels:

```java
ElliottInvalidationIndicator boolInvalidation = facade.invalidation();

if (boolInvalidation.getValue(index)) {
    System.out.println("Current wave structure is invalidated");
    // Reassess wave count
}
```

The `ElliottInvalidationIndicator` checks if the current wave structure violates Elliott Wave rules (e.g., Wave 2 retracing beyond Wave 1 start, Wave 4 overlapping with Wave 1, etc.).

---

## Intermediate Usage Patterns

### Multi-Degree Analysis

Analyze multiple timeframes simultaneously:

```java
// Primary trend (larger degree)
ElliottWaveFacade primaryFacade = 
    ElliottWaveFacade.fractal(series, 10, ElliottDegree.PRIMARY);

// Intermediate trend (smaller degree)
ElliottWaveFacade intermediateFacade = 
    ElliottWaveFacade.fractal(series, 3, ElliottDegree.INTERMEDIATE);

int index = series.getEndIndex();

// Get interpretations at both degrees
Optional<ElliottScenario> primaryBaseCase = primaryFacade.primaryScenario(index);
Optional<ElliottScenario> intermediateBaseCase = intermediateFacade.primaryScenario(index);

// Trade when degrees align
if (primaryBaseCase.isPresent() && intermediateBaseCase.isPresent()) {
    ElliottScenario primaryBase = primaryBaseCase.get();
    ElliottScenario intermediateBase = intermediateBaseCase.get();
    
    if (primaryBase.isBullish() && intermediateBase.currentPhase() == ElliottPhase.WAVE3) {
        // Strong bullish alignment: wave 3 at intermediate degree within bullish base case
        System.out.println("Aligned bullish setup");
    }
}
```

### Custom Swing Detection

Use custom price sources or swing detectors:

```java
// Use close prices instead of high/low
ClosePriceIndicator close = new ClosePriceIndicator(series);
ElliottSwingIndicator swings = new ElliottSwingIndicator(close, 3, 3, ElliottDegree.INTERMEDIATE);

// Create facade from custom swing indicator
ElliottWaveFacade facade = ElliottWaveFacade.from(swings, close);

// Or with custom configuration
Num fibTolerance = series.numFactory().numOf(0.25);
ElliottSwingCompressor compressor = new ElliottSwingCompressor(series);
ElliottWaveFacade facade = ElliottWaveFacade.from(
    swings, 
    close, 
    Optional.of(fibTolerance), 
    Optional.of(compressor)
);
```

### Swing Compression

Filter out small swings before analysis using `ElliottSwingCompressor`:

```java
ElliottSwingIndicator rawSwings = new ElliottSwingIndicator(series, 3, ElliottDegree.MINOR);

// Option 1: No filtering (all swings retained)
ElliottSwingCompressor noFilter = new ElliottSwingCompressor();

// Option 2: Absolute thresholds (explicit price and bar length)
Num minimumAmplitude = series.numFactory().numOf(5.0);  // Minimum price move
int minimumLength = 2;  // Minimum bars between pivots
ElliottSwingCompressor compressor = new ElliottSwingCompressor(minimumAmplitude, minimumLength);

// Option 3: Relative price-based (percentage of current price)
ClosePriceIndicator closePrice = new ClosePriceIndicator(series);
ElliottSwingCompressor relativeCompressor = new ElliottSwingCompressor(
    closePrice, 
    0.01,  // 1% of current price
    2      // Minimum 2 bars
);

// Option 4: Convenience constructor (1% of current price, 2 bars minimum)
ElliottSwingCompressor defaultCompressor = new ElliottSwingCompressor(series);

// Use compressor with wave count indicator
ElliottWaveCountIndicator counter = new ElliottWaveCountIndicator(rawSwings, compressor);

// Get filtered swings
List<ElliottSwing> compressed = compressor.compress(rawSwings.getValue(index));
```

The compressor filters swings that don't meet both the minimum amplitude and minimum bar length thresholds. This is useful for removing noise and focusing on significant price movements.

### Wave Degree Navigation

Navigate between wave degrees programmatically:

```java
ElliottDegree degree = ElliottDegree.INTERMEDIATE;

ElliottDegree higher = degree.higherDegree();  // Returns PRIMARY
ElliottDegree lower = degree.lowerDegree();    // Returns MINOR

// Check degree relationships
if (degree.isHigherOrEqual(ElliottDegree.MINOR)) {
    // This degree is significant enough for swing trading
}

// Iterate through degrees
for (ElliottDegree d : ElliottDegree.values()) {
    System.out.println(d.name());
}
```

### Auto-Selecting Wave Degrees

The `ElliottDegree` class provides recommendations based on bar duration and history length:

```java
Duration barDuration = Duration.ofDays(1);  // Daily bars
int barCount = 365;  // One year of data

// Get recommended degrees (ordered by best fit)
List<ElliottDegree> recommendations = ElliottDegree.getRecommendedDegrees(barDuration, barCount);

// Use the first recommendation (best fit)
ElliottDegree selected = recommendations.get(0);

// Or iterate through all recommendations
for (ElliottDegree degree : recommendations) {
    System.out.println("Recommended: " + degree);
}
```

The recommendation system considers:
- **Bar duration**: Filters out degrees that are too fine for the timeframe
- **History length**: Matches total history (duration × count) to typical ranges for each degree
- **Score ranking**: Returns degrees ordered by how well they fit the available data

**Typical ranges (rule of thumb):**
- Daily bars: PRIMARY through MINUTE degrees
- Weekly bars: CYCLE, PRIMARY, INTERMEDIATE degrees
- Hourly bars: INTERMEDIATE through MINUETTE degrees
- 5-15 minute bars: MINOR through SUB_MINUETTE degrees

The `ElliottWaveAnalysis` class automatically uses degree recommendations when no explicit degree is provided via command-line arguments.

---

## Advanced Topics

### Scenario Generator Configuration

Fine-tune how scenarios are generated:

```java
// Create generator with custom thresholds
ElliottScenarioGenerator generator = new ElliottScenarioGenerator(
    series.numFactory(),
    0.10,  // minConfidence: lower threshold keeps more scenarios
    10     // maxScenarios: maximum to return
);

// Create scenario indicator with custom generator
ElliottScenarioIndicator scenarios = new ElliottScenarioIndicator(
    swingIndicator, channelIndicator, generator);
```

### Working with Scenario History

Track scenario evolution for a trading journal:

```java
StringBuilder journal = new StringBuilder();

for (int i = 50; i < series.getBarCount(); i++) {
    ElliottScenarioSet set = facade.scenarios().getValue(i);
    
    journal.append(String.format("Bar %d: %s%n", i, set.summary()));
    
    // Track scenario changes
    if (i > 50) {
        ElliottScenarioSet previous = facade.scenarios().getValue(i - 1);
        Optional<ElliottScenario> prevBaseCase = previous.base();
        Optional<ElliottScenario> currBaseCase = set.base();
        
        if (prevBaseCase.isPresent() && currBaseCase.isPresent()) {
            if (prevBaseCase.get().currentPhase() != currBaseCase.get().currentPhase()) {
                journal.append("  ** Phase change detected **\n");
            }
        }
    }
}
```

### Combining with Other Indicators

Elliott Wave analysis works well with momentum and volume indicators:

```java
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);
RSIIndicator rsi = new RSIIndicator(new ClosePriceIndicator(series), 14);

int index = series.getEndIndex();
Optional<ElliottScenario> baseCase = facade.primaryScenario(index);
Num rsiValue = rsi.getValue(index);

if (baseCase.isPresent()) {
    ElliottScenario scenario = baseCase.get();
    
    // Wave 2 + oversold RSI = potential wave 3 entry
    if (scenario.currentPhase() == ElliottPhase.WAVE2 
            && rsiValue.isLessThan(series.numFactory().numOf(30))) {
        System.out.println("Wave 3 entry setup with RSI confirmation");
    }
    
    // Wave 5 + overbought RSI + bearish divergence = potential exit
    if (scenario.currentPhase() == ElliottPhase.WAVE5
            && rsiValue.isGreaterThan(series.numFactory().numOf(70))) {
        System.out.println("Potential wave 5 exhaustion");
    }
}
```

### Performance Considerations

All Elliott Wave indicators extend `CachedIndicator`, so values are cached after first calculation:

```java
// First call calculates and caches
ElliottScenarioSet set1 = scenarios.getValue(index);

// Second call returns cached value (no recalculation)
ElliottScenarioSet set2 = scenarios.getValue(index);

// Get unstable bar count (values before this index may not be reliable)
int unstable = scenarios.getCountOfUnstableBars();
```

---

## Best Practices

### Swing Detection Configuration

1. **Match Window Size to Timeframe**: 
   - Intraday: 3-5 bars
   - Daily: 5-10 bars
   - Weekly: 10-20 bars

2. **Consider Market Volatility**:
   - High volatility: Use ZigZag with ATR-based thresholds
   - Low volatility: Fractal windows work well

### Confidence Interpretation

1. **Don't Chase High Confidence**: A 90% confidence scenario isn't "right"—it just fits the current data well
2. **Watch for Confidence Decay**: If confidence drops bar-over-bar, the count may be becoming less valid
3. **Value Consensus Over Confidence**: When multiple scenarios agree on direction, that's often more actionable than a single high-confidence count

### Managing Multiple Counts

1. **Plan for Alternatives**: Before entering a trade, identify what price level would shift you to the alternative count
2. **Use Conservative Invalidation**: When uncertain, use the conservative invalidation mode
3. **Accept Ambiguity**: Some market conditions genuinely have multiple valid interpretations—don't force a single count

### Error Handling

Always check for valid data before using values:

```java
// Check Num values
Num price = indicator.getValue(index);
if (Num.isValid(price)) {
    // Safe to use
}

// Check Optional scenarios
Optional<ElliottScenario> baseCase = facade.primaryScenario(index);
if (baseCase.isPresent() && baseCase.get().isHighConfidence()) {
    // Safe to trade
}

// Check confidence validity
ElliottConfidence conf = scenario.confidence();
if (conf.isValid()) {
    // Safe to use confidence values
}

// Check scenario set
ElliottScenarioSet set = scenarios.getValue(index);
if (!set.isEmpty()) {
    // Safe to access scenarios
}
```

---

## Integration with Trading Strategies

### Basic Scenario-Aware Rule

```java
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);

// Enter long when high-confidence wave 3 begins
Rule entryRule = new Rule() {
    @Override
    public boolean isSatisfied(int index, TradingRecord tradingRecord) {
        Optional<ElliottScenario> baseCase = facade.primaryScenario(index);
        return baseCase.isPresent()
            && baseCase.get().currentPhase() == ElliottPhase.WAVE3
            && baseCase.get().isHighConfidence()
            && facade.hasScenarioConsensus(index);
    }
};

// Exit at wave 5 completion or invalidation
Rule exitRule = new Rule() {
    @Override
    public boolean isSatisfied(int index, TradingRecord tradingRecord) {
        Optional<ElliottScenario> baseCase = facade.primaryScenario(index);
        if (baseCase.isEmpty()) return true;  // Exit if no scenarios
        
        ElliottScenario scenario = baseCase.get();
        Num currentPrice = series.getBar(index).getClosePrice();
        
        // Exit conditions
        boolean wave5Complete = scenario.currentPhase() == ElliottPhase.WAVE5 
            && scenario.expectsCompletion();
        boolean invalidated = scenario.isInvalidatedBy(currentPrice);
        
        return wave5Complete || invalidated;
    }
};
```

Note: The `expectsCompletion()` method on `ElliottScenario` indicates whether the current phase is expected to complete soon (e.g., Wave 5 or Corrective C).

Strategy strategy = new BaseStrategy(entryRule, exitRule);
```

### Confidence-Based Position Sizing

```java
public double calculatePositionSize(ElliottScenario scenario, double baseSize) {
    ElliottConfidence conf = scenario.confidence();
    
    if (conf.isHighConfidence()) {
        return baseSize * 1.0;  // Full size
    } else if (conf.isAboveThreshold(0.5)) {
        return baseSize * 0.5;  // Half size
    } else {
        return baseSize * 0.25; // Quarter size or skip
    }
}
```

### Dynamic Stop Based on Invalidation

```java
public Num calculateStopLevel(ElliottScenarioSet scenarioSet, boolean conservative) {
    InvalidationMode mode = conservative 
        ? InvalidationMode.CONSERVATIVE 
        : InvalidationMode.PRIMARY;
    
    ElliottInvalidationLevelIndicator invalidation = 
        new ElliottInvalidationLevelIndicator(scenarioIndicator, mode);
    
    return invalidation.getValue(scenarioSet.barIndex());
}
```

### Multi-Scenario Trading Logic

```java
// Trade when primary and alternatives agree on direction
public boolean shouldEnterLong(int index) {
    ElliottScenarioSet set = facade.scenarios().getValue(index);
    
    // Require at least 2 scenarios
    if (set.size() < 2) return false;
    
    // Check if base case is bullish
    Optional<ElliottScenario> baseCase = set.base();
    if (baseCase.isEmpty() || !baseCase.get().isBullish()) return false;
    
    // Check if majority of alternatives also bullish
    List<ElliottScenario> alternatives = set.alternatives();
    long bullishAlternatives = alternatives.stream()
        .filter(ElliottScenario::isBullish)
        .count();
    
    double bullishRatio = (double)(bullishAlternatives + 1) / set.size();
    
    return bullishRatio >= 0.6; // 60% of scenarios are bullish
}
```

---

## Summary

ta4j's Elliott Wave indicators provide a sophisticated toolkit for wave-based technical analysis that acknowledges the inherent uncertainty in wave counting:

### Quick Start with Scenarios

```java
// Create facade
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);
int index = series.getEndIndex();

// Get base case interpretation with confidence
Optional<ElliottScenario> baseCase = facade.primaryScenario(index);
if (baseCase.isPresent()) {
    ElliottScenario bc = baseCase.get();
    System.out.println("Phase: " + p.currentPhase());
    System.out.println("Confidence: " + String.format("%.1f%%", p.confidence().asPercentage()));
    System.out.println("Invalidation: " + p.invalidationPrice());
    System.out.println("Target: " + p.primaryTarget());
}

// Check for consensus
if (facade.hasScenarioConsensus(index)) {
    System.out.println("Strong consensus: " + facade.scenarioConsensus(index));
}

// Get alternatives
List<ElliottScenario> alts = facade.alternativeScenarios(index);
System.out.println("Alternative counts: " + alts.size());
```

### Quick Start with Example Classes

For the fastest way to see Elliott Wave analysis in action, use the provided example classes:

```bash
# Analyze Bitcoin with default settings
java BTCUSDElliottWaveAnalysis

# Analyze Ethereum
java ETHUSDElliottWaveAnalysis

# Analyze S&P 500
java SP500ElliottWaveAnalysis

# Custom analysis with command-line arguments
java ElliottWaveAnalysis Coinbase BTC-USD PT1D PRIMARY 1686960000 1697040000
```

All examples generate charts with wave pivot labels, scenario analysis, and confidence scores. Charts are saved to `temp/charts/` and displayed if running in a non-headless environment.

### Key Takeaways

1. **Embrace Uncertainty**: Multiple valid wave counts are normal, not a problem
2. **Use Confidence Wisely**: High confidence means good fit to rules, not prediction accuracy
3. **Plan for Alternatives**: Know what would change your view before entering trades
4. **Set Invalidation Stops**: Use explicit invalidation levels for disciplined risk management
5. **Watch for Consensus**: When scenarios agree, conviction can be higher
6. **Leverage Examples**: Start with the provided example classes to understand usage patterns

The modular design allows you to build custom workflows that match your trading style, whether you prefer a single deterministic count or a full scenario-based approach with confidence weighting.
