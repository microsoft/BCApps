## Context

The `simplify-remove-gb-templates` change removed 9 AL objects from the App layer: tables T680 (Payment Period Header), T681 (Payment Period Line), T689 (Paym. Prac. Dispute Ret. Data); pages P690–P693; codeunit C684 (GB CSV Export); and the PaymentPracticeDefaultPeriods interface. It also removed the `Payment Period Code` field from T687 (Payment Practice Header) and reverted period storage to T685 (Payment Period) with its `SetupDefaults()` method.

The test codeunit (134197) and test library (134196) still reference all deleted objects. Every test fails at compile time because:
- The test library creates D&R data records (T689) on every header insert
- The test library reads Payment Period Header/Line (T680/T681) for period initialization
- The test library calls `PaymentPeriodMgt.InsertDefaultTemplate()` which no longer exists
- 28 tests directly exercise deleted functionality (GB CSV export, D&R data lifecycle, template management)
- The test codeunit declares `PaymentPeriods: array[3] of Record "Payment Period Line"` (T681)

## Goals / Non-Goals

**Goals:**
- Restore compilation of the Test and Test Library projects
- Delete tests that exercise removed functionality
- Fix surviving tests to use T685 (Payment Period) instead of T680/T681
- Remove test library helpers for deleted objects
- Preserve test coverage for all surviving functionality (generation, aggregation, averages, scheme handlers, Small Business filtering)

**Non-Goals:**
- Adding new test coverage for the simplified architecture
- Modifying the App layer
- Changing test patterns or refactoring unrelated test code

## Decisions

### 1. Fix at the library level first, then clean the test codeunit

The test library is the root of the cascade — almost every test helper creates Payment Period templates (T680/T681) and inserts D&R data (T689). Fixing the library first unblocks all surviving tests.

**Alternative**: Fix test codeunit first, stub out library calls → rejected because it would duplicate the library's responsibility and leave broken library code.

### 2. Replace `InsertDefaultTemplate` with `PaymentPeriod.SetupDefaults()`

The old flow was: `PaymentPeriodMgt.InsertDefaultTemplate(scheme)` creating T680/T681 records per reporting scheme. The new flow uses T685's `SetupDefaults()` which creates one global set of periods based on application family.

The library's `CreateDefaultPaymentPeriodTemplates()` becomes:
```
PaymentPeriod.DeleteAll();
PaymentPeriod.SetupDefaults();
```

No scheme parameter needed — T685 handles localization internally.

### 3. Remove `InsertDisputeRetData` from all header creation helpers

Previously every header got a companion T689 record. T689 is deleted. The `CreatePaymentPracticeHeader` overloads and `CreatePaymentPracticeHeaderWithScheme` simply stop calling `InsertDisputeRetData` and stop calling `FindDefaultPaymentPeriodCode`.

### 4. Keep D&R header calculation tests (4 tests)

The `DisputeRetCalcHeaderTotals_*` tests validate `CalculateHeaderTotals` on C681, which still exists and is called via the SchemeHandler interface during generation. These tests use `MockPaymentPracticeData` (a local helper with no T689 dependency) and `CreatePaymentPracticeHeaderWithScheme` (fixable). Worth preserving.

### 5. Delete all GB CSV and template management tests outright

No stub, no skip. These test objects that no longer exist.

## Risks / Trade-offs

- **[Reduced coverage]** → 28 tests removed covers functionality that no longer exists. No mitigation needed — the code is gone.
- **[Period initialization change]** → T685 `SetupDefaults()` uses `GetApplicationFamily()` which returns different periods per localization. Tests run in W1 context so they get the default 5-bucket set. → Tests that reference `PaymentPeriods[1..3]` still work because they read the first 3 periods by `Days From` ascending.
- **[Stale grep index]** → VS Code grep may still show hits in deleted files. → Use `Test-Path` to verify actual file state when uncertain.
