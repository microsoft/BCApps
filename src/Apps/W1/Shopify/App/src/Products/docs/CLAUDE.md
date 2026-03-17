# Products

This module owns the bidirectional sync between Shopify products/variants and BC Items/Item Variants. It also handles image sync, product-to-collection assignment, and sales channel publication. The separation exists because the product data model is the densest mapping in the connector -- a single BC Item fans out into a Shopify Product, one or more Variants, Inventory Items, and optionally collection memberships.

## How it works

Sync direction is controlled by `Shop."Sync Item"`. "To Shopify" runs `ShpfyProductExport`, which iterates all `Shpfy Product` records that already have an `Item SystemId` and pushes field changes detected via RecordRef comparison. "From Shopify" runs `ShpfySyncProducts.ImportProductsFromShopify`, which fetches product IDs from the API, skips anything whose `Updated At` has not changed, then hands each product to `ShpfyProductImport`. Import attempts mapping first (`ShpfyProductMapping.FindMapping`), then either updates the existing BC Item or auto-creates one depending on shop settings.

Mapping (`ShpfyProductMapping.DoFindMapping`) resolves a Shopify variant to a BC Item+Item Variant using the `SKU Mapping` enum on the shop -- Item No., Variant Code, Item No. + Variant Code, Bar Code, or Vendor Item No. Each strategy parses the variant's SKU field differently and falls back to barcode-based lookup via Item References. The linking is stored as `Item SystemId` (Guid) on both Product and Variant tables, plus `Item Variant SystemId` on Variant -- never by "No." directly.

Export supports a price-only fast path (`SetOnlyUpdatePriceOn`) that skips product field updates and can batch variant price changes through a bulk mutation. When `Shop."UoM as Variant"` is enabled, each Item Unit of Measure becomes a separate Shopify variant; the `UoM Option Id` field (1, 2, or 3) records which option slot holds the UoM value. Product creation (`ShpfyCreateProduct`) builds temporary Product+Variant records, optionally maps BC Item Attributes marked "As Option" to Shopify's 3 product option slots, validates uniqueness of option combinations, then posts via `ProductAPI.CreateProduct`.

## Things to know

- Linking uses `SystemId` (Guid), not `"No."`. The `"Item No."` and `"Variant Code"` fields on `Shpfy Product` and `Shpfy Variant` are FlowFields that look up through `SystemId`. If an Item is renumbered, the link survives.
- `"Has Variants"` on `Shpfy Product` is set to `true` when the BC Item has Item Variants or when `"UoM as Variant"` creates multiple Shopify variants. When false, a single "Default Title" variant is created. The mapping logic uses this flag to decide whether it needs to resolve `Item Variant SystemId`.
- `"Mapped By Item"` on `Shpfy Variant` is true when mapping found an Item but no specific Item Variant -- the variant is linked at the Item level only.
- Image sync uses integer hash comparison (`"Image Hash"` on both Product and Variant). `ShpfyProductImageExport` computes a hash of the BC Item picture; if it matches the stored hash, the export is skipped. Images flow through a staged upload URL pattern.
- `"Description as HTML"` is a Blob field with its own `"Description Html Hash"` for change detection. `SetDescriptionHtml` writes the blob and updates the hash in one call.
- Product removal is dispatched through `IRemoveProductAction` -- an interface enum with three implementations: DoNothing, StatusToArchived, StatusToDraft. This runs on the `OnDelete` trigger of `Shpfy Product`.
- Shopify enforces a maximum of 2048 variants per product. `CreateProduct` checks this limit before sending the create mutation. Item Attributes marked "As Option" are capped at 3 (matching Shopify's product option limit).
