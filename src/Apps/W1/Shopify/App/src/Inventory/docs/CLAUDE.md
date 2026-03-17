# Inventory

Handles stock level synchronization from BC to Shopify. This is typically one-way -- BC is the source of truth for inventory, and the connector pushes calculated stock levels to Shopify per-location.

## How it works

The module uses a two-tier data model. `ShpfyShopLocation` maps each Shopify location to BC locations via a `Location Filter` expression (e.g., `EAST|WEST`), and carries a `Stock Calculation` enum that controls how stock is computed. `ShpfyShopInventory` stores per-variant, per-location stock levels with both the last-calculated BC stock and the last-imported Shopify stock, plus timestamps for each.

`ShpfySyncInventory` drives the sync loop: first it imports current Shopify stock levels for all enabled locations (via `ShpfyInventoryAPI.ImportStock`), then it exports any differences (via `ExportStock`). During import, inventory records that no longer exist in Shopify are tracked by SystemId and cleaned up afterward by `RemoveUnusedInventoryIds`. During export, `CalcStock` computes BC stock, compares it to `Shopify Stock`, and only pushes when they differ. The export batches up to 250 quantities per `inventorySetQuantities` mutation call, and retries up to 3 times on concurrency errors (`IDEMPOTENCY_CONCURRENT_REQUEST`, `CHANGE_FROM_QUANTITY_STALE`).

Stock calculation is interface-driven. The `ShpfyStockCalculation` enum implements both `ShpfyStockCalculation` (the `GetStock` method) and `ShpfyIStockAvailable` (the `CanHaveStock` guard). Built-in options are Disabled, Projected Available Balance Today (`ShpfyBalanceToday`), and Free Inventory (`ShpfyFreeInventory`). The enum is extensible, so extensions can add custom calculation strategies. There is also `ShpfyExtendedStockCalculation` which extends the base interface with a location-aware overload.

## Things to know

- `ShpfyInventoryEvents.OnAfterCalculationStock` fires after every stock calculation, letting extensions adjust the final number before it is pushed to Shopify (e.g., subtracting safety stock).
- Negative calculated stock is clamped to 0 before sending to Shopify -- see the `if ShopInventory.Stock < 0 then JQuantity.Add('quantity', 0)` branch in `CalcStock`.
- UoM conversion is applied when a variant maps to a non-base unit of measure, dividing the stock by `Qty. per Unit of Measure`.
- The `Default Product Location` flag on `ShpfyShopLocation` controls which locations new products are auto-added to in Shopify. You cannot mix standard locations with fulfillment service locations for this flag.
- The `Is Fulfillment Service` field distinguishes 3PL locations from physical warehouses. Fulfillment service locations carry their own service ID and callback URL.
- Items of type Non-Inventory and Service are excluded from stock calculation entirely.
