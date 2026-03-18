# Order matching engine

The Order matching engine provides generic purchase order line matching infrastructure used by the Import subsystem's PurchaseOrderMatching module. It includes shared data models, matching algorithms, and UI components that support both manual and AI-powered line-level matching between imported documents and existing purchase orders.

## How it works

The order matching engine provides E-Doc. Imported Line table to store extracted line data before resolution to purchase records. This table is populated during Read step and serves as the source for matching logic during Prepare step. Each imported line has both external values (item description from document) and Business Central references ([BC] Item No., [BC] Vendor No.) populated during master data resolution.

Matching logic is implemented in EDocLineMatching codeunit, which provides both manual and Copilot-powered matching. Manual matching loads candidate purchase order lines filtered by vendor and date range, displays them in a selectable list, and creates E-Doc. Order Match records linking imported lines to selected PO lines. Copilot matching (in Copilot subdirectory) calls AOAI Function with line descriptions and receives similarity-scored match suggestions.

The E-Doc. Order Match table stores match relationships with quantity tracking for split scenarios (one imported line matched to multiple PO lines). Match records persist after Finish step, enabling audit of which invoice lines were matched to which PO lines and with what confidence scores.

Order Match page provides user-facing UI for reviewing and modifying matches. It shows imported lines on the left, candidate PO lines on the right, and allows drag-and-drop or selection-based matching. Match status indicators (green checkmark, yellow warning, red error) show validation results.

## Things to know

- **Imported Line is pre-resolution** -- E-Doc. Imported Line records are created during Read step before master data resolution. They contain external identifiers extracted from the document, not yet validated against Business Central tables.
- **Generic for all document types** -- Order matching infrastructure is generic, used for purchase invoices, purchase credit memos, and sales orders (matching to sales quotes). The same engine handles different document type scenarios.
- **Match table is append-only** -- E-Doc. Order Match records are never updated after creation (except for user confirmation flag). To modify a match, delete the old record and insert a new one. This preserves audit trail.
- **Quantity is optional** -- Match records can specify matched quantity (for splits) or leave blank to match entire line quantity. Blank quantity is interpreted as "match full line".
- **Matching is reversible** -- Users can un-match lines by deleting match records. This doesn't affect imported line data, only the match linkage. Re-matching is allowed with different PO lines.
- **Copilot is optional** -- Services can enable/disable Copilot matching independently. When disabled, only manual matching UI is available. Copilot doesn't replace manual matching, it supplements it with suggestions.
- **Match validation is deferred** -- Matches are created without validation during Prepare step. Validation occurs during Finish step when creating purchase records. This enables users to create tentative matches and review validation warnings before finalizing.
