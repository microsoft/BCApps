## Context

The staged changes introduced a `Reporting Scheme` + `PaymentPracticeSchemeHandler` system that enriches the `Generate` flow. Two bugs emerged when this new system interacts with the existing `Company Size` aggregation path:

1. `PaymentPractices.Generate` validates `Payment Period Code` unconditionally — but the Size Aggregator never uses payment periods.
2. `Paym. Prac. Size Aggregator` was not updated to call `SchemeHandler.CalculateLineTotals`, so scheme-specific line fields (`Invoice Count`, `Invoice Value`) remain zero.

## Goals / Non-Goals

**Goals:**
- Company Size aggregation works for all three reporting schemes (Standard, Dispute & Retention, Small Business) without requiring a payment period code.
- Scheme-specific line totals are populated for Company Size lines, matching the behavior of the Period Aggregator.

**Non-Goals:**
- Changing the Company Size aggregator's grouping logic or adding new grouping dimensions.
- Addressing the semantic oddity of Small Business + Company Size (sub-grouping an already-filtered set). That combination is valid, just uncommon.

## Decisions

### Decision 1: Gate period code validation on Aggregation Type

In `PaymentPractices.Generate`, wrap the `Payment Period Code` check so it only fires when `Aggregation Type = Period`:

```
if (Header."Aggregation Type" = Period) and (Header."Payment Period Code" = '') then
    ValidatePaymentPeriodCode(...)
```

**Rationale:** The Size Aggregator iterates `CompanySize` records, not `PaymentPeriodLine` records. Requiring a period code blocks a valid code path. The alternative — always requiring a period code even for size aggregation — adds unnecessary setup for the user with no benefit.

### Decision 2: Call SchemeHandler.CalculateLineTotals in Size Aggregator

After inserting each Company Size line, call `SchemeHandler.CalculateLineTotals(PaymentPracticeLine, PaymentPracticeData)` and modify the line if counts were populated, mirroring the pattern already used in the Period Aggregator.

**Rationale:** The interface contract says `CalculateLineTotals` is called for every generated line. The Period Aggregator already does this. Keeping the Size Aggregator out of sync creates a gap visible when Small Business + Company Size is used.

The data filter context for `PaymentPracticeData` at the point of the call already has `"Company Size Code"` set, so the scheme handler receives the correctly scoped recordset.

## Risks / Trade-offs

- [Minimal risk] Standard and Dispute & Retention `CalculateLineTotals` are no-ops, so the extra call is harmless for those schemes — just a virtual dispatch with an empty body.
- [Low risk] For Small Business + Company Size, `Invoice Count` / `Invoice Value` reflect the intersection of "small business supplier" and a specific company size code. This is correct behavior but the resulting numbers may confuse users unfamiliar with the scheme's upstream filter. No mitigation needed — this is existing system semantics.
