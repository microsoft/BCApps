# Inventory

Synchronizes BC item stock levels to Shopify inventory per location.
Push-only (BC to Shopify) -- reads current Shopify stock to detect drift,
then overwrites with calculated BC stock.

## How it works

`Shpfy Shop Location` (`Tables/ShpfyShopLocation.Table.al`) maps Shopify
locations to BC locations. The `Location Filter` field accepts filter
expressions (`EAST|WEST`, `A*`), not just single codes. `Default Location Code`
is separate, used on sales documents.

Stock calculation is interface-driven. The `Shpfy Stock Calculation` enum
implements both `Shpfy Stock Calculation` (compute stock) and
`Shpfy IStock Available` (can this item type have stock). Three built-in
values: `Disabled`, `Projected Available Balance Today`, and
`Non-reserved Inventory`. The enum is `Extensible = true`.

The `Shpfy Extended Stock Calculation` interface extends the base to also
receive the Shop Location record. `InventoryAPI` checks for this via `is`
type check and downcasts when available.

Sync in `ShpfySyncInventory` imports Shopify stock per location, then
exports recalculated BC stock. `InventoryAPI` batches up to 250 quantities
per GraphQL mutation with idempotency keys and 3 retries on concurrency
errors.

## Things to know

- Each Shop Location has its own `Stock Calculation` setting -- different
  locations can use different strategies.
- `OnAfterCalculationStock` event allows post-calculation stock adjustment.
- Fulfillment service locations cannot mix with standard locations for
  `Default Product Location`.
- Negative stock is clamped to zero. Non-Inventory and Service items skip.
