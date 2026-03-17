# Translations

Multi-language product translation sync from BC item translations to Shopify's `translationsRegister` API.

`Shpfy Language` (`ShpfyLanguage.Table.al`) maps a Shopify locale (2-char code like "fr", "de") to a BC Language Code. Each record belongs to a shop. The `Sync Translations` flag controls whether translations are pushed for that locale -- it requires a Language Code to be set first. `ShpfyTranslationApi.PullLanguages` syncs the list from Shopify, skipping the primary locale (which is handled by the shop's own language setting) and removing locales that no longer exist in Shopify.

`Shpfy Translation` (`ShpfyTranslation.Table.al`) is a temporary-style record keyed by Resource Type + Resource ID + Locale + Name. The value is stored as a BLOB to handle long text. The `AddTranslation` method compares against the persisted table and only keeps entries where the text actually changed -- unchanged translations are deleted from the temp set so they don't generate unnecessary API calls.

The `Shpfy ICreate Translation` interface dispatches by `Shpfy Resource Type` (currently only `Product`). `ShpfyCreateTranslProduct.Codeunit.al` implements it: it reads the BC item translation for the mapped language code (via `ShpfyTranslationMgt.GetItemTranslation`) to populate the `title` key, and uses `ProductExport.CreateProductBody` for the `body_html` key. Each key is matched against a translatable content digest fetched from Shopify via `RetrieveTranslatableContentDigests` -- the digest is required by Shopify's API to identify which version of the source content the translation applies to.

`ShpfyTranslationApi.CreateOrUpdateTranslations` builds the GraphQL mutation by concatenating translation objects and calling `translationsRegister`. The escaping in `EscapeGrapQLData` handles backslashes and quotes for inline GraphQL strings.
