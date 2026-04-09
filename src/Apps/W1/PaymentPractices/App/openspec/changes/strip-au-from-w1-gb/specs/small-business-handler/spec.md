## MODIFIED Requirements

### Requirement: Small Business handler implements both interfaces
Codeunit `Paym. Prac. Small Bus. Handler` (C682) SHALL implement `PaymentPracticeSchemeHandler` for the `Small Business` enum value. All four methods SHALL be empty pass-throughs (same pattern as C680 Standard Handler). The handler SHALL NOT reference `Vendor`, `Small Business Supplier`, or any AU-specific logic.

#### Scenario: Handler is a no-op stub
- **WHEN** a Payment Practice Header has Reporting Scheme = Small Business
- **THEN** ValidateHeader does nothing, UpdatePaymentPracData returns true for all rows, CalculateHeaderTotals and CalculateLineTotals are no-ops

## REMOVED Requirements

### Requirement: AU default payment periods
**Reason**: AU/NZ period defaults removed from W1/GB branch. Colleague re-adds when implementing AU.
**Migration**: No action required. `InsertDefaultPeriods_AUNZ()` and its case branch in `SetupDefaults()` are deleted.

### Requirement: Small Business Supplier field on Vendor
**Reason**: Vendor table extension (TE680) and Vendor Card page extension (PE680) are AU-only objects removed from W1/GB branch.
**Migration**: No action required. Colleague recreates from au-complete spec section 5.

### Requirement: Non-small-business vendors excluded from data generation
**Reason**: Stub handler returns true for all rows — no vendor filtering. AU-specific filtering removed.
**Migration**: Colleague restores `UpdatePaymentPracData()` logic in C682 when implementing AU.

### Requirement: ValidateHeader rejects Customer and Vendor+Customer
**Reason**: Stub handler has empty `ValidateHeader()` — no header type restrictions. AU-specific validation removed.
**Migration**: Colleague restores validation in C682 when implementing AU.

### Requirement: CalculateHeaderTotals populates total invoice count and value
**Reason**: Stub handler has empty `CalculateHeaderTotals()`. AU-specific header totals removed.
**Migration**: Colleague restores logic in C682 when implementing AU.
