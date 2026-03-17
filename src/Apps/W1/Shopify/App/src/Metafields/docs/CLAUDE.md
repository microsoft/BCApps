# Metafields

Metafields are Shopify's key-value extension mechanism. This folder implements a single `Shpfy Metafield` table that stores metafields across all owner types, with type-safe validation and bidirectional sync.

## Multi-owner polymorphism

The `Shpfy Metafield` table uses two fields to identify ownership: `Owner Type` (enum) and `Parent Table No.` (integer). These are kept in sync -- validating either one sets the other via `GetOwnerType` (a case statement mapping table IDs to enum values) and the `Shpfy IMetafield Owner Type` interface (which returns the table ID). Four owner types exist: `Customer`, `Product`, `ProductVariant`, `Company`, each backed by a codeunit in `Codeunits/IOwnerType/` that implements `GetTableId`, `RetrieveMetafieldIdsFromShopify`, `GetShopCode`, and `CanEditMetafields`.

The composite key `(Parent Table No., Owner Id)` indexes metafields by owner, while the primary key is just the Shopify `Id`.

## Negative ID allocation

BC-created metafields get negative IDs via the OnInsert trigger: find the lowest existing Id, subtract 1 (minimum -1). This mirrors the pattern used in `Shpfy Customer Address`. When synced to Shopify, the real positive ID replaces the placeholder. The default namespace for BC-created metafields is `Microsoft.Dynamics365.BusinessCentral`.

## Type-safe value validation

The `Shpfy IMetafield Type` interface provides four methods: `HasAssistEdit`, `IsValidValue`, `AssistEdit`, and `GetExampleValue`. The `Shpfy Metafield Type` enum maps ~25 Shopify types to implementations in `Codeunits/IMetafieldType/`. The Value field's OnValidate trigger calls `IMetafieldType.IsValidValue` and errors with the example value on failure. The `money` type additionally validates that the currency code matches the shop's currency.

Notable: `string` and `integer` are legacy types that error on assignment, directing users to `single_line_text_field` and `number_integer` respectively. `rating` and `rich_text_field` are intentionally commented out as unsupported.

## Adding a new type

To add a new metafield type:

1. Add a value to the `Shpfy Metafield Type` enum with an `Implementation` pointing to a new codeunit
2. Create the codeunit implementing `Shpfy IMetafield Type` in `Codeunits/IMetafieldType/`
3. Implement the four interface methods (validation logic, example value, optional assist edit)

## Sync API

`ShpfyMetafields.Codeunit.al` is the public facade (Access = Public). It delegates to `ShpfyMetafieldAPI.Codeunit.al` for the actual Shopify GraphQL calls. Three operations: `GetMetafieldDefinitions` (pulls definitions from Shopify), `SyncMetafieldToShopify` (single metafield), `SyncMetafieldsToShopify` (all metafields for an owner, filtered by `Last Updated by BC`).
