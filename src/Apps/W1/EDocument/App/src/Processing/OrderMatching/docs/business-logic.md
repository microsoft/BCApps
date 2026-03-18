# Business logic

The Order matching engine implements line-level matching between imported documents and existing purchase orders.

## Imported line lifecycle

E-Doc. Imported Line records are created during Read step:

1. **Creation:**
   - Read step extracts line data from structured format
   - For each line in source document, create E-Doc. Imported Line record:
     - "E-Document Entry No." = parent document
     - "Line No." = sequential (10000, 20000, 30000...)
     - External fields populated from extraction (Description, Quantity, Unit Price)
     - [BC] fields initially blank

2. **Resolution:**
   - Prepare step calls provider interfaces to resolve master data
   - IVendorProvider resolves "[BC] Vendor No." on header
   - IItemProvider resolves "[BC] Item No." on each line
   - IUnitOfMeasureProvider resolves "[BC] Unit of Measure" on each line
   - Resolved references written to [BC] fields

3. **Matching:**
   - After resolution, matching logic runs (if enabled)
   - EDocLineMatching loads candidate PO lines for resolved vendor
   - Manual or Copilot matching creates E-Doc. Order Match records
   - Imported lines with matches flagged as "Matched" (calculated field)

4. **Transformation:**
   - Finish step reads imported lines + match records
   - For matched lines: Create Purchase Invoice linked to PO
   - For unmatched lines: Create standalone Purchase Invoice
   - Imported line data preserved for audit

5. **Persistence:**
   - Imported lines remain after Finish step completes
   - Linked to final Purchase Line via "E-Document Line Entry No." extension field
   - Deleted only when E-Document is deleted (cascade)

## Manual matching workflow

User-initiated matching via UI:

1. **Open matching page:**
   - User opens E-Document with status "Prepare Done"
   - Navigates to "Match to Purchase Orders" action
   - System opens E-Doc. Order Match page

2. **Load candidates:**
   - System calls EDocLineMatching.LoadCandidatePOLines()
   - Filters purchase order lines:
     - Document Type = Order
     - Vendor No. = resolved [BC] Vendor No.
     - Not fully invoiced (Outstanding Quantity > 0)
     - Not already matched to other e-documents
   - Displays candidates in grid with columns:
     - PO Document No. + Line No.
     - Item No. + Description
     - Ordered Quantity
     - Outstanding Quantity
     - Unit Cost

3. **User selection:**
   - User selects imported line in left pane
   - User selects one or more PO lines in right pane
   - For quantity split, user enters matched quantity per PO line
   - User clicks "Create Match" button

4. **Match validation:**
   - System validates:
     - Total matched quantity <= imported line quantity
     - Each PO line outstanding quantity >= matched quantity
     - Item No. matches between imported line and PO line (if both populated)
   - If validation fails, show error and prevent match creation
   - If validation succeeds, create E-Doc. Order Match records

5. **Visual feedback:**
   - Matched imported lines show green checkmark icon
   - Matched quantity displayed next to imported line
   - Un-match button enabled for reversal

## Candidate line filtering

EDocLineMatching implements sophisticated filtering logic:

**Base filters (always applied):**
```al
PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
PurchaseLine.SetRange("Pay-to Vendor No.", ImportedLine."[BC] Vendor No.");
PurchaseLine.SetFilter("Outstanding Quantity", '>0');
```

**Item-based filtering (if imported line has item resolved):**
```al
if ImportedLine."[BC] Item No." <> '' then
    PurchaseLine.SetRange("No.", ImportedLine."[BC] Item No.");
```

**UOM-based filtering (if imported line has UOM resolved):**
```al
if ImportedLine."[BC] Unit of Measure" <> '' then
    PurchaseLine.SetRange("Unit of Measure Code", ImportedLine."[BC] Unit of Measure");
```

**Date range filtering (from service configuration):**
```al
EDocPOMatchingSetup.Get(EDocumentService.Code);
if EDocPOMatchingSetup."Match Scope Date Filter" <> '' then begin
    DateFilter := CalcDate(EDocPOMatchingSetup."Match Scope Date Filter", Today);
    PurchaseLine.SetFilter("Expected Receipt Date", '>=%1', DateFilter);
end;
```

**Exclusion of already-matched lines:**
```al
// Query existing matches to exclude PO lines already matched to other e-documents
EDocOrderMatch.SetRange("Purchase Line SystemId", PurchaseLine.SystemId);
EDocOrderMatch.SetFilter("E-Doc. Imported Line SystemId", '<>%1', ImportedLine.SystemId);
if not EDocOrderMatch.IsEmpty() then
    continue; // Skip this PO line
```

This multi-tier filtering reduces candidate set from potentially thousands to dozens, improving UI performance and match accuracy.

## Quantity split handling

Splitting single imported line across multiple PO lines:

1. **User initiates split:**
   - Selects imported line (Quantity = 100)
   - Selects multiple PO lines (PO #1 has Outstanding = 60, PO #2 has Outstanding = 50)
   - System prompts for quantity distribution

2. **System suggests distribution:**
   - Auto-fill quantities to match PO outstanding amounts where possible:
     - PO #1: Matched Quantity = 60
     - PO #2: Matched Quantity = 40 (limited by imported line remaining)
   - User can adjust quantities manually

3. **Validation:**
   - Sum of matched quantities (60 + 40 = 100) must equal imported line quantity
   - Each matched quantity must be <= PO line outstanding quantity
   - If validation fails, show error with details

4. **Match record creation:**
   - Create E-Doc. Order Match record for PO #1:
     - E-Doc. Imported Line SystemId = imported line
     - Purchase Line SystemId = PO #1 Line SystemId
     - Matched Quantity = 60
   - Create E-Doc. Order Match record for PO #2:
     - E-Doc. Imported Line SystemId = imported line
     - Purchase Line SystemId = PO #2 Line SystemId
     - Matched Quantity = 40

5. **Finish step handling:**
   - Read match records for imported line
   - Create two Purchase Invoice lines:
     - Line 1: Quantity = 60, Order No. = PO #1, Order Line No. = PO #1 line
     - Line 2: Quantity = 40, Order No. = PO #2, Order Line No. = PO #2 line
   - Both invoice lines link to same E-Document via "E-Document Entry No."

## Match confidence calculation

For Copilot-suggested matches, confidence score determines auto-accept:

**Confidence components:**
1. Description similarity (0.0-1.0):
   - Exact match: 1.0
   - High overlap: 0.7-0.9
   - Moderate overlap: 0.4-0.6
   - Low overlap: 0.0-0.3

2. Quantity compatibility (0.0-1.0):
   - Exact quantity match: 1.0
   - Under-invoice (imported < PO): 0.9
   - Over-invoice within 10%: 0.7
   - Over-invoice >10%: 0.3

3. Price compatibility (0.0-1.0):
   - Price difference 0-2%: 1.0
   - Price difference 2-5%: 0.8
   - Price difference 5-10%: 0.6
   - Price difference >10%: 0.3

**Final confidence:**
```
Confidence = 0.5 * Description + 0.25 * Quantity + 0.25 * Price
```

**Auto-accept threshold:**
- Confidence >= 0.7: Auto-accept match (create E-Doc. Order Match record)
- Confidence 0.5-0.7: Suggest for user review (show in suggestion list)
- Confidence < 0.5: Discard (don't suggest, likely false positive)

## Match persistence and audit

Match records persist after Finish step:

**Audit capabilities:**
1. Drill-down from Purchase Invoice Line to source E-Doc. Imported Line
2. View which PO lines were matched to imported lines
3. Review match confidence scores (for Copilot matches)
4. Track match source (Manual, Copilot, Historical)
5. Analyze match accuracy over time (user-confirmed vs. rejected suggestions)

**Reporting scenarios:**
- Match rate % by service (how many lines get matched automatically)
- Copilot accuracy (% of suggestions accepted by users)
- Common unmatched item descriptions (candidates for item master data cleanup)
- Price variance distribution (identify vendors with frequent price changes)

**Data retention:**
- Match records are deleted when E-Document is deleted (cascade)
- Consider archiving old match data to separate table for long-term analysis
- Active match records should span last 90 days (configurable)
