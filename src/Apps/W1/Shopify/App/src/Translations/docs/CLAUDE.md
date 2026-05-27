# Translations

Syncs multi-language product data (titles and descriptions) from BC item translations to Shopify's translation API. The module is interface-driven to support extending translation to other resource types.

## How it works

The `Shpfy ICreate Translation` interface defines a single method -- `CreateTranslation` -- that accepts a source record, a Shopify language, a temporary translation record set, and a dictionary of translatable content digests. The only implementation today is `ShpfyCreateTranslProduct`, which translates product titles from BC's Item Translation table and product body HTML via `ProductExport.CreateProductBody`, both for a given language code.

Translations are stored in the `Shpfy Translation` table, keyed by resource type, resource ID, locale, and field name (e.g., "title", "body_html"). The value is a BLOB to handle large HTML descriptions. The table includes change detection -- `AddTranslation` compares the new translation against the stored one and only keeps the record if it has actually changed. Each translation also stores the `Transl. Content Digest` from Shopify, which is required by the translations API to identify which version of the original content the translation applies to.

`ShpfyTranslationMgt` provides a helper to look up BC Item Translation records by item number, variant code, and language code. The `Shpfy Language` table maps Shopify's shop languages to BC language codes and locales.

## Things to know

- The `Shpfy ICreate Translation` interface is the extension point -- new resource types (e.g., collections, metafields) would add new implementations.
- Translation values are stored as BLOBs because product body HTML can exceed normal text field limits.
- Change detection prevents unnecessary API calls -- only translations that differ from the last synced value are included in the update query.
- The `Transl. Content Digest` is Shopify's content fingerprint; it must match the current translatable content or the API will reject the update.
- The `Shpfy Resource Type` enum identifies what kind of Shopify entity is being translated (currently just Product).
