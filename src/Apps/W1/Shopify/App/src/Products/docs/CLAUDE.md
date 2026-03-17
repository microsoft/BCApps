# Products

The Products module handles bidirectional synchronization between BC Items and Shopify Products. A BC Item becomes a Shopify Product; its Item Variants and Units of Measure become Shopify Variants. This is the highest-traffic sync area in the connector because products carry price, inventory, images, and metadata.

## How it works

On export, `ShpfyProductExport` iterates every `Shpfy Product` that has a non-empty `Item SystemId` and rebuilds the Shopify representation from the current BC Item. It compares old and new records field-by-field via `RecordRef` and only calls the API when something changed. Variant-level updates are batched into a temporary record set and sent through `ShpfyVariantAPI.UpdateProductVariants` in one pass. A separate "only update price" mode skips all non-price fields and can use the bulk mutation API for throughput. New products go through `ShpfyCreateProduct`, which assembles temp Product and Variant records, validates option compatibility, and hands them to `ShpfyProductAPI.CreateProduct`.

On import, `ShpfyProductImport` retrieves the product and its variant IDs from Shopify, upserts local records, then delegates to `ShpfyProductMapping` to link each variant to a BC Item + Item Variant by SKU, barcode, or vendor item number (depending on the shop's `SKU Mapping` setting). If no mapping is found and `Auto Create Unknown Items` is on, `ShpfyCreateItem` creates the BC Item.

Price calculation is handled by `ShpfyProductPriceCalc`, which creates a temporary Sales Quote header using the shop's (or catalog's) posting groups, customer price group, and currency. It validates a Sales Line to let the standard BC pricing engine resolve the final price, compare-at price, and unit cost. Catalog-level overrides support multi-market and B2B pricing.

Image sync runs as a separate pipeline in `ShpfySyncProductImage`, exporting item pictures to Shopify or downloading Shopify images into BC Item pictures. It uses hash-based change detection on `Shpfy Product."Image Hash"` to avoid redundant uploads.

## Things to know

- Products link to Items via `Item SystemId` (a Guid), not `Item No.`. The `Item No.` field is a FlowField calculated from the SystemId. This means item renumbering does not break the mapping.
- Change detection uses integer hash fields -- `Image Hash`, `Tags Hash`, `Description Html Hash` -- so the connector can skip API calls when nothing changed. The `ShpfyHash` codeunit computes these.
- When `UoM as Variant` is enabled on the shop, each Item Unit of Measure becomes its own Shopify Variant. The `UoM Option Id` field (1, 2, or 3) on `Shpfy Variant` tracks which of the three option slots holds the UoM value. The connector searches all three slots when matching during export updates.
- Shopify limits products to 3 option slots and 2048 variants. Item Attributes marked as "As Option" (`Shpfy Incl. in Product Sync` = `As Option`) are mapped to these option slots by `FillProductOptionsForShopifyVariants` in `ShpfyProductExport`. The connector validates uniqueness of option combinations and skips items that exceed 3 attributes.
- The `Has Variants` flag is semantic, not structural. A single-variant product still has one `Shpfy Variant` record, but `Has Variants` is false. This affects how mapping works -- see `ShpfyProductMapping.FindMapping` where `Mapped By Item` handles the single-variant case.
- The `IRemoveProductAction` interface (with implementations DoNothing, StatusToArchived, StatusToDraft) runs on product delete and when a blocked item is exported, controlling what happens on the Shopify side.
- Bulk operations (`ShpfyBulkOperationMgt`) are attempted first for price updates and image updates; the connector falls back to per-record API calls if the bulk mutation fails.
