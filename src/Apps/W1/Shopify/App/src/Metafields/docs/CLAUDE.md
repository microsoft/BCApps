# Metafields

Extensible custom field system that attaches key-value metadata to Shopify
entities: products, variants, customers, and companies.

## How it works

The `Shpfy Metafield` table (`Tables/ShpfyMetafield.Table.al`) stores all
metafields. Each record has an `Owner Type` enum and `Owner Id`
identifying the parent entity, plus a `Parent Table No.` mapping to the
BC table. Two interface systems handle polymorphism:

- `Shpfy IMetafield Type` -- per-value-type behavior (validation, assist
  edit, example values). The `Shpfy Metafield Type` enum maps 26 types
  (boolean, money, url, references, etc.) to codeunits in
  `Codeunits/IMetafieldType/`.
- `Shpfy IMetafield Owner Type` -- per-owner behavior (table ID lookup,
  Shopify metafield retrieval, shop code resolution, edit permissions).
  Four implementations in `Codeunits/IOwnerType/` cover Customer, Product,
  Variant, and Company.

The public API is `Shpfy Metafields` codeunit
(`Codeunits/ShpfyMetafields.Codeunit.al`, Access = Public) exposing sync
and definition retrieval methods.

## Things to know

- Default namespace: `'Microsoft.Dynamics365.BusinessCentral'` (set in
  OnInsert trigger).
- Negative IDs = BC-created metafields not yet synced to Shopify.
- Money type requires currency match with the shop -- enforced in the
  Value OnValidate trigger via `CheckShopCurrency`.
- Legacy types `string` and `integer` are blocked at validation time,
  directing users to `single_line_text_field` and `number_integer`.
- Both the type enum (`Extensible = false`) and owner type enum are not
  extensible by third parties.
