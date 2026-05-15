# Extensibility

This document covers how to extend the Subcontracting app's behavior and what base BC events it subscribes to.

## Events published by this app

The app publishes 6 InternalEvents. Because they're internal (not public), they're only available to code within the same app or apps that have internalsVisibleTo access.

### How do I override which vendor is treated as the subcontractor?

Subscribe to `OnBeforeGetSubcontractor` in `SubcontractingManagement` (codeunit 99001505). This fires before the standard Work Center -> Vendor lookup. Set `IsHandled := true` and populate `Vendor` and `HasSubcontractor` to bypass the default logic entirely. The default logic calls `WorkCenter.Get(WorkCenterNo)` and reads `"Subcontractor No."`, then calls `TestField("Subcontr. Location Code")` on the vendor.

### How do I override the work center used when creating component purchase lines?

Subscribe to `OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor` in `SubcPurchaseOrderCreator` (codeunit 99001557). This fires during `TransferSubcontractingProdOrderComp` before the app decides which work center's subcontractor to use. Modify `SubContractorWorkCenterNo` to redirect. The app itself uses this event internally -- `SubcontractingManagementExt` subscribes to it to inject the vendor from the SingleInstanceDictionary during the prod-order-from-purchase-line wizard flow.

### How do I customize the "show created PO" dialog?

Subscribe to `OnBeforeShowCreatedPurchaseOrder` in `SubcPurchaseOrderCreator` (codeunit 99001557). Set `IsHandled := true` to suppress the default confirmation dialog and page navigation. You receive the `ProdOrderNo` and `NoOfCreatedPurchOrder` count.

### How do I run custom logic after a routing header is created by the "Create Prod. Routing" report?

Subscribe to `OnAfterInsertRoutingHeader` in the `SubcCreateProdRouting` report (report 99001500). The app itself uses this to auto-create a purchase provisioning routing line via `SubcCreateProdRtngExt`.

### How do I customize BOM-to-component field transfer?

Subscribe to `OnAfterTransferSubcontractingFieldsBOMComponent` in `SubcCalcProdOrderExt` (codeunit 99001517). This fires after the "Subcontracting Type" and "Orig. Location/Bin Code" fields are copied from the Production BOM Line to the Prod. Order Component. Use it to copy additional custom fields or override the transferred values.

### How do I inject logic before the wizard builds temporary production order structures?

Subscribe to `OnBeforeBuildTemporaryStructureFromBOMRouting` in `SubcTempDataInitializer` (codeunit in `Prod Order Creation Wizard/Codeunits/`). You receive the `SubcTempDataInitializer` codeunit instance and can modify the temporary data before it gets transformed into prod order components and routing lines.

## Base BC events this app subscribes to

The app subscribes to approximately 40 base BC events. Here are the most important ones, grouped by what they accomplish.

### Manufacturing pipeline

- **Calculate Prod. Order / OnAfterTransferRoutingLine** (`SubcCalcProdOrderExt`): Applies subcontractor pricing to routing lines and updates linked component locations when a production order is refreshed.
- **Calculate Prod. Order / OnAfterTransferBOMComponent** (`SubcCalcProdOrderExt`): Copies Subcontracting Type from BOM lines to prod order components and snapshots original location codes.
- **Carry Out Action / OnAfterTransferPlanningComp** (`SubcCarryOutActionExt`): Copies subcontracting fields when planning components become prod order components during MPS/MRP carry-out.
- **Planning Line Management / OnAfterTransferRtngLine** (`SubcPlanningLineMgmtExt`): Applies subcontractor pricing during planning routing line creation.
- **Calculate Subcontracts / OnAfterTransferProdOrderRoutingLine** (`SubcCalcSubcontractsExt`): Populates Description 2 from work center during subcontracting worksheet calculation.
- **Calculate Standard Cost / OnAfterCalcRtngLineCost** (`SubcCalcStandardCostExt`): Overrides routing line cost with subcontractor price during standard cost rollup.

### Purchase flow

- **Purchase Header / OnAfterCopyBuyFromVendorFieldsFromVendor** (`SubcPurchaseHeaderExt`): Copies vendor's subcontracting location to purchase header.
- **Purchase Header / OnAfterValidateEvent(Buy-from Vendor No.)** (`SubcPurchaseHeaderExt`): Triggers cascade delete of linked production orders and transfers when vendor changes.
- **Req. Wksh.-Make Order / OnAfterInsertPurchOrderLine** (`SubcReqWkshMakeOrd`): After a requisition line becomes a purchase line, inserts the prod order description line and creates component purchase lines.
- **Purch.-Post / OnBeforeItemJnlPostLine** (`SubcPurchPostExt`): Fills item journal line with subcontracting output entry fields when posting item charges against subcontracting receipt lines.

### Transfer flow

- **Trans. Order Post Receipt/Shipment/Transfer** (multiple codeunits in `Extensions/Transfer/`): Copy subcontracting reference fields from transfer lines to posted document lines during transfer posting.
- **Direct Transfer Line** (`SubcDirectTransferLineExt`): Copies subcontracting fields during direct transfer posting.

### Item posting

- **Item Jnl.-Post Line / OnAfterInitItemLedgEntry** (`SubcItemJnlPostLineExt`): Copies subcontracting fields (Prod. Order No., PO reference, Operation No.) from item journal line to item ledger entry during posting.
- **Mfg. Item Jnl. Check Line / OnBeforeCheckSubcontracting** (`SubcItemJnlCheckExt`): Handles the "Common Work Center" concept -- when an item journal line references the common work center, the standard subcontracting check is bypassed.

### Reservation handling

- **Prod. Order Comp.-Reserve / OnVerifyChangeOnBeforeHasError** (`SubcProdOrdCompRes`): Suppresses the auto-tracking verification error when component location is swapped during transfer creation. This subscriber uses `EventSubscriberInstance = Manual` and is bound only during specific operations.

## Key patterns for extending this app

**Manual event subscriber binding**: Several subscriber codeunits use `EventSubscriberInstance = Manual` (`SubcontractingManagementExt`, `SubcProdOrdCompRes`, `SubcCreateProdRtngExt`). They're bound/unbound at specific points in the flow using `BindSubscription`/`UnbindSubscription`. If you extend these codeunits or create competing subscribers, be aware they only fire during their bound lifetime.

**SetLoadFields discipline**: The app consistently uses `SetLoadFields` before `Get`/`Find` calls. If you add subscribers that access fields not in the load set, you'll need to ensure your fields are loaded.

**SingleInstanceDictionary as state bus**: The `SingleInstanceDictionary` codeunit (SingleInstance = true) acts as a cross-subscriber state-passing mechanism. If you need to pass context from one event subscriber to another where there's no direct parameter path, follow the same pattern: store with a string key, retrieve in the other subscriber, and always clean up afterward.
