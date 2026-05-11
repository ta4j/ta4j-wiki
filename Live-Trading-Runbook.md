# Live Trading Runbook

This runbook documents the minimum production operating model for ta4j-based live systems.

## Scope and ownership

ta4j provides:

- `BarSeries` and `ConcurrentBarSeries` for market state
- indicators, rules, and strategy evaluation
- `BaseTradingRecord` for position/fill state and downstream analytics

Your system still owns:

- market-data ingestion and historical backfill
- order routing and retries
- reconciliation against broker account state
- persistence, recovery, and alerting

## Standard control loop

1. Ingest bars/trades into series
2. Evaluate strategy on close (or your chosen deterministic checkpoint)
3. Emit order intent
4. Update trading record from broker-confirmed fills
5. Publish metrics and risk snapshots

Reference docs:

- [Live Trading](Live-trading.md)
- [Bar Series and Bars](Bar-series-and-bars.md)
- [Canonical User Journey](Canonical-User-Journey.md)

## Startup checklist

- Load latest strategy configuration
- Rebuild or load the latest `BarSeries` snapshot
- Load persisted `TradingRecord` snapshot and broker mapping keys (`orderId`, `correlationId`)
- Reconcile open orders/positions with broker before evaluating new signals
- Verify clock skew and trading session boundaries
- Confirm alerting and logging pipeline health

## Runtime controls

### Data integrity

- Alert when expected bars are missing or delayed
- Track duplicate/late bars and apply deterministic handling
- Detect timezone or session-boundary drift

### Execution integrity

- Never treat an order intent as a fill
- Only mutate `TradingRecord` from confirmed fills (`operate(fill)` or `operate(Trade.fromFills(...))`)
- Track reject/cancel/partial-fill rates per venue and symbol

### Risk integrity

- Maintain max position and max notional safeguards outside strategy logic
- Apply emergency kill-switch conditions (connectivity, stale feed, repeated rejects)
- Keep bounded exposure during reconnect/recovery periods

## Persistence model

Persist at minimum:

- latest processed market timestamp/index
- latest strategy descriptor/config hash
- `TradingRecord` snapshot (including fill metadata and fees)
- broker-side IDs needed for idempotent recovery

Persist before marking events as durable in downstream systems.

## Recovery and reconciliation procedure

1. Pause new strategy-triggered submissions
2. Reload series and trading record from durable state
3. Fetch broker open positions and open orders
4. Reconcile differences:
   - missing local fills -> backfill into `TradingRecord`
   - unknown broker orders -> quarantine and investigate
5. Recompute open-position metrics (`getCurrentPosition`, `getOpenPositions`)
6. Resume signal evaluation only after state convergence

## Incident playbook

### Stale or missing bars

- Quarantine strategy decisions for affected symbols
- Backfill bars from a trusted source
- Re-evaluate pending signals if policy requires

### Repeated order rejects

- Disable affected strategy routes
- Capture reject payloads and classify root cause
- Resume only after routing/risk-policy correction

### Divergent position state (local vs broker)

- Stop automated exits/entries
- Force reconciliation cycle
- Re-enable automation after explicit state match

## Observability minimum

Track and alert on:

- bar lag and ingestion gap counts
- strategy signal count vs confirmed fill count
- rejected/cancelled/expired order rates
- reconciliation mismatch count
- unrealized and realized PnL deltas

## References

- [Troubleshooting Hub](Troubleshooting-Hub.md)
- [Backtesting Realism Checklist](Backtesting-Realism-Checklist.md)
- [Usage Examples](Usage-examples.md#bots--live-trading)
