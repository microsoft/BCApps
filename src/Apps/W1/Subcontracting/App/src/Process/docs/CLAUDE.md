# Process

The Process folder contains the bulk of the Subcontracting app's runtime logic -- everything that executes when users create purchase orders, transfer components, post shipments, or calculate prices. Files are organized first by AL object type (Codeunits, Tableextensions, Pageextensions, etc.) and then by business domain within each type folder (Manufacturing, Purchase, Transfer, Warehouse, MasterData).

## How it works

The folder uses a dual organization scheme. Top-level subfolders correspond to AL object types: `Codeunits/`, `Tableextensions/`, `Pageextensions/`, `Tables/`, `Pages/`, `Enumerations/`, and `Reports/`. Within the `Codeunits/Extensions/`, `Tableextensions/`, and `Pageextensions/` folders, files are further grouped by domain -- Manufacturing, Purchase, Transfer, Warehouse, and MasterData. A few extension codeunits and table extensions sit directly in their parent folder when they span multiple domains (e.g., `SubcItemLedgerEntry.TableExt.al`, `SubcReqLineExtension.Codeunit.al`).

The eight core codeunits in `Codeunits/` are the orchestrators. `SubcontractingManagement` is the central hub -- it handles component location changes, reservation entry transfers between Prod. Order Components and Transfer Lines, and subcontractor vendor lookup. `SubcPurchaseOrderCreator` drives purchase order creation from routing lines via the requisition worksheet. `SubcSynchronizeManagement` keeps production order quantities and dates in sync when purchase lines change. `SubcPriceManagement` resolves subcontractor prices from the `SubcontractorPrice` table, with UOM conversion and currency handling. `SubcFactboxMgmt` provides the drill-down logic behind all factbox cues on purchase, transfer, and production order pages.

The 35 extension codeunits in `Codeunits/Extensions/` subscribe to base app events to inject subcontracting behavior without modifying base app code. Manufacturing and Purchase domain extensions are mostly thin event wiring -- they copy subcontracting fields between records or delegate to core codeunits. The Transfer domain is the most complex part of the app, with 13 codeunits handling posting overrides, reservation entry rewiring, item tracking preservation, and warehouse direct posting orchestration. The `SubcTransOrderPostTransExt` codeunit alone handles the hardest problem: reassembling reservation chains from Transfer Line back to Prod. Order Component after a direct transfer posts, including surplus tracking for unmatched entries.

## Things to know

- The `Subcontracting Type` enum on Prod. Order Component (`Empty`, `Purchase`, `InventoryByVendor`, `Transfer`) controls which flow a component follows. Only `Transfer` type components get transfer orders created for them; `Purchase` components are added directly to the subcontracting purchase order as item lines via `TransferSubcontractingProdOrderComp` in `SubcPurchaseOrderCreator`.

- Transfer orders are created by two reports -- `SubcCreateTransfOrder.Report.al` for outbound transfers and `SubcCreateSubCReturnOrder.Report.al` for returns. These are processing-only reports triggered from purchase order actions, not codeunit procedures. They reuse existing open transfer headers when possible (matching on vendor, from/to location, and return order flag).

- The `Direct Transfer Posting` enum on Location (`Empty`, `Receipt and Shipment`, `Direct Transfer`) propagates to Transfer Header when Transfer-to Code is validated. The `SubcTransferPostExt` codeunit overrides the base app's default "Post Transfer Order" dialog to respect this enum -- running shipment+receipt sequentially, a single direct transfer, or skipping entirely.

- The `Components at Location` enum (`Purchase`, `Company`, `Manufacturing`) in Subc. Management Setup controls where the transfer-from location comes from when creating transfer orders -- the purchase line's location, Company Information, or Manufacturing Setup respectively. This is a setup-level decision, not per-order.

- Reservation entries are transferred in two phases during transfer order creation: first from Prod. Order Component to Transfer Line (outbound), then a matching inbound reservation is created from Transfer Line to Prod. Order Component at the destination. The `TempGlobalReservationEntry` temporary table in `SubcontractingManagement` bridges these two phases within a single call.

- The `SubcWhseDirectPosting` codeunit implements one-step warehouse posting for subcontracting transfers. When a transfer header uses `Receipt and Shipment` posting and the destination location has no inbound warehouse handling, it automatically posts the receipt immediately after the shipment completes -- suppressing commits to keep both in a single transaction.

- Every transfer document type gets the same set of subcontracting fields copied through its lifecycle: Transfer Header to Transfer Shipment Header, Transfer Line to Transfer Shipment Line, etc. This is handled by 6 separate copy-field extension codeunits (`SubcTransShptHeaderExt`, `SubcTransRcptHeaderExt`, `SubcTransferShptLineExt`, `SubcTransferRcptLineExt`, `SubcDirectTransferLineExt`, `SubcTransferLineExt`). If you add a new field to Transfer Line, you must also add it to all posted line types.
