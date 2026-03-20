# Subcontracting

This app adds enhanced subcontracting support to Business Central's manufacturing module. It lets you outsource routing operations to vendor subcontractors, automatically create purchase orders from routing lines, and manage how components get to the subcontractor's location -- via direct purchase, vendor-held inventory, or transfer orders. It bridges the gap between BC's manufacturing, purchasing, and transfer order domains that base BC handles only partially.

## Quick reference

- **ID range**: 99001500--99001600
- **Objects**: 150 files (64 codeunits, 27 table extensions, 34 page extensions, 10 pages, 5 reports, 7 enums, 2 tables)

## How it works

The core concept is that a Work Center has a Subcontractor No. (a Vendor). When a production order's routing includes such a work center, the routing operation is outsourced. The app creates a purchase order to the subcontractor for the manufacturing service, and separately handles getting the raw materials (components) to the subcontractor's location.

Component provisioning is controlled per Production BOM Line via the "Subcontracting Type" enum, which flows through to Prod. Order Components. The three strategies are: **Purchase** -- the subcontractor buys the components and you get a component purchase line on the subcontracting PO; **InventoryByVendor** -- components are already at the vendor's location (same location-swap behavior as Purchase, but no additional PO lines); and **Transfer** -- you ship components from your location to the subcontractor via transfer orders, with full item tracking and reservation entry handoff. Each strategy changes the component's Location Code differently: Purchase/InventoryByVendor redirect to the vendor's "Subcontr. Location Code", while Transfer preserves the original location (storing it in "Orig. Location Code" for rollback).

Purchase order creation from routing lines follows a specific path: `SubcPurchaseOrderCreator` calculates the quantity to purchase (accounting for scrap and already-ordered quantities), inserts a Requisition Worksheet line, then immediately runs "Carry Out Action Msg." to convert it into a real purchase order. The pricing comes from the `SubcontractorPrice` table, which has a 9-field composite primary key supporting multi-dimensional price lookups by vendor, item, work center, variant, standard task, date, UOM, minimum quantity, and currency.

The app extends base BC entirely through table extensions, page extensions, and event subscribers -- it introduces only two new tables (SubcontractorPrice and SubcManagementSetup). Everything else is wired into existing BC tables via field additions and codeunit event subscriptions. The Production Order gets a "Created from Purch. Order" flag; Purchase Lines get fields linking back to the production order's routing; Transfer Lines get bidirectional references to both the purchase order and the production order.

The app does NOT handle warehouse management integration beyond basic location/bin code assignment, does not manage subcontractor capacity planning, and does not extend to assembly orders. It is scoped to manufacturing production orders with routing-based subcontracting.

## Structure

- `src/Setup/` -- The singleton setup table and its page
- `src/Process/Codeunits/` -- Core business logic: `SubcontractingManagement` (orchestrator), `SubcPurchaseOrderCreator` (PO creation), `SubcSynchronizeManagement` (qty/date sync and cascade delete), `SubcPriceManagement` (price resolution), `SubcFactboxMgmt` (UI helper navigating across documents)
- `src/Process/Codeunits/Extensions/` -- Event subscribers organized by domain: Manufacturing/, Purchase/, Transfer/, Warehouse/. These wire the app into base BC events
- `src/Process/Tableextensions/` -- Field additions organized the same way: Manufacturing/, MasterData/, Purchase/, Transfer/
- `src/Process/Pageextensions/` -- UI surface organized by domain: Manufacturing/, MasterData/, Purchase/, Transfer/, Warehouse/
- `src/Process/Tables/` -- Just SubcontractorPrice
- `src/Process/Pages/` -- Factbox pages and the SubcontractorPrices list
- `src/Process/Enumerations/` -- SubcontractingType, ComponentsAtLocation, DirectTransferPostType, TransferSourceType
- `src/Process/Reports/` -- 5 reports for creating routings, transfer orders, return orders, dispatching lists, and detailed cost calculations
- `src/Process/Prod Order Creation Wizard/` -- The wizard flow that creates production orders from purchase lines, including temporary table handling and BOM/routing version management
- `src/General/` -- SingleInstanceDictionary (cross-subscriber state passing)
- `src/Install/` -- Installation and company initialization
- `src/Permissions/` -- Permission sets

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)
- [src/Process/docs/](src/Process/docs/) -- Process folder overview and transfer domain deep-dive
- [src/Process/Prod Order Creation Wizard/docs/](src/Process/Prod%20Order%20Creation%20Wizard/docs/) -- Wizard for creating production orders from purchase lines

## Things to know

- SubcManagementSetup is a singleton god-config table controlling everything from requisition worksheet names to wizard UI behavior to default flushing methods -- you must call `GetSubmanagementSetup()` to cache it, and many procedures silently exit if the record doesn't exist
- Component provisioning strategy ("Subcontracting Type") is set per BOM line and flows through to prod. order components via `SubcCalcProdOrderExt`, which also snapshots the original location/bin into "Orig. Location Code" / "Orig. Bin Code" for rollback
- Purchase lines can only reference Released production orders -- the status filter is enforced via TableRelation on every field that points to Production Order or Prod. Order Line
- Work Center must have both "Subcontractor No." and "Gen. Prod. Posting Group" populated to participate in subcontracting; `CheckProdOrderRtngLine` enforces this before creating POs
- Direct Transfer vs. standard transfer posting is controlled at the Location level via "Direct Transfer Posting" enum, not at the transfer order level -- the transfer header inherits it from the destination location
- The "Created from Purch. Order" flag on Production Order enables reverse synchronization: PO quantity and date changes propagate back to the production order via `SubcSynchronizeManagement`, but only when no receipts have been posted yet
- Vendor change on purchase header triggers cascade delete of linked production orders, transfer orders, and component purchase lines -- but only if no Item Ledger Entries or Capacity Ledger Entries exist for that production order
- SubcontractingManagement is the central orchestrator with procedures for location changes, subcontractor lookup, reservation transfers, and component location management
- SubcPurchaseOrderCreator handles PO creation from routing lines by inserting a requisition line and immediately running "Carry Out Action Msg." to convert it
- The app publishes 6 InternalEvents: `OnBeforeGetSubcontractor`, `OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor`, `OnBeforeShowCreatedPurchaseOrder`, `OnAfterInsertRoutingHeader`, `OnAfterTransferSubcontractingFieldsBOMComponent`, and `OnBeforeBuildTemporaryStructureFromBOMRouting`
- The SingleInstanceDictionary codeunit is a workaround for passing state (vendor no., calculation dates, item record IDs) between event subscribers that have no direct calling relationship -- it uses `Dictionary of [Text, Code[1024]]` keyed by string constants
- The Prod Order Creation Wizard (`SubcCreateProdOrdOpt`) works entirely with temporary copies of Production BOM Lines, Routing Lines, and Prod. Order Components, only committing to real tables after the user confirms -- making it safe to cancel without side effects
