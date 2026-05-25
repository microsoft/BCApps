## Why

The staged changes introduced a `Payment Period Code` validation in `Generate` that fires regardless of `Aggregation Type`. This blocks the Company Size aggregation path, which never uses payment periods. Additionally, the Size Aggregator does not call `SchemeHandler.CalculateLineTotals`, so `Invoice Count` and `Invoice Value` remain zero when using Small Business + Company Size — producing empty columns on the Lines page.

## What Changes

- Gate the `Payment Period Code` validation in `PaymentPractices.Generate` so it only fires when `Aggregation Type = Period`.
- Add a `SchemeHandler.CalculateLineTotals` call to `Paym. Prac. Size Aggregator.GenerateLines` so scheme-specific line totals are populated for all aggregation types.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `reporting-scheme`: The Generate flow must skip payment-period validation when aggregation type is Company Size.
- `small-business-handler`: `CalculateLineTotals` must be invoked for Company Size lines so `Invoice Count` / `Invoice Value` are populated.

## Impact

- `PaymentPractices.Codeunit.al` — conditional gate on period code check.
- `PaymPracSizeAggregator.Codeunit.al` — call `CalculateLineTotals` after inserting each line.
