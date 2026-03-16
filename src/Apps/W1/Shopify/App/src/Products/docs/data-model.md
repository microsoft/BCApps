# Data model

## Overview

The product data model mirrors Shopify's own hierarchy -- Product, Variant, InventoryItem -- but adds BC-side linking fields and change-tracking hashes. A `Shpfy Product` record always has at least one child `Shpfy Variant`, and each variant has at most one child `Shpfy Inventory Item`. This three-level structure exists because Shopify treats them as distinct API resources with independent IDs and lifecycles: a product carries catalog metadata, a variant carries price/SKU/option values, and an inventory item carries fulfillment-related properties like country of origin and tracking.

## Product-to-Item linking

Both `Shpfy Product` (field 101) and `Shpfy Variant` (field 101) carry an `Item SystemId` Guid that points at the BC Item's `SystemId`. The `Item No.` fields (103/104) are FlowFields computed from that Guid. This design decouples the mapping from the Item's natural key, so Item number series changes or renames leave the Shopify link intact. On the variant level, `Item Variant SystemId` (field 102) similarly links to a BC `Item Variant` record. The `Mapped By Item` boolean (field 107) is set when a variant was matched at the Item level only, with no corresponding Item Variant -- this happens for single-variant products and for the UoM-only-variant pattern.

## Change-detection hashes

`Shpfy Product` stores three integer hash fields: `Image Hash` (104), `Tags Hash` (105), and `Description Html Hash` (106). These are computed via `Shpfy Hash` and compared before export to avoid unnecessary API calls. On the variant side, `Shpfy Variant` carries its own `Image Hash` (field 108) for per-variant image tracking. The image export codeunit (`ShpfyProductImageExport`) computes a fresh hash from the BC Item picture and short-circuits when it matches the stored value.

## Dual timestamps

Every product and variant carries an `Updated At` timestamp reflecting the last modification time reported by Shopify, plus a `Last Updated by BC` timestamp set whenever BC pushes changes outward. During import, the sync logic in `ShpfySyncProducts.ImportProductsFromShopify` skips a product when both `Updated At` and `Last Updated by BC` are older than the incoming Shopify timestamp -- this prevents re-importing data that BC itself pushed.

## HasVariants and single-variant products

The `Has Variants` boolean on `Shpfy Product` is `false` for products where Shopify shows a single "Default Title" variant. Even so, a `Shpfy Variant` row always exists. The mapping logic in `ShpfyProductMapping.FindMapping` uses this flag to decide whether it needs to resolve an `Item Variant SystemId`: when `Has Variants` is false, a bare Item match is sufficient and the variant row stores only `Item SystemId`.

## UoM Option Id

When the shop's "UoM as Variant" toggle is on, each Item Unit of Measure becomes a separate Shopify variant. The `UoM Option Id` integer (field 106 on `Shpfy Variant`) records which of the three Shopify option slots (1, 2, or 3) holds the unit-of-measure code. In the simplest case -- no item variants, only UoM variants -- option 1 carries the UoM and `UoM Option Id` is 1. When both item variants and UoM are present, option 1 is "Variant" (the item variant code) and option 2 is the UoM, so `UoM Option Id` is 2. The export, import, and mapping codeunits all use this field to locate the UoM value dynamically rather than hard-coding a slot.

## Inventory item and shop locations

`Shpfy Inventory Item` (table 30126) sits below `Shpfy Variant`, linked by `Variant Id`. It holds fulfillment-related metadata -- country/province of origin, tracking status, unit cost -- that Shopify manages separately from the variant's pricing data. Stock levels are not stored here; those are reconciled through `Shpfy Shop Inventory` and `Shpfy Shop Location` tables (defined outside this module) that pair inventory items with specific Shopify locations and BC location codes.

## Collections

`Shpfy Product Collection` and `Shpfy Shop Collection Map` support Shopify's collection concept. The map table ties a shop code to a collection ID, and `ShpfyProductCollectionAPI` handles the GraphQL retrieval. Collections do not affect product sync directly but appear in the UI for filtering.
