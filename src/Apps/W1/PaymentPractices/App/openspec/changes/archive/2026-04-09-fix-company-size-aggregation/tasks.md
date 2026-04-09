## 1. Gate Payment Period Code validation

- [x] 1.1 In `PaymentPractices.Codeunit.al`, wrap the `Payment Period Code` check in `Generate` with an `Aggregation Type = Period` condition so Company Size aggregation skips it

## 2. Add CalculateLineTotals to Size Aggregator

- [x] 2.1 In `PaymPracSizeAggregator.Codeunit.al`, resolve `SchemeHandler` from `PaymentPracticeHeader."Reporting Scheme"` and call `SchemeHandler.CalculateLineTotals(PaymentPracticeLine, PaymentPracticeData)` after inserting each Company Size line; modify the line if `Invoice Count <> 0` or `Invoice Value <> 0`
