## Why

The `Payment Practice Header` table (T687) has ~50 fields, where ~31 are exclusive to the Dispute & Retention (GB) reporting scheme. These fields are blank and irrelevant for Standard and Small Business schemes, bloating the core table. Extracting them into a dedicated 1:1 table cleans up the header, isolates GB-specific concerns, and enables a "copy from previous period" workflow — important because UK companies report twice per year and ~80% of the qualitative fields (narratives, boolean policies, retention structure) rarely change between periods.

## What Changes

- Extract ~31 Dispute & Retention fields (30-34, 40-58, 60-73) from `Payment Practice Header` into a new 1:1 table `Paym. Prac. Dispute Ret. Data` (T689), keeping only fields 20-23 (payment statistics) on the header since they are also used by the Small Business scheme
- Create a new page `Paym. Prac. Dispute Ret. Card` (P693) for editing the D&R qualitative fields, opened from the main Payment Practice Card via a `Style = StandardAccent` clickable link field with `OnDrillDown`
- Remove the D&R field groups (Qualifying Contracts, Payment Terms, Construction Contract Retention, Dispute Resolution, Payment Policies) from the Payment Practice Card page and replace with the link field
- Create lifecycle management: insert/delete T689 record in sync with the header
- Add a "Copy from Previous Period" action on P693 that copies standing-policy fields from the most recent D&R record, clearing period-specific monetary amounts
- Update `Paym. Prac. GB CSV Export` (C684) to read D&R fields from T689 instead of the header
- Move `CalculateRetentionPercentages()` logic from header table to T689
- Update tests to reference D&R fields from the new table

## Capabilities

### New Capabilities
- `dispute-retention-detail-table`: New 1:1 supplementary table holding all D&R qualitative fields, with lifecycle management and copy-from-previous functionality
- `dispute-retention-detail-page`: Page for viewing/editing D&R details, opened from the header card via a clickable link

### Modified Capabilities
- `gb-csv-export`: CSV export reads D&R fields from the new table instead of the header
- `dispute-retention-handler`: Handler references updated; CalculateHeaderTotals unchanged (fields 20-23 stay on header)

## Impact

- **Tables**: T687 loses ~31 fields; new T689 created with those fields
- **Pages**: P687 loses 5 groups, gains 1 link field + action; new P693 created
- **Codeunits**: C684 (GB CSV Export) field references change from header to T689
- **Tests**: Field reference updates in PaymentPracticesUT.Codeunit.al and PaymentPracticesLibrary.Codeunit.al
- **No breaking changes to interfaces**: `PaymentPracticeSchemeHandler` interface unchanged; handler codeunit C681 unchanged (only touches fields 20-23 on header)
