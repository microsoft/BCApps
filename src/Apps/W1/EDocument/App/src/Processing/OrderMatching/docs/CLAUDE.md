# Order matching (V1)

The V1 purchase order line matching system. When an incoming e-document is linked to an existing purchase order, this module lets users (or the automatic matcher) pair imported e-document lines with PO lines, adjusting quantities and costs before the PO is updated.

## How it works

`EDocLineMatching` is the central codeunit. It provides automatic matching (filter on UOM, cost, discount, then check description similarity at 80% threshold or item reference/text-to-account mapping match), manual matching (user-selected pairs with validation), and the `ApplyToPurchaseOrder` procedure that commits matches by updating purchase line costs and quantities.

`E-Doc. Imported Line` (6165) is a buffer table that holds parsed e-document line data in a form suitable for matching. Lines are inserted during V1 import processing from the parsed purchase lines. `E-Doc. Order Match` (6164) is the many-to-many join between imported lines and PO lines, storing matched quantity, unit costs from both sides, and descriptions for the matching UI.

The matching pages (`EDocOrderLineMatching`, `EDocImportedLineSub`, `EDocPurchaseOrderSub`, `EDocOrderMatch`, `EDocOrderMatchAct`) provide side-by-side views of imported and PO lines with match/unmatch actions.

## Things to know

- Automatic matching uses string nearness (80% threshold via `RecordMatchMgt.CalculateStringNearness`) as a fallback when no item reference or text-to-account mapping exists. This means description-only matches require high similarity.

- When matching many imported lines to one PO line, all imported lines must have identical unit cost, discount %, and UOM. The system validates this strictly and errors if they differ.

- `ApplyToPurchaseOrder` validates all imported lines are fully matched before proceeding. Partial matches are rejected at the point of applying to the PO.

- The `CreateMatchingRule` procedure creates `Item Reference` or `Text-to-Account Mapping` records when the user checks "Learn Matching Rule" -- this teaches the system for future automatic matching.

- `CreatePurchaseOrderLine` allows creating a new PO line directly from the matching page when no suitable PO line exists for an imported line.

- This module is distinct from `Import/Purchase/PurchaseOrderMatching/` which handles V2 matching. V1 works on `E-Doc. Imported Line`; V2 works on `E-Document Purchase Line`.
