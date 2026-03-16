# Inventory

Stock level synchronization from BC to Shopify. This module calculates available inventory using configurable strategies, maps BC locations to Shopify locations, and pushes stock quantities via the GraphQL `inventorySetQuantities` mutation. It is separate from the Products module, which handles item/variant metadata -- Inventory only deals with numeric stock levels.

## How it works

The core loop runs in `ShpfySyncInventory.Codeunit.al`: it iterates each `Shpfy Shop Location` where `Stock Calculation` is not Disabled, imports current Shopify stock levels via `ShpfyInventoryAPI.Codeunit.al`, then exports recalculated BC stock back to Shopify. The `ShpfyShopLocation` table (30113) maps a Shopify location ID to a `Location Filter` (a BC location code filter) and a `Default Location Code` used on sales documents.

Stock calculation is interface-driven via `Shpfy Stock Calculation` (`ShpfyStockCalculation.Interface.al`). The `Shpfy Stock Calculation` enum (30135) implements two interfaces simultaneously: `Shpfy Stock Calculation` for the actual computation and `Shpfy IStock Available` for the boolean "can this location have stock" check. Built-in strategies are `ShpfyBalanceToday.Codeunit.al` (projected available balance from `ItemAvailabilityFormsMgt.CalcAvailQuantities`) and `ShpfyFreeInventory.Codeunit.al` (on-hand inventory minus reserved). The enum is extensible, so partners can add custom strategies. There is also an `Shpfy Extended Stock Calculation` interface that adds a `ShopLocation` parameter for location-aware calculations.

Export batches up to 250 quantity updates per GraphQL call in `ExportStock`, using an idempotency key and retry logic (up to 3 attempts) for `IDEMPOTENCY_CONCURRENT_REQUEST` and `CHANGE_FROM_QUANTITY_STALE` errors. The `ShpfyShopInventory` table (30112) tracks both the last Shopify-imported stock and the last BC-calculated stock, only sending updates when they differ.

## Things to know

- The `Stock Calculation` enum's `Disabled` value uses `Shpfy Can Not Have Stock` for `IStock Available`, so disabled locations are silently skipped during export rather than zeroed.
- UoM conversion is applied during stock calculation: if the variant's UoM option differs from the item's base UoM, the stock is divided by `Qty. per Unit of Measure`.
- Negative calculated stock is clamped to zero before sending to Shopify (`CalcStock` in `ShpfyInventoryAPI`).
- `SetInventoryIds` / `RemoveUnusedInventoryIds` form a garbage-collection pair -- they track all existing `ShpfyShopInventory` records before import, then delete any that were not refreshed.
- `ShpfyShopLocation` prevents mixing standard Shopify locations with fulfillment service locations for `Default Product Location`.
- Non-Inventory and Service type items are excluded from stock calculation entirely.
- The `OnAfterCalculationStock` event in `ShpfyInventoryEvents.Codeunit.al` allows partners to adjust stock after calculation.
