# Products

Bi-directional product and variant sync between BC Items and Shopify Products.

## What it does

Export pushes BC Item data (title, description, vendor, price, variants, images,
tags, metafields, translations, tariff numbers, and country of origin) to
Shopify. Import pulls Shopify Products back and either maps them to existing
Items or auto-creates new ones via templates.

*Updated: 2026-07-29 -- HS code and country of origin now participate in product sync*

## How it works

Export (`ShpfyProductExport`) iterates products that already have an Item SystemId
link. For each one it re-fills product fields from the Item, compares the record
field-by-field with a snapshot, and only calls the API when something changed.
Variants are matched by Item Variant SystemId and optionally by UoM option slot.
New BC Item Variants that have no Shopify counterpart are created as new Shopify
variants; existing ones are updated. Price-only sync is a separate fast path that
uses bulk GraphQL mutations when enough changed prices have been collected.

Import (`ShpfyProductImport`) uses `ShpfyProductMapping` to find a BC Item for
each variant. Mapping is SKU-driven -- the Shop's SKU Mapping setting determines
whether SKU is matched as Item No., Variant Code, Item No.+Variant Code, Barcode,
or Vendor Item No. If that primary strategy fails, the shop can optionally fall
back to the variant barcode. Unmatched products can auto-create Items via
`ShpfyCreateItem`, which applies an Item Template and creates references.

*Updated: 2026-07-29 -- price-only sync uses changed-price count and mapping fallback is configurable*

## Things to know

- Product-to-Item linking uses `Item SystemId` (a Guid), not Item No. The
  FlowField `Item No.` is derived via CalcFormula.
- The `Has Variants` flag on Product controls whether the connector expects
  Item Variant mappings on each Variant. When false, a single variant maps
  directly to the Item with no Item Variant required.
- `UoM as Variant` creates a Shopify variant per BC Unit of Measure. The UoM
  option slot (1, 2, or 3) is tracked in `UoM Option Id` on the Variant.
- Product.OnDelete invokes `IRemoveProductAction` from the Shop setting --
  implementations archive, draft, or do nothing in Shopify.
- Hash fields (`Image Hash`, `Tags Hash`, `Description Html Hash`) enable
  cheap change detection without comparing blob content.
- `ICreateProductStatusValue` determines whether newly created products start
  as Active, Draft, or Unlisted. Active means the connector creates the product
  as immediately active, Draft keeps it in draft, and Unlisted sends Shopify's
  Unlisted status without additional local branching. Archived is separate --
  it is a product status and removal outcome, not a "Status for Created
  Products" choice.
- Max 2048 variants per product -- enforced in `ShpfyCreateProduct`.
- Price sync silently skips items whose unit of measure is invalid (not in `Unit of Measure` table or not in `Item Unit of Measure` for that item). A `Shpfy Skipped Record` entry is logged instead of raising an error.
- Item attributes marked "As Option" can drive Shopify product options instead
  of the default Variant/UoM scheme, with validation for uniqueness and
  completeness.
- When `Find Mapping by Barcode` is enabled, barcode lookup is a fallback after
  SKU mapping fails. Disable it when barcodes are shared, recycled, or not a
  trustworthy item identity in BC.
- HS code and country of origin flow through `Shpfy Variant` during import and
  export. Import only writes existing BC Tariff Number and Country/Region values
  to Items, so blank or unknown Shopify values do not wipe existing item data.
- Product import skips products whose Shopify `Updated At` is not newer than
  both the local product timestamp and `Last Updated by BC`. When a stale product
  is skipped, mapped variants are left intact rather than being deleted.
- `Shpfy Product Price Calc.` is SingleInstance and caches a temporary Sales
  Quote. Its shop cache is refreshed when WorkDate changes, so price sync does
  not keep using yesterday's document date in long-running sessions.
- The Item Card treats variant-mapped items as already mapped. "Add to Shopify"
  is only enabled for shops where neither a Product nor a Variant maps to the
  current Item.
- In product export, an existing Shopify variant can map to a different BC Item
  than the parent product. `UpdateProductData` re-fetches the parent Item after
  updating existing variants so child-item variants do not corrupt the remaining
  create/update decisions for the parent.
- Bulk variant price updates send `compareAtPrice: null` when the compare-at
  price is not greater than the current price. The Shopify Variants page exposes
  Compare-at Price for diagnostics and personalization.

*Updated: 2026-07-29 -- product status, mapping, origin sync, import staleness, and price-sync gotchas added*
