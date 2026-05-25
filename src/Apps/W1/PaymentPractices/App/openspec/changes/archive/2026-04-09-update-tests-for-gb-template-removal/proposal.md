## Why

The `simplify-remove-gb-templates` change deleted 9 objects (T680, T681, T689, P690–693, C684, PaymentPracticeDefaultPeriods interface), removed the `Payment Period Code` field from the header, and reverted period data back to T685. The test codeunit and test library still reference all deleted objects, causing full compilation failure.

## What Changes

- **Delete 28 tests** that exercise removed functionality: GB CSV export (9 tests), Dispute & Retention data lifecycle (7), Payment Period Template management (10), card controls for deleted UI elements (2)
- **Fix 29 surviving tests** by updating library helpers that reference deleted objects (T680/T681 Payment Period Header/Line, T689 Dispute Ret. Data)
- **Rewrite test library** to remove helpers for deleted objects and update period initialization to use T685 `Payment Period.SetupDefaults()` instead of T680/T681 templates
- **Update test codeunit globals** — change `PaymentPeriods` array type from `Record "Payment Period Line"` to `Record "Payment Period"`, remove CSV helper procedures and labels

## Capabilities

### New Capabilities

- `test-cleanup`: Covers the deletion, repair, and library update of the Payment Practices test suite to align with the simplified app layer

### Modified Capabilities

## Impact

- `Test/src/PaymentPracticesUT.Codeunit.al` — 28 tests deleted, 29 tests fixed, helper procedures and vars removed
- `Test Library/src/PaymentPracticesLibrary.Codeunit.al` — ~16 procedures deleted or rewritten
- `Test/app.json` and `Test Library/app.json` — may need dependency updates if they reference deleted objects
- No impact on the App layer (already changed by `simplify-remove-gb-templates`)
