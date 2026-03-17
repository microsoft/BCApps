# Inventory

Synchronizes stock levels between Business Central and Shopify, mapping BC locations to Shopify locations and calculating available inventory using pluggable stock calculation strategies.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfySyncInventory.Codeunit.al`, `Codeunits/ShpfyInventoryAPI.Codeunit.al`
- **Key patterns**: Interface-based strategy pattern for stock calculation, enum-driven implementation selection

## Structure

- Codeunits (9): sync orchestration, API calls, stock calculation implementations (BalanceToday, FreeInventory, CanHaveStock, CanNotHaveStock, DisabledValue), events
- Tables (2): ShpfyShopInventory, ShpfyShopLocation
- Enums (3): InventoryManagement, InventoryPolicy, StockCalculation
- Interfaces (3): IStockAvailable, StockCalculation, ExtendedStockCalculation
- Pages (2): InventoryFactBox, ShopLocationsMapping
- Reports (2): CreateLocationFilter, SyncStockToShopify

## Key concepts

- The `Shpfy Stock Calculation` enum implements both `Shpfy Stock Calculation` and `Shpfy IStock Available` interfaces, so each enum value provides its own stock calculation logic and stock availability check
- Built-in calculations: "Projected Available Balance Today" and "Non-reserved Inventory" (free inventory); "Disabled" turns off sync for a location
- `ShpfyShopLocation` maps a Shopify location to a BC location filter and a default location code, and controls which stock calculation is used per location
- The sync flow first imports current inventory from Shopify, then exports calculated BC stock back to Shopify
- The `ExtendedStockCalculation` interface allows third-party extensions to plug in custom stock calculations
