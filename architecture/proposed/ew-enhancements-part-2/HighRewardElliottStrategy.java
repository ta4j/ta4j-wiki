package ta4jexamples.strategies;

import org.ta4j.core.*;
import org.ta4j.core.analysis.elliottwave.ElliottWaveAnalyzer;
import org.ta4j.core.analysis.elliottwave.ElliottAnalysisResult;
import org.ta4j.core.analysis.elliottwave.phase.ElliottPhase;
import org.ta4j.core.analysis.elliottwave.scenario.ElliottScenario;
import org.ta4j.core.analysis.elliottwave.swing.SwingDetectors;
import org.ta4j.core.analysis.elliottwave.compression.CompressionProfiles;
import org.ta4j.core.analysis.elliottwave.confidence.ConfidenceProfiles;
import org.ta4j.core.analysis.elliottwave.scenario.PatternSet;
import org.ta4j.core.analysis.elliottwave.scenario.ScenarioType;
import org.ta4j.core.num.Num;
import org.ta4j.core.indicators.helpers.ClosePriceIndicator;
import org.ta4j.core.indicators.RSIIndicator;
import org.ta4j.core.indicators.MACDIndicator;
import org.ta4j.core.indicators.SMAIndicator;
import org.ta4j.core.trading.rules.*;

/**
 * A strategy that trades only high‑confidence Elliott Wave impulses with
 * favourable risk‑reward.  This example assumes availability of new
 * ElliottWaveAnalyzer API as described in the feature/ew‑analysis‑improvements PRD.
 */
public class HighRewardElliottStrategy {

    public static NamedStrategy build(BarSeries series) {
        // Set up adaptive swing detector (ATR‑driven) and fractal confirmation
        var adaptiveDetector = SwingDetectors.adaptiveZigZagSwingDetector(builder ->
            builder.atrPeriod(14)
                   .minThreshold(0.03)
                   .maxThreshold(0.08)
        );
        var fractalDetector = SwingDetectors.fractalSwingDetector(5);
        var swingDetector = SwingDetectors.composite(adaptiveDetector, fractalDetector);

        // Compress swings to primary degree
        var compressionProfile = CompressionProfiles.primaryDegree();

        // Generate only impulse scenarios
        var patternSet = PatternSet.only(ScenarioType.IMPULSE);

        // Custom confidence weights for impulses
        var confidenceModel = ConfidenceProfiles.defaultByScenarioType()
            .withWeight(ScenarioType.IMPULSE, weights -> {
                weights.setFibonacciWeight(0.40);
                weights.setTimeProportionWeight(0.20);
                weights.setAlternationWeight(0.20);
                weights.setChannelWeight(0.10);
                weights.setCompletenessWeight(0.10);
            });

        var analyzer = ElliottWaveAnalyzer.builder()
            .swingDetector(swingDetector)
            .swingCompression(compressionProfile)
            .patternSet(patternSet)
            .confidenceModel(confidenceModel)
            .build();

        // Additional indicators
        ClosePriceIndicator close = new ClosePriceIndicator(series);
        SMAIndicator sma200 = new SMAIndicator(close, 200);
        RSIIndicator rsi14 = new RSIIndicator(close, 14);
        MACDIndicator macd = new MACDIndicator(close, 12, 26);

        // Trend filter: price above 200‑SMA
        Rule trendRule = new OverIndicatorRule(close, sma200);

        // Momentum confirmation: RSI > 50 and MACD > 0
        Rule momentumRule = new OverThresholdRule(rsi14, 50).and(new OverIndicatorRule(macd, series.numOf(0)));

        // Impulse and risk/reward rule
        Rule impulseRule = new AbstractRule() {
            @Override
            public boolean isSatisfied(int index, TradingRecord record) {
                ElliottAnalysisResult result = analyzer.analyze(series.subseries(0, index + 1));
                ElliottScenario base = result.scenarios().base();
                if (base == null || base.type() != ScenarioType.IMPULSE) return false;
                ElliottPhase phase = base.currentPhase();
                if (!(phase == ElliottPhase.WAVE3 || phase == ElliottPhase.WAVE5)) return false;
                if (!base.isHighConfidence() || !result.scenarioSummary().hasStrongConsensus()) return false;
                Num closePrice = close.getValue(index);
                Num invalidation = base.invalidationPrice();
                Num target = base.primaryTarget();
                if (closePrice.isLessThanOrEqual(invalidation) || closePrice.isGreaterThanOrEqual(target)) return false;
                Num risk = closePrice.minus(invalidation);
                Num reward = target.minus(closePrice);
                if (risk.isLessThanOrEqual(series.numOf(0))) return false;
                Num rr = reward.dividedBy(risk);
                return rr.isGreaterThanOrEqual(series.numOf(3));
            }
        };

        // Entry rule combines trend, momentum and impulse
        Rule entryRule = trendRule.and(momentumRule).and(impulseRule);

        // Exit rule triggers on scenario completion/invalidity or momentum reversal
        Rule exitRule = new AbstractRule() {
            @Override
            public boolean isSatisfied(int index, TradingRecord record) {
                if (!record.isOpened()) return false;
                ElliottAnalysisResult result = analyzer.analyze(series.subseries(0, index + 1));
                ElliottScenario base = result.scenarios().base();
                if (base == null) return false;
                Num closePrice = close.getValue(index);
                if (base.expectsCompletion() || base.isInvalidated()) return true;
                if (closePrice.isLessThanOrEqual(base.invalidationPrice())) return true;
                if (!momentumRule.isSatisfied(index)) return true;
                return false;
            }
        };

        Strategy strategy = new BaseStrategy(entryRule, exitRule);
        return new NamedStrategy("High‑Reward Elliott Wave Strategy", strategy);
    }
}
