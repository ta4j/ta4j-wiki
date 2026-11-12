# Perpetual Futures Live Trading

Use this page when recording venue-confirmed perpetual fills, fees and funding settlements for analysis and restart recovery.

Requires ta4j 0.28.1 or later. The APIs and [`PerpetualFuturesFillRecordingExample`](https://github.com/ta4j/ta4j/blob/350c19840962b8430c99d1c35895de146849b9fa/ta4j-examples/src/main/java/ta4jexamples/backtesting/PerpetualFuturesFillRecordingExample.java) are in the pending [recorded holding-costs PR](https://github.com/ta4j/ta4j/pull/1734), stacked on the [backtest examples PR](https://github.com/ta4j/ta4j/pull/1733). These are proposed additions, not APIs already available in a released version.

## 1) Ownership boundary

ta4j owns the recorded fills, matching policy, holding-cost allocation and analysis. Your adapter owns exchange authentication, order submission, contract metadata, collateral and liquidation, event ordering, deduplication, settlement-to-bar mapping, durable checkpoints and reconciliation. A strategy signal is not proof of a fill.

For a linear contract, convert venue contracts to base-asset amounts before recording. Express prices, fill fees and holding costs in a consistent quote currency. Inverse contracts require the reciprocal-price and quote-face-value representation described in [Backtesting](Perpetual-Futures-Backtesting.md#8-inverse-contracts); do not feed their native amounts into a linear record unchanged.

## 2) Create the record and record confirmed events

The complete `buildRecord` method in `PerpetualFuturesFillRecordingExample` records two entry lots, a partial close, a paid settlement, a received settlement and a final close:

```java
    static BaseTradingRecord buildRecord() {
        NumFactory nums = ANALYSIS_SERIES.numFactory();
        BaseTradingRecord record = new BaseTradingRecord(TradeType.BUY, ExecutionMatchPolicy.FIFO,
                RecordedTradeCostModel.INSTANCE, new ZeroCostModel(), null, null);

        // Two confirmed entry lots: two base units at 100 and one at 105.
        record.operate(new TradeFill(0, null, nums.numOf(100), nums.numOf(2), nums.numOf(2), ExecutionSide.BUY,
                "entry-1", "lot-1"));
        record.operate(new TradeFill(1, null, nums.numOf(105), nums.one(), nums.one(), ExecutionSide.BUY,
                "entry-2", "lot-2"));
        record.recordHoldingCost(3, nums.numOf(6)); // paid, allocated 4 and 2

        // Close half of the first lot; it carries half of that lot's funding.
        record.operate(new TradeFill(4, null, nums.numOf(110), nums.one(), nums.one(), ExecutionSide.SELL,
                "exit-1", null));
        record.recordHoldingCost(5, nums.numOf(-2)); // received, allocated to the remaining exposure
        record.operate(new TradeFill(6, null, nums.numOf(110), nums.numOf(2), nums.numOf(2), ExecutionSide.SELL,
                "exit-2", null));
        return record;
    }
```

`RecordedTradeCostModel` makes the actual fill fees affect net profit. `ZeroCostModel` disables modeled holding costs: the confirmed settlements supply those costs instead. Combining recorded settlements with `FundingCostModel` adds both, so use that combination only when they represent deliberately distinct charges.

The offline example has no venue timestamps. In your adapter, retain the real event timestamps and identifiers and map them consistently to the analysis series. An order can produce several fills; record executions rather than replacing them with the requested quantity.

## 3) Funding sign, allocation and indices

- Positive `recordHoldingCost(index, cost)` means paid; negative means received. Pass the total settlement for the exposure currently open in this record, not a rate or one amount per lot.
- Allocation is proportional to each open lot's remaining amount. A cost of 8 across amounts 1 and 3 becomes 2 and 6. A partial close of one third of a lot carrying 6 takes 2 to the closed position and leaves 4 with the remaining amount.
- Allocation uses the lots open **when the method is called**. The index determines when that recorded cost becomes visible to analysis; it does not reconstruct historical exposure. Apply events in venue order: an exit before a settlement already allocated to an open lot is rejected. Reconcile late corrections in your own ledger before replaying.
- Use the same settlement-to-bar convention on every run. The index cannot precede any currently open lot's entry. Unlike modeled periodic funding, an explicitly recorded cost at the entry index is included from that index.
- `Position.getHoldingCost(finalIndex)` includes recorded costs through that index; `getHoldingCost()` includes all applicable recorded costs. A closed position does not include costs after its exit. Use position-level accessors, not the record's configured holding model, to inspect allocated costs.
- Null and non-finite amounts are rejected. Use the same numeric type as every open lot (for example, `DecimalNum` costs for `DecimalNum` amounts); incompatible types are rejected before allocating any shares. Nonzero costs require open exposure; zero is a no-op. Other `TradingRecord` implementations may reject recording with `UnsupportedOperationException`.

A method call is additive and is not idempotent. Deduplicate venue settlement identifiers before applying them. Do not record the same aggregate settlement once for each lot.

## 4) Reconcile and evaluate

For the worked sequence above, gross trading profit is 25 quote units. Entry fees total 3 and exit fees total 3. The paid 6 and received 2 produce a net holding cost of 4, leaving net profit of 15.

Reconcile each component independently with the venue statement: quantities, entry and exit prices, actual fees, paid and received funding, and currency conversions. A matching final balance alone can hide offsetting mistakes. Rounding belongs at the venue's documented currency/contract boundary, not in each allocation share.

The example's `main` uses `GrossProfitLossCriterion`, `TotalFeesCriterion`, `Position.getHoldingCost` and `NetProfitLossCriterion`. With real analysis bars, use the same net-profit, return-on-capital and drawdown criteria as the backtest. Keep committed capital in the P&L currency. Capital plus `CumulativePnL` is an equity series; price-ratio return criteria do not measure leveraged return on margin.

## 5) Persistence and restarts

`BaseTradingRecord` serializes indexed recorded holding-cost shares alongside its lots and closed positions. Existing streams without those fields deserialize with no recorded costs. Cost models are transient: after deserialization call the existing `rehydrate` overload with `RecordedTradeCostModel.INSTANCE` and the intended modeled holding cost (`ZeroCostModel` for this example) before evaluating profit or resuming analysis.

Atomically commit the record together with its applied-event deduplication state and venue checkpoint. Saving them separately can either apply a charge twice or skip it after a crash.

If your storage cannot commit them atomically, keep an append-only event log keyed by unique venue identifiers and publish an immutable record snapshot plus its log checkpoint as one generation. The checkpoint must mark a contiguous, fully applied log prefix, and the snapshot must contain exactly that prefix—not merely everything applied through the most recent venue identifier. If venue-order processing leaves gaps in arrival-log order, buffer events or delay publication until those gaps are applied; never advance the checkpoint past an unapplied entry. Restart from the last completely published generation and replay entries after its checkpoint once, in venue order.

Preserve the same bar-index mapping and matching policy. Load Java serialization only from trusted storage. After restart, reconcile open quantities and outstanding venue events before resuming order submission.

## 6) Troubleshooting

| Symptom | Check |
| --- | --- |
| Net profit ignores fill fees | Construct or rehydrate with `RecordedTradeCostModel` |
| Funding appears twice | Remove duplicate event application or an unintended modeled funding charge |
| A received settlement reduces profit | Pass a negative holding cost |
| Earlier bars include later funding | Check the settlement index and use indexed position/curve evaluation |
| Recording rejects an index | It must not precede any currently open lot's entry |
| Recording rejects a nonzero cost | Confirm exposure is still open and events are applied in venue order |
| Results change after restart | Restore cost models, index mapping and the durable event checkpoint |
| Adapter cannot explain a liquidation | ta4j does not infer venue liquidation or margin-account events |

## Related pages

- [Perpetual futures](Perpetual-Futures.md)
- [Backtesting](Perpetual-Futures-Backtesting.md)
- [Cookbook](Perpetual-Futures-Cookbook.md)
- [Live trading](Live-trading.md)
- [Live trading runbook](Live-Trading-Runbook.md)
- [Analysis criteria and risk metrics](Analysis-Criteria-and-Risk-Metrics.md)
