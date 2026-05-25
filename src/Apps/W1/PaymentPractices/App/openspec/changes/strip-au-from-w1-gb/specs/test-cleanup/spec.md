## MODIFIED Requirements

### Requirement: Tests for deleted objects are removed
The test codeunit SHALL NOT contain tests that reference `Paym. Prac. Dispute Ret. Data` (T689), `Paym. Prac. GB CSV Export` (C684), `Payment Period Header` (T680), `Payment Period Line` (T681), `Payment Period Card` (P690), `Payment Period List` (P691), `DisputeRetentionLink` page control, OR AU-specific Small Business handler behavior (`SmallBusinessValidateHeader`, `SmallBusinessNonSmallVendorExcluded`, `SmallBusinessSmallVendorIncluded`, `CreateSmallBusinessVendor`).

#### Scenario: AU Small Business handler tests removed
- **WHEN** the test codeunit is compiled
- **THEN** no test procedures named `SmallBusinessValidateHeaderRejectsCustomer`, `SmallBusinessValidateHeaderRejectsVendorCustomer`, `SmallBusinessNonSmallVendorExcluded`, or `SmallBusinessSmallVendorIncluded` exist

#### Scenario: AU test library helper removed
- **WHEN** the test library is compiled
- **THEN** no procedure named `CreateSmallBusinessVendor` exists (it references `Vendor."Small Business Supplier"` from deleted TE680)

#### Scenario: Clean compilation
- **WHEN** the AL compiler runs on the Test and Test Library projects
- **THEN** zero compilation errors are produced
