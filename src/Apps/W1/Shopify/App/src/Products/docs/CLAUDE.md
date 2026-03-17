# Products

Products is the bidirectional synchronization engine between BC Items and Shopify Products. It handles the full lifecycle: exporting BC items as Shopify products, importing Shopify products into BC, mapping between the two systems via SKU-based strategies, and keeping prices, images, and metadata in sync. This is the largest and most complex sync domain in the connector because the BC Item model (Item + Item Variant + Unit of Measure) does not map neatly onto the Shopify Product model (Product + Variant with up to 3 option slots).

## How it works

The entry point is `ShpfySyncProducts.Codeunit.al`, which reads the Shop's "Sync Item" direction setting and dispatches to either export or import. Export (`ShpfyProductExport.Codeunit.al`) iterates over Shopify Product records that already have an "Item SystemId" link, re-fills product fields from the BC Item, and detects changes by doing a field-by-field RecordRef comparison. If anything changed, it calls ProductAPI to push updates. For variants, the export code handles three distinct combination patterns: Item Variants only, UoM only, and Item Variants x UoM (which occupies two option slots). The export also supports a "price only" fast path that uses Shopify bulk operations to batch-update variant prices via GraphQL mutations.

Import (`ShpfyProductImport.Codeunit.al`) pulls product IDs from Shopify, compares `Updated At` timestamps to skip unchanged products, then retrieves full product and variant details via the API. For each variant, it runs `ShpfyProductMapping.Codeunit.al` to find the corresponding BC Item. The mapping logic (`DoFindMapping`) implements five SKU strategies configured on the Shop: Item No., Variant Code, Item No. + Variant Code (split by a configurable separator), Vendor Item No., and Bar Code. If no mapping is found and "Auto Create Unknown Items" is enabled, `ShpfyCreateItem.Codeunit.al` creates the BC Item. Product creation for the reverse direction is handled by `ShpfyCreateProduct.Codeunit.al`, which builds temporary Product and Variant records, fills in options and pricing, then calls the API to create the product in Shopify.

The product-to-item link is maintained via `SystemId` GUIDs stored on both the Product and Variant tables. The Product table stores `Item SystemId` pointing to the BC Item; the Variant table stores both `Item SystemId` and `Item Variant SystemId`. This means a Shopify Variant can point to a BC Item without a BC Item Variant (when the variant represents a UoM rather than a true variant), tracked by the `Mapped By Item` flag.

## Things to know

- The Variant table has three pairs of option fields (`Option 1/2/3 Name` and `Value`). The `UoM Option Id` field (values 1, 2, or 3) records which option slot holds the unit-of-measure value. When searching for an existing variant during export, the code scans all three option slots sequentially -- this leads to the verbose triple-nested filter pattern visible in `ShpfyProductExport.Codeunit.al`.

- Hash-based change detection is used for tags (`Tags Hash`), description HTML (`Description Html Hash`), and images (`Image Hash`) on the Product table. These integer hash fields avoid re-pushing unchanged blobs to Shopify.

- Item Attributes marked as "As Option" (`ShpfyInclInProductSync` enum on the Item Attribute table extension) can be used as Shopify product options instead of BC Item Variants. The export validates that at most 3 attributes are marked, that all variants have values for them, and that no duplicate option-value combinations exist. This logic lives entirely in `ShpfyProductExport.Codeunit.al` in the `#region Shopify Product Options as Item/Variant Attributes` section.

- Product description HTML is stored as a Blob field and composed from three optional sources: Extended Text, Marketing Text (Entity Text), and Item Attributes rendered as an HTML table. The composition order is controlled by Shop flags (`Sync Item Extended Text`, `Sync Item Marketing Text`, `Sync Item Attributes`).

- The `Shpfy Inventory Item` table (`ShpfyInventoryItem.Table.al`) sits below Variant in the hierarchy. Each Variant has one Inventory Item keyed by a separate Shopify ID. It tracks origin, shipping requirements, and tracking status. Deleting a Variant cascades to delete its Inventory Items.

- The SKU-to-item mapping during import falls through multiple strategies: first the configured SKU mapping, then a barcode lookup as a last resort. The barcode fallback runs regardless of the SKU mapping setting, which can produce unexpected matches if barcodes overlap across items.

- The `ShpfyProductPriceCalc.Codeunit.al` respects the Shop's Customer Price Group and Customer Discount Group settings when computing variant prices. Blocked items and blocked variants are skipped with a logged reason via `ShpfySkippedRecord`.
