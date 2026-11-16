# Products data model

## Entity relationships

```mermaid
erDiagram
    Product ||--o{ Variant : "has"
    Variant ||--o| InventoryItem : "tracked by"
    Product }o--|| Shop : "belongs to"
    Product }o--o| Item : "maps by SystemId"
    Variant }o--o| Item : "can map directly"
    Variant }o--o| ItemVariant : "maps to"

    Product {
        bigint Id
        enum Status
        guid Item_SystemId
        datetime Last_Updated_by_BC
    }
    Variant {
        bigint Id
        guid Item_SystemId
        guid Item_Variant_SystemId
        code Tariff_No
        code Country_Region_of_Origin_Code
        decimal Compare_at_Price
    }
    InventoryItem {
        bigint Id
        bigint Variant_Id
        text Country_Region_of_Origin
        datetime Updated_At
    }
```

*Updated: 2026-07-29 -- diagram now shows item mappings and origin/compare-at fields carried by variants*

## Product (table 30127)

The central record linking a Shopify product to a BC Item. The link is through
`Item SystemId`, a Guid pointing at the BC Item's SystemId. A FlowField `Item No.`
resolves this to a human-readable code, but all logic operates on the Guid. The
secondary key `(Shop Code, Item SystemId)` enforces one product per item per shop.

Hash fields enable cheap change detection. `Description Html Hash`, `Tags Hash`, and
`Image Hash` are integer hashes computed by `Shpfy Hash` and stored alongside the
blob/tag data. Export compares the current hash to the stored one rather than
diffing the full content. `Last Updated by BC` timestamps the most recent export
so the connector can distinguish BC-initiated changes from Shopify-side edits.

The OnDelete trigger is where product removal policy lives. It reads the Shop's
"Action for Removed Products" setting, resolves it to an `IRemoveProductAction`
implementation, and calls `RemoveProductAction` before cascading deletes to
Variants and Metafields.

`Status` is Shopify-facing and now includes Active, Archived, Draft, and
Unlisted. The creation setting on the Shop can choose Active, Draft, or Unlisted
through `ICreateProductStatusValue`; Archived is reserved for existing products
and removal flows.

*Updated: 2026-07-29 -- Unlisted product status added and creation status choices clarified*

## Variant (table 30129)

Each Shopify variant belongs to a Product via `Product Id`. It maps to a BC Item
via `Item SystemId` and optionally to an Item Variant via `Item Variant SystemId`.
The `Mapped By Item` flag distinguishes variants that were matched to the item
itself (no variant code) from those matched to a specific Item Variant.

Shopify allows up to three option name/value pairs per variant. The connector uses
these for two different purposes depending on configuration. When `UoM as Variant`
is on, one option slot holds the Unit of Measure code and `UoM Option Id` (1, 2,
or 3) records which slot it occupies. When item attributes are marked "As Option",
the option slots hold attribute name/value pairs instead.

The `Image Hash` field tracks the variant-level image separately from the product
image, enabling per-variant image sync.

`Tariff No.` and `Country/Region of Origin Code` are stored on the Variant
because Shopify exposes HS code and origin on the variant inventory item payload.
Export fills them from the BC Item when `"Sync HS Code and Country"` (captioned *Sync HS Code and Country of Origin*) is
enabled. Import reads them from Shopify and uses them when creating or updating
BC Items, but update logic only applies values that resolve to existing BC
Tariff Number and Country/Region records.

`Compare at Price` is part of the variant's pricing state. Price sync only sends
it when it is greater than the actual price; otherwise the GraphQL payload clears
Shopify's compare-at price with `null`.

*Updated: 2026-07-29 -- variant origin fields and compare-at price behavior added*

## InventoryItem (table 30126)

A Shopify inventory item, linked to a Variant by `Variant Id`. This is Shopify's
physical-goods record -- it holds country of origin, shipping requirements, unit
cost, and whether inventory is tracked. There is no direct BC table counterpart;
it exists purely to mirror the Shopify data model.

The import path updates `InventoryItem` only when Shopify's inventory item
`updatedAt` is newer than the local `Updated At`. The Variant still carries the
HS code and country code used by BC mapping and export.

*Updated: 2026-07-29 -- inventory item origin data and timestamp behavior clarified*

## The "Has Variants" gotcha

When a Product's `Has Variants` is false, the product has a single default variant
in Shopify. The connector maps this variant directly to the BC Item with no Item
Variant needed. When `Has Variants` is true, the connector expects each non-default
Variant to carry an `Item Variant SystemId`. This flag drives branching throughout
export, import, and mapping -- if it gets out of sync with reality, mapping will
silently fail or skip variants.

Variant-mapped items count as mapped for the Item Card and Item List actions.
The UI checks both `Shpfy Product.Item SystemId` and `Shpfy Variant.Item SystemId`
before allowing "Add to Shopify" for a shop.

*Updated: 2026-07-29 -- variant-level item mappings now affect add-to-Shopify availability*
