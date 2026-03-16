# Products

This module owns the bidirectional synchronization of product catalog data between Shopify and Business Central. It covers product creation, export, import, mapping to BC Items, variant handling, image sync, price calculation, and SKU resolution -- essentially everything required to keep the two product catalogs in agreement.

## How it works

Synchronization direction is controlled by the Shop card's "Sync Item" setting and dispatched by `ShpfySyncProducts.Codeunit.al`. The **import path** (`From Shopify`) retrieves product IDs via GraphQL through `ShpfyProductAPI`, compares `Updated At` and `Last Updated by BC` timestamps to skip unchanged records, then hands each product to `ShpfyProductImport`. Import iterates every variant, delegates to `ShpfyProductMapping` to resolve the Shopify variant to a BC Item + Item Variant, and -- if no match is found and "Auto Create Unknown Items" is enabled -- runs `ShpfyCreateItem` to mint new Items from an item template.

The **export path** (`To Shopify`) is driven by `ShpfyProductExport`. It walks every `Shpfy Product` record that already has an `Item SystemId`, calls `FillInProductFields` and one of several `FillInProductVariantData` overloads to build the desired state from BC data, then diff-checks the result against the current Shopify record via `RecordRef` field comparison. Only changed records are pushed through `ProductApi.UpdateProduct` or `VariantApi.UpdateProductVariants`. A dedicated `OnlyUpdatePrice` mode skips all non-price fields and can batch updates via bulk mutation.

Product-to-Item mapping in `ShpfyProductMapping` is driven by the shop's "SKU Mapping" enum (`Item No.`, `Variant Code`, `Item No. + Variant Code`, `Vendor Item No.`, `Bar Code`). The mapping code attempts a direct lookup first, then falls back to barcode-based item reference resolution. When "UoM as Variant" is active, the `UoM Option Id` field on the variant tells the mapper which option slot (1, 2, or 3) holds the unit-of-measure value.

## Things to know

- Products link to BC Items via `Item SystemId` (a Guid), not `Item No.`. The `Item No.` field on both `Shpfy Product` and `Shpfy Variant` is a FlowField that reverse-looks-up through `SystemId`. This means Item renames do not break the mapping.
- A product with `Has Variants = false` still has exactly one variant row in `Shpfy Variant`. The flag controls whether the mapping logic requires an `Item Variant SystemId` or accepts a bare Item match.
- Image export in `ShpfyProductImageExport` uses a hash comparison (`Image Hash` field) computed from `CalcItemImageHash` to avoid re-uploading unchanged pictures. The same pattern applies to tags (`Tags Hash`) and HTML descriptions (`Description Html Hash`).
- Price calculation in `ShpfyProductPriceCalc` works by creating a temporary Sales Quote header with the shop's posting groups and customer price group, then inserting a temporary Sales Line. This picks up all BC pricing rules, discounts, and VAT logic automatically.
- The `UoM Option Id` field on `Shpfy Variant` records which of the three Shopify option slots carries the unit-of-measure value. When UoM-as-variant is enabled with item variants, variants occupy option 1 and UoM occupies option 2 (so `UoM Option Id = 2`). Without item variants, UoM sits in option 1.
- Item attributes marked with `Shpfy Incl. in Product Sync = "As Option"` can drive Shopify product options instead of the Variant/UoM pattern. `ShpfyProductExport` validates that no more than three attributes are flagged, that every item variant has values for all of them, and that no duplicate option combinations exist.
- Each product import calls `Commit()` before `CreateItem.Run` so that a failure on one product does not roll back all preceding products. Errors are captured per-product in the `Has Error` / `Error Message` fields.
