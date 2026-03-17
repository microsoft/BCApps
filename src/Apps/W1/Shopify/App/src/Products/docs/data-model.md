# Data model

## Overview

The product data model mirrors Shopify's hierarchy: a Product contains Variants, and each Variant has exactly one Inventory Item. Stock levels are tracked per-variant per-location. Collections group products for storefront organization. Every table uses Shopify's BigInteger IDs as primary keys and links to BC entities via SystemId Guids.

## Product-Variant-InventoryItem hierarchy

`Shpfy Product` (table 30127) is the top-level entity. It carries the product title, description HTML (stored as a Blob), vendor, product type, status (Draft/Active/Archived), and SEO fields. The key BC link is `Item SystemId` -- a Guid pointing to the BC Item. The `Item No.` field is a FlowField resolved from that Guid, so renaming an item in BC does not sever the connection. The secondary key on `(Shop Code, Item SystemId)` supports efficient lookups during export, which filters on `Item SystemId <> NullGuid`.

Three hash fields drive change detection: `Image Hash`, `Tags Hash`, and `Description Html Hash`. These are plain integers computed by `ShpfyHash.CalcHash`. On export, the connector compares the new hash against the stored one and skips the API call if they match.

`Shpfy Variant` (table 30129) is the sellable unit. Every product has at least one variant. The variant carries price, compare-at price, unit cost, SKU, barcode, weight, taxable flag, and inventory policy. It links to BC via both `Item SystemId` and `Item Variant SystemId`, allowing a variant to map to a specific BC Item Variant. The `Mapped By Item` flag is true when the variant was matched at the item level (no specific variant code) -- this happens for single-variant products or when "Add Item as Variant" groups multiple items under one product.

The three option slot pairs (`Option 1 Name`/`Option 1 Value` through `Option 3 Name`/`Option 3 Value`) map to Shopify's product options. When `UoM as Variant` is active, one slot holds the unit of measure code and `UoM Option Id` records which slot (1, 2, or 3) that is. This matters during export updates, where the connector must search all three slots to find an existing variant's UoM match.

`Shpfy Inventory Item` (table 30126) has a 1:1 relationship with Variant, linked by `Variant Id`. It holds fulfillment-related data: country/region of origin, whether shipping is required, whether inventory tracking is enabled, and unit cost. This is the entity Shopify uses for inventory management operations.

Cascade deletes flow downward: deleting a Product deletes its Variants (and their Metafields), and deleting a Variant deletes its Inventory Items (and their Metafields). The Product delete trigger also invokes the `IRemoveProductAction` interface, which may change the product's status on Shopify before the local record disappears.

## Inventory tracking

`Shpfy Shop Inventory` (table 30112) tracks stock levels at the intersection of shop, product, variant, and location -- its composite primary key is `(Shop Code, Product Id, Variant Id, Location Id)`. It stores both the last-imported Shopify stock and the last-calculated BC stock, with timestamps for each. The delta between these drives inventory adjustments.

`Shpfy Shop Location` (table 30113) maps Shopify locations to BC locations. Each row has a `Location Filter` (a BC location code filter expression) and a `Default Location Code` used on sales documents. The `Stock Calculation` enum controls how inventory is computed for that location (or disables sync entirely). The `Is Fulfillment Service` flag distinguishes third-party fulfillment locations, which cannot be mixed with standard locations for the `Default Product Location` setting. When a location is deleted, its `Shpfy Shop Inventory` rows cascade-delete.

## Collections

`Shpfy Product Collection` (table 30163) represents a Shopify collection (product grouping). It stores the collection name, a `Default` flag (whether new products are auto-assigned to it), and an `Item Filter` Blob that holds a BC item filter expression. The item filter is used during export to decide which items belong to the collection. Collections are managed per-shop via `ShpfyProductCollectionAPI`.

## The Has Variants subtlety

Shopify always creates at least one variant per product. When a BC Item has no Item Variants and `UoM as Variant` is off, `ShpfyCreateProduct.CreateTempShopifyVariantFromItem` creates a single variant with an empty title (Shopify will display it as "Default Title") and sets `Has Variants` to false on the product. In this case, `ShpfyProductMapping` considers the mapping complete if the Item SystemId is set, even without an Item Variant SystemId. The `Mapped By Item` flag on the variant distinguishes this situation from a multi-variant product where variant-level mapping simply has not happened yet.
