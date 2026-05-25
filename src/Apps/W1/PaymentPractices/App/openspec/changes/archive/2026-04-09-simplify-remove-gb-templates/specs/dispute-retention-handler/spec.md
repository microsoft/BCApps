## MODIFIED Requirements

### Requirement: GB payment policy tick-box fields
The `Payment Practice Header` SHALL NOT contain user-entered fields for payment policies. These fields (30-34) SHALL NOT exist on T689 either, as T689 is removed.

#### Scenario: Policy fields do not exist
- **WHEN** a developer inspects Payment Practice Header (T687) and the broader codebase
- **THEN** fields 30-34 for payment policies do not exist on any table

### Requirement: Construction contract retention fields
The `Payment Practice Header` SHALL NOT contain construction contract retention fields. These fields (40-58, 72-73) SHALL NOT exist on T689 either, as T689 is removed.

#### Scenario: Retention fields do not exist
- **WHEN** a developer inspects Payment Practice Header (T687) and the broader codebase
- **THEN** fields 40-58 and 72-73 for retention do not exist on any table

### Requirement: Payment Practice Card shows GB-specific groups
The `Payment Practice Card` page SHALL NOT show Payment Policies, Qualifying Contracts, Payment Terms, Construction Contract Retention, or Dispute Resolution groups. It SHALL NOT show a drilldown link to the D&R detail page. The Payment Statistics group (fields 20-23) SHALL remain visible on the card when Reporting Scheme = `Dispute & Retention`.

#### Scenario: GB card shows only payment statistics
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Dispute & Retention
- **THEN** the Payment Statistics group (Total Number of Payments, Total Amount of Payments, Total Amt. of Overdue Payments, Pct Overdue Due to Dispute) is visible
- **AND** no D&R drilldown link, policy groups, or retention groups are shown

#### Scenario: Non-GB card layout unchanged
- **WHEN** a user opens a Payment Practice Card with Reporting Scheme = Standard
- **THEN** no D&R-specific content is visible and the card layout is unchanged from the base behavior

## REMOVED Requirements

### Requirement: Detail table field declaration order follows CSV column sequence
**Reason**: Table T689 removed — no fields to order.
**Migration**: No action required.
