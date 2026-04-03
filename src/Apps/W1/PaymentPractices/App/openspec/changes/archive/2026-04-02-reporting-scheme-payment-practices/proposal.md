## Why

The W1 Payment Practices app currently supports only the standard/French payment practices reporting. GB (UK) and AU/NZ markets have distinct regulatory requirements — UK's SI 2017/395 mandates dispute tracking, SCF (supply chain finance) disclosure, and construction contract retention reporting, while Australia's Payment Times Reporting Act 2020 requires small business supplier filtering with invoice count/value metrics. A single extensible reporting scheme mechanism lets the app serve all three markets without per-country forks.

## What Changes

- New extensible `Paym. Prac. Reporting Scheme` enum (Standard, Dispute & Retention, Small Business) with two interfaces: default period provisioning and scheme-specific generation-time handling
- Three handler codeunit implementations: Standard (W1/FR pass-through), Dispute & Retention (GB — dispute status, SCF payment date, construction retention), Small Business (AU/NZ — small business vendor filtering, invoice count/value)
- New `Payment Period Header` + `Payment Period Line` template tables replacing the old single `Payment Period` table, enabling user-editable named period configurations per reporting scheme (SAF-T mapping pattern)
- `Payment Practice Header` extended with `Reporting Scheme` (auto-detected from app family), `Payment Period Code`, GB payment policy tick-boxes, payment statistics, and construction contract retention fields
- `Payment Practice Data` extended with dispute status, overdue-due-to-dispute, and SCF payment date fields
- `Payment Practice Line` extended with invoice count and invoice value fields for AU/NZ
- BaseApp `Vendor` table extended with `Small Business Supplier` boolean; `Vendor Ledger Entry` extended with `SCF Payment Date` date field
- Core generation logic updated: scheme handler validates headers, filters/enriches data rows before insert, calculates scheme-specific header and line totals
- New pages: Payment Period Card (ListPlus), Payment Period List, Payment Period Subpage
- Updated pages: Payment Practice Card (conditional GB/AU field groups), Payment Practice Lines (AU columns), Payment Practice Data List (GB columns), Vendor Card (Small Business Supplier field)
- Old `Payment Period` table (685) deprecated with upgrade codeunit migrating existing data to new template structure
- GB CSV export and AU CSV export codeunits (detailed format TBD)

## Capabilities

### New Capabilities
- `reporting-scheme`: Extensible enum + dual-interface architecture controlling which fields, calculations, and exports are active per reporting scheme
- `payment-period-templates`: Named, user-editable payment period configurations (header + lines) replacing the old global period table, with optional Default flag (mutual exclusion within scheme), cascading auto-fill on Payment Practice Header (default → sole template → blank), scheme-filtered lookup, Reporting Scheme non-editable after insert, and upgrade migration
- `dispute-retention-handler`: GB-specific handler — dispute status flow from VLE, SCF payment date logic, construction contract retention fields and calculations, payment policy tick-boxes
- `small-business-handler`: AU/NZ-specific handler — small business supplier filtering, invoice count/value per period bucket, vendor-only validation
- `gb-csv-export`: UK government CSV export for Dispute & Retention scheme
- `au-csv-export`: AU government delimited export + declaration document for Small Business scheme

### Modified Capabilities

## Impact

- **Tables modified**: Payment Practice Header (687), Payment Practice Data (686), Payment Practice Line (688), Payment Period (685 — deprecated)
- **Tables created**: Payment Period Header (680), Payment Period Line (681)
- **BaseApp tables modified**: Vendor (23), Vendor Ledger Entry (25)
- **Codeunits modified**: PaymentPractices (689), PaymentPracticeBuilders (688), InstallPaymentPractices, PaymPracPeriodAggregator
- **Pages modified**: Payment Practice Card (687), Payment Practice Lines (688), Payment Practice Data List (686), Vendor Card, Payment Periods (685 — deprecated)
- **Pages created**: Payment Period Card (690), Payment Period List (691), Payment Period Subpage (692)
- **ID range**: 680–698 (enums, tables, pages, codeunits)
- **Upgrade path**: Existing Payment Period data migrated to new template tables; existing Payment Practice Headers backfilled with detected scheme and period code
