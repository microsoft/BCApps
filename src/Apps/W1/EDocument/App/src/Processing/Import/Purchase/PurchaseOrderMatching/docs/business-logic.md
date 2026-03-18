# Business logic

Purchase order matching implements manual and AI-powered line-level matching between imported invoices and existing purchase orders.

## Candidate line loading

EDocPOMatching.LoadAvailablePOLinesForEDocumentLine determines which PO lines can be matched:

Filtering criteria:
1. Purchase Line."Document Type" = Order (not quotes, blanket orders, invoices)
2. Purchase Line."Pay-to Vendor No." = resolved [BC] Vendor No. from imported document
3. Purchase Line.Type = Item (excludes GL account lines, charges)
4. If imported line has [BC] Unit of Measure assigned, filter to matching UOM
5. Exclude lines already fully invoiced (Quantity Invoiced = Quantity)
6. Exclude lines matched to other e-document lines (check E-Doc. Purchase Line PO Match)
7. Include lines already matched to current imported line (enable un-matching)

If E-Document Purchase Header has "[BC] Purchase Order No." populated (extracted from invoice reference), candidates are further filtered to that specific order unless it would result in zero candidates.

Performance optimization: Query uses SetLoadFields to load only necessary columns (Document No., Line No., Description, Quantity, Qty. Invoiced), reducing data transfer for large result sets.

## Manual matching workflow

User-driven matching process:

1. Open E-Document with status "Prepare Done"
2. Navigate to Lines, select imported line
3. Click "Match to PO Line" action
4. System loads candidates via LoadAvailablePOLinesForEDocumentLine
5. E-Doc. Select PO Lines page displays:
   - PO Document No. + Line No.
   - Item No. + Description
   - Ordered Quantity
   - Quantity Invoiced (to date)
   - Outstanding Quantity (Ordered - Invoiced)
   - Unit Cost (for price comparison)
6. User selects one or more PO lines
7. For quantity splits, user enters partial quantity per PO line
8. User clicks OK to confirm match
9. System validates:
   - Total matched quantity doesn't exceed imported line quantity
   - Each PO line outstanding quantity covers matched quantity
   - Price variance is within tolerance (if configured)
10. System creates E-Doc. Purchase Line PO Match records
11. Matched lines show PO reference in review UI

## Copilot matching workflow

AI-powered automatic matching:

1. During Prepare step, after master data resolution
2. Check if Copilot PO matching enabled on service
3. For each imported line with [BC] Vendor No. resolved:
   - Load candidate PO lines (same vendor, item lines only)
   - Build text corpus: Imported line description + PO line descriptions
   - Call EDocPOCopilotMatching.MatchWithCopilot
4. Copilot analyzes:
   - Description similarity (fuzzy text matching)
   - Quantity compatibility (invoice qty <= PO outstanding qty)
   - Price variance (invoice price vs. PO price within tolerance)
5. AOAI Function returns JSON array of match suggestions:
   ```json
   [
     {
       "importedLineNo": 10000,
       "poDocumentNo": "PO-001",
       "poLineNo": 10000,
       "confidence": 0.85,
       "reason": "Description matches and quantity compatible"
     }
   ]
   ```
6. For each suggestion:
   - If confidence >= threshold (default 0.7), auto-accept match
   - If confidence < threshold, add to suggestions buffer for user review
7. Auto-accepted matches create E-Doc. Purchase Line PO Match records
8. Suggestions appear in "Review Copilot Suggestions" page

## Confidence calculation

Copilot confidence score is calculated from multiple factors:

**Description similarity** (50% weight):
- Exact description match: 1.0
- High token overlap (>80%): 0.8-1.0
- Moderate token overlap (50-80%): 0.5-0.8
- Low token overlap (<50%): 0.0-0.5

**Quantity compatibility** (25% weight):
- Invoice qty exactly matches PO outstanding: 1.0
- Invoice qty < PO outstanding (under-invoicing): 0.9
- Invoice qty > PO outstanding but within 10%: 0.7
- Invoice qty > PO outstanding by >10%: 0.3

**Price variance** (25% weight):
- Price difference 0-2%: 1.0
- Price difference 2-5%: 0.8
- Price difference 5-10%: 0.6
- Price difference >10%: 0.3

Final confidence = weighted sum of factors. Matches below 0.5 are not suggested (likely incorrect).

## Receipt-based matching

When E-Doc. PO Matching Setup."Configuration Receipt" = "Match to Receipt Lines":

1. Instead of querying Purchase Line (orders), query Purch. Rcpt. Line (receipts)
2. Filter to same vendor, item type, not fully invoiced
3. E-Doc. Line By Receipt query provides optimized receipt line lookup
4. User/Copilot matches invoice lines to receipt lines
5. E-Doc. Purchase Line PO Match stores Receipt Line SystemId
6. During Finish step:
   - System resolves receipt line back to original PO line
   - Creates Purchase Invoice linked to PO with receipt quantity validation
   - Validates invoice quantity <= receipt quantity (can't invoice more than received)

Receipt matching is common in industries with partial deliveries where invoicing must exactly match what was received, not what was originally ordered.

## Quantity splitting logic

EDocPOMatching supports splitting imported line across multiple PO lines:

1. User matches imported line (Qty = 100) to multiple PO lines
2. For each PO line, user specifies matched quantity:
   - PO #1 Line 10000: Match 60 units
   - PO #2 Line 10000: Match 40 units
3. System validates sum of matched quantities (60 + 40 = 100) equals imported quantity
4. Creates two E-Doc. Purchase Line PO Match records:
   - Record 1: Imported Line SystemId → PO #1 Line SystemId, Qty = 60
   - Record 2: Imported Line SystemId → PO #2 Line SystemId, Qty = 40
5. During Finish step:
   - Creates two Purchase Line records linked to same invoice header
   - Line 1: Order No. = PO #1, Order Line No. = 10000, Quantity = 60
   - Line 2: Order No. = PO #2, Order Line No. = 10000, Quantity = 40

Splitting is automatic when user selects multiple PO lines; system prompts for quantity distribution if not evenly divisible.

## Validation and warnings

Match validation occurs at creation and during Finish step:

**At match creation:**
- Imported line quantity must be positive
- PO line outstanding quantity must be >= matched quantity
- For splits, sum of matched quantities must equal imported line quantity

**During Finish step:**
- Price variance check: Calculate % difference between invoice price and PO price
- If variance exceeds threshold (configured in E-Doc. PO Matching Setup):
  - Create E-Doc. PO Match Warning record
  - Warning type = Price Variance
  - Warning message = "Invoice price $10.50 exceeds PO price $10.00 by 5%"
- Quantity variance check: If invoice quantity > PO outstanding quantity:
  - Create E-Doc. PO Match Warning record
  - Warning type = Quantity Exceeded
  - Warning message = "Invoice quantity 110 exceeds PO outstanding quantity 100 by 10"
- Warnings don't block Finish step but appear in E-Doc. PO Match Warning table
- Users review warnings via "Review Match Warnings" action before posting

## Match persistence and audit

E-Doc. Purchase Line PO Match records persist after Finish step completes:

1. Records remain in table after Purchase Invoice created
2. Link is preserved: E-Document Line → PO Line → Purchase Invoice Line
3. Reporting can analyze:
   - Match rate % (matched lines / total lines)
   - Common unmatched items
   - Average price variance for matched lines
   - Copilot accuracy (user accepted/rejected suggestions)
4. Historical match data trains future Copilot suggestions
5. Match records are deleted only when E-Document is deleted (cascade)

## Copilot grounding and learning

EDocPOCopilotMatching implements grounding to improve suggestions:

1. After Copilot provides match suggestions
2. User reviews and accepts/rejects each suggestion
3. Accepted matches are marked as "Confirmed" in match table
4. Rejected suggestions are logged to E-Doc. Activity Log with rejection reason
5. Next time Copilot runs for same vendor/item patterns:
   - Learns from confirmed matches (reinforces similar suggestions)
   - Avoids rejected patterns (reduces false positives)
6. Grounding data feeds back into AOAI Function context window:
   - System prompt includes recent confirmed matches as examples
   - AI learns company-specific matching preferences over time
