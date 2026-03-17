# Products module -- implementation details

## Product sync flow

The orchestrator is `Shpfy Sync Products` (codeunit 30185). It reads `Shop."Sync Item"` and dispatches accordingly:

- **"To Shopify"** -- runs `Shpfy Product Export`
- **"From Shopify"** -- runs `ImportProductsFromShopify`, then updates `Shop` last sync time

A price-only sync mode (`OnlySyncPrice`) skips non-price fields and always runs the export path.

## Import workflow (From Shopify)

1. **Retrieve IDs** -- `ProductAPI.RetrieveShopifyProductIds` pages through GraphQL (`GetProductIds` / `GetNextProductIds`) and returns a `Dictionary of [BigInteger, DateTime]` of all product IDs updated since last sync.

2. **Filter unchanged** -- For each ID, if the local `Shpfy Product` record exists and its `"Updated At"` and `"Last Updated by BC"` are both >= the Shopify `updatedAt`, the product is skipped. New and changed products go into a temp record set.

3. **Per-product import** -- `Shpfy Product Import` (codeunit 30180) runs for each product:
   - Calls `ProductAPI.RetrieveShopifyProduct` to fetch full product JSON and update `Shpfy Product` fields (title, description, vendor, status, tags, SEO, metafields).
   - Calls `VariantAPI.RetrieveShopifyProductVariantIds` then `VariantAPI.RetrieveShopifyVariant` for each variant, populating `Shpfy Variant` and `Shpfy Inventory Item` records.

4. **Item mapping** -- `Shpfy Product Mapping` attempts to find a matching BC Item/Item Variant for each variant using the configured SKU mapping strategy. If no mapping exists and `Shop."Auto Create Unknown Items"` is enabled, `Shpfy Create Item` creates the BC item from an item template.

5. **Item update** -- If a mapping exists and `Shop."Shopify Can Update Items"` is enabled, `Shpfy Update Item` syncs Shopify data back to the BC item.

### Mapping logic (`Shpfy Product Mapping`)

The `DoFindMapping` procedure resolves Shopify variants to BC items based on `Shop."SKU Mapping"`:

| SKU Mapping value | Lookup strategy |
|---|---|
| Item No. | `Item.Get(SKU)` |
| Variant Code | `Item Variant` where `Code = SKU` |
| Item No. + Variant Code | Split SKU by `Shop."SKU Field Separator"`, look up Item then Item Variant |
| Vendor Item No. | Match via `Item Vendor` table or `Item Reference` (type Vendor) |
| Bar Code | Match via `Item Reference` (type Bar Code) |

Fallback: if SKU mapping fails, barcode matching is attempted using the variant's `Barcode` field.

### Item creation (`Shpfy Create Item`)

- Finds or uses the shop's `"Item Templ. Code"` (extensible via `OnBeforeFindItemTemplate` / `OnAfterFindItemTemplate`)
- Creates the BC Item from the template, sets Description, Unit Cost, Unit Price, Item Category (matched by `Product Type`), and Vendor (matched by name)
- Creates Item References for barcode and vendor item no. based on SKU mapping
- Creates Item Variants when `SKU Mapping` is "Item No. + Variant Code" or "Variant Code"
- Creates Unit of Measure records when the variant has a UoM option

## Export workflow (To Shopify)

`Shpfy Product Export` (codeunit 30178) is the main export codeunit. Its `OnRun` trigger:

1. Iterates existing `Shpfy Product` records for the shop to update existing products.
2. Uses bulk operations when record count exceeds the threshold.
3. For each product, builds updated field values from BC Item data via `FillInProductFields` and compares against the current Shopify state.
4. Sends `productUpdate` GraphQL mutations for changed products.
5. For variants, sends `productVariantsBulkUpdate` or individual variant mutations.

### New product creation

`Shpfy Create Product` (codeunit 30174) handles first-time export of a BC item:

1. `CreateTempProduct` builds temporary `Shpfy Product` and `Shpfy Variant` records from the BC Item, Item Variants, and optionally Item Units of Measure.
2. The `ICreateProductStatusValue` interface determines the initial status (Active or Draft) based on `Shop."Status for Created Products"`.
3. `VariantAPI.FindShopifyProductVariant` checks if the product already exists in Shopify (by SKU or barcode).
4. If not found, `ProductAPI.CreateProduct` sends a `productCreate` GraphQL mutation including title, description, product type, vendor, status, tags, options, and collections.
5. After creation, `VariantAPI.AddProductVariants` creates additional variants.
6. The product is published to configured sales channels via `ProductAPI.PublishProduct`.

### Variant management

Variants support up to 3 option dimensions (`Option 1/2/3 Name` and `Value` on `Shpfy Variant`). When `Shop."UoM as Variant"` is enabled, Item Units of Measure become an additional option dimension alongside Item Variant codes. The `"UoM Option Id"` field (1, 2, or 3) tracks which option slot holds the UoM value.

Items with more than 2048 variants are skipped during export (Shopify's limit).

### SKU generation on export

The `GetVariantSKU` procedure in `Shpfy Create Product` generates SKUs based on the same `Shop."SKU Mapping"` setting:

- **Bar Code** -- uses the item barcode from Item Reference
- **Item No.** -- uses `Item."No."`
- **Variant Code** -- uses `ItemVariant.Code`
- **Item No. + Variant Code** -- concatenates with `Shop."SKU Field Separator"`
- **Vendor Item No.** -- uses the vendor item reference

## Price calculation

`Shpfy Product Price Calc.` (codeunit 30182) computes `UnitCost`, `Price`, and `ComparePrice` for each variant:

1. Creates a temporary `Sales Header` (Quote) populated with the shop's customer, posting groups, VAT settings, and currency code. When a catalog is used, its settings override the shop's.
2. Creates a temporary `Sales Line` for the item/variant/UoM and reads the calculated `"Unit Cost"`, `"Unit Price"`, and `"Line Amount"`.
3. `ComparePrice` = the full unit price before line discounts; `Price` = the discounted line amount. If ComparePrice <= Price, ComparePrice is zeroed out (no strikethrough price).
4. Extensible via `OnBeforeCalculateUnitPrice` (can fully handle pricing) and `OnAfterCalculateUnitPrice` (can adjust results).

## Image sync

`Shpfy Sync Product Image` (codeunit 30184) handles bidirectional image sync controlled by `Shop."Sync Item Images"`:

### Export (To Shopify)

1. For each `Shpfy Product`, `Shpfy Product Image Export` runs:
   - Reads the BC Item's `Picture` media
   - Computes an image hash; skips if unchanged
   - Creates a staged upload URL via `ProductAPI.CreateImageUploadUrl`
   - Uploads the image binary via HTTP PUT
   - Calls `UpdateProductImage` or `UpdateProductWithNewImage` GraphQL mutation
2. Variant images are exported separately via `Shpfy Variant Image Export`.
3. When record count exceeds the bulk threshold, image updates are batched into a bulk mutation.

### Import (From Shopify)

1. `ProductAPI.RetrieveShopifyProductImages` fetches all product images.
2. `VariantAPI.RetrieveShopifyProductVariantImages` fetches variant-level images.
3. For each image, downloads via HTTP GET and writes to `Item.Picture` or `ItemVariant.Picture`.

## Collection mapping

`Shpfy Product Collection` (table 30163) stores Shopify collections with:

- `Default` flag -- when true, new products are automatically added to this collection
- `"Item Filter"` (Blob) -- optional BC item filter; only items matching the filter are added

During product creation, `ProductAPI.AddDefaultCollectionsToGraphQuery` includes `collectionsToJoin` in the GraphQL mutation for all default collections whose item filter matches the source item.

Collections are retrieved from Shopify via `Shpfy Product Collection API`.

## Sales channel publication

`Shpfy Sales Channel` (table 30160) stores available publication channels. Products are published to channels marked with `"Use for publication" = true` (or the default channel if none are selected). Publication happens via `publishablePublish` GraphQL mutation after product creation.

## Interface extensibility points

### ICreateProductStatusValue

Implemented by `Shpfy Cr. Prod. Status Value` enum (Active, Draft). Determines the Shopify status for newly created products. Subscribers can override via `OnBeforeFindItemTemplate`.

### IRemoveProductAction

Implemented by `Shpfy Remove Product Action` enum:

- **DoNothing** -- no action on product deletion
- **StatusToArchived** -- sets Shopify product status to Archived
- **StatusToDraft** -- sets Shopify product status to Draft

Triggered from the `Shpfy Product` table's `OnDelete` trigger.

## Event-based extensibility (`Shpfy Product Events`)

Key integration events (all in codeunit 30177):

- `OnBeforeCalculateUnitPrice` / `OnAfterCalculateUnitPrice` -- override or adjust pricing
- `OnBeforeCreateItem` / `OnAfterCreateItem` -- intercept BC item creation from Shopify
- `OnBeforeCreateItemVariant` / `OnAfterCreateItemVariant` -- intercept variant creation
- `OnBeforeFindItemTemplate` / `OnAfterFindItemTemplate` -- override item template selection
- `OnBeforeFindProductMapping` -- override product-to-item mapping
- `OnBeforeSendCreateShopifyProduct` / `OnBeforeSendUpdateShopifyProduct` -- modify data before API calls
- `OnAfterCreateTempShopifyProduct` -- modify temp product/variant/tag data before export
- `OnAfterFillInShopifyProductFields` -- adjust product fields after they are populated from BC Item
- `OnAfterCreateProductBodyHtml` / `OnBeforeCreateProductBodyHtml` -- customize product description HTML
- `OnAfterUpdateItemPicture` / `OnAfterUpdateItemVariantPicture` -- post-processing after image import

## Key tables and relationships

```
Shpfy Shop (1) ----< Shpfy Product (N)
                         |
                         |--- "Item SystemId" --> Item (BC)
                         |--- "Shop Code" --> Shpfy Shop
                         |
                         +----< Shpfy Variant (N)
                                   |
                                   |--- "Product Id" --> Shpfy Product
                                   |--- "Item SystemId" --> Item (BC)
                                   |--- "Item Variant SystemId" --> Item Variant (BC)
                                   |
                                   +----< Shpfy Inventory Item (N)
                                             |--- "Variant Id" --> Shpfy Variant

Shpfy Shop (1) ----< Shpfy Product Collection (N)
Shpfy Shop (1) ----< Shpfy Sales Channel (N)
```

- `Shpfy Product.Id` is the Shopify product legacy resource ID (BigInteger PK)
- `Shpfy Variant.Id` is the Shopify variant legacy resource ID (BigInteger PK)
- `Shpfy Inventory Item.Id` is the Shopify inventory item ID
- BC linkage is via `SystemId` GUIDs (`"Item SystemId"`, `"Item Variant SystemId"`)
- Tags and metafields are stored in shared tables (`Shpfy Tag`, `Shpfy Metafield`) linked by parent table number and owner ID
