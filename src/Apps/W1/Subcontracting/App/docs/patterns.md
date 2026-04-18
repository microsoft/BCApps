# Patterns

Recurring design patterns in the Subcontracting codebase, plus legacy patterns you should understand but not replicate.

## Temporary table wizard pattern

The production order creation wizard (`SubcCreateProdOrdOpt.Codeunit.al`) is the most architecturally interesting part of the app. It never modifies real tables until the user confirms. The flow is:

1. `SubcTempDataInitializer` creates temporary copies of Production BOM Header, BOM Lines, Routing Header, Routing Lines, Production Order, Prod. Order Line, Prod. Order Component, and Prod. Order Routing Line
2. BOM and routing data are loaded from the best available source (Stockkeeping Unit or Item)
3. The wizard page binds to these temporary records, letting users edit freely
4. On confirmation, `TransferTemporaryDataToRealTables` creates real records by iterating the temp tables and calling Init/Insert/Validate on real records
5. If the user modified BOM/routing data and it doesn't match any existing certified version, new versions are created with auto-generated numbers from the No. Series

The entire real-table-write phase runs under `[CommitBehavior(CommitBehavior::Ignore)]`, so the caller controls the transaction. And `SubcTempProdOrdBind` uses `BindSubscription` to inject behavior during the production order creation that only applies in the wizard context.

The cleanup is equally careful: if the user chose not to save BOM/routing changes to the item (GlobalSubcRtngBOMSourceType = Empty), newly created BOMs and routings are deleted. But if "Always Save Modified Versions" is true in setup, newly created versions are preserved even without saving to the item.

This pattern is worth studying because it solves a real problem: how to give users an editable preview of what a complex multi-table operation will produce, without leaving orphaned records on cancel.

## Cascading reference tracking

The app maintains bidirectional references across three document types: Purchase Line, Production Order (with its sub-tables), and Transfer Line. Every link is stored on both sides:

- Purchase Line stores Prod. Order No. (base field) and Subc. Prod. Order No./Line No./etc. (extension fields for component lines)
- Transfer Line stores both Subcontr. Purch. Order No. and Prod. Order No.
- Prod. Order Component uses FlowFields that aggregate across Transfer Lines and Item Ledger Entries filtered by these references

This enables `SubcFactboxMgmt` to provide navigation from any document to any related document. The factbox accepts a `Variant` parameter, resolves it to a RecordRef, and switches on the table number to extract the relevant reference fields. It handles Purchase Line, Purch. Rcpt. Line, Purch. Inv. Line, Transfer Line, Transfer Shipment Line, Transfer Receipt Line, Item Ledger Entry, Capacity Ledger Entry, Prod. Order Routing Line, and Prod. Order Component.

The cost of this pattern is maintenance -- every reference field must be populated during document creation, copied during posting (to receipt/shipment/invoice lines), and cleaned up during cascade delete. The app has dedicated procedures for each of these lifecycle events.

## FlowField cross-document quantities

Prod. Order Component uses six FlowFields that aggregate quantities from Transfer Lines and Item Ledger Entries:

- "Qty. transf. to Subcontr" -- sums ILE.Quantity where Entry Type = Transfer, matching prod order/line/comp and a "Purchase Order Filter" FlowFilter
- "Qty. in Transit (Base)" -- sums Transfer Line."Qty. in Transit (Base)" where Return Order = false
- "Qty. on Trans Order (Base)" -- sums Transfer Line."Outstanding Qty. (Base)" where Return Order = false
- Two return-order variants of the transit/outstanding fields

All these FlowFields use the "Purchase Order Filter" FlowFilter to scope to a specific subcontracting PO. This is a key design choice -- without the filter, you'd see quantities from ALL subcontracting activity for that component, which is meaningless when multiple POs reference the same production order.

The five secondary keys on Transfer Line exist primarily to support these FlowFields efficiently. Key99001504 (Prod Order + Prod Line + Comp Line + PO No. + Return Order) directly matches the FlowField filter set.

## SingleInstance dictionary for cross-subscriber state

The `SingleInstanceDictionary` codeunit (codeunit 99001500, `SingleInstance = true`) solves the problem of passing context between event subscribers that have no parameter relationship. It maintains three dictionaries: `Dictionary of [Text, Code[1024]]`, `Dictionary of [Text, Date]`, and `Dictionary of [Text, RecordId]`.

The app uses it in two scenarios:

**Standard cost calculation**: The `OnCalcMfgItemOnBeforeCalcRtngCost` subscriber stores the Item RecordId, `OnAfterSetProperties` stores the calculation date, and `OnAfterCalcRtngLineCost` retrieves both to perform subcontractor price lookup. Without the dictionary, the cost calculation subscriber would have no way to know which item it's calculating for, because the event only provides the routing line and quantity.

**Prod order creation from purchase line**: The vendor number is stored in the dictionary with key `'Sub_CreateProdOrderProcess'`, and the `SubcontractingManagementExt` subscriber retrieves it to set the work center number when the standard lookup fails. The method `GetDictionaryKey_Sub_CreateProdOrderProcess()` centralizes the key string.

Always call `ClearAllDictionariesForKey` after consuming the stored value. Failing to clean up a SingleInstance dictionary means stale values leak across unrelated operations.

## Five-key index strategy on Transfer Line

Transfer Line's five secondary keys (Key99001500 through Key99001504) represent five distinct query patterns the app needs:

- **By purchase order**: Finding all transfer lines for a given PO (used by factbox drill-downs)
- **By production routing**: Finding transfer lines for a specific routing operation (used by factbox and transfer order creation)
- **By purchase order + production routing**: Finding transfer lines that link a specific PO to a specific routing (used by more specific factbox navigation)
- **By production order line**: Finding all transfer lines for a production line regardless of PO (similar to above with different leading columns for optimizer choice)
- **By production component**: The FlowField key -- matches the CalcFormula filters on Prod. Order Component's FlowFields

This is an unusual number of secondary keys for a single table extension. The cost is write amplification on every Transfer Line insert/modify/delete. The benefit is that every navigation path and FlowField evaluation can use an index scan instead of a table scan.

## Manual event subscriber binding

Three codeunits use `EventSubscriberInstance = Manual`:

- **SubcontractingManagementExt** (99001527): Bound during `HandleSubcontractingAfterUpdate` in the wizard and during `SubcCreateProdOrdOpt`'s transfer phase. Provides the vendor-to-work-center fallback via SingleInstanceDictionary.
- **SubcProdOrdCompRes** (99001530): Bound during transfer creation to suppress the reservation verification error that fires when a component's location changes. Without this, swapping a component from location A to the subcontractor's location would trigger an error because the reservation tracking can't auto-track across the location change.
- **SubcCreateProdRtngExt** (99001526): Bound during routing creation to auto-insert a purchase provisioning routing line with the common work center.

This pattern is the right approach when a subscriber should only be active during a specific operation. But it requires careful attention to `UnbindSubscription` -- if an error occurs between bind and unbind, the subscriber stays bound for the rest of the session.

## Legacy patterns

**Find('<') usage**: `GetLineNoBeforeInsertedLineNo` in `SubcPurchaseOrderCreator` uses `Find('<')` wrapped in `#pragma warning disable AA0181`. This is a deprecated record navigation method. The pragma suppresses the compiler warning but the pattern should not be replicated in new code.

**Direct Modify in loops**: Several procedures call `ProdOrderComponent.Modify()` inside `repeat...until` loops without explicit error handling (e.g., `UpdLinkedComponents`, `DelLocationLinkedComponents`). This is technically correct AL but lacks the `Modify(true)` form that runs triggers. The choice between `Modify()` and `Modify(true)` appears intentional here -- the app wants to update field values without re-running validation triggers that would recursively change locations.

**Commented-out code with TODO**: The Transfer Header extension has a TODO comment about Direct Transfer validation: "This causes Quality Management tests to fail. Enable this after the initial checkin and investigate." The code includes a dummy assignment (`"Do Not Validate" := false;`) as a placeholder. This suggests the Direct Transfer Posting feature is not fully integrated with all BC modules yet.

**ModifyAll for field clearing**: `DeleteEnhancedDocumentsByChangeOfVendorNo` uses five sequential `ModifyAll` calls to clear purchase line references. Each `ModifyAll` is a separate SQL UPDATE statement. A single `Modify` in a loop would be fewer round trips for small record sets but more expensive for large ones -- the current approach is pragmatic for the expected cardinality.
