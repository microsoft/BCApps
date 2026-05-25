## 1. Create Supplementary Table

- [x] 1.1 Create `Paym. Prac. Dispute Ret. Data` table (T689) in `App/src/Tables/PaymPracDisputeRetData.Table.al` with PK `Header No.` (Integer, TableRelation → T687."No."), all D&R qualitative fields (30-34, 40-58, 60-73), field validation triggers (`Retention in Specific Circs.` clears desc, `Std Retention Pct Used` clears pct, `Payment Terms Have Changed` clears Suppliers Notified), and `CalculateRetentionPercentages()` procedure
- [x] 1.2 Add `CopyFromPrevious()` procedure to T689: find most recent T689 record by linked header Ending Date (excluding current), copy standing-policy fields, clear period-specific fields (54-58, 66-67, 33, 61), show message if no previous found

## 2. Update Payment Practice Header

- [x] 2.1 Remove fields 30-34, 40-58, 60-73 from `Payment Practice Header` table (T687) — keep only fields 1-23 and 15-16
- [x] 2.2 Remove `CalculateRetentionPercentages()` procedure from T687
- [x] 2.3 Add T689 record creation in T687 `OnInsert` trigger (after `UpdateNo()`)
- [x] 2.4 Add T689 record deletion in T687 `DeleteLinkedRecords()` procedure

## 3. Create D&R Detail Page

- [x] 3.1 Create `Paym. Prac. Dispute Ret. Card` page (P693) in `App/src/Pages/PaymPracDisputeRetCard.Page.al` with SourceTable = T689, groups: Qualifying Contracts (60-62), Payment Terms (63-70), Construction Contract Retention (40-58 with gate), Dispute Resolution (71), Payment Policies (30-34)
- [x] 3.2 Add conditional field editability on P693: Suppliers Notified (editable when Payment Terms Changed), Retention Circs. Desc. (editable when Retention in Specific Circs.), Standard Retention Pct (editable when Std Retention Pct Used), Terms Fairness Desc. (editable when Terms Fairness Practice), Prescribed Days Desc. (editable when Release Within Prescribed Days)
- [x] 3.3 Add `Copy from Previous Period` action on P693 with confirmation dialog, invoking `CopyFromPrevious()` and refreshing the page

## 4. Update Payment Practice Card

- [x] 4.1 Remove D&R field groups from P687: Qualifying Contracts, Payment Terms, Construction Contract Retention, Dispute Resolution, Payment Policies
- [x] 4.2 Add `Dispute & Retention` group with `Style = StandardAccent` clickable link field and `OnDrillDown` trigger opening P693, visible only when `IsDisputeRetention`
- [x] 4.3 Keep Payment Statistics group (fields 20-23) with existing `Visible = IsDisputeRetention`
- [x] 4.4 Remove `ExportGBCSV` action visibility dependency on removed fields (action itself stays, still gated by `IsDisputeRetention`)

## 5. Update GB CSV Export

- [x] 5.1 Update `Paym. Prac. GB CSV Export` (C684) `BuildDataRow()` to read D&R qualitative fields from T689 via `Get(Header."No.")` instead of from the header record
- [x] 5.2 Verify payment statistics fields (20-23) still read from header record in C684

## 6. Update app.json

- [x] 6.1 Register new table T689 and page P693 in `app.json` if required by the project structure

## 7. Update Tests

- [x] 7.1 Update `PaymentPracticesUT.Codeunit.al` — change D&R field references from header to T689 record
- [x] 7.2 Update `PaymentPracticesLibrary.Codeunit.al` — update helper procedures that set D&R fields to use T689
- [x] 7.3 Add test for `CopyFromPrevious()`: create two headers with D&R data, invoke copy, verify standing-policy fields copied and period-specific fields cleared
- [x] 7.4 Add test for T689 lifecycle: verify record created on header insert and deleted on header delete
