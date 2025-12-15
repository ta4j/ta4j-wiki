# Elliott Wave Indicators

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

- **ElliottDegree**: Enumeration of wave degrees (Grand Supercycle through Sub-Minuette) with navigation methods (`higherDegree()`, `lowerDegree()`)
- **ElliottSwing**: Immutable record representing a single swing between two pivots
- **ElliottPhase**: Enumeration of wave phases (WAVE1-5, CORRECTIVE_A-C, NONE) with helper methods (`isImpulse()`, `isCorrective()`, `completesStructure()`)
- **ElliottRatio**: Record containing ratio value, type, and `isValid()` helper
- **ElliottChannel**: Record with `upper()`, `lower()`, `median()`, `width()`, `isValid()`, and `contains()` methods
- **ElliottSwingCompressor**: Utility for filtering/compressing swing sequences
- **ElliottFibonacciValidator**: Validates Fibonacci relationships between waves
- **ElliottSwingMetadata**: Helper for slicing and analyzing swing windows

### Advanced Indicators

- **ElliottConfluenceIndicator**: Measures confluence of multiple Elliott Wave signals
- **ElliottChannelIndicator**: Projects price channels based on Elliott Wave structure
- **ElliottInvalidationIndicator**: Signals when wave structure is invalidated

### Factory Class

- **ElliottWaveFacade**: Facade that creates and coordinates a complete set of Elliott Wave indicators from a single configuration, with lazy initialization and shared swing detection

---

## Getting Started

### Using ElliottWaveFacade (Recommended)

The simplest way to get started is with the `ElliottWaveFacade` facade, which creates and coordinates all Elliott Wave indicators:

```java
BarSeries series = // your bar series (minimum ~60 bars recommended for window=5; ~50 bars for window=3)

// Create a complete Elliott Wave analysis facade
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);

// Access any indicator through the facade
int index = series.getEndIndex();
ElliottPhase phase = facade.phase().getValue(index);
ElliottRatio ratio = facade.ratio().getValue(index);
ElliottChannel channel = facade.channel().getValue(index);

// Check for confluence
if (facade.confluence().isConfluent(index)) {
    System.out.println("Strong Elliott Wave confluence detected");
}
```

### Basic Setup (Manual)

For more control, create indicators individually:

```java
BarSeries series = // your bar series (minimum ~50 bars for meaningful analysis)

// Create swing indicator with 3-bar fractal windows
// Note: A window of N bars requires 2N+1 bars to confirm a pivot
ElliottSwingIndicator swings = new ElliottSwingIndicator(
    series, 
    3,  // lookback/lookforward window
    ElliottDegree.INTERMEDIATE  // wave degree
);

// Get swings at current index
int currentIndex = series.getEndIndex();
List<ElliottSwing> swingList = swings.getValue(currentIndex);
```

### Using ZigZag Swings

For adaptive swing detection based on volatility:

```java
// ZigZag with ATR(14) reversal threshold - adapts to market volatility
ElliottWaveFacade facade = ElliottWaveFacade.zigZag(series, ElliottDegree.INTERMEDIATE);

// Or create just the swing indicator
ElliottSwingIndicator swings = ElliottSwingIndicator.zigZag(
    series, 
    ElliottDegree.INTERMEDIATE
);
```

### Basic Wave Phase Detection

```java
// Use a window size appropriate for your data frequency
// Daily data: 3-5 bars; Weekly: 2-3 bars; Intraday: 5-10 bars
ElliottSwingIndicator swings = new ElliottSwingIndicator(series, 3, ElliottDegree.INTERMEDIATE);
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
ElliottSwingIndicator swings = new ElliottSwingIndicator(series, 3, ElliottDegree.INTERMEDIATE);
ElliottRatioIndicator ratios = new ElliottRatioIndicator(swings);

int index = series.getEndIndex();
ElliottRatio ratio = ratios.getValue(index);

// Always check validity before using the ratio
if (ratio.isValid()) {
    if (ratio.type() == RatioType.RETRACEMENT) {
        System.out.println("Retracement ratio: " + ratio.value());
    } else if (ratio.type() == RatioType.EXTENSION) {
        System.out.println("Extension ratio: " + ratio.value());
    }
}

// Check if near a Fibonacci level (e.g., 0.618)
Num target = series.numFactory().numOf(0.618);
Num tolerance = series.numFactory().numOf(0.05);
if (ratios.isNearLevel(index, target, tolerance)) {
    System.out.println("Near 61.8% retracement level");
}
```

---

## Intermediate Usage Patterns

### Multi-Degree Analysis

Analyze multiple timeframes simultaneously:

```java
// Primary trend (longer timeframe) - use larger window for bigger waves
ElliottSwingIndicator primarySwings = new ElliottSwingIndicator(series, 10, ElliottDegree.PRIMARY);
ElliottPhaseIndicator primaryPhase = new ElliottPhaseIndicator(primarySwings);

// Intermediate trend (shorter timeframe) - smaller window for finer detail
ElliottSwingIndicator intermediateSwings = new ElliottSwingIndicator(series, 3, ElliottDegree.INTERMEDIATE);
ElliottPhaseIndicator intermediatePhase = new ElliottPhaseIndicator(intermediateSwings);

// Use both for context
int index = series.getEndIndex();
ElliottPhase primary = primaryPhase.getValue(index);
ElliottPhase intermediate = intermediatePhase.getValue(index);

// Trade in direction of primary trend, using intermediate for timing
if (primary.isImpulse() && intermediate.isCorrective()) {
    // Potential entry during intermediate correction in primary impulse
}

// Use ElliottDegree navigation for degree relationships
ElliottDegree degree = ElliottDegree.INTERMEDIATE;
ElliottDegree higherDegree = degree.higherDegree();  // Returns PRIMARY
ElliottDegree lowerDegree = degree.lowerDegree();    // Returns MINOR

// Check degree relationships
if (degree.isHigherOrEqual(ElliottDegree.MINOR)) {
    // This degree is significant enough for swing trading
}
```

### Custom Swing Detection

Use custom price sources or swing detectors:

```java
// Use close prices instead of high/low for smoother swings
ClosePriceIndicator close = new ClosePriceIndicator(series);
ElliottSwingIndicator swings = new ElliottSwingIndicator(
    close, 
    3,  // lookback
    3,  // lookforward
    ElliottDegree.INTERMEDIATE
);

// Or use existing swing indicators for full control
RecentSwingIndicator customHighs = // your custom high detector
RecentSwingIndicator customLows = // your custom low detector
ElliottSwingIndicator customSwings = new ElliottSwingIndicator(
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
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);
ElliottRatioIndicator ratios = facade.ratio();
NumFactory nf = series.numFactory();

int index = series.getEndIndex();
ElliottRatio ratio = ratios.getValue(index);

// Common Fibonacci retracement levels
Num fib236 = nf.numOf(0.236);
Num fib382 = nf.numOf(0.382);
Num fib500 = nf.numOf(0.500);
Num fib618 = nf.numOf(0.618);
Num fib786 = nf.numOf(0.786);
Num tolerance = nf.numOf(0.02); // 2% tolerance

if (ratio.isValid() && ratio.type() == RatioType.RETRACEMENT) {
    if (ratios.isNearLevel(index, fib618, tolerance)) {
        // Strong support/resistance at 61.8% retracement
    } else if (ratios.isNearLevel(index, fib382, tolerance)) {
        // Moderate retracement at 38.2%
    }
}
```

### Swing Compression

Filter swings before analysis to remove noise:

```java
// Create a compressor that filters out small swings
Num minimumAmplitude = series.numFactory().numOf(5.0);  // Minimum price move
int minimumLength = 2;  // Minimum bars between pivots
ElliottSwingCompressor compressor = new ElliottSwingCompressor(minimumAmplitude, minimumLength);

// Use compressor with wave count indicator
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
// ElliottWaveFacade provides coordinated indicators with shared swing source
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);

int index = series.getEndIndex();
Num confluenceScore = facade.confluence().getValue(index);

// Check if confluence meets minimum threshold (default is 2)
if (facade.confluence().isConfluent(index)) {
    // Strong confluence - high confidence signal
    System.out.println("Confluence score: " + confluenceScore);
}

// Or create manually with custom configuration
ClosePriceIndicator close = new ClosePriceIndicator(series);
ElliottRatioIndicator ratios = new ElliottRatioIndicator(swings);
ElliottChannelIndicator channels = new ElliottChannelIndicator(swings);

ElliottConfluenceIndicator confluence = new ElliottConfluenceIndicator(
    close, 
    ratios,
    channels
);
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
    Num width = channelData.width();  // Distance between upper and lower
    
    // Check if current price is within channel
    Num currentPrice = close.getValue(index);
    Num tolerance = series.numFactory().numOf(0.01); // 1% tolerance
    if (channelData.contains(currentPrice, tolerance)) {
        // Price is within projected channel
    }
    
    // Use channel width for position sizing or stop placement
    System.out.println("Channel width: " + width);
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

1. **Check for Valid Data**: Use `isValid()` methods on data classes like `ElliottRatio` and `ElliottChannel`
2. **Use Num.isFinite()**: The `Num.isFinite(value)` utility checks if a numeric value is non-null and not NaN
3. **Sufficient Swings**: Ensure enough swings exist for your analysis (typically 5+ for impulses)
4. **Edge Cases**: Handle cases where swings are still forming or structure is ambiguous

```java
// Example: Safe value access pattern
ElliottRatio ratio = ratios.getValue(index);
if (ratio.isValid()) {
    // Safe to use ratio.value()
}

ElliottChannel channel = channels.getValue(index);
if (channel.isValid()) {
    // Safe to use channel bounds
    Num width = channel.width();
}

// For general Num values
Num value = someIndicator.getValue(index);
if (Num.isFinite(value)) {
    // Safe to use the value
}
```

### Integration with Other Indicators

- **Trend Confirmation**: Combine with moving averages or trend indicators
- **Momentum**: Use RSI or MACD to confirm wave direction
- **Volume**: Volume should expand in impulse waves, contract in corrections
- **Support/Resistance**: Align Elliott Wave targets with traditional S/R levels

---

## Integration with Trading Strategies

### Basic Elliott Wave Rule

```java
// Use ElliottWaveFacade for simplified setup
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);
ElliottPhaseIndicator phase = facade.phase();

// Enter long at start of Wave 3 (strongest impulse wave)
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
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);
ElliottRatioIndicator ratios = facade.ratio();
Num fib618 = series.numFactory().numOf(0.618);
Num tolerance = series.numFactory().numOf(0.02);

Rule entryRule = new Rule() {
    @Override
    public boolean isSatisfied(int index, TradingRecord tradingRecord) {
        ElliottRatio ratio = ratios.getValue(index);
        return ratio.isValid() 
            && ratio.type() == RatioType.RETRACEMENT 
            && ratios.isNearLevel(index, fib618, tolerance);
    }
};
```

### Multi-Factor Strategy

```java
// Combine Elliott Wave with other indicators
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);
ElliottPhaseIndicator phase = facade.phase();
ClosePriceIndicator close = new ClosePriceIndicator(series);
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
    new UnderIndicatorRule(rsi, series.numFactory().numOf(70)),
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

ta4j's Elliott Wave indicators provide a powerful toolkit for wave-based technical analysis. The recommended approach is to use `ElliottWaveFacade` for easy setup:

```java
// Quick start with ElliottWaveFacade
ElliottWaveFacade facade = ElliottWaveFacade.fractal(series, 5, ElliottDegree.INTERMEDIATE);

// Access all indicators through the facade
ElliottPhase phase = facade.phase().getValue(index);
boolean isConfluent = facade.confluence().isConfluent(index);
boolean isInvalidated = facade.invalidation().getValue(index);
```

Start with basic swing detection and phase identification, then gradually incorporate ratio analysis, confluence, and advanced features as you become more comfortable with the system. Remember that Elliott Wave analysis is as much art as science—use the indicators as tools to support your analysis, not as absolute truth.

The modular design allows you to build custom workflows that match your trading style, whether you're a pure Elliott Wave trader or combining waves with other technical indicators. All data classes provide `isValid()` methods to ensure safe value access, and the `Num.isFinite()` utility helps with general numeric validation.

