## Why

Commit `260ce28` contains the full W1 + GB + AU prototype on branch `features/629871-master-Payment-Practices-W1-GB-Simple`. The AU portion (Small Business scheme) will be implemented by a colleague using their own coding style on a separate `au-prototype` branch forked from that commit. The W1/GB branch must be stripped of all AU-specific runtime objects — the handler, CSV export, declaration report, vendor extension, and vendor card extension — while retaining the shared W1 infrastructure (enum value 2, CalculateLineTotals calls, Invoice Count/Value fields) so the colleague has minimal files to touch when re-adding AU.

## What Changes

- **Delete** 5 pure-AU files: C682 handler (real implementation), C694 AU CSV export, R680 AU declaration report + Word layout, TE680 Vendor table extension, PE680 Vendor Card page extension
- **Replace** C682 with a stub pass-through handler (empty methods, same pattern as C680 Standard Handler) so enum value 2 "Small Business" compiles
- **Remove** `ExportAUCSV` action and its promoted reference from Payment Practice Card (references deleted C694)
- **Remove** AU/NZ entries from permission set (R680, C694)
- **Remove** `InsertDefaultPeriods_AUNZ()` method and its `'AU','NZ'` case from `PaymentPeriod.SetupDefaults()`
- **Remove** `'AU','NZ'` case from `PaymentPeriodMgt.DetectReportingScheme()` (falls to `else → Standard`)
- **Remove** 4 AU-specific tests from test codeunit and `CreateSmallBusinessVendor()` from test library

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `small-business-handler`: Handler becomes a stub (all 4 methods are empty pass-throughs). Vendor extension and CSV export removed. Enum value 2 retained for compilation.
- `au-csv-export`: Entire capability removed (C694 deleted, ExportAUCSV action removed from card).
- `reporting-scheme`: `DetectReportingScheme()` no longer returns `"Small Business"` for AU/NZ — falls to Standard. Enum value 2 still exists but dispatches to a no-op stub.
- `test-cleanup`: Remove 4 AU-specific tests and 1 AU test helper.

## Impact

- **App layer**: 5 files deleted, 1 file stubbed, 4 files edited (PaymentPeriodMgt, PaymentPeriod table, PaymentPracticeCard page, PermissionSet)
- **Test layer**: 2 files edited (PaymentPracticesUT, PaymentPracticesLibrary)
- **Colleague's AU branch**: Starts from commit `260ce28` which has the full working AU code. Colleague rebuilds from the au-complete spec, touching ~7 files instead of ~14 (because CalculateLineTotals infrastructure stays in W1)
- **No BaseApp changes** — all edits are within the PaymentPractices extension
