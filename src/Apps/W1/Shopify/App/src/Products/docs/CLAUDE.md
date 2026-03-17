# Products module

Bidirectional synchronization of products and variants between Business Central items and Shopify products, including price calculation, image sync, SKU mapping, and collection assignment.

## Quick reference

- Sync direction is controlled by `Shop."Sync Item"` -- either "To Shopify" or "From Shopify"
- Entry point: `Shpfy Sync Products` (codeunit 30185) runs against a `Shpfy Shop` record
- Export creates/updates Shopify products via GraphQL mutations; import fetches product IDs then retrieves details per product
- Bulk operations are used when record counts exceed a threshold (image updates, variant/product mutations)

## Structure

```
Products/
  Codeunits/
    ShpfySyncProducts        -- Orchestrator: dispatches import or export
    ShpfyProductExport       -- BC Item -> Shopify Product (create + update)
    ShpfyProductImport       -- Shopify Product -> BC (mapping + item creation)
    ShpfyCreateProduct       -- Creates a new Shopify product from a BC Item
    ShpfyCreateItem          -- Creates a new BC Item from a Shopify product
    ShpfyProductAPI          -- GraphQL calls for products (CRUD, images, publish)
    ShpfyVariantAPI          -- GraphQL calls for variants (CRUD, find by SKU/barcode)
    ShpfyProductPriceCalc    -- Price/cost/compare-price calculation via temp Sales Line
    ShpfyProductMapping      -- SKU-based mapping between Shopify variants and BC items
    ShpfyProductEvents       -- Integration/internal events for extensibility
    ShpfySyncProductImage    -- Bidirectional image sync (product + variant level)
    ShpfyProductImageExport  -- Uploads BC item pictures to Shopify
    ShpfyVariantImageExport  -- Uploads BC item variant pictures to Shopify
    ShpfyCreateItem          -- Creates BC items from imported Shopify products
    ShpfyCreateItemAsVariant -- Adds a BC item as a variant to an existing Shopify product
    ShpfyUpdateItem          -- Updates existing BC items from Shopify data
    ShpfyProductCollectionAPI -- Retrieves collections from Shopify
    ShpfySalesChannelAPI     -- Retrieves sales channels for product publication
  Tables/
    ShpfyProduct             -- Shopify product record (ID 30127)
    ShpfyVariant             -- Shopify variant record (ID 30129)
    ShpfyInventoryItem       -- Shopify inventory item (ID 30126)
    ShpfyProductCollection   -- Shopify collection with optional item filter (ID 30163)
    ShpfySalesChannel        -- Sales channels for publication (ID 30160)
  Enums/
    ShpfyProductStatus       -- Active, Archived, Draft
    ShpfySKUMapping          -- Item No., Variant Code, Item No.+Variant Code, Vendor Item No., Bar Code
    ShpfyRemoveProductAction -- DoNothing, StatusToArchived, StatusToDraft
    ShpfyCrProdStatusValue   -- Active, Draft (status for newly created products)
    ShpfyVariantCreateStrategy -- DEFAULT, REMOVE_STANDALONE_VARIANT
    ShpfyInclInProductSync   -- blank, As Option (for UoM in product sync)
  Interfaces/
    ShpfyICreateProductStatusValue -- Determines product status on creation
    ShpfyIRemoveProductAction      -- Action when a product is removed from Shopify
  Pages/
    ShpfyProducts, ShpfyProductsOverview, ShpfyVariants,
    ShpfyProductCollections, ShpfySalesChannels, ShpfyAddItemConfirm
  Reports/
    ShpfySyncProducts, ShpfySyncImages,
    ShpfyAddItemtoShopify, ShpfyAddItemAsVariant
```

## Documentation

- [implementation.md](implementation.md) -- Sync flows, mapping logic, price calculation, image handling, and extensibility

## Key concepts

- **Shop-scoped**: All operations run in the context of a single `Shpfy Shop` record
- **Temporary records pattern**: Export builds temp `Shpfy Product` and `Shpfy Variant` records from BC data, then sends them to the API
- **SKU mapping**: Configurable strategy that determines how Shopify variant SKUs map to BC Item No., Variant Code, Vendor Item No., or barcode
- **Bulk operations**: Large mutation sets (images, variants) use Shopify bulk mutation API to avoid rate limits
- **Interface extensibility**: Product status on creation and remove-product behavior are pluggable via AL interfaces
