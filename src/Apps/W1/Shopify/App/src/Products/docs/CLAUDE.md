# Products

This module handles bidirectional product synchronization between BC Items and Shopify Products/Variants. Export pushes item data, prices, images, metafields, and translations to Shopify. Import retrieves Shopify products and either maps them to existing BC items or auto-creates new ones.

## How it works

Export runs from `ShpfyProductExport.Codeunit.al` (triggered by `ShpfySyncProducts.Report.al`). It iterates all `Shpfy Product` records that have a linked `Item SystemId`, calls `FillInProductFields` to populate title, vendor, product type, body HTML, tags hash, and status, then does a field-by-field `RecordRef` comparison (`HasChange`) against the previously synced state. Only changed products are sent to Shopify via `ProductApi.UpdateProduct`. The variant loop follows: existing variants are updated, missing ones created, and all are batched into a temp table before a single `UpdateProductVariants` call. When `OnlyUpdatePrice` is true, the export skips all non-price fields and uses GraphQL bulk operations for speed, falling back to per-variant calls if the bulk mutation fails.

Import runs from `ShpfyProductImport.Codeunit.al`. It retrieves a product from Shopify, then iterates its variants. For each variant, `ShpfyProductMapping` attempts to find a matching BC item using the shop's SKU Mapping strategy (Item No., Barcode, Vendor Item No., Variant Code, or Item No. + Variant Code). If a mapping is found and `Shopify Can Update Items` is enabled, `ShpfyUpdateItem` runs. If no mapping is found and `Auto Create Unknown Items` is enabled, `ShpfyCreateItem` runs.

## Things to know

- Products link to BC items via `Item SystemId` (Guid), not `Item No.`. The `Item No.` field on `Shpfy Product` is a FlowField that looks up the item by SystemId. This means renumbering an item does not break the link.
- The `Last Updated by BC` timestamp on product and variant records prevents sync loops -- when the export updates a product, this timestamp is set so the next import cycle can skip recently-pushed changes.
- Change detection for the product body and tags uses integer hash fields (`Description Html Hash`, `Tags Hash`, `Image Hash`) stored on the product record. The `ShpfyHash` codeunit computes these.
- Shopify limits products to 3 option slots. Item attributes marked with `Shpfy Incl. in Product Sync = "As Option"` fill these slots. The export validates that all item variants have unique attribute combinations and that no variant is missing a value. See `CheckItemAttributesCompatibleForProductOptions` in `ShpfyProductExport`.
- UoM-as-variant mode (`Shop."UoM as Variant"`) consumes one option slot for the unit of measure. The `UoM Option Id` field on the variant (1, 2, or 3) tracks which option slot holds the UoM value, and this value determines UoM resolution during order mapping in the Order handling module.
- When a BC item is blocked, the `Action for Removed Products` shop setting controls behavior: `StatusToArchived` archives the Shopify product, `StatusToDraft` sets it to draft, and `DoNothing` skips the item entirely. The `IRemoveProductAction` interface dispatches this.
- The `Shpfy Shop Collection Map` table (30128) is obsolete as of version 28. Collections are now managed through `Shpfy Product Collection` (30163) with an item filter blob.
