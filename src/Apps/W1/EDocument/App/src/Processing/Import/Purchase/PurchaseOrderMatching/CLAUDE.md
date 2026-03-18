# Purchase order matching

Purchase order matching links imported invoice lines to existing purchase orders, enabling 3-way match validation (PO + Receipt + Invoice) and preventing over-invoicing. This subsystem provides both manual matching UI and Copilot-powered automatic matching based on line descriptions and quantities.

## How it works

During Prepare step, after master data resolution completes, the system checks if PO matching is enabled on the service. If enabled, EDocPOMatching.LoadAvailablePOLinesForEDocumentLine queries purchase order lines that are candidates for matching: same vendor as resolved [BC] Vendor No., document type = Order, not already matched to other e-document lines.

Manual matching opens E-Doc. Select PO Lines page showing candidate lines with quantities, prices, and outstanding amounts. Users select lines that correspond to imported invoice lines, optionally splitting quantities across multiple PO lines. The system creates E-Doc. Purchase Line PO Match records linking imported line SystemId to PO line SystemId.

Copilot matching (if enabled in service configuration) calls EDocPOCopilotMatching with imported line descriptions and candidate PO lines. The AI analyzes text similarity, quantity matching, and price variance, returning match suggestions with confidence scores. Suggestions above the configured threshold are auto-accepted; lower-confidence suggestions are presented for user review.

During Finish step, matched lines create Purchase Invoice documents with "Order No." and "Order Line No." fields set, linking the invoice to the PO. The system validates invoice quantity doesn't exceed PO outstanding quantity and price variance is within configured tolerance. Warnings are logged if thresholds are exceeded but processing continues (users can review before posting).

Receipt matching extends PO matching to 3-way scenarios. The system can match invoice lines to posted receipt lines rather than order lines, validating invoice quantity matches received quantity and preventing double-invoicing for partial receipts.

## Things to know

- **Matching scope filtering** -- E-Doc. PO Matching Setup table defines filters for candidate PO lines (date range, specific orders, item categories). This reduces candidates shown to users and improves Copilot accuracy by focusing on relevant orders.
- **Quantity splitting** -- Users can split a single imported line across multiple PO lines. For example, invoice line for 100 units can match 60 units from PO #1 and 40 units from PO #2. Split matches create multiple E-Doc. Purchase Line PO Match records with quantities.
- **Receipt-based matching** -- Configuration option enables matching to receipt lines instead of order lines. This validates invoices against what was actually received rather than what was ordered, preventing over-invoicing from partial receipts.
- **Price tolerance** -- E-Doc. PO Matching Setup specifies maximum % price difference between invoice and PO. Matches exceeding tolerance generate warnings in E-Doc. PO Match Warning table but don't block processing. Users review warnings before posting.
- **Copilot confidence threshold** -- Matches with confidence below configured threshold (default 0.7) are presented as suggestions requiring user approval. Matches above threshold are auto-accepted during automatic processing, reducing manual review burden.
- **Match persistence** -- PO match records persist after Finish step, enabling audit of which invoice lines matched which PO lines. This history is used by reporting to analyze matching accuracy and identify frequently unmatched items.
- **Undo behavior** -- Undoing Prepare step deletes all PO match records for the document. Undoing Finish step preserves matches, enabling re-generation of invoice with same matches but different field mappings.
