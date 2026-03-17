# Inventory

Stock calculation and export to Shopify, driven by a per-location strategy pattern.

Each Shopify location (`Shpfy Shop Location` table) carries a `Stock Calculation` enum that implements two interfaces simultaneously -- `Shpfy Stock Calculation` (computes the number) and `Shpfy IStock Available` (decides whether the location can hold stock at all). The built-in strategies are "Disabled" (returns 0, marks location as non-stocking), "Projected Available Balance Today" (`ShpfyBalanceToday.Codeunit.al` -- uses `ItemAvailabilityFormsMgt.CalcAvailQuantities`), and "Non-reserved Inventory" (`ShpfyFreeInventory.Codeunit.al` -- `Inventory - Reserved Qty. on Inventory`). The enum is `Extensible = true`, so partners can add custom calculations.

The `Shpfy Extended Stock Calculation` interface extends `Shpfy Stock Calculation` with a location-aware overload. `ShpfyInventoryAPI` checks at runtime whether the resolved implementation supports the extended interface and calls the appropriate overload -- this lets custom implementations filter by BC location without the connector knowing the details.

Location mapping is central. `Shpfy Shop Location` has a `Location Filter` field (a BC location code filter expression) that scopes the Item record before stock calculation, plus a `Default Location Code` used on sales documents. The report `ShpfyCreateLocationFilter.Report.al` provides a picker UI to build the filter string. Locations are synced from Shopify via `ShpfySyncShopLocations.Codeunit.al`, which also manages fulfillment service callback URLs.

The sync flow in `ShpfySyncInventory.Codeunit.al` first imports current Shopify inventory levels per location (via paginated GraphQL), then exports calculated BC stock using `inventorySetQuantities` mutations batched in groups of 250. Export uses an idempotency key and retries up to 3 times on `IDEMPOTENCY_CONCURRENT_REQUEST` / `CHANGE_FROM_QUANTITY_STALE` errors. Negative stock is clamped to 0. UoM conversion happens when the variant's UoM option differs from the item's base UoM.

The `OnAfterCalculationStock` integration event in `ShpfyInventoryEvents.Codeunit.al` fires after every stock calculation with the Item, Shop, LocationFilter, and a `var StockResult` -- this is the primary extension point for partners who want to adjust the final number without replacing the entire strategy.
