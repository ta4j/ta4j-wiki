# Backtesting Realism Checklist

Use this checklist before trusting a strategy leaderboard.

## 1) Data realism

- [ ] Data source, symbol mapping, and timeframe are explicit
- [ ] Timezone/session boundaries are consistent with target venue
- [ ] Missing bars and duplicates are detected and handled deterministically
- [ ] Corporate actions or symbol regime shifts are accounted for when applicable

## 2) Indicator and warmup correctness

- [ ] Indicator warmup is enforced with `strategy.setUnstableBars(...)`
- [ ] No indicator reads future data (look-ahead)
- [ ] Moving-window truncation effects (`setMaximumBarCount`) are understood

## 3) Execution realism

- [ ] Execution model (`next-open`, `current-close`, slippage, stop-limit) matches intended simulation
- [ ] Fee and holding cost models reflect expected market conditions
- [ ] Order-sizing assumptions are explicit and reproducible
- [ ] Partial-fill semantics are tested if they matter for deployment

## 4) Evaluation discipline

- [ ] At least one return metric and one risk metric are used
- [ ] Rankings are justified (single criterion vs weighted criteria)
- [ ] Sensitivity to small parameter changes is inspected
- [ ] Baseline comparisons exist (for example, buy-and-hold or simpler strategy)

## 5) Out-of-sample robustness

- [ ] Validation includes holdout or walk-forward periods
- [ ] Hyperparameter tuning avoids leakage between train and test segments
- [ ] Candidate promotion criteria are stable across market regimes

## 6) Reproducibility

- [ ] Input data range and source are documented
- [ ] Strategy parameters and execution assumptions are versioned
- [ ] Backtest commands are recorded and rerunnable
- [ ] Major metric outputs are captured for regression comparisons

## Recommended companion docs

- [Backtesting](Backtesting.md)
- [Walk-Forward Research](Walk-Forward-Research.md)
- [Analysis Criteria and Risk Metrics](Analysis-Criteria-and-Risk-Metrics.md)
- [Troubleshooting Hub](Troubleshooting-Hub.md)
