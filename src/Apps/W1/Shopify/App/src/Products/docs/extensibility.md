# Products extensibility

All events are defined in `ShpfyProductEvents` (codeunit 30177). The two
interfaces live in the Interfaces/ subfolder.

## Customizing price calculation

- `OnBeforeCalculateUnitPrice` -- set `Handled := true` and populate UnitCost,
  Price, and ComparePrice yourself to replace the default Sales Line-based
  calculation entirely. Receives Item, VariantCode, UoM, Shop, and Catalog.
- `OnAfterCalculateUnitPrice` -- adjust the computed values after the default
  calculation runs. Same parameters, but no Handled flag.

These fire inside `ShpfyProductPriceCalc.CalcPrice` and are the right place
to implement custom pricing tiers, catalog-specific markups, or currency
overrides.

`Shpfy Update Price Source` (codeunit 30272) is public and is manually bound by
`CalcPrice` while the temporary Sales Line is validated. It supplies Shopify
shop pricing context to the price source pipeline when the temporary customer
does not exist as a real BC Customer.

*Updated: 2026-07-29 -- public price-source subscriber documented*

## Customizing product mapping (import)

- `OnBeforeFindProductMapping` -- intercept the mapping lookup before the
  SKU-based strategy runs. Set Handled to bypass default logic. You receive
  the Product, Variant, and output Item/ItemVariant records to populate.

If you do not handle the event, the built-in mapping tries the configured SKU
strategy first and then only falls back to barcode when the Shop's
`Find Mapping by Barcode` setting is enabled. Subscribers that depend on barcode
identity should be explicit rather than assuming the fallback is always active.

*Updated: 2026-07-29 -- barcode fallback is now a shop-controlled mapping behavior*

## Customizing item creation (import)

- `OnBeforeCreateItem` / `OnAfterCreateItem` -- fire around the creation of
  a BC Item from a Shopify product. OnBefore can set Handled to supply your
  own item creation logic. OnAfter is for post-creation enrichment (custom
  fields, dimensions, etc.).
- `OnBeforeCreateItemVariant` / `OnAfterCreateItemVariant` -- same pattern
  for Item Variant creation when the product has variants.
- `OnBeforeCreateItemVariantCode` -- override the auto-generated variant code
  (which defaults to the Shop's Variant Prefix + incrementing number).
- `OnBeforeFindItemTemplate` / `OnAfterFindItemTemplate` -- control which
  Item Template is used when auto-creating items.

## Customizing product body html (export)

- `OnBeforeCreateProductBodyHtml` -- completely replace the HTML generation.
  Set Handled and write your own ProductBodyHtml.
- `OnAfterCreateProductBodyHtml` -- post-process the generated HTML, e.g., to
  append custom sections or strip unwanted content.

## Customizing barcodes

- `OnBeforGetBarcode` / `OnAfterGetBarcode` -- override barcode resolution
  for a given Item No., Variant Code, and UoM. OnBefore can set Handled;
  OnAfter can modify the resolved barcode.

## Customizing exported product data

- `OnAfterFillInShopifyProductFields` -- modify the Shopify product record
  after standard fields (title, vendor, type, description, tags) are set
  from the BC Item.
- `OnAfterFillInProductVariantData` / `OnAfterFillInProductVariantDataFromVariant`
  -- modify variant data after standard fields are set. The "FromVariant"
  version fires when both ItemVariant and ItemUnitOfMeasure are present.
- `OnBeforSetProductTitle` / `OnAfterSetProductTitle` -- override or adjust
  the product title derived from Item Description / Item Translation.
- `OnBeforeSendCreateShopifyProduct` / `OnBeforeSendUpdateShopifyProduct` /
  `OnBeforeSendAddShopifyProductVariant` / `OnBeforeSendUpdateShopifyProductVariant`
  -- last chance to modify the records before they are serialized to API calls.

## Customizing item updates (import)

- `OnBeforeUpdateItem` / `OnAfterUpdateItem` -- fire when Shopify product
  data is being written back to an existing BC Item.
- `OnBeforeUpdateItemVariant` / `OnAfterUpdateItemVariant` -- same for Item
  Variants.
- `OnDoUpdateItemBeforeModify` / `OnDoUpdateItemVariantBeforeModify` -- fire
  just before `Item.Modify()` / `ItemVariant.Modify()`, with an
  `IsModifiedByEvent` flag to signal whether your subscriber made changes.

## Interfaces

**IRemoveProductAction** -- determines what happens in Shopify when a Product
record is deleted in BC. Implementations: `ShpfyRemoveProductDoNothing`,
`ShpfyToArchivedProduct`, `ShpfyToDraftProduct`. Chosen via the "Action for
Removed Products" enum on the Shop. Not extensible (enum is non-extensible).

**ICreateProductStatusValue** -- returns the initial Shopify status when creating
a new product from a BC Item. Implementations are Active, Draft, and Unlisted:
`ShpfyCreateProdStatusActive`, `ShpfyCreateProdStatusDraft`, and
`ShpfyCreateProdStatusUnlisted`. Chosen via the "Status for Created Products"
enum on the Shop. The enum is non-extensible, so partners can select the built-in
strategies but cannot add another creation-status value through enum extension.

*Updated: 2026-07-29 -- Unlisted creation status implementation added*

## Public product facade

`Shpfy Product` (codeunit 30234) is a public facade over the internal
add-to-Shopify flow. It exposes the same high-level operations used by the Item
Card: confirming the target shop, adding an Item to Shopify, validating
attribute-as-option compatibility, resolving product URLs, and opening the
product overview.

Use this facade when an extension needs "Add to Shopify" parity without reaching
into internal codeunits such as `Shpfy Sync Products` or `Shpfy Product Export`.
The facade preserves the same checks as the UI, including shop selection and
attribute option validation.

*Updated: 2026-07-29 -- public facade procedures exposed for add-to-Shopify parity*
