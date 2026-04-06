## ADDED Requirements

### Requirement: Payment Period Header table exists
The system SHALL provide a `Payment Period Header` table (ID 680) with fields: Code (Code[20], PK), Description (Text[250]), Reporting Scheme (Enum `Paym. Prac. Reporting Scheme`), Default (Boolean). The Reporting Scheme field SHALL be non-editable after insert (editable only while the record has not yet been saved for the first time). The `Default` field is optional — a scheme may have zero or one default template. Setting Default = true SHALL silently clear Default on any other Payment Period Header with the same Reporting Scheme (mutual exclusion). Setting Default = false is always allowed. OnDelete SHALL cascade-delete child Payment Period Lines and block deletion if referenced by any Payment Practice Header.

#### Scenario: Create a payment period template
- **WHEN** a user creates a Payment Period Header with Code 'CUSTOM', Description 'Custom Periods', Reporting Scheme = Standard
- **THEN** the record is created and available for selection on Payment Practice Headers

#### Scenario: Only one default per scheme (mutual exclusion)
- **WHEN** a user sets Default = true on a Payment Period Header with Reporting Scheme = Standard
- **THEN** any other Payment Period Header with Reporting Scheme = Standard has Default set to false silently

#### Scenario: User can uncheck default
- **WHEN** a user sets Default = false on the only default Payment Period Header for Reporting Scheme = Standard
- **THEN** Default is set to false and no template is the default for that scheme

#### Scenario: Cannot delete referenced template
- **WHEN** a user attempts to delete a Payment Period Header that is referenced by an existing Payment Practice Header's Payment Period Code
- **THEN** deletion is blocked with an error

#### Scenario: Reporting Scheme is not editable after insert
- **WHEN** a user opens an existing Payment Period Header card
- **THEN** the Reporting Scheme field is not editable

### Requirement: Payment Period Line table exists
The system SHALL provide a `Payment Period Line` table (ID 681) with fields: Period Header Code (Code[20], PK1, TableRelation = Payment Period Header), Line No. (Integer, PK2), Days From (Integer, MinValue = 0), Days To (Integer, MinValue = 0 where 0 = unlimited), Description (Text[250], auto-generated from Days From/To).

#### Scenario: Create period bucket lines
- **WHEN** a user adds a line to Payment Period Header 'GB-DEFAULT' with Days From = 0, Days To = 30
- **THEN** the line is created and Description is auto-generated as '0 to 30 days.'

#### Scenario: Open-ended final bucket
- **WHEN** a user adds a line with Days From = 121, Days To = 0
- **THEN** the Description is auto-generated as 'More than 121 days.'

### Requirement: Payment Period Code on Payment Practice Header
The `Payment Practice Header` table SHALL have a field `Payment Period Code` (field 16, Code[20], TableRelation = Payment Period Header filtered by Reporting Scheme matching the header's Reporting Scheme) displayed with `ShowMandatory = true` on the Payment Practice Header card page. On insert, the code SHALL auto-fill using cascading logic: (1) if a default Payment Period Header exists for the detected Reporting Scheme, select it; (2) else if exactly one Payment Period Header exists for the scheme, select it; (3) otherwise leave blank. On Reporting Scheme OnValidate, the same cascading logic SHALL apply to update the code for the new scheme; if no templates exist for the new scheme, a confirmation dialog asks to create the default template from `GetDefaultPaymentPeriods()` — if confirmed, the template is created and the code is set; if declined, the code is left blank.

#### Scenario: Auto-fill period code from default template
- **WHEN** a new Payment Practice Header is inserted and a default Payment Period Header exists for the detected Reporting Scheme
- **THEN** the Payment Period Code is set to that default template's Code

#### Scenario: Auto-fill period code from sole template
- **WHEN** a new Payment Practice Header is inserted, no default exists, but exactly one Payment Period Header exists for the detected scheme
- **THEN** the Payment Period Code is set to that sole template's Code

#### Scenario: No auto-fill when multiple non-default templates
- **WHEN** a new Payment Practice Header is inserted and multiple Payment Period Headers exist for the detected scheme with none marked as default
- **THEN** the Payment Period Code is left blank

#### Scenario: No templates exist
- **WHEN** a new Payment Practice Header is inserted and no Payment Period Headers exist for the detected scheme
- **THEN** the Payment Period Code is left blank

#### Scenario: Scheme change triggers period code update
- **WHEN** the user changes Reporting Scheme
- **THEN** the Payment Period Code is updated using the same cascading logic (default → sole template → blank)

#### Scenario: Scheme change with no templates prompts creation
- **WHEN** the user changes Reporting Scheme and no Payment Period Headers exist for the new scheme
- **THEN** a confirmation dialog asks to create the default template; if confirmed, the template is created and Payment Period Code is set; if declined, Payment Period Code is left blank

#### Scenario: Payment Period Code lookup is filtered by scheme
- **WHEN** the user opens the lookup on Payment Period Code
- **THEN** only Payment Period Headers matching the header's Reporting Scheme are shown

#### Scenario: Generation guard — templates exist for scheme but none selected
- **WHEN** Generate() is called on a header with blank Payment Period Code and at least one Payment Period Header exists for the header's Reporting Scheme
- **THEN** an error is raised: 'You must select a Payment Period Code before generating.'

#### Scenario: Generation guard — no templates exist for scheme
- **WHEN** Generate() is called on a header with blank Payment Period Code and no Payment Period Headers exist for the header's Reporting Scheme
- **THEN** an actionable error is raised: 'No payment period templates exist for the selected reporting scheme. Create a template first.' with a navigation action that opens the Payment Period List page (P691)

### Requirement: Period Aggregator uses Payment Period Line
The `Paym. Prac. Period Aggregator` SHALL read period buckets from `Payment Period Line` filtered by the header's `Payment Period Code` instead of the old global `Payment Period` table.

#### Scenario: Generate lines from template periods
- **WHEN** a Payment Practice Header with Payment Period Code 'GB-DEFAULT' generates period-aggregated lines
- **THEN** one line is created per Payment Period Line under 'GB-DEFAULT', using the line's Days From and Days To for bucketing

### Requirement: Payment Period pages exist
The system SHALL provide: Payment Period Card (P690, PageType = ListPlus) with header fields and a lines subpage, Payment Period List (P691) for browsing templates, and Payment Period Subpage (P692, PageType = ListPart) for editing lines. On the Payment Period Card, the Reporting Scheme field SHALL be editable only during insert (when the record has not yet been saved); after the first save it SHALL be read-only.

#### Scenario: User navigates period templates
- **WHEN** a user opens the Payment Period List page
- **THEN** all Payment Period Headers are listed and the user can open any card to edit its lines

#### Scenario: New template has editable scheme
- **WHEN** a user presses New on the Payment Period List and the card opens
- **THEN** the Reporting Scheme field is editable and the user can select a scheme before saving

#### Scenario: Existing template has read-only scheme
- **WHEN** a user opens an existing Payment Period Header card
- **THEN** the Reporting Scheme field is not editable

### Requirement: Old Payment Period table deprecated
Table 685 `Payment Period` SHALL be marked with `ObsoleteState = Pending` and `ObsoleteReason = 'Replaced by Payment Period Header + Payment Period Line tables.'`.

#### Scenario: Old table is obsolete
- **WHEN** a developer references table 685 Payment Period
- **THEN** a compiler warning indicates it is pending deprecation

### Requirement: Upgrade codeunit migrates period data
An upgrade codeunit (C683) SHALL compare old `Payment Period` rows against the detected scheme's defaults. If they match, only the default template is created. If they differ, both a "MIGRATED" template (with old data) and the scheme's default template are created. All existing Payment Practice Headers with blank Payment Period Code SHALL be backfilled — with "MIGRATED" if it was created, otherwise with the default template code. The Reporting Scheme on existing headers SHALL be backfilled from `GetApplicationFamily()`.

#### Scenario: Upgrade with default periods (no customization)
- **WHEN** the app upgrades and old Payment Period rows match the detected scheme's defaults
- **THEN** a single default Payment Period Header + Lines template is created with Default = true, and existing headers are backfilled with that code

#### Scenario: Upgrade with custom periods
- **WHEN** the app upgrades and old Payment Period rows differ from the detected scheme's defaults
- **THEN** both "MIGRATED" (Default = false, old data) and the scheme default template (Default = true) are created, and existing headers are backfilled with "MIGRATED"

### Requirement: Install codeunit seeds default template
On fresh install, the install codeunit SHALL create one Payment Period Header + Lines by calling `GetDefaultPaymentPeriods()` for the detected scheme (GB → GB-DEFAULT, FR → FR-DEFAULT, AU/NZ → AU-DEFAULT, all others → W1-DEFAULT) with Default = true.

#### Scenario: Fresh install on W1 environment
- **WHEN** the app is freshly installed on a W1 environment
- **THEN** a Payment Period Header 'W1-DEFAULT' with Default = true is created with 5 period lines (0-30, 31-60, 61-90, 91-120, 121+)

#### Scenario: Fresh install on GB environment
- **WHEN** the app is freshly installed on a GB environment
- **THEN** a Payment Period Header 'GB-DEFAULT' with Default = true is created with 4 period lines (0-30, 31-60, 61-120, 121+)
