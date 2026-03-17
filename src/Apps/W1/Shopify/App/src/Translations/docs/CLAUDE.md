# Translations

Multi-language product synchronization between BC item translations and Shopify's translatable resources.

## How it works

`ShpfyTranslationApi.Codeunit.al` manages three concerns: pulling shop locales, retrieving translatable content digests, and registering translations. Shop locales are synced from Shopify's `shopLocales` query into the `ShpfyLanguage.Table.al`, with the primary locale skipped since it is handled by the shop's main language code setting. Languages removed from Shopify are deleted locally. Each language row maps a Shopify two-letter locale to a BC language code, and the `Sync Translations` flag must be enabled per language.

Translation export uses the `ICreateTranslation` interface pattern. `ShpfyCreateTranslProduct.Codeunit.al` implements this for products: given a BC Item record and a Shopify language, it reads the BC item translation for that language code (via `ShpfyTranslationMgt.GetItemTranslation`) and the product body HTML. Before creating a translation record, the API retrieves Shopify's `translatableContentDigests` for the resource -- these digests are required by Shopify's `translationsRegister` mutation to identify which field version is being translated. The `ShpfyTranslation.Table.al` uses an `AddTranslation` method that creates a temporary record, compares it against the persisted version, and only keeps it if the value actually changed.

## Things to know

- The `Transl. Content Digest` field is mandatory for Shopify's translation API -- it ties the translation to a specific version of the source content. Stale digests will cause the mutation to fail silently.
- The `ShpfyLanguage` table enforces that you cannot change the `Language Code` while `Sync Translations` is enabled, and vice versa, preventing misconfigured mappings.
- Translation values are stored in BLOB fields because product descriptions can exceed normal text field limits.
- The interface-based design (`ICreateTranslation`) allows adding translation support for new resource types without modifying the core API codeunit.
- GraphQL data in translation values is escaped by double-escaping backslashes and quotes, which can produce unexpected results if the source text already contains escape sequences.
