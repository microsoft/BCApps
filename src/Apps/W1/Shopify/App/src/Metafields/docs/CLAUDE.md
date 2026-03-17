# Metafields

Handles Shopify's custom key-value metadata system. Metafields can be attached to products, variants, customers, and companies, and the connector supports bidirectional sync between BC and Shopify.

## How it works

The `ShpfyMetafield` table (in `ShpfyMetafield.Table.al`) stores all metafields with an `Owner Type` enum and `Owner Id` pointing to the parent Shopify record. On insert, if no namespace is set it defaults to `Microsoft.Dynamics365.BusinessCentral`. New metafields created in BC get negative IDs (starting from -1, decrementing) so they do not collide with Shopify-assigned IDs -- once synced, `ShpfyMetafieldAPI.SyncMetafieldToShopify` returns the real Shopify ID.

The type system uses two extensible interface patterns. `ShpfyIMetafieldType` (implemented per enum value in `ShpfyMetafieldType.Enum.al`) provides validation (`IsValidValue`), assist-edit dialogs, and example values. `ShpfyIMetafieldOwnerType` (implemented per value in `ShpfyMetafieldOwnerType.Enum.al`) maps owner types to BC table IDs via `GetTableId`, retrieves metafield IDs from Shopify, and resolves the shop code from an owner record. The owner types are Customer, Product, ProductVariant, and Company.

`ShpfyMetafieldAPI` orchestrates sync in both directions. Exporting to Shopify uses the `metafieldsSet` mutation, batching up to 25 metafields per call. It compares `Last Updated by BC` timestamps against Shopify's `updatedAt` and only pushes metafields that changed in BC since the last Shopify update. Importing from Shopify uses `UpdateMetafieldsFromShopify`, which deletes metafields that no longer exist on the Shopify side.

## Things to know

- The money type validates that the currency code in the value matches the shop's currency (or LCY if no shop currency is set). This validation fires on the `Value` field's OnValidate trigger.
- Values longer than 2048 characters are silently skipped during import from Shopify, since that is the BC field length limit.
- Deprecated types `string` and `integer` are blocked on validate -- the UI forces users to `single_line_text_field` and `number_integer` instead.
- Metafield definitions can be pulled from Shopify via `GetMetafieldDefinitions`, which imports the first 50 definitions for a given owner type and creates placeholder metafield records.
- The `Parent Table No.` and `Owner Type` fields are kept in sync via their respective OnValidate triggers -- setting one automatically sets the other.
- Extensions can add new owner types by extending `ShpfyMetafieldOwnerType` enum and implementing `ShpfyIMetafieldOwnerType`, or new value types by extending `ShpfyMetafieldType` and implementing `ShpfyIMetafieldType`.
