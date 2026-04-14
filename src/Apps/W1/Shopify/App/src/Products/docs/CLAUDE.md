# Products

Bi-directional product and variant sync between BC Items and Shopify Products.

## What it does

Export pushes BC Item data (title, description, vendor, price, variants, images,
tags, metafields, translations) to Shopify. Import pulls Shopify Products back
and either maps them to existing Items or auto-creates new ones via templates.

## How it works

Export (`ShpfyProductExport`) iterates products that already have an Item SystemId
link. For each one it re-fills product fields from the Item, compares the record
field-by-field with a snapshot, and only calls the API when something changed.
Variants are matched by Item Variant SystemId and optionally by UoM option slot.
New BC Item Variants that have no Shopify counterpart are created as new Shopify
variants; existing ones are updated. Price-only sync is a separate fast path that
uses bulk GraphQL mutations.

Import (`ShpfyProductImport`) uses `ShpfyProductMapping` to find a BC Item for
each variant. Mapping is SKU-driven -- the Shop's SKU Mapping setting determines
whether SKU is matched as Item No., Variant Code, Item No.+Variant Code, Barcode,
or Vendor Item No. Unmatched products can auto-create Items via
`ShpfyCreateItem`, which applies an Item Template and creates references.

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
  as Active or Draft.
- Max 2048 variants per product -- enforced in `ShpfyCreateProduct`.
- Price sync silently skips items whose unit of measure is invalid (not in `Unit of Measure` table or not in `Item Unit of Measure` for that item). A `Shpfy Skipped Record` entry is logged instead of raising an error.
- Item attributes marked "As Option" can drive Shopify product options instead
  of the default Variant/UoM scheme, with validation for uniqueness and
  completeness.
