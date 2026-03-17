# Inventory

Stock level sync from BC to Shopify. The flow is primarily export-oriented -- BC calculates stock per item/variant/location and pushes it to Shopify. Import of current Shopify stock levels happens first to enable delta calculations, but can be skipped via `SetSkipImport`.

## How it works

`ShpfySyncInventory.Codeunit.al` (TableNo = "Shpfy Shop Inventory") runs in two phases. First, unless `SkipImport` is set, it iterates all `Shpfy Shop Location` records where `Stock Calculation` is not Disabled, calling `InventoryAPI.ImportStock` for each to pull current Shopify quantities into `Shpfy Shop Inventory`. Then it calls `InventoryAPI.ExportStock` to push BC-calculated stock.

The actual stock calculation lives in `ShpfyInventoryAPI.GetStock`. For each `Shpfy Shop Inventory` row, it resolves the linked Item via the variant's `Item SystemId`, applies the location's `Location Filter` and variant filter, then delegates to the `Shpfy Stock Calculation` interface. The enum (`ShpfyStockCalculation.Enum.al`) provides two built-in strategies -- "Projected Available Balance at Today" (`ShpfyBalanceToday`) and "Free Inventory (not reserved)" (`ShpfyFreeInventory`). The enum is `Extensible = true` and implements two interfaces simultaneously: `Shpfy Stock Calculation` for the basic `GetStock(Item)` signature and `Shpfy IStock Available` which controls whether a location reports as stock-capable at all. There is also `Shpfy Extended Stock Calculation`, an interface that extends the base with a `GetStock(Item, ShopLocation)` overload -- `GetStock` checks `is "Shpfy Extended Stock Calculation"` at runtime to pick the right call.

After the strategy returns a value, `GetStock` adjusts for unit of measure (if the variant maps to a UoM option), then fires `OnAfterCalculationStock` from `ShpfyInventoryEvents.Codeunit.al` to let subscribers apply custom adjustments.

## Things to know

- Each Shopify location maps to one `Shpfy Shop Location` row, which carries a `Location Filter` (a text filter like "MAIN|WEST") for aggregating stock across multiple BC locations, and a `Default Location Code` used on sales documents. Setting one auto-populates the other if blank.
- `Default Product Location` on a shop location cannot mix standard locations with fulfillment service locations -- the validate trigger on `ShpfyShopLocation.Table.al` blocks this with a client error.
- `Is Fulfillment Service` distinguishes merchant warehouses from 3PL providers; fulfillment service locations carry their own callback URL and service ID.
- The `Shpfy Shop Inventory` table is keyed by `[Shop Code, Product Id, Variant Id, Location Id]` and tracks both `Shopify Stock` (last imported) and `Stock` (last calculated from BC), each with its own timestamp.
- `Disabled` is the `InitValue` for `Stock Calculation` on new locations -- stock sync is opt-in per location, not automatic.
- The `SyncShopLocations` codeunit pulls the list of locations from Shopify; it runs separately from the inventory sync itself.
