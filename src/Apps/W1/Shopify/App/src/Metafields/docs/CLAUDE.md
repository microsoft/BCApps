# Metafields

Manages Shopify metafields as a polymorphic, owner-agnostic system. Metafields are arbitrary key-value pairs that extend Shopify entities (products, variants, customers, companies) with custom data. This module handles type validation, bidirectional sync, and definition management.

## How it works

The `Shpfy Metafield` table (30101) stores all metafields in a single table, disambiguated by `Owner Type` (an enum: Customer, Product, ProductVariant, Company) and `Owner Id`. Setting `Owner Type` triggers its `IMetafieldOwnerType` implementation to derive `Parent Table No.`, and vice versa. Each owner type codeunit (e.g., `ShpfyMetafieldOwnerProduct`) knows how to retrieve existing metafield IDs from Shopify via GraphQL, look up the shop code from the owner record, and determine whether editing is allowed based on shop configuration.

Type validation is driven by the `IMetafieldType` interface. The `ShpfyMetafieldType` enum maps ~25 types (boolean, color, date, money, number_integer, single_line_text_field, url, volume, weight, various references, etc.) to implementing codeunits. Each provides `IsValidValue`, `HasAssistEdit`, `AssistEdit`, and `GetExampleValue`. When the `Value` field is validated on the table, the appropriate type implementation is invoked. The legacy `string` and `integer` types are blocked with an error directing users to `single_line_text_field` and `number_integer` respectively.

Syncing to Shopify goes through `ShpfyMetafieldAPI.CreateOrUpdateMetafieldsInShopify`, which compares local `"Last Updated by BC"` timestamps against Shopify's `updatedAt` to decide what to push. Shopify's `metafieldsSet` mutation accepts at most 25 metafields per call, so the code batches accordingly. Syncing from Shopify uses `UpdateMetafieldsFromShopify`, which processes a JSON array of metafield edges, creates or updates local records, and deletes any that no longer exist on the Shopify side.

## Things to know

- New metafields get auto-assigned negative IDs on insert (starting at -1, decrementing), similar to customer addresses. The namespace defaults to `Microsoft.Dynamics365.BusinessCentral` if left blank.
- The `money` type enforces that the currency code in the JSON value matches the shop's currency (or the LCY code from General Ledger Setup). Validation calls `ShpfyMtfldTypeMoney.TryExtractValues` which parses the `{"amount": "...", "currency_code": "..."}` JSON and verifies the currency exists in the Currency table.
- `rating` and `rich_text_field` types are intentionally commented out in the enum -- they are unsupported in BC.
- Metafield values longer than 2048 characters are silently skipped during import from Shopify, since `Value` is a `Text[2048]` field.
- The public API surface is `ShpfyMetafields` (codeunit 30418) with three methods: `GetMetafieldDefinitions`, `SyncMetafieldToShopify`, and `SyncMetafieldsToShopify`. Internal callers like `ShpfyCustomerExport` use this facade.
- Metafield definitions can be pulled from Shopify (first 50 per owner type) to pre-populate the namespace, key, and type without requiring manual entry.
- The `OnModify` trigger on the metafield table auto-stamps `"Last Updated by BC"`, which drives the delta-sync logic.
