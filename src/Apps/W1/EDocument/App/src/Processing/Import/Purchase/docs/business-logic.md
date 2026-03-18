# Business logic

The Purchase domain implements temporary staging for extracted purchase document data with dual-field resolution pattern.

## Dual-field resolution pattern

Each external concept is represented by two fields:

**External value field** -- Stores text extracted from e-document exactly as received. Examples:
- "Vendor Company Name" stores "Acme Corp Ltd"
- "Item No." stores "SUPP-12345"
- "Unit of Measure" stores "EA"

**Business Central reference field** -- Stores validated BC reference after resolution. Examples:
- "[BC] Vendor No." stores "V001" (after IVendorProvider lookup)
- "[BC] Item No." stores "1000" (after IItemProvider lookup)
- "[BC] Unit of Measure" stores "PCS" (after IUnitOfMeasureProvider lookup)

Resolution flow:

1. Read step populates external value fields from extracted data
2. External fields are immutable after Read completes (audit trail)
3. Prepare step calls provider interfaces to resolve [BC] fields
4. Provider receives external value, queries master data, returns BC reference
5. If resolution succeeds, [BC] field is populated
6. If resolution fails, [BC] field remains blank, user must resolve manually
7. Finish step validates required [BC] fields are populated before creating purchase documents

Example resolution code:

```al
// During Prepare step
IVendorProvider := EDocumentService."Vendor Provider";
if IVendorProvider.GetVendor(EDocPurchaseHeader."Vendor Company Name", Vendor) then
    EDocPurchaseHeader."[BC] Vendor No." := Vendor."No."
else
    EDocumentLog.InsertWarning('Vendor not found: ' + EDocPurchaseHeader."Vendor Company Name");
```

## Header field population

E-Document Purchase Header stores these field groups:

**Identification fields:**
- Customer Company Name / Customer Company Id (bill-to party)
- Vendor Company Name / Vendor Address / Vendor Tax ID (seller party)
- Sales Invoice No. (vendor's invoice number)
- Purchase Order No. (referenced PO if exists)

**Date fields:**
- Invoice Date (document issue date)
- Due Date (payment due date)
- Document Date (accounting date)

**Amount fields:**
- Total Amount (gross total)
- VAT Amount (tax total)
- Subtotal Amount (net total)
- Currency Code (document currency)

**Business Central resolution fields:**
- [BC] Vendor No. (mandatory for Finish)
- [BC] Currency Code (resolved from external currency)
- [BC] Payment Terms Code (resolved from external payment terms)
- [BC] Purchase Order No. (matched PO if exists)

During Finish step, header fields map to Purchase Header as follows:

```al
PurchaseHeader."Buy-from Vendor No." := EDocPurchaseHeader."[BC] Vendor No.";
PurchaseHeader."Document Date" := EDocPurchaseHeader."Document Date";
PurchaseHeader."Due Date" := EDocPurchaseHeader."Due Date";
PurchaseHeader."Vendor Invoice No." := EDocPurchaseHeader."Sales Invoice No.";
PurchaseHeader."Currency Code" := EDocPurchaseHeader."[BC] Currency Code";
PurchaseHeader."Payment Terms Code" := EDocPurchaseHeader."[BC] Payment Terms Code";
```

## Line field population

E-Document Purchase Line stores these field groups:

**External item identification:**
- Item No. (supplier's item code)
- Description (line description text)
- GTIN / EAN (global item identifier)

**Quantity and pricing:**
- Quantity (ordered quantity)
- Quantity Received (if matching to receipt)
- Unit Price (price per unit)
- Line Discount % (line-level discount)
- Line Amount (extended amount)

**Business Central resolution fields:**
- [BC] Item No. (resolved item reference)
- [BC] Unit of Measure (resolved UOM code)
- [BC] Purchase Type (Item, G/L Account, Charge (Item))
- [BC] Purchase Type No. (Item No. or G/L Account No. depending on type)

Purchase Type resolution logic:

1. If IItemProvider resolves item, set Type = Item, Type No. = Item No.
2. If item resolution fails and IPurchaseLineAccountProvider suggests GL account, set Type = G/L Account, Type No. = G/L Account No.
3. If both fail and line has charge item indicator, set Type = Charge (Item), let user assign charge item
4. If all fail, log error and leave type blank (user must resolve)

During Finish step, line fields map to Purchase Line:

```al
PurchaseLine.Type := EDocPurchaseLine."[BC] Purchase Type";
PurchaseLine."No." := EDocPurchaseLine."[BC] Purchase Type No.";
PurchaseLine.Description := EDocPurchaseLine.Description;
PurchaseLine.Quantity := EDocPurchaseLine.Quantity;
PurchaseLine."Direct Unit Cost" := EDocPurchaseLine."Unit Price";
PurchaseLine."Line Discount %" := EDocPurchaseLine."Line Discount %";
PurchaseLine."Unit of Measure Code" := EDocPurchaseLine."[BC] Unit of Measure";
```

## User review workflow

After Prepare step completes, users review in E-Document Purchase Draft page:

1. Open E-Document with status "Prepare Done"
2. Page shows header factbox with external + [BC] fields
3. Lines subpage shows grid with:
   - External item identification columns
   - [BC] reference columns (editable)
   - Quantity/price columns
   - Match status column (if PO matching enabled)
4. User reviews each line:
   - Green checkmark = all [BC] fields resolved
   - Yellow warning = partial resolution, manual fix needed
   - Red error = missing mandatory resolution
5. User edits [BC] fields directly in grid or via lookup pages
6. User clicks "Finish Draft" action to create Purchase Header/Line
7. System validates all mandatory [BC] fields populated before proceeding

## Match-to-order workflow

When purchase order matching is configured:

1. During Prepare step, EDocPOMatching loads candidate PO lines for vendor
2. Manual matching: User opens "Select PO Lines" page, chooses lines to match
3. Copilot matching: System calls AI to suggest matches based on descriptions
4. Match records created in E-Doc. Purchase Line PO Match table
5. Matched lines show PO reference in review UI
6. During Finish step:
   - System creates Purchase Invoice linked to PO
   - Sets "Order No." and "Order Line No." on Purchase Line
   - Validates quantities and prices against PO constraints
   - Warns if invoice quantity exceeds PO outstanding quantity

Match-to-order is common for 3-way match scenarios where companies want to ensure invoices correspond to authorized purchase orders and received goods.

## Historical matching workflow

When historical matching is enabled:

1. System maintains E-Doc. Purchase Line History table with past purchases
2. During Prepare step, system queries history for similar line descriptions
3. Calls AOAI Function with current line + historical matches
4. AI returns suggested GL account or item based on similarity
5. Suggestions appear in review UI with confidence scores
6. User accepts/rejects suggestions
7. Accepted suggestions update history (reinforce pattern)
8. Rejected suggestions don't affect history (ignore outliers)

Historical matching improves over time as more documents are processed and user corrections train the model.

## Draft feedback collection

Users can provide feedback on extraction quality:

1. After reviewing purchase draft, user clicks "Provide Feedback" action
2. E-Doc. Draft Feedback page shows extracted fields with thumbs up/down buttons
3. User marks fields as correctly/incorrectly extracted
4. Feedback is logged to telemetry with document format and extraction method
5. Microsoft uses feedback to improve MLLM prompts and ADI mappings
6. Feedback is anonymous and doesn't affect current document processing

Feedback is entirely optional and intended for continuous improvement of extraction algorithms.
