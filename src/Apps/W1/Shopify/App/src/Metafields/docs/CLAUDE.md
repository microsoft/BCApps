# Metafields

Shopify's custom field system, implemented as typed key-value pairs that attach to products, variants, customers, or companies. This module handles the full lifecycle: type validation, value editing, and two-way sync via GraphQL.

## How it works

The Shpfy Metafield table (ID 30101) stores each metafield with a `Namespace` + `Name` composite identity (e.g., "custom.warranty_years"). The `Owner Type` enum (Customer, Product, ProductVariant, Company) determines which parent entity a metafield belongs to, and `Parent Table No.` is auto-calculated from it via the `IMetafieldOwnerType` interface -- each owner type implementation returns the correct BC table ID and can retrieve the shop code from the owner.

Type safety is enforced through the `Shpfy IMetafield Type` interface. Each Shopify type (single_line_text_field, number_integer, number_decimal, money, date, boolean, url, color, weight, dimension, volume, etc.) has its own codeunit in the `IMetafieldType` subfolder implementing `IsValidValue`, `GetExampleValue`, `HasAssistEdit`, and `AssistEdit`. When a Value is validated on the table, the current Type's `IsValidValue` is called; on failure the error message includes the example value. The `money` type (`ShpfyMtfldTypeMoney.Codeunit.al`) additionally validates that the currency code in the JSON `{"amount":"5.99","currency_code":"CAD"}` matches the shop's configured currency (falling back to LCY from General Ledger Setup).

The public API codeunit `ShpfyMetafields.Codeunit.al` (ID 30418, Access = Public) exposes three procedures: `GetMetafieldDefinitions`, `SyncMetafieldToShopify`, and `SyncMetafieldsToShopify`. The bulk sync only sends metafields whose `Last Updated by BC` timestamp indicates they changed since the last sync.

## Things to know

- New metafields created in BC get negative IDs (assigned in `OnInsert`: first gets -1, subsequent get `min existing - 1`), just like customer addresses. These are replaced with real Shopify IDs after the first sync.
- The `OnModify` trigger automatically stamps `Last Updated by BC` to CurrentDateTime, which prevents sync loops -- the import side checks this timestamp against Shopify's `Updated At`.
- Default namespace for BC-created metafields is `Microsoft.Dynamics365.BusinessCentral`.
- The deprecated `string` and `integer` types are blocked in the `Type` validate trigger with explicit error messages directing users to `single_line_text_field` and `number_integer` respectively.
- `Owner Resource` (the old text-based owner field) was removed in v28 -- only `Owner Type` (the enum) remains.
- The `money` type's `TryExtractValues` is a `[TryFunction]` that also validates the currency code exists in the BC Currency table and ensures the JSON has exactly 2 keys -- extra fields fail validation silently.
