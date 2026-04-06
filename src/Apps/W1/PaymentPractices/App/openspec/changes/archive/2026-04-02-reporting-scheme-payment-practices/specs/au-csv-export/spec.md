## ADDED Requirements

### Requirement: AU CSV export codeunit exists
The system SHALL provide a codeunit `Paym. Prac. AU CSV Export` (C694) that generates a delimited text file per the AU government schema (Payment Times Reports Register format) for the Small Business reporting scheme.

#### Scenario: Export triggered from Payment Practice Card
- **WHEN** a user invokes the AU CSV export action on a Payment Practice Card with Reporting Scheme = Small Business
- **THEN** a delimited text file is generated and downloaded

#### Scenario: Export blocked for wrong scheme
- **WHEN** a user attempts the AU CSV export on a Payment Practice Card with Reporting Scheme = Standard
- **THEN** the action is not available or an error is raised

### Requirement: AU export includes header-level totals
The export SHALL include the total number of invoices and total value of invoices from the Payment Practice Header.

#### Scenario: Header totals in export
- **WHEN** an AU export is generated for a header with total invoices = 50, total value = $250,000
- **THEN** the export file contains these totals in the correct columns

### Requirement: AU export includes period-aggregated invoice data
The export SHALL include per-period-bucket invoice count and invoice value from Payment Practice Lines, plus the standard payment timing percentages.

#### Scenario: Period data with invoice counts in export
- **WHEN** an AU export is generated with 3 period lines (0-30, 31-60, 61+)
- **THEN** the export contains invoice count and invoice value for each period bucket

### Requirement: AU declaration document
The system SHALL provide a declaration document (Word layout or equivalent) with fields for officer name, signature block, and ABN, triggered from the Payment Practice Card for the Small Business scheme.

#### Scenario: Declaration generated
- **WHEN** a user invokes the AU declaration action on a Small Business Payment Practice Card
- **THEN** a declaration document is generated with placeholders for officer name, signature, and ABN

### Requirement: Export format details deferred
The exact delimited file format (delimiter, quoting, encoding), column mapping to AU government schema, and declaration document Word layout fields SHALL be specified before implementation begins. The export codeunit structure and triggering mechanism SHALL be implemented; field-to-column mapping is finalized when AU government schema details are confirmed.

#### Scenario: Export structure ready for format specification
- **WHEN** the AU export codeunit is implemented with placeholder column mapping
- **THEN** updating the column mapping and format details does not require architectural changes
