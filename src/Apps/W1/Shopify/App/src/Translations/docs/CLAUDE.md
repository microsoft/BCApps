# Translations

Multi-language product content sync to Shopify Markets/Locales. Maps BC item translations to Shopify translatable resources, using change detection to avoid unnecessary API calls.

## How it works

`Shpfy Language` (30156) maps Shopify locales (2-letter codes) to BC Language Codes per shop, with a `Sync Translations` toggle that requires a language code to be set first. `Shpfy Translation` (30157) stores per-resource translations keyed by (Resource Type, Resource ID, Locale, Name), with the translation value stored as a BLOB and a `Transl. Content Digest` field for change detection.

The `Shpfy ICreate Translation` interface (implemented per `Shpfy Resource Type` enum) generates translation records for a given resource and language. `ShpfyCreateTranslProduct` is the product implementation, which reads BC `Item Translation` records via `ShpfyTranslationMgt.GetItemTranslation()`. The `ShpfyTranslationApi` codeunit handles the GraphQL calls to Shopify's `translatableResourcesByIds` and `translationsRegister` endpoints.

The `AddTranslation` method on the Translation table inserts a temporary record, then compares it against the persisted copy -- if the value hasn't changed, the temporary record is deleted, preventing unnecessary API writes.

## Things to know

- Translation sync is opt-in per language: the `Sync Translations` field on `Shpfy Language` must be enabled, and a BC Language Code must be mapped to the Shopify locale.
- Change detection works by comparing the new translation text against the persisted `Shpfy Translation` record. Only changed translations are included in the sync payload sent to Shopify.
- The `Transl. Content Digest` field stores Shopify's digest of the original translatable content, which is required by the Shopify API to associate translations with the correct content version.
- The `Shpfy Resource Type` enum is extensible, meaning new resource types (beyond products) can be added by third-party extensions implementing `Shpfy ICreate Translation`.
- `ShpfyTranslationMgt.GetItemTranslation()` looks up BC's `Item Translation` table by Item No., Variant Code, and Language Code, returning the translated description or blank if not found.
