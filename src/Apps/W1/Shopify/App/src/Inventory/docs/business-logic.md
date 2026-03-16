# Business logic

## Overview

Inventory synchronization maintains stock level parity between BC and Shopify. It supports flexible location mapping, multiple calculation strategies, and handles UOM conversions.

## Key codeunits

### Shpfy Sync Inventory (30197)

- **Key procedures**: OnRun trigger (TableNo = Shpfy Shop Inventory)
- **Data flow**:
  1. Filters shop locations by shop code and stock calculation <> Disabled
  2. Calls InventoryAPI.ImportStock for each location
  3. Calls InventoryAPI.ExportStock with all shop inventory records
  4. Removes unused inventory IDs (variants deleted in Shopify)

### Shpfy Inventory API (30195)

- **Key procedures**:
  - ImportStock: retrieves inventory levels from Shopify
  - ExportStock: sends calculated stock to Shopify
  - GetStock: calculates BC stock for a variant/location
- **Data flow**:
  - Import: ExecuteGraphQL(GetInventoryEntries) -> ImportInventoryLevels -> update Shopify Stock field
  - Export: CalcStock for each record -> build JSON quantities array -> ExecuteGraphQL(ModifyInventory)
  - Pagination: HasNextResults checks pageInfo.hasNextPage, GetNext* queries continue with cursor

## Processing flows

### Stock import from Shopify

1. ImportStock called with ShopLocation
2. Builds parameters with LocationId
3. Executes GetInventoryEntries GraphQL query
4. ImportInventoryLevels parses JSON:
   - Extracts InventoryItemId, VariantId, ProductId, Stock from edges.node
   - Updates or inserts Shpfy Shop Inventory record
   - Sets Shopify Stock field (not calculated Stock field)
   - Removes processed inventory ID from tracking list
5. Repeats with GetNextInventoryEntries if hasNextPage
6. RemoveUnusedInventoryIds deletes records still in list (deleted variants)

### Stock export to Shopify

1. ExportStock called with shop inventory recordset
2. For each record: CalcStock determines if update needed
3. If Stock <> Shopify Stock and location CanHaveStock:
   - Builds JSON quantity object: `{inventoryItemId, locationId, quantity, changeFromQuantity: null}`
   - Adds to JQuantities array
4. When batch reaches 250: ExecuteInventoryGraphQL sends mutation
5. Mutation uses idempotency key to prevent duplicates on retry
6. Retries up to 3 times if concurrency errors (IDEMPOTENCY_CONCURRENT_REQUEST, CHANGE_FROM_QUANTITY_STALE)

### Stock calculation strategies

#### Projected Available Balance Today (Shpfy Balance Today)

- Implementation: calls ItemAvailabilityFormsMgt.CalcAvailQuantities
- Returns: ProjAvailableBalance (inventory + supply - demand through today)
- Use case: prevent overselling by considering future demand

#### Non-reserved Inventory (Shpfy Free Inventory)

- Implementation: calculates Inventory - Reserved Quantity
- Returns: unreserved stock available for new orders
- Use case: prevent selling reserved inventory

#### Disabled (Shpfy Disabled Value)

- Returns: 0
- CanHaveStock: false
- Use case: exclude location from sync

### Location mapping

- **Shpfy Shop Location** table stores Shopify location properties:
  - Id: Shopify location ID
  - Name: Shopify location name
  - Location Filter: BC location code filter (e.g., "BLUE|RED|GREEN")
  - Default Location Code: BC location for sales documents
  - Stock Calculation: which strategy to use
  - Active, Is Primary, Is Fulfillment Service: Shopify flags
- When calculating stock:
  1. ShopLocation.Location Filter applied to Item."Location Filter"
  2. ShopLocation."Stock Calculation" determines which interface implementation
  3. If variant has UOM in option: stock converted from base UOM to sales UOM

### Unit of measure conversion

1. GetStock retrieves item's Sales Unit of Measure
2. If variant has UoM Option Id (1, 2, or 3):
   - Extracts UOM code from Option 1/2/3 Value
3. StockCalculation.GetStock returns quantity in base UOM
4. If UOM <> Base UOM:
   - Looks up Item Unit of Measure record
   - Divides stock by Qty. per Unit of Measure
5. Returns converted quantity
