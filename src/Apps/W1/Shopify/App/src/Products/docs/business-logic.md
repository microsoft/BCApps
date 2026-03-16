# Products business logic

## Synchronization flows

### Export to Shopify (Shpfy Sync Products, Shpfy Product Export)

**Location:**
- `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Codeunits\ShpfySyncProducts.Codeunit.al`
- `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Codeunits\ShpfyProductExport.Codeunit.al`

**Trigger:** Shop."Sync Item" = "To Shopify"

**Flow:**
1. Shpfy Sync Products.Run(Shop) calls ExportItemsToShopify()
2. Shpfy Product Export filters Shpfy Product where "Item SystemId" is not null
3. For each product:
   - If Shop."Can Update Shopify Products" or OnlyUpdatePrice, call UpdateProductData()
   - Export creates product body HTML from extended text, marketing text, and attributes (CreateProductBody)
   - Calculate prices using Shpfy Product Price Calc (see Price calculation)
   - Update product and variants via Shpfy Product API and Shpfy Variant API
4. Optionally use bulk operations for price updates

**Only price sync:** SetOnlySyncPriceOn() skips product fields, updates only variant prices.

### Import from Shopify (Shpfy Sync Products, Shpfy Product Import)

**Location:**
- `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Codeunits\ShpfyProductImport.Codeunit.al`

**Trigger:** Shop."Sync Item" = "From Shopify"

**Flow:**
1. Shpfy Sync Products calls ImportProductsFromShopify()
2. Retrieve product IDs via Shpfy Product API.RetrieveShopifyProductIds() (returns Dictionary of [BigInteger, DateTime])
3. For each product ID:
   - If product exists locally and Updated At > Product."Updated At" and Product."Last Updated by BC", mark for import
   - If product doesn't exist locally, mark for import
4. For each marked product:
   - Shpfy Product Import.Run() retrieves full product data via ProductApi.RetrieveShopifyProduct()
   - Retrieve variant IDs via VariantApi.RetrieveShopifyProductVariantIds()
   - For each variant, retrieve full data via VariantApi.RetrieveShopifyVariant()
5. Attempt mapping via Shpfy Product Mapping.FindMapping()
6. If mapping found and Shop."Shopify Can Update Items", call Shpfy Update Item
7. If no mapping and Shop."Auto Create Unknown Items", call Shpfy Create Item
8. If error, store in Product."Has Error" and "Error Message"

**Last sync time:** Stored in Shpfy Synchronization Info after successful sync.

## Mapping strategies

### Product/variant to item mapping (Shpfy Product Mapping)

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Codeunits\ShpfyProductMapping.Codeunit.al`

**Direction: Shopify to BC (DoFindMapping, ShopifyToBC)**

Strategy based on Shop."SKU Mapping":

1. **Item No.** -- If variant.SKU matches Item."No.", map to that item
2. **Vendor Item No.** -- If variant.SKU matches Item Vendor."Vendor Item No.", map to item (optionally filtered by product.Vendor)
3. **Variant Code** -- Split SKU into item no. + variant code, map to Item Variant
4. **Item No. + Variant Code** -- SKU = Item No. + separator + Variant Code
5. **Bar Code** -- Check Item."Bar Code" or Item Reference."Reference No."

**Variant mapping logic:**
- If product."Has Variants" = false, variant maps to item (Mapped By Item = true)
- If product."Has Variants" = true:
  - Variant can map to Item Variant (Item Variant SystemId set)
  - Or variant can map directly to item if it's a UoM variant (UoM Option Id set)

**Events:** OnBeforeFindProductMapping allows subscribers to override mapping.

### Item to product mapping (reverse direction)

**Direction: BC to Shopify**

Used when exporting items. Searches Shpfy Product/Variant by Item SystemId.

## Price calculation

### Shpfy Product Price Calc. (30182)

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Codeunits\ShpfyProductPriceCalc.Codeunit.al`

**Single instance codeunit** -- maintains state across calls.

**Method:** CalcPrice(Item, ItemVariant, UnitOfMeasure, var UnitCost, var Price, var ComparePrice)

**Logic:**
1. Create temporary Sales Header with:
   - Customer No. or shop code as sell-to
   - Customer Price Group, Customer Disc. Group from shop or customer
   - Gen. Bus. Posting Group, VAT Bus. Posting Group, Tax Area Code from shop
   - Currency Code, Prices Including VAT
2. Create temporary Sales Line:
   - Type = Item, No. = Item."No."
   - Variant Code, Quantity = 1
   - Validate Unit of Measure Code
3. BC pricing engine calculates:
   - UnitCost from Sales Line."Unit Cost"
   - ComparePrice from Sales Line."Unit Price" (before discount)
   - Price from Sales Line."Line Amount" (after discount)
4. If ComparePrice <= Price, set ComparePrice = 0 (Shopify shows compare-at only if higher)

**Events:**
- OnBeforeCalculateUnitPrice, OnAfterCalculateUnitPrice -- allow price override

**Catalog support:** If Catalog is set, pricing can be catalog-specific.

## Image synchronization

### Shpfy Sync Product Image (30184)

**Trigger:** Report "Shpfy Sync Images" or automatic after product export

**Flow:**
1. Shpfy Product Image Export and Shpfy Variant Image Export retrieve images from Item."Picture" or Item Variant."Picture"
2. Upload via GraphQL (productCreateMedia, productVariantAppendMedia mutations)
3. Update Product."Image Hash" or Variant."Image Hash" to track changes
4. Only sync if hash changed (incremental sync)

**Hash calculation:** Shpfy Hash codeunit computes hash of image binary data.

## Product creation

### Shpfy Create Product (30177)

**Flow:**
1. Create Shpfy Product record from Item
2. Set product.Title from Item.Description
3. Set product.Status from Shop."Status for Created Products" (Active or Draft)
4. Create variants:
   - If item has Item Variants, create one Shpfy Variant per Item Variant
   - Variant.SKU set according to Shop."SKU Mapping"
   - Variant options (Option 1/2/3) set from Item Attribute or UoM
5. Call Shpfy Product API.CreateProduct() (GraphQL productCreate mutation)
6. Store product ID and variant IDs

**Strategy:** Uses Shpfy Variant Create Strategy enum for variant creation behavior.

## Item creation (from Shopify)

### Shpfy Create Item (30175)

**Flow:**
1. Read Shpfy Variant data
2. If Shop."Auto Create Unknown Items" enabled, create Item from template (Shop."Item Templ. Code")
3. Set Item."No." from SKU or generate new number
4. Set Item.Description from Variant."Display Name" or Product.Title
5. If product."Has Variants" and variant has Item Variant Code, create Item Variant
6. Set Item."Unit Price", "Unit Cost" from variant
7. Set Item."Vendor No." from product.Vendor
8. If creation fails, store error in Product."Has Error"

## Tag synchronization

**Storage:** Shpfy Tag table (Parent Table No. = Database::"Shpfy Product", Parent Id = product.Id)

**Methods:**
- Product.GetCommaSeparatedTags() reads tags
- Product.UpdateTags(CommaSeparatedTags) writes tags
- Tags.Hash tracks changes

**Sync:** Included in product export/import.

## Events for extensibility

### Shpfy Product Events (30183)

**Published events:**
- OnBeforeCreateProductBodyHtml, OnAfterCreateProductbodyHtml -- customize HTML description
- OnAfterProductsToSynchronizeFiltersSet -- filter products for sync
- OnBeforeCalculateUnitPrice, OnAfterCalculateUnitPrice -- override pricing
- OnBeforeFindProductMapping -- override mapping logic
- OnAfterGetCommaSeparatedTags -- customize tags

## Key configuration (Shpfy Shop fields)

**Product sync:**
- `Sync Item` -- " ", "To Shopify", "From Shopify"
- `Can Update Shopify Products` -- Allow BC to update existing Shopify products
- `Status for Created Products` -- Active or Draft

**Item creation:**
- `Auto Create Unknown Items` -- Create BC items from Shopify products
- `Item Templ. Code` -- Template for new items
- `Shopify Can Update Items` -- Allow Shopify to update BC items

**SKU and mapping:**
- `SKU Mapping` -- How SKU maps to BC (Item No., Variant Code, etc.)
- `UoM as Variant` -- Represent units of measure as variants

**Content:**
- `Sync Item Extended Text` -- Include extended text in product body
- `Sync Item Marketing Text` -- Include marketing text
- `Sync Item Attributes` -- Include item attributes as HTML

**Images:**
- `Sync Item Images` -- "To Shopify", "From Shopify", or disabled
