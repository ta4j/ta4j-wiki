# Troubleshooting Hub

This hub centralizes common ta4j issues for production-minded users.

## Fast triage matrix

| Symptom | Likely cause | First place to check |
| --- | --- | --- |
| Indicator output does not match external charting tool | Warmup or initialization differences; data-length dependence | [FAQ](FAQ.md), [Technical Indicators](Technical-indicators.md) |
| Strategy behaves differently in live vs backtest | Execution assumptions differ (fill timing, partial fills, costs) | [Backtesting](Backtesting.md), [Live Trading](Live-trading.md) |
| Unrealized/open-position numbers look wrong | Trade recording mismatch or lot policy misunderstanding | [Live Trading](Live-trading.md), [Live Trading Runbook](Live-Trading-Runbook.md) |
| Results change after enabling moving windows | Historical bars evicted by `setMaximumBarCount` | [Bar Series and Bars](Bar-series-and-bars.md) |
| Noisy or unstable leaderboard across reruns | Overfitting, weak validation geometry, or non-deterministic data pipeline | [Walk-Forward Research](Walk-Forward-Research.md), [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md) |
| Charting fails in CI/headless environment | GUI rendering unavailable | [Charting](Charting.md) |

## Deep-dive troubleshooting paths

### Data and series issues

- Validate symbol, interval, and timezone alignment
- Check for gaps, duplicated bars, and late bars
- Confirm deterministic reconstruction of the same bar range

Read:

- [Data Sources](Data-Sources.md)
- [Bar Series and Bars](Bar-series-and-bars.md)

### Indicator and strategy issues

- Validate unstable/warmup bars
- Confirm no accidental future-data usage in custom indicators/rules
- Compare component values step by step before testing composed strategy behavior

Read:

- [Technical Indicators](Technical-indicators.md)
- [Trading Strategies](Trading-strategies.md)
- [FAQ](FAQ.md)

### Execution and trading-record issues

- Distinguish order intent from confirmed fills
- Verify `ExecutionMatchPolicy` behavior for partial exits
- Reconcile local record state with broker/account state after failures

Read:

- [Backtesting](Backtesting.md)
- [Live Trading](Live-trading.md)
- [Live Trading Runbook](Live-Trading-Runbook.md)

### Evaluation and model-quality issues

- Confirm metric set includes both return and risk
- Audit train/test split and walk-forward design
- Validate strategy ranking logic and weighting assumptions

Read:

- [Analysis Criteria and Risk Metrics](Analysis-Criteria-and-Risk-Metrics.md)
- [Walk-Forward Research](Walk-Forward-Research.md)
- [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md)

## Escalation checklist

Before opening an issue:

1. Capture exact dataset source, symbol, and date range
2. Capture strategy parameters and execution model
3. Include reproducible command and expected vs actual behavior
4. Include logs or chart snapshots that isolate the discrepancy
