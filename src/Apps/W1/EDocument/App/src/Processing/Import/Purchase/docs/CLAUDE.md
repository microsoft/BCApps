# Purchase

Pages and tables for the purchase import UI and the core `E-Document Purchase Line` table. This is where users review and edit draft purchase data before it becomes a real BC purchase document. Also contains the `History/` subdirectory for tracking vendor assignment and line mapping history across invoices.

## How it works

`E-Document Purchase Line` (6101) is the primary draft line table. Its fields are split into two regions: external data fields (3-100) that hold raw values from the source document (product code, description, unit price, quantity), and `[BC]` fields (101+) that hold resolved BC values (purchase line type, type no., unit of measure code, item reference). The prepare draft step populates the `[BC]` fields; the external fields are populated during the read-into-draft step.

The pages -- `EDocReadablePurchaseDoc`, `EDocReadPurchLines`, `EDocDraftFeedback` -- provide the read-only and editable views for the draft. `EDocDraftFeedback` is used to display validation results and warnings to the user.

The `History/` subdirectory contains `E-Doc. Purchase Line History` and `E-Doc. Vendor Assign. History` tables plus the `EDocPurchaseHistMapping` codeunit that finds previous invoices for the same vendor and copies line-level settings (account, deferral, dimensions) to new drafts.

## Things to know

- `E-Document Line Mapping` (6105) is the V1 line mapping table. In V1, users manually set the purchase line type, type number, UOM, and dimensions per line. In V2, this is replaced by the `[BC]` fields on `E-Document Purchase Line` plus the additional fields EAV system.

- The `E-Doc. Purchase Line History` table stores the SystemId of the `Purch. Inv. Line` that was created when a previous e-document was posted. This enables the "copy from history" pattern used by both the additional fields system and the prepare draft step.

- `E-Doc. Vendor Assign. History` tracks which vendor was assigned to previous e-documents from the same source, enabling automatic vendor resolution for repeat senders.

- The `EDocPurchaseHistMapping` codeunit ties historical mapping together -- it searches for past invoices from the same vendor, matches lines by description similarity, and copies the resolved values to the new draft.
