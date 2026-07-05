# Live Candle vs Closed Candle Evaluation

This page explains one of the most common first live-trading pitfalls in ta4j: repeated buys (or sells) while the same candle is still open.

## Short answer

- ta4j evaluates the data that currently exists in your `BarSeries`.
- ta4j does **not** enforce "closed candles only."
- If you replace the last bar while it is still forming, you are evaluating a **live candle**.
- If you evaluate only after appending a completed bar, you are evaluating a **closed candle**.

## Why repeated entries happen

Repeated entries usually come from one or more integration issues:

1. Calling `strategy.shouldEnter(index)` instead of `strategy.shouldEnter(index, tradingRecord)`
2. Placing exchange orders but not recording confirmed fills in `tradingRecord`
3. Evaluating many times on the same live bar without a de-duplication guard

When this happens, ta4j can keep seeing the entry rule as true and still think no position is open.

## Closed-candle mode (simple and stable)

Use this mode if you want less noise and one decision per completed bar:

- append only finished bars
- evaluate once per new closed bar
- pass `tradingRecord` into `shouldEnter`/`shouldExit`

```java
int index = series.getEndIndex(); // latest closed bar
if (strategy.shouldEnter(index, tradingRecord)) {
    submitBuyOrder();
}
```

## Live-candle mode (faster but needs safeguards)

Use this mode if you want intra-candle reactions:

- replace/update the last bar as ticks arrive
- evaluate on each update
- always pass `tradingRecord`
- add de-duplication protection

```java
int lastEntryBarIndex = -1;
while (true) {
    int index = series.getEndIndex();
    if (strategy.shouldEnter(index, tradingRecord) && index != lastEntryBarIndex) {
        submitBuyOrder();
        lastEntryBarIndex = index;
    }
}
```

## Fill synchronization rule

This is critical:

- Strategy signal = "should I attempt an order?"
- Trading record = "what actually filled?"

After your exchange confirms execution, write it into ta4j (`enter/exit` or `operate(fill)`), so strategy state and broker state stay aligned.

```java
if (strategy.shouldEnter(index, tradingRecord)) {
    ExchangeOrder order = submitBuyOrder();
    if (order.isFilled()) {
        tradingRecord.enter(index, fillPrice, fillAmount);
    }
}
```

If your venue gives partial fills, use `TradingRecord.operate(fill)` as fills arrive.

## Practical checklist before going live

- Use `shouldEnter(index, tradingRecord)` and `shouldExit(index, tradingRecord)`
- Decide explicitly: closed-candle mode or live-candle mode
- If live-candle mode: enforce one-entry-per-bar-index or equivalent idempotency key
- Update ta4j record only from confirmed fills
- Reconcile ta4j state with exchange state after restart

## Related pages

- [Live Trading](Live-trading.md)
- [Live Trading Runbook](Live-Trading-Runbook.md)
- [Troubleshooting Hub](Troubleshooting-Hub.md)
