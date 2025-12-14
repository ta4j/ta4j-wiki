# Elliott Wave Indicators

<<<<<<< HEAD
A comprehensive guide to using ta4j's Elliott Wave analysis tools, from basic concepts to advanced trading strategies.

## Table of Contents

1. [Introduction to Elliott Wave Theory](#introduction-to-elliott-wave-theory)
2. [Overview of ta4j's Elliott Wave Implementation](#overview-of-ta4js-elliott-wave-implementation)
3. [Core Components](#core-components)
4. [Getting Started](#getting-started)
5. [Intermediate Usage Patterns](#intermediate-usage-patterns)
6. [Advanced Topics](#advanced-topics)
7. [Best Practices](#best-practices)
8. [Integration with Trading Strategies](#integration-with-trading-strategies)

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

### Why Elliott Wave Analysis?

Elliott Wave analysis helps traders:
- Identify potential trend reversals and continuations
- Set price targets based on Fibonacci relationships
- Understand market structure and context
- Time entries and exits more precisely
- Combine with other technical indicators for confirmation

---

## Overview of ta4j's Elliott Wave Implementation

ta4j provides a comprehensive suite of indicators for Elliott Wave analysis, designed to work seamlessly with the rest of the ta4j ecosystem. The implementation follows Elliott Wave principles while providing flexibility for different trading styles and timeframes.

### Design Philosophy

The Elliott Wave indicators in ta4j are built on several key principles:

1. **Swing-Based Foundation**: All Elliott Wave analysis starts with swing detection—identifying alternating pivot highs and lows in price action.
2. **Modular Architecture**: Components are designed to work independently or together, allowing you to build custom analysis workflows.
3. **Validation-Driven**: Wave identification includes validation against Elliott Wave rules and Fibonacci relationships.
4. **Degree-Aware**: The system supports multiple wave degrees, allowing analysis across different timeframes.
5. **Resilient to Edge Cases**: Indicators gracefully handle insufficient data, returning `NaN` values rather than throwing exceptions.

### Component Hierarchy

The Elliott Wave system in ta4j follows a layered architecture:

```
BarSeries
    ↓
Swing Detection (Fractal/ZigZag)
    ↓
ElliottSwingIndicator (alternating swings)
    ↓
┌─────────────────────────────────────┐
│  Analysis Layer                     │
├─────────────────────────────────────┤
│ • ElliottPhaseIndicator             │
│ • ElliottRatioIndicator             │
│ • ElliottWaveCountIndicator         │
│ • ElliottConfluenceIndicator        │
│ • ElliottChannelIndicator           │
│ • ElliottInvalidationIndicator      │
└─────────────────────────────────────┘
```

### Integration with ta4j Ecosystem

Elliott Wave indicators integrate naturally with:
- **Swing Detection**: Built on ta4j's fractal and ZigZag swing indicators
- **Rules**: Elliott Wave phases and ratios can drive trading rules
- **Strategies**: Combine with other indicators for multi-factor strategies
- **Charting**: Visualize waves, ratios, and phases on price charts
- **Backtesting**: Test Elliott Wave-based strategies using ta4j's backtesting framework

---

## Core Components

### ElliottSwingIndicator

The foundation of all Elliott Wave analysis. This indicator detects alternating swing highs and lows, producing a sequence of `ElliottSwing` objects.

**Key Features:**
- Supports both fractal (window-based) and ZigZag (ATR-based) swing detection
- Automatically compresses consecutive pivots of the same type (retains most extreme)
- Associates each swing with a wave degree for multi-timeframe analysis
- Returns a list of swings up to the current bar index

**Common Use Cases:**
- Building the swing sequence for wave counting
- Accessing swing pivot points and amplitudes
- Filtering swings by degree or other criteria

### ElliottPhaseIndicator

Tracks the current Elliott Wave phase (WAVE1 through WAVE5, or CORRECTIVE_A through CORRECTIVE_C).

**Key Features:**
- Validates wave structure against Elliott Wave rules
- Checks Fibonacci relationships between waves
- Provides helper methods to access impulse and corrective segments
- Recursively processes swing history to identify complete cycles

**Wave Validation:**
- Wave 2 retracement validation
- Wave 3 extension requirements
- Wave 4 retracement and non-overlap rules
- Wave 5 projection targets
- Corrective wave A-B-C structure

### ElliottRatioIndicator

Calculates Fibonacci-style ratios between consecutive swings, classifying them as retracements or extensions.

**Key Features:**
- Automatically classifies ratios as RETRACEMENT or EXTENSION
- Handles edge cases (insufficient swings, zero amplitudes)
- Provides `isNearLevel()` helper for tolerance-based level matching
- Returns `ElliottRatio` records with value and type

**Ratio Types:**
- **Retracement**: Latest swing divided by opposite-direction prior swing
- **Extension**: Latest swing divided by same-direction prior swing (when new extreme is made)

### ElliottWaveCountIndicator

Counts the number of swings in the current sequence, optionally after compression.

**Key Features:**
- Simple swing counting for wave structure analysis
- Optional swing compression before counting
- Useful for identifying when sufficient waves exist for pattern recognition

### Supporting Components

- **ElliottDegree**: Enumeration of wave degrees (Grand Supercycle through Sub-Minuette)
- **ElliottSwing**: Immutable record representing a single swing between two pivots
- **ElliottPhase**: Enumeration of wave phases (WAVE1-5, CORRECTIVE_A-C, NONE)
- **ElliottRatio**: Record containing ratio value and type (RETRACEMENT/EXTENSION/NONE)
- **ElliottSwingCompressor**: Utility for filtering/compressing swing sequences
- **ElliottFibonacciValidator**: Validates Fibonacci relationships between waves
- **ElliottSwingMetadata**: Helper for slicing and analyzing swing windows

### Advanced Indicators

- **ElliottConfluenceIndicator**: Measures confluence of multiple Elliott Wave signals
- **ElliottChannelIndicator**: Projects price channels based on Elliott Wave structure
- **ElliottInvalidationIndicator**: Signals when wave structure is invalidated

---

## Getting Started

### Basic Setup

The simplest way to get started is with a fractal-based swing detector:

```java
BarSeries series = // your bar series

// Create swing indicator with 5-bar fractal windows
ElliottSwingIndicator swings = new ElliottSwingIndicator(
    series, 
    5,  // lookback window
    ElliottDegree.INTERMEDIATE  // wave degree
);

// Get swings at current index
int currentIndex = series.getEndIndex();
List<ElliottSwing> swingList = swings.getValue(currentIndex);
```

### Using ZigZag Swings

For adaptive swing detection based on volatility:

```java
// ZigZag with ATR(14) reversal threshold
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(
    series, 
    ElliottDegree.INTERMEDIATE
);
```

### Basic Wave Phase Detection

```java
ElliottSwingIndicator swings = new ElliottSwingIndicator(series, 5, ElliottDegree.INTERMEDIATE);
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings);

int index = series.getEndIndex();
ElliottPhase currentPhase = phase.getValue(index);

if (currentPhase.isImpulse()) {
    System.out.println("Current impulse wave: " + currentPhase.impulseIndex());
} else if (currentPhase.isCorrective()) {
    System.out.println("Current corrective wave: " + currentPhase.correctiveIndex());
}
```

### Basic Ratio Analysis

```java
ElliottSwingIndicator swings = new ElliottSwingIndicator(series, 5, ElliottDegree.INTERMEDIATE);
ElliottRatioIndicator ratios = new ElliottRatioIndicator(swings);

int index = series.getEndIndex();
ElliottRatio ratio = ratios.getValue(index);

if (ratio.type() == RatioType.RETRACEMENT) {
    System.out.println("Retracement ratio: " + ratio.value());
} else if (ratio.type() == RatioType.EXTENSION) {
    System.out.println("Extension ratio: " + ratio.value());
}

// Check if near a Fibonacci level (e.g., 0.618)
Num target = series.numOf(0.618);
Num tolerance = series.numOf(0.05);
if (ratios.isNearLevel(index, target, tolerance)) {
    System.out.println("Near 61.8% retracement level");
}
```

---

## Intermediate Usage Patterns

### Multi-Degree Analysis

Analyze multiple timeframes simultaneously:

```java
// Primary trend (longer timeframe)
ElliottSwingIndicator primarySwings = new ElliottSwingIndicator(series, 20, ElliottDegree.PRIMARY);
ElliottPhaseIndicator primaryPhase = new ElliottPhaseIndicator(primarySwings);

// Intermediate trend (shorter timeframe)
ElliottSwingIndicator intermediateSwings = new ElliottSwingIndicator(series, 5, ElliottDegree.INTERMEDIATE);
ElliottPhaseIndicator intermediatePhase = new ElliottPhaseIndicator(intermediateSwings);

// Use both for context
int index = series.getEndIndex();
ElliottPhase primary = primaryPhase.getValue(index);
ElliottPhase intermediate = intermediatePhase.getValue(index);

// Trade in direction of primary trend, using intermediate for timing
if (primary.isImpulse() && intermediate.isCorrective()) {
    // Potential entry during intermediate correction in primary impulse
}
```

### Custom Swing Detection

Use custom price sources or swing detectors:

```java
// Use close prices instead of high/low
ClosePriceIndicator close = new ClosePriceIndicator(series);
ElliottSwingIndicator swings = new ElliottSwingIndicator(
    close, 
    5,  // lookback
    5,  // lookforward
    ElliottDegree.INTERMEDIATE
);

// Or use existing swing indicators
RecentSwingIndicator customHighs = // your custom high detector
RecentSwingIndicator customLows = // your custom low detector
ElliottSwingIndicator swings = new ElliottSwingIndicator(
    customHighs, 
    customLows, 
    ElliottDegree.INTERMEDIATE
);
```

### Wave Confirmation Patterns

Wait for wave confirmation before acting:

```java
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings);

int index = series.getEndIndex();

// Wait for complete 5-wave impulse
if (phase.isImpulseConfirmed(index)) {
    List<ElliottSwing> impulseSwings = phase.impulseSwings(index);
    // Analyze the completed impulse structure
}

// Wait for complete A-B-C correction
if (phase.isCorrectiveConfirmed(index)) {
    List<ElliottSwing> correctiveSwings = phase.correctiveSwings(index);
    // Analyze the completed correction
}
```

### Ratio-Based Entry/Exit Signals

Use Fibonacci ratios for trade management:

```java
ElliottRatioIndicator ratios = new ElliottRatioIndicator(swings);

int index = series.getEndIndex();
ElliottRatio ratio = ratios.getValue(index);

// Common Fibonacci retracement levels
Num fib236 = series.numOf(0.236);
Num fib382 = series.numOf(0.382);
Num fib500 = series.numOf(0.500);
Num fib618 = series.numOf(0.618);
Num fib786 = series.numOf(0.786);
Num tolerance = series.numOf(0.02); // 2% tolerance

if (ratio.type() == RatioType.RETRACEMENT) {
    if (ratios.isNearLevel(index, fib618, tolerance)) {
        // Strong support/resistance at 61.8% retracement
    } else if (ratios.isNearLevel(index, fib382, tolerance)) {
        // Moderate retracement at 38.2%
    }
}
```

### Swing Compression

Filter swings before analysis:

```java
ElliottSwingCompressor compressor = // your compressor logic
ElliottWaveCountIndicator counter = new ElliottWaveCountIndicator(swings, compressor);

int index = series.getEndIndex();
int swingCount = counter.getValue(index);
List<ElliottSwing> compressedSwings = counter.getSwings(index);
```

---

## Advanced Topics

### Confluence Analysis

Combine multiple Elliott Wave signals for stronger confirmation:

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
ElliottRatioIndicator ratios = new ElliottRatioIndicator(swings);
ElliottChannelIndicator channels = new ElliottChannelIndicator(swings);

ElliottConfluenceIndicator confluence = new ElliottConfluenceIndicator(
    close, 
    ratios,
    channels
);

int index = series.getEndIndex();
Num confluenceScore = confluence.getValue(index);

// Check if confluence meets minimum threshold (default is 2)
if (confluence.isConfluent(index)) {
    // Strong confluence - high confidence signal
}
```

### Channel Projection

Project price channels based on Elliott Wave structure:

```java
ElliottChannelIndicator channel = new ElliottChannelIndicator(swings);
ClosePriceIndicator close = new ClosePriceIndicator(series);

int index = series.getEndIndex();
ElliottChannel channelData = channel.getValue(index);

// Access channel boundaries
if (channelData.isValid()) {
    Num upperBound = channelData.upper();
    Num lowerBound = channelData.lower();
    Num median = channelData.median();
    
    // Check if current price is within channel
    Num currentPrice = close.getValue(index);
    Num tolerance = series.numOf(0.01); // 1% tolerance
    if (channelData.contains(currentPrice, tolerance)) {
        // Price is within projected channel
    }
    // Use for target projection or stop placement
}
```

### Wave Invalidation Detection

Monitor for wave structure invalidations:

```java
ElliottInvalidationIndicator invalidation = new ElliottInvalidationIndicator(
    phaseIndicator
);

int index = series.getEndIndex();
boolean isInvalidated = invalidation.getValue(index);

if (isInvalidated) {
    // Wave count needs to be reassessed
    // Previous wave labels may be incorrect
}
```

### Custom Fibonacci Validation

Fine-tune Fibonacci relationship validation:

```java
// Create custom validator with specific tolerances
ElliottFibonacciValidator validator = new ElliottFibonacciValidator(
    series.numFactory()
);
// Configure validator parameters as needed

ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings, validator);
```

### Recursive Wave Analysis

Analyze nested wave structures:

```java
// The phase indicator automatically handles recursive cycles
// When a complete 5-3 cycle finishes, it looks for the next cycle
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings);

int index = series.getEndIndex();
ElliottPhase current = phase.getValue(index);

// The indicator internally tracks multiple cycles
// Access impulse and corrective segments separately
List<ElliottSwing> impulse = phase.impulseSwings(index);
List<ElliottSwing> correction = phase.correctiveSwings(index);
```

### Performance Considerations

- **Caching**: All indicators extend `CachedIndicator`, so values are cached after first calculation
- **Unstable Bars**: Use `getCountOfUnstableBars()` to determine when indicators stabilize
- **Swing Window Size**: Larger windows produce fewer swings but more reliable pivots
- **Degree Selection**: Match degree to your trading timeframe and data granularity

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

3. **Allow for Flat Tops/Bottoms**:
   - Set `allowedEqualBars` > 0 for markets with frequent equal highs/lows

### Wave Degree Selection

- **Match to Trading Timeframe**: Use INTERMEDIATE for daily charts, MINOR for intraday
- **Consistency**: Use the same degree across related indicators
- **Multi-Timeframe**: Analyze higher degree for trend, lower degree for entries

### Validation and Confirmation

1. **Wait for Confirmation**: Use `isImpulseConfirmed()` and `isCorrectiveConfirmed()` before acting
2. **Check Multiple Signals**: Combine phase, ratio, and confluence indicators
3. **Respect Invalidation**: Monitor `ElliottInvalidationIndicator` and reassess when invalidated

### Error Handling

1. **Check for NaN**: Always validate indicator values before use
2. **Sufficient Swings**: Ensure enough swings exist for your analysis (typically 5+ for impulses)
3. **Edge Cases**: Handle cases where swings are still forming or structure is ambiguous

### Integration with Other Indicators

- **Trend Confirmation**: Combine with moving averages or trend indicators
- **Momentum**: Use RSI or MACD to confirm wave direction
- **Volume**: Volume should expand in impulse waves, contract in corrections
- **Support/Resistance**: Align Elliott Wave targets with traditional S/R levels

---

## Integration with Trading Strategies

### Basic Elliott Wave Rule

```java
ElliottSwingIndicator swings = new ElliottSwingIndicator(series, 5, ElliottDegree.INTERMEDIATE);
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings);

// Enter long at start of Wave 3
Rule entryRule = new Rule() {
    @Override
    public boolean isSatisfied(int index, TradingRecord tradingRecord) {
        ElliottPhase current = phase.getValue(index);
        return current == ElliottPhase.WAVE3;
    }
};

// Exit at completion of Wave 5
Rule exitRule = new Rule() {
    @Override
    public boolean isSatisfied(int index, TradingRecord tradingRecord) {
        ElliottPhase current = phase.getValue(index);
        return current == ElliottPhase.WAVE5 && phase.isImpulseConfirmed(index);
    }
};

Strategy strategy = new BaseStrategy(entryRule, exitRule);
```

### Ratio-Based Entry

```java
ElliottRatioIndicator ratios = new ElliottRatioIndicator(swings);
Num fib618 = series.numOf(0.618);
Num tolerance = series.numOf(0.02);

Rule entryRule = new Rule() {
    @Override
    public boolean isSatisfied(int index, TradingRecord tradingRecord) {
        ElliottRatio ratio = ratios.getValue(index);
        return ratio.type() == RatioType.RETRACEMENT 
            && ratios.isNearLevel(index, fib618, tolerance);
    }
};
```

### Multi-Factor Strategy

```java
// Combine Elliott Wave with other indicators
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings);
RSIIndicator rsi = new RSIIndicator(close, 14);
SMAIndicator sma = new SMAIndicator(close, 50);

Rule entryRule = new AndRule(
    // Elliott Wave: entering Wave 3
    new Rule() {
        @Override
        public boolean isSatisfied(int index, TradingRecord tradingRecord) {
            return phase.getValue(index) == ElliottPhase.WAVE3;
        }
    },
    // RSI: not overbought
    new UnderIndicatorRule(rsi, series.numOf(70)),
    // Price: above SMA (uptrend)
    new OverIndicatorRule(close, sma)
);
```

### Strategy with Wave Invalidation

```java
ElliottInvalidationIndicator invalidation = new ElliottInvalidationIndicator(phase);

Rule exitRule = new OrRule(
    // Normal exit: Wave 5 complete
    new Rule() {
        @Override
        public boolean isSatisfied(int index, TradingRecord tradingRecord) {
            return phase.isImpulseConfirmed(index);
        }
    },
    // Emergency exit: wave invalidated
    new Rule() {
        @Override
        public boolean isSatisfied(int index, TradingRecord tradingRecord) {
            return invalidation.getValue(index);
        }
    }
);
```

---

## Additional Resources

- **Elliott Wave Theory**: Study the foundational principles from Elliott's original work and modern interpretations
- **Fibonacci Analysis**: Understand Fibonacci retracements, extensions, and projections
- **Swing Detection**: See [Trendlines & Swing Points](Trendlines-and-Swing-Points.md) for detailed swing detection documentation
- **Strategy Development**: Review [Trading Strategies](Trading-strategies.md) for rule composition patterns
- **Backtesting**: Use [Backtesting](Backtesting.md) guide to validate Elliott Wave strategies

---

## Summary

ta4j's Elliott Wave indicators provide a powerful toolkit for wave-based technical analysis. Start with basic swing detection and phase identification, then gradually incorporate ratio analysis, confluence, and advanced features as you become more comfortable with the system. Remember that Elliott Wave analysis is as much art as science—use the indicators as tools to support your analysis, not as absolute truth.

The modular design allows you to build custom workflows that match your trading style, whether you're a pure Elliott Wave trader or combining waves with other technical indicators. As development continues, new features and refinements will be added to enhance the analysis capabilities.

=======
The Elliott Wave indicator suite provides a complete toolkit for identifying, validating, and analyzing Elliott Wave patterns in price action. Built on ta4j's swing detection infrastructure, these indicators work together to detect the classic 5-wave impulse and 3-wave corrective structures while validating them against Fibonacci ratios and projecting price channels.

## Overview

Elliott Wave Theory posits that market movements follow repetitive patterns of five waves in the direction of the trend (impulse) followed by three waves against it (correction). The ta4j Elliott Wave suite automates:

- **Swing detection**: Identifying alternating pivot highs and lows
- **Phase tracking**: Recognizing which wave (1-5 or A-C) the market is currently in
- **Fibonacci validation**: Ensuring waves conform to expected retracement/extension ratios
- **Channel projection**: Drawing support/resistance boundaries based on swing geometry
- **Confluence scoring**: Combining multiple signals for higher-confidence setups
- **Invalidation detection**: Flagging when wave counts break canonical rules

## Core Classes

### ElliottSwingIndicator

**Purpose**: The foundation of the Elliott Wave system. Detects alternating swing highs and lows, merging them into a sequence of `ElliottSwing` objects that represent price movements between pivots.

**Why it exists**: Elliott Wave analysis requires a clean sequence of alternating swings. This indicator composes swing high/low detectors and ensures they alternate properly, compressing consecutive pivots of the same type (keeping only the most extreme).

**Usage in isolation**:
```java
// ZigZag-based swings (recommended for most use cases)
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(series, ElliottDegree.PRIMARY);

// Fractal-based swings with custom window
ElliottSwingIndicator swings = new ElliottSwingIndicator(series, 5, 5, 0, ElliottDegree.INTERMEDIATE);

// Get swing list at current bar
List<ElliottSwing> currentSwings = swings.getValue(series.getEndIndex());
for (ElliottSwing swing : currentSwings) {
    System.out.println("Swing: " + swing.fromPrice() + " -> " + swing.toPrice() + 
                       " (amplitude: " + swing.amplitude() + ")");
}
```

**Usage in combination**: All other Elliott Wave indicators depend on `ElliottSwingIndicator`. It's the first component you create and pass to phase, ratio, and channel indicators.

### ElliottDegree

**Purpose**: Enumeration representing the time scale or "degree" of the wave structure being analyzed (e.g., PRIMARY, INTERMEDIATE, MINOR).

**Why it exists**: Elliott Wave patterns exist at multiple timeframes simultaneously. A PRIMARY wave may contain multiple INTERMEDIATE waves, which in turn contain MINOR waves. The degree metadata helps track which timeframe you're analyzing.

**Usage**: Passed to `ElliottSwingIndicator` constructors and stored in each `ElliottSwing` for context.

```java
ElliottDegree degree = ElliottDegree.PRIMARY; // For daily charts
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(series, degree);
```

### ElliottSwing

**Purpose**: Immutable record representing a single swing between two pivots, containing index/price coordinates, direction, amplitude, and degree metadata.

**Why it exists**: Provides a clean abstraction for price movements between pivots. Used throughout the suite for calculations and validations.

**Key methods**:
- `isRising()`: Returns true if swing moves upward
- `amplitude()`: Absolute price change between pivots
- `length()`: Number of bars covered by the swing

### ElliottPhaseIndicator

**Purpose**: Tracks the current Elliott Wave phase by analyzing swing sequences. Identifies whether the market is in an impulse wave (1-5) or corrective wave (A-C) and which specific wave within that structure.

**Why it exists**: Knowing the current wave phase is critical for Elliott Wave trading. This indicator automates the complex logic of recognizing valid 5-wave impulses and 3-wave corrections based on Fibonacci relationships and wave rules.

**Usage in isolation**:
```java
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(series, ElliottDegree.PRIMARY);
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings);

int endIndex = series.getEndIndex();
ElliottPhase currentPhase = phase.getValue(endIndex);
System.out.println("Current phase: " + currentPhase); // WAVE1, WAVE2, ..., WAVE5, CORRECTIVE_A, etc.

if (phase.isImpulseConfirmed(endIndex)) {
    System.out.println("5-wave impulse complete!");
}
if (phase.isCorrectiveConfirmed(endIndex)) {
    System.out.println("A-B-C correction complete!");
}
```

**Usage in combination**: Works with `ElliottFibonacciValidator` to validate wave relationships. Output feeds into `ElliottInvalidationIndicator` and can be used to extract specific wave segments for analysis.

```java
// Get the five impulse swings
List<ElliottSwing> impulseWaves = phase.impulseSwings(endIndex);
// Get the three corrective swings
List<ElliottSwing> correctiveWaves = phase.correctiveSwings(endIndex);
```

### ElliottFibonacciValidator

**Purpose**: Validates that wave amplitudes conform to expected Fibonacci retracement and extension ratios. Checks wave 2 retracements, wave 3 extensions, wave 4 retracements, wave 5 projections, and corrective wave relationships.

**Why it exists**: Elliott Wave patterns must follow specific Fibonacci relationships to be valid. Wave 2 typically retraces 38.2%-78.6% of wave 1, wave 3 extends 100%-261.8% of wave 1, etc. This validator enforces these rules.

**Usage in isolation**:
```java
NumFactory factory = series.numFactory();
Num tolerance = factory.numOf(0.25); // 25% tolerance around Fibonacci levels
ElliottFibonacciValidator validator = new ElliottFibonacciValidator(factory, tolerance);

ElliottSwing wave1 = swings.get(0);
ElliottSwing wave2 = swings.get(1);
if (validator.isWaveTwoRetracementValid(wave1, wave2)) {
    System.out.println("Wave 2 retracement is valid!");
}
```

**Usage in combination**: Passed to `ElliottPhaseIndicator` constructor to enable Fibonacci validation during phase detection. Without it, phase detection only checks wave direction and boundary rules, not Fibonacci ratios.

```java
ElliottFibonacciValidator validator = new ElliottFibonacciValidator(
    series.numFactory(), 
    series.numFactory().numOf(0.25)
);
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings, validator);
```

### ElliottInvalidationIndicator

**Purpose**: Flags when the current wave count violates canonical Elliott Wave rules (e.g., wave 2 exceeding wave 1 start, wave 4 overlapping wave 1 territory).

**Why it exists**: Elliott Wave counts can become invalid when price action breaks key rules. This indicator provides a boolean signal that trading systems can use to reset their state or exit positions.

**Usage in isolation**:
```java
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings, validator);
ElliottInvalidationIndicator invalidation = new ElliottInvalidationIndicator(phase);

int endIndex = series.getEndIndex();
if (invalidation.getValue(endIndex)) {
    System.out.println("Wave count invalidated - reset analysis");
}
```

**Usage in combination**: Typically used in trading rules to exit positions or reset strategy state when wave structure breaks down.

### ElliottChannelIndicator

**Purpose**: Projects support and resistance channel boundaries based on the most recent swing highs and lows. Draws parallel lines through the last two rising swings (upper channel) and last two falling swings (lower channel).

**Why it exists**: Elliott Wave channels help identify potential price targets and support/resistance zones. The channel is recalculated on each bar using the latest swing geometry, providing dynamic boundaries.

**Usage in isolation**:
```java
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(series, ElliottDegree.PRIMARY);
ElliottChannelIndicator channel = new ElliottChannelIndicator(swings);

int endIndex = series.getEndIndex();
ElliottChannel currentChannel = channel.getValue(endIndex);
if (currentChannel.isValid()) {
    System.out.println("Upper: " + currentChannel.upper());
    System.out.println("Lower: " + currentChannel.lower());
    System.out.println("Median: " + currentChannel.median());
}
```

**Usage in combination**: Used with `ElliottConfluenceIndicator` to score confluence when price is near channel boundaries. Can be plotted on charts to visualize support/resistance zones.

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
Num price = close.getValue(endIndex);
Num tolerance = series.numFactory().numOf(10.0); // $10 tolerance
if (currentChannel.contains(price, tolerance)) {
    System.out.println("Price is within channel boundaries");
}
```

### ElliottRatioIndicator

**Purpose**: Calculates Fibonacci-style ratios between consecutive swings. Classifies the latest swing as either a retracement (reversing direction) or extension (continuing direction with new extreme).

**Why it exists**: Understanding swing ratios helps identify when price is at key Fibonacci levels, which often act as support/resistance or reversal points.

**Usage in isolation**:
```java
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(series, ElliottDegree.PRIMARY);
ElliottRatioIndicator ratio = new ElliottRatioIndicator(swings);

int endIndex = series.getEndIndex();
ElliottRatio currentRatio = ratio.getValue(endIndex);
System.out.println("Ratio type: " + currentRatio.type()); // RETRACEMENT or EXTENSION
System.out.println("Ratio value: " + currentRatio.value()); // e.g., 0.618, 1.618

// Check if near a specific Fibonacci level
Num target618 = series.numFactory().numOf(0.618);
Num tolerance = series.numFactory().numOf(0.05);
if (ratio.isNearLevel(endIndex, target618, tolerance)) {
    System.out.println("Near 61.8% Fibonacci level!");
}
```

**Usage in combination**: Used with `ElliottConfluenceIndicator` to score confluence when ratios match key Fibonacci levels. Helps identify high-probability reversal or continuation zones.

### ElliottConfluenceIndicator

**Purpose**: Aggregates multiple Elliott Wave signals into a single confluence score. Combines Fibonacci ratio matches and channel boundary proximity to identify high-confidence setups.

**Why it exists**: Individual signals can be noisy. Combining ratio validation with channel alignment provides stronger confirmation for trading decisions.

**Usage in isolation**:
```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(series, ElliottDegree.PRIMARY);
ElliottRatioIndicator ratio = new ElliottRatioIndicator(swings);
ElliottChannelIndicator channel = new ElliottChannelIndicator(swings);

ElliottConfluenceIndicator confluence = new ElliottConfluenceIndicator(close, ratio, channel);

int endIndex = series.getEndIndex();
Num score = confluence.getValue(endIndex);
System.out.println("Confluence score: " + score); // 0, 1, or 2

if (confluence.isConfluent(endIndex)) {
    System.out.println("High confluence setup detected!");
}
```

**Usage in combination**: The score (0-2) can be used in trading rules. Score of 2 means both ratio and channel conditions are met, indicating strong confluence.

### ElliottWaveCountIndicator

**Purpose**: Counts the number of swings detected by the swing indicator. Optionally filters swings using a compressor before counting.

**Why it exists**: Sometimes you just need to know how many swings exist, or count only "significant" swings that meet minimum amplitude/length thresholds.

**Usage in isolation**:
```java
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(series, ElliottDegree.PRIMARY);
ElliottWaveCountIndicator count = new ElliottWaveCountIndicator(swings);

int endIndex = series.getEndIndex();
Integer swingCount = count.getValue(endIndex);
System.out.println("Total swings: " + swingCount);
```

**Usage in combination**: Use with `ElliottSwingCompressor` to count only significant swings, filtering out noise.

```java
ClosePriceIndicator close = new ClosePriceIndicator(series);
Num minAmplitude = close.getValue(series.getEndIndex())
    .multipliedBy(series.numFactory().numOf(0.01)); // 1% of current price
ElliottSwingCompressor compressor = new ElliottSwingCompressor(minAmplitude, 5); // Min 5 bars

ElliottWaveCountIndicator filteredCount = new ElliottWaveCountIndicator(swings, compressor);
System.out.println("Significant swings: " + filteredCount.getValue(endIndex));
```

### ElliottSwingCompressor

**Purpose**: Filters swing sequences by minimum amplitude and/or minimum bar length. Removes small, insignificant swings that might be noise.

**Why it exists**: Raw swing detection can produce many small swings in choppy markets. The compressor helps focus on meaningful price movements.

**Usage**: Always used with `ElliottWaveCountIndicator`:

```java
Num minAmplitude = series.numFactory().numOf(50.0); // $50 minimum swing
int minBars = 10; // Minimum 10 bars per swing
ElliottSwingCompressor compressor = new ElliottSwingCompressor(minAmplitude, minBars);

List<ElliottSwing> originalSwings = swings.getValue(endIndex);
List<ElliottSwing> compressedSwings = compressor.compress(originalSwings);
```

### ElliottSwingMetadata

**Purpose**: Immutable snapshot of swing statistics including highest/lowest prices, swing count, and validation status. Provides convenient access to swing list subsets.

**Why it exists**: Many indicators need to analyze swing sequences. This class provides a validated, queryable view of swings with helper methods for common operations.

**Usage**: Typically created internally by indicators, but can be used directly:

```java
ElliottSwingMetadata metadata = ElliottSwingMetadata.of(
    swings.getValue(endIndex), 
    series.numFactory()
);

if (metadata.isValid()) {
    System.out.println("Highest price: " + metadata.highestPrice());
    System.out.println("Lowest price: " + metadata.lowestPrice());
    System.out.println("Swing count: " + metadata.size());
    
    // Get first 5 swings
    List<ElliottSwing> firstFive = metadata.leading(5);
    // Get last 3 swings
    List<ElliottSwing> lastThree = metadata.trailing(3);
}
```

### ElliottPhase

**Purpose**: Enumeration representing the current wave phase (NONE, WAVE1-5, CORRECTIVE_A-C).

**Why it exists**: Provides a type-safe way to represent and query wave phases throughout the system.

**Usage**:
```java
ElliottPhase phase = phaseIndicator.getValue(endIndex);

if (phase.isImpulse()) {
    System.out.println("Impulse wave " + phase.impulseIndex());
}
if (phase.isCorrective()) {
    System.out.println("Corrective wave " + phase.correctiveIndex());
}
if (phase.completesStructure()) {
    System.out.println("Structure complete!");
}
```

### ElliottChannel

**Purpose**: Immutable record containing upper, lower, and median channel boundaries.

**Usage**: Returned by `ElliottChannelIndicator`:

```java
ElliottChannel channel = channelIndicator.getValue(endIndex);
if (channel.isValid()) {
    Num upper = channel.upper();
    Num lower = channel.lower();
    Num median = channel.median();
}
```

### ElliottRatio

**Purpose**: Immutable record containing a ratio value and type (RETRACEMENT, EXTENSION, or NONE).

**Usage**: Returned by `ElliottRatioIndicator`:

```java
ElliottRatio ratio = ratioIndicator.getValue(endIndex);
if (ratio.type() == ElliottRatio.RatioType.RETRACEMENT) {
    System.out.println("Retracement ratio: " + ratio.value());
}
```

## Walkthroughs

### Beginner: Basic Wave Detection

This walkthrough demonstrates the simplest use case: detecting swings and identifying the current wave phase.

```java
import org.ta4j.core.BarSeries;
import org.ta4j.core.indicators.elliott.*;

// Load your price data
BarSeries series = loadYourData();

// Step 1: Create swing indicator using ZigZag (easiest method)
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(
    series, 
    ElliottDegree.PRIMARY
);

// Step 2: Create phase indicator to track wave structure
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings);

// Step 3: Check current wave phase
int currentBar = series.getEndIndex();
ElliottPhase currentPhase = phase.getValue(currentBar);

System.out.println("Current wave phase: " + currentPhase);

// Step 4: Get wave details
if (phase.isImpulseConfirmed(currentBar)) {
    List<ElliottSwing> impulseWaves = phase.impulseSwings(currentBar);
    System.out.println("5-wave impulse detected with " + impulseWaves.size() + " waves");
    
    for (int i = 0; i < impulseWaves.size(); i++) {
        ElliottSwing wave = impulseWaves.get(i);
        System.out.println("Wave " + (i + 1) + ": " + 
            wave.fromPrice() + " -> " + wave.toPrice() + 
            " (amplitude: " + wave.amplitude() + ")");
    }
}

if (phase.isCorrectiveConfirmed(currentBar)) {
    List<ElliottSwing> correctiveWaves = phase.correctiveSwings(currentBar);
    System.out.println("A-B-C correction detected");
}
```

**What this does**: 
- Uses ZigZag swing detection (simplest setup)
- Tracks wave phases without Fibonacci validation
- Prints current phase and wave details

**When to use**: Learning Elliott Wave concepts, basic pattern recognition, or when you want the simplest possible setup.

### Intermediate: Fibonacci-Validated Wave Analysis

This walkthrough adds Fibonacci validation and channel projection for more robust analysis.

```java
import org.ta4j.core.BarSeries;
import org.ta4j.core.indicators.elliott.*;
import org.ta4j.core.indicators.helpers.ClosePriceIndicator;

BarSeries series = loadYourData();
ClosePriceIndicator close = new ClosePriceIndicator(series);

// Step 1: Create swing indicator
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(
    series, 
    ElliottDegree.PRIMARY
);

// Step 2: Create Fibonacci validator with 25% tolerance
NumFactory factory = series.numFactory();
ElliottFibonacciValidator validator = new ElliottFibonacciValidator(
    factory, 
    factory.numOf(0.25)
);

// Step 3: Create phase indicator with Fibonacci validation
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings, validator);

// Step 4: Create channel indicator for support/resistance
ElliottChannelIndicator channel = new ElliottChannelIndicator(swings);

// Step 5: Create ratio indicator for Fibonacci level detection
ElliottRatioIndicator ratio = new ElliottRatioIndicator(swings);

// Step 6: Create invalidation indicator to catch rule violations
ElliottInvalidationIndicator invalidation = new ElliottInvalidationIndicator(phase);

// Step 7: Analyze current state
int currentBar = series.getEndIndex();

// Check for invalidation first
if (invalidation.getValue(currentBar)) {
    System.out.println("WARNING: Wave count invalidated!");
    return;
}

// Get current phase
ElliottPhase currentPhase = phase.getValue(currentBar);
System.out.println("Current phase: " + currentPhase);

// Check Fibonacci ratios
ElliottRatio currentRatio = ratio.getValue(currentBar);
if (currentRatio.type() != ElliottRatio.RatioType.NONE) {
    System.out.println("Current ratio: " + currentRatio.type() + " = " + currentRatio.value());
    
    // Check if near key Fibonacci levels
    Num fib618 = factory.numOf(0.618);
    Num fib1618 = factory.numOf(1.618);
    Num tolerance = factory.numOf(0.05);
    
    if (ratio.isNearLevel(currentBar, fib618, tolerance)) {
        System.out.println("Near 61.8% Fibonacci level - potential reversal zone");
    }
    if (ratio.isNearLevel(currentBar, fib1618, tolerance)) {
        System.out.println("Near 161.8% Fibonacci extension - potential target");
    }
}

// Check channel boundaries
ElliottChannel currentChannel = channel.getValue(currentBar);
if (currentChannel.isValid()) {
    Num currentPrice = close.getValue(currentBar);
    System.out.println("Channel upper: " + currentChannel.upper());
    System.out.println("Channel lower: " + currentChannel.lower());
    System.out.println("Current price: " + currentPrice);
    
    Num channelTolerance = factory.numOf(10.0);
    if (currentChannel.contains(currentPrice, channelTolerance)) {
        System.out.println("Price is within channel - potential support/resistance");
    }
}

// Get wave structure details
if (phase.isImpulseConfirmed(currentBar)) {
    List<ElliottSwing> impulse = phase.impulseSwings(currentBar);
    System.out.println("\nImpulse structure:");
    for (int i = 0; i < impulse.size(); i++) {
        ElliottSwing wave = impulse.get(i);
        System.out.println("  Wave " + (i + 1) + ": " + wave.amplitude());
    }
}
```

**What this does**:
- Validates waves against Fibonacci ratios
- Projects support/resistance channels
- Detects Fibonacci retracement/extension levels
- Flags wave count invalidations
- Provides comprehensive wave analysis

**When to use**: When you need validated wave counts, want to identify Fibonacci support/resistance levels, or need channel boundaries for trading decisions.

### Advanced: Confluence-Based Trading System

This walkthrough demonstrates a complete trading system using confluence scoring, swing compression, and integration with ta4j trading rules.

```java
import org.ta4j.core.*;
import org.ta4j.core.indicators.elliott.*;
import org.ta4j.core.indicators.helpers.ClosePriceIndicator;
import org.ta4j.core.rules.*;
import org.ta4j.core.num.Num;

BarSeries series = loadYourData();
ClosePriceIndicator close = new ClosePriceIndicator(series);
NumFactory factory = series.numFactory();

// Step 1: Create swing indicator with custom degree
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(
    series, 
    ElliottDegree.INTERMEDIATE  // Use intermediate for shorter-term analysis
);

// Step 2: Create compressor to filter noise
Num currentPrice = close.getValue(series.getEndIndex());
Num minSwingAmplitude = currentPrice.multipliedBy(factory.numOf(0.02)); // 2% minimum
ElliottSwingCompressor compressor = new ElliottSwingCompressor(minSwingAmplitude, 5);

// Step 3: Create filtered swing count
ElliottWaveCountIndicator swingCount = new ElliottWaveCountIndicator(swings, compressor);

// Step 4: Create Fibonacci validator with tight tolerance
ElliottFibonacciValidator validator = new ElliottFibonacciValidator(
    factory, 
    factory.numOf(0.15)  // 15% tolerance for stricter validation
);

// Step 5: Create phase indicator
ElliottPhaseIndicator phase = new ElliottPhaseIndicator(swings, validator);

// Step 6: Create channel and ratio indicators
ElliottChannelIndicator channel = new ElliottChannelIndicator(swings);
ElliottRatioIndicator ratio = new ElliottRatioIndicator(swings);

// Step 7: Create confluence indicator with custom settings
// Custom Fibonacci levels
List<Num> retracementLevels = List.of(
    factory.numOf(0.236), factory.numOf(0.382), factory.numOf(0.5),
    factory.numOf(0.618), factory.numOf(0.786), factory.numOf(1.0)
);
List<Num> extensionLevels = List.of(
    factory.numOf(1.272), factory.numOf(1.414), 
    factory.numOf(1.618), factory.numOf(2.0), factory.numOf(2.618)
);

ElliottConfluenceIndicator confluence = new ElliottConfluenceIndicator(
    close, 
    ratio, 
    channel,
    retracementLevels,
    extensionLevels,
    factory.numOf(0.05),  // Ratio tolerance
    currentPrice.multipliedBy(factory.numOf(0.01)),  // Channel tolerance (1% of price)
    factory.numOf(2.0)  // Minimum score for confluence
);

// Step 8: Create invalidation indicator
ElliottInvalidationIndicator invalidation = new ElliottInvalidationIndicator(phase);

// Step 9: Build trading rules using confluence and phase
Rule entryLong = new BooleanIndicatorRule(confluence, confluence::isConfluent)
    .and(new BooleanIndicatorRule(phase, idx -> {
        ElliottPhase p = phase.getValue(idx);
        // Enter long on wave 3 or 5 of impulse, or at start of correction
        return p == ElliottPhase.WAVE3 || p == ElliottPhase.WAVE5 || 
               p == ElliottPhase.CORRECTIVE_A;
    }))
    .and(new BooleanIndicatorRule(invalidation, idx -> !invalidation.getValue(idx)))
    .and(new OverIndicatorRule(close, channel.getValue(series.getEndIndex()).median()));

Rule exitLong = new BooleanIndicatorRule(invalidation, idx -> invalidation.getValue(idx))
    .or(new BooleanIndicatorRule(phase, idx -> {
        ElliottPhase p = phase.getValue(idx);
        // Exit when correction completes or wave 5 completes
        return p == ElliottPhase.CORRECTIVE_C || 
               (p == ElliottPhase.WAVE5 && phase.isImpulseConfirmed(idx));
    }))
    .or(new UnderIndicatorRule(close, channel.getValue(series.getEndIndex()).lower()));

// Step 10: Create strategy
Strategy strategy = new BaseStrategy(
    "Elliott Wave Confluence",
    entryLong,
    exitLong
);

// Step 11: Backtest or analyze
int currentBar = series.getEndIndex();

// Print comprehensive analysis
System.out.println("=== Elliott Wave Analysis ===");
System.out.println("Current phase: " + phase.getValue(currentBar));
System.out.println("Swing count (filtered): " + swingCount.getValue(currentBar));
System.out.println("Confluence score: " + confluence.getValue(currentBar));
System.out.println("Is confluent: " + confluence.isConfluent(currentBar));
System.out.println("Invalidated: " + invalidation.getValue(currentBar));

ElliottChannel ch = channel.getValue(currentBar);
if (ch.isValid()) {
    System.out.println("Channel: " + ch.lower() + " - " + ch.upper());
    System.out.println("Price position: " + 
        (close.getValue(currentBar).isGreaterThan(ch.median()) ? "Above median" : "Below median"));
}

ElliottRatio r = ratio.getValue(currentBar);
if (r.type() != ElliottRatio.RatioType.NONE) {
    System.out.println("Current ratio: " + r.type() + " = " + r.value());
}

// Get detailed wave structure
if (phase.isImpulseConfirmed(currentBar)) {
    List<ElliottSwing> impulse = phase.impulseSwings(currentBar);
    System.out.println("\nImpulse Waves:");
    for (int i = 0; i < impulse.size(); i++) {
        ElliottSwing w = impulse.get(i);
        System.out.println("  Wave " + (i + 1) + ": " + 
            w.fromPrice() + " -> " + w.toPrice() + 
            " (amplitude: " + w.amplitude() + ", bars: " + w.length() + ")");
    }
}

if (phase.isCorrectiveConfirmed(currentBar)) {
    List<ElliottSwing> correction = phase.correctiveSwings(currentBar);
    System.out.println("\nCorrective Waves:");
    String[] labels = {"A", "B", "C"};
    for (int i = 0; i < correction.size(); i++) {
        ElliottSwing w = correction.get(i);
        System.out.println("  Wave " + labels[i] + ": " + 
            w.fromPrice() + " -> " + w.toPrice() + 
            " (amplitude: " + w.amplitude() + ", bars: " + w.length() + ")");
    }
}
```

**What this does**:
- Filters swings to remove noise
- Uses strict Fibonacci validation
- Combines multiple signals via confluence scoring
- Creates trading rules based on wave phase and confluence
- Provides comprehensive analysis output
- Integrates with ta4j's strategy system

**When to use**: Building automated trading systems, backtesting Elliott Wave strategies, or when you need the highest-confidence setups combining multiple validation methods.

## Best Practices

1. **Choose the right degree**: Match `ElliottDegree` to your analysis timeframe. PRIMARY for daily charts, INTERMEDIATE for 4-hour, MINOR for hourly.

2. **Use ZigZag for most cases**: `ElliottSwingIndicator.zigZag()` is simpler and more adaptive than fractal-based swings. Use fractals only when you need fixed-window confirmation.

3. **Validate with Fibonacci**: Always use `ElliottFibonacciValidator` with `ElliottPhaseIndicator` for realistic wave detection. Without it, you'll get many false positives.

4. **Check invalidation**: Monitor `ElliottInvalidationIndicator` and reset your analysis when waves invalidate. Don't trade on invalidated counts.

5. **Use confluence for entries**: Individual signals can be noisy. Use `ElliottConfluenceIndicator` to wait for multiple confirmations before entering trades.

6. **Compress noisy markets**: In choppy conditions, use `ElliottSwingCompressor` to focus on significant swings only.

7. **Combine with other indicators**: Elliott Wave works best when combined with volume, momentum, or trend indicators for additional confirmation.

8. **Respect unstable bars**: Check `indicator.getCountOfUnstableBars()` and wait for stability before making trading decisions, especially with ZigZag swings.

9. **Visualize your analysis**: Use the charting API to plot channels, swing markers, and wave labels for visual confirmation.

10. **Backtest thoroughly**: Elliott Wave patterns are subjective. Backtest your rules extensively to ensure they work in practice, not just in theory.

## Common Patterns

### Pattern 1: Wave 3 Entry
```java
Rule wave3Entry = new BooleanIndicatorRule(phase, idx -> 
    phase.getValue(idx) == ElliottPhase.WAVE3
).and(new BooleanIndicatorRule(confluence, confluence::isConfluent));
```

### Pattern 2: Correction Completion Exit
```java
Rule correctionExit = new BooleanIndicatorRule(phase, idx -> 
    phase.isCorrectiveConfirmed(idx) && 
    phase.getValue(idx) == ElliottPhase.CORRECTIVE_C
);
```

### Pattern 3: Channel Breakout
```java
ElliottChannel ch = channel.getValue(idx);
Rule channelBreakout = new CrossedUpIndicatorRule(close, ch.upper())
    .or(new CrossedDownIndicatorRule(close, ch.lower()));
```

### Pattern 4: Fibonacci Retracement Bounce
```java
Rule fibBounce = new BooleanIndicatorRule(ratio, r -> {
    ElliottRatio ratio = r.getValue(idx);
    return ratio.type() == ElliottRatio.RatioType.RETRACEMENT &&
           ratio.isNearLevel(idx, factory.numOf(0.618), factory.numOf(0.05));
}).and(new CrossedUpIndicatorRule(close, someSupportLevel));
```

## Troubleshooting

**Problem**: No waves detected
- **Solution**: Check that you have enough bars (swings need confirmation). ZigZag needs ATR-sized reversals. Try increasing ATR period or using fractal swings with smaller windows.

**Problem**: Too many invalidations
- **Solution**: Increase Fibonacci tolerance in `ElliottFibonacciValidator`. Real markets don't follow perfect ratios. 0.25-0.30 tolerance is often needed.

**Problem**: Channels not appearing
- **Solution**: Channels need at least 4 swings (2 rising, 2 falling). Ensure your swing indicator is detecting enough swings.

**Problem**: Phase stuck at WAVE1
- **Solution**: Wave 2 must retrace wave 1 within Fibonacci bounds. If your validator is too strict, waves won't progress. Check validator tolerance.

**Problem**: Confluence never triggers
- **Solution**: Lower the minimum score or adjust tolerances. Score of 2 requires both ratio AND channel alignment, which is rare. Consider using score of 1 for more signals.

## Related Documentation

- [Trendlines and Swing Points](Trendlines-and-Swing-Points.md) - Understanding the underlying swing detection
- [Technical Indicators](Technical-indicators.md) - General indicator usage patterns
- [Trading Strategies](Trading-strategies.md) - Building strategies with indicators
- [Charting](Charting.md) - Visualizing Elliott Wave analysis
>>>>>>> c93b32d (Update documentation to clarify data source usage and improve consistency across files. Adjusted references in Backtesting.md, Bar-series-and-bars.md, and Getting-started.md to align with recent naming conventions and enhance clarity on data ingestion methods.)
