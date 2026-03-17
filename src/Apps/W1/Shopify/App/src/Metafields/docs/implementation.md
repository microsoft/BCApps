# Metafields implementation guide

## Overview

Metafields are custom key-value pairs attached to Shopify resources (products, variants, customers, companies). They allow merchants to store additional structured data beyond what the standard Shopify object model provides. The Shopify Connector synchronizes metafields bidirectionally between Shopify and Business Central.

Each metafield has a namespace, key (name), typed value, and belongs to an owner resource. Values are stored as text in BC (max 2048 characters) and validated against the metafield's type. Metafields that exceed the 2048-character limit in Shopify are not imported.

## Key patterns

### IMetafieldType interface

Defined in `Interfaces/ShpfyIMetafieldType.Interface.al`, the `Shpfy IMetafield Type` interface provides the contract for type-specific validation and editing of metafield values. All 26 supported types implement this interface.

The interface has four methods:

- `HasAssistEdit(): Boolean` -- whether the type provides a structured edit dialog
- `IsValidValue(Value: Text): Boolean` -- validates a raw text value against the type's format
- `AssistEdit(var Value: Text[2048]): Boolean` -- opens a dialog for structured editing; returns true if the value was modified
- `GetExampleValue(): Text` -- returns a sample value shown in validation error messages

The enum `Shpfy Metafield Type` (ID 30159) in `Enums/ShpfyMetafieldType.Enum.al` maps each type to its implementation codeunit. The enum is not extensible. Two legacy types (`string`, `integer`) are kept for backward compatibility but blocked from new use -- the table's `Type` field OnValidate trigger raises an error directing users to `single_line_text_field` and `number_integer` respectively.

**All type implementations** (in `Codeunits/IMetafieldType/`):

| Enum value | Codeunit | Validation approach | Has assist edit |
|---|---|---|---|
| `string` | `Shpfy Mtfld Type String` | Always valid (legacy, blocked) | No |
| `integer` | `Shpfy Mtfld Type Integer` | Always valid (legacy, blocked) | No |
| `json` | `Shpfy Mtfld Type JSON` | `JsonObject.ReadFrom()` | No |
| `boolean` | `Shpfy Mtfld Type Boolean` | `Evaluate(Boolean, Value, 9)` | No |
| `color` | `Shpfy Mtfld Type Color` | Regex `^#[0-9A-Fa-f]{6}$` | No |
| `date` | `Shpfy Mtfld Type Date` | `Evaluate(Date, Value, 9)` | No |
| `date_time` | `Shpfy Mtfld Type DateTime` | `Evaluate(DateTime, Value, 9)` | No |
| `dimension` | `Shpfy Mtfld Type Dimension` | JSON with `value` (decimal) + `unit` from `Shpfy Metafield Dimension Type` | Yes |
| `money` | `Shpfy Mtfld Type Money` | JSON with `amount` (decimal) + `currency_code` (must exist in Currency table) | Yes |
| `multi_line_text_field` | `Shpfy Mtfld Type Multi Text` | Always valid | Yes |
| `number_decimal` | `Shpfy Mtfld Type Num Decimal` | `Evaluate(Decimal, Value, 9)` | No |
| `number_integer` | `Shpfy Mtfld Type Num Integer` | `Evaluate(BigInteger, Value, 9)`, range-checked to +/-9007199254740991 | No |
| `single_line_text_field` | `Shpfy Mtfld Type Single Text` | Always valid | No |
| `url` | `Shpfy Mtfld Type URL` | Regex for http/https/mailto/sms/tel URLs | No |
| `volume` | `Shpfy Mtfld Type Volume` | JSON with `value` (decimal) + `unit` from `Shpfy Metafield Volume Type` | Yes |
| `weight` | `Shpfy Mtfld Type Weight` | JSON with `value` (decimal) + `unit` from `Shpfy Metafield Weight Type` | Yes |
| `collection_reference` | `Shpfy Mtfld Type Collect. Ref` | Regex for `gid://shopify/Collection/\d+` | No |
| `file_reference` | `Shpfy Mtfld Type File Ref` | Regex for `gid://shopify/` prefixed IDs | No |
| `metaobject_reference` | `Shpfy Mtfld Type Metaobj. Ref` | Regex for `gid://shopify/Metaobject/\d+` | No |
| `mixed_reference` | `Shpfy Mtfld Type Mixed Ref` | Regex for `gid://shopify/` prefixed IDs | No |
| `page_reference` | `Shpfy Mtfld Type Page Ref` | Regex for `gid://shopify/OnlineStorePage/\d+` | No |
| `product_reference` | `Shpfy Mtfld Type Product Ref` | Regex for `gid://shopify/Product/\d+` | No |
| `variant_reference` | `Shpfy Mtfld Type Variant Ref` | Regex for `gid://shopify/ProductVariant/\d+` | No |
| `customer_reference` | `Shpfy Mtfld Type Customer Ref` | Regex for `gid://shopify/Customer/\d+` | No |
| `company_reference` | `Shpfy Mtfld Type Company Ref` | Regex for `gid://shopify/Company/\d+` | No |
| `article_reference` | `Shpfy Mtfld Type Article Ref` | Regex for `gid://shopify/OnlineStoreArticle/\d+` | No |

**Unsupported Shopify types** (intentionally omitted): `rating`, `rich_text_field`. These are skipped during import via `ConvertToMetafieldType` in the API codeunit.

Types fall into three categories:

- **Simple types** (boolean, color, date, date_time, number_decimal, number_integer, single_line_text_field, url, json) -- validate the raw text value directly, no assist edit
- **Composite types** (money, dimension, volume, weight) -- store JSON with value + unit/currency, provide an assist edit dialog via `Shpfy Metafield Assist Edit` page
- **Reference types** (collection, file, metaobject, mixed, page, product, variant, customer, company, article) -- validate as Shopify GID format strings, no assist edit

### Supporting enums for composite types

- `Shpfy Metafield Dimension Type` (ID 30160) -- in, ft, yd, mm, cm, m
- `Shpfy Metafield Volume Type` (ID 30158) -- ml, cl, L, m3, fl oz, pt, qt, gal, imp fl oz, imp pt, imp qt, imp gal
- `Shpfy Metafield Weight Type` (ID 30157) -- kg, g, lb, oz
- `Shpfy Metafield Value Type` (ID 30102) -- obsolete legacy enum (String, Integer, Json), pending removal

### IMetafieldOwnerType interface

Defined in `Interfaces/ShpfyIMetafieldOwnerType.Interface.al`, the `Shpfy IMetafield Owner Type` interface binds metafields to their parent Shopify resource. It has four methods:

- `GetTableId(): Integer` -- returns the BC table ID for the owner record
- `RetrieveMetafieldIdsFromShopify(OwnerId: BigInteger): Dictionary of [BigInteger, DateTime]` -- fetches metafield IDs and their `updatedAt` timestamps from Shopify via GraphQL
- `GetShopCode(OwnerId: BigInteger): Code[20]` -- resolves the shop code from the owner record
- `CanEditMetafields(Shop: Record "Shpfy Shop"): Boolean` -- determines if the user can edit metafields based on shop sync settings

The enum `Shpfy Metafield Owner Type` (ID 30156) in `Enums/ShpfyMetafieldOwnerType.Enum.al` maps to four implementations (in `Codeunits/IOwnerType/`):

| Enum value | Codeunit | BC table | GraphQL query | Edit condition |
|---|---|---|---|---|
| `Customer` | `Shpfy Metafield Owner Customer` | `Shpfy Customer` | `CustomerMetafieldIds` | Can Update Shopify Customer AND import is not AllCustomers |
| `Product` | `Shpfy Metafield Owner Product` | `Shpfy Product` | `ProductMetafieldIds` | Sync Item = To Shopify AND Can Update Shopify Products |
| `ProductVariant` | `Shpfy Metafield Owner Variant` | `Shpfy Variant` | `VariantMetafieldIds` | Sync Item = To Shopify AND Can Update Shopify Products |
| `Company` | `Shpfy Metafield Owner Company` | `Shpfy Company` | `CompanyMetafieldIds` | Can Update Shopify Companies AND import is not AllCompanies |

The `Shpfy Metafield` table resolves owner type from table number via a case statement in `GetOwnerType()`, and vice versa through the `Owner Type` field's OnValidate trigger.

### Metafield sync flow

#### From Shopify to BC (import)

1. During product/customer/company sync, the caller passes a `JsonArray` of metafield nodes to `MetafieldAPI.UpdateMetafieldsFromShopify()`
2. The method collects all existing metafield IDs for the owner in BC
3. For each JSON node, it calls `UpdateMetadataField()` which:
   - Skips values longer than 2048 characters
   - Skips unsupported types (rating, rich_text_field) via `ConvertToMetafieldType()`
   - Upserts the metafield record (modify if exists, insert if new)
4. Any BC metafield IDs not seen in the Shopify response are deleted (cleanup of removed metafields)

#### From BC to Shopify (export)

1. `MetafieldAPI.CreateOrUpdateMetafieldsInShopify()` is the main entry point
2. It first retrieves current metafield IDs + timestamps from Shopify via the owner type's `RetrieveMetafieldIdsFromShopify()`
3. `CollectMetafieldsInBC()` filters to metafields that either:
   - Were updated in BC more recently than in Shopify (`Last Updated by BC > updatedAt`)
   - Do not yet exist in Shopify (new metafields)
   - Are not legacy types (string, integer are excluded)
   - Have a non-empty value
4. The Shopify `metafieldsSet` mutation accepts at most 25 metafields per call, so the method batches accordingly
5. Each metafield is serialized to a GraphQL fragment via `CreateMetafieldQuery()` with key, namespace, ownerId (as a GID), value, and type

#### Metafield definitions import

`GetMetafieldDefinitions()` fetches the first 50 metafield definitions from Shopify for a given owner type. It creates placeholder metafield records (no value) so users can populate them in BC before syncing back to Shopify.

### The Shpfy Metafield table

Defined in `Tables/ShpfyMetafield.Table.al` (ID 30101), key fields:

- `Id` (BigInteger, PK) -- Shopify's legacy resource ID. New metafields created in BC get negative auto-decremented IDs until synced
- `Namespace` (Text[255]) -- defaults to `Microsoft.Dynamics365.BusinessCentral` on insert
- `Name` (Text[64]) -- the metafield key
- `Type` (Enum "Shpfy Metafield Type") -- validated on change; blocks legacy types
- `Value` (Text[2048]) -- validated via the type's `IMetafieldType.IsValidValue()`; money type additionally checks shop currency
- `Owner Type` / `Parent Table No.` -- bidirectionally linked; setting one auto-sets the other
- `Owner Id` (BigInteger) -- the Shopify ID of the parent resource
- `Last Updated by BC` (DateTime) -- set on modify, used for change detection during export

### Public API

`Codeunits/ShpfyMetafields.Codeunit.al` (ID 30418) is the only `Access = Public` codeunit in the module. It exposes three methods:

- `GetMetafieldDefinitions(ParentTableNo, OwnerId, ShopCode)` -- imports definitions from Shopify
- `SyncMetafieldToShopify(var Metafield, ShopCode): BigInteger` -- syncs a single metafield, returns the Shopify ID
- `SyncMetafieldsToShopify(ParentTableNo, OwnerId, ShopCode)` -- bulk-syncs all changed metafields for an owner

### UI

- `Pages/ShpfyMetafields.Page.al` (ID 30163) -- list page for viewing/editing metafields for a resource. Editability is controlled by `IMetafieldOwnerType.CanEditMetafields()`. Has actions for "Get Metafield Definitions" and "Sync to Shopify". On insert, immediately syncs the new metafield to Shopify.
- `Pages/ShpfyMetafieldAssistEdit.Page.al` (ID 30164) -- standard dialog page used by composite types (money, dimension, volume, weight, multi-line text) for structured value editing.

## Integration points

Metafields connect to other modules through the owner type pattern:

- **Products module** -- metafields are fetched alongside product data during product sync. The `Shpfy Metafield Owner Product` codeunit ties into `Shpfy Product` (table) and checks `Shop."Sync Item"` and `Shop."Can Update Shopify Products"` settings.
- **Variants module** -- same sync permissions as products, tied to `Shpfy Variant` table.
- **Customers module** -- `Shpfy Metafield Owner Customer` resolves shop code via `Shpfy Customer."Shop Id"`. Edit permissions depend on `Shop."Can Update Shopify Customer"` and `Shop."Customer Import From Shopify"`.
- **Companies module** -- `Shpfy Metafield Owner Company` checks `Shop."Can Update Shopify Companies"` and `Shop."Company Import From Shopify"`.
- **GraphQL layer** -- each owner type uses a specific `Shpfy GraphQL Type` enum value (e.g., `ProductMetafieldIds`, `CustomerMetafieldIds`) for retrieving metafield IDs. The `MetafieldSet` mutation is shared across all owner types for writing.
- **Currency** -- the money type validates against the BC Currency table and checks that the currency code matches the shop's configured currency.

## Common tasks

### Adding a new metafield type

1. Add a new value to the `Shpfy Metafield Type` enum in `Enums/ShpfyMetafieldType.Enum.al` with the Shopify API type name as the enum member name
2. Create a new codeunit in `Codeunits/IMetafieldType/` implementing `Shpfy IMetafield Type`
3. Wire the implementation in the enum value's `Implementation` property
4. If the type needs structured editing, set `HasAssistEdit()` to return true and add a section to `Shpfy Metafield Assist Edit` page

### Extending owner types

1. Add a new value to the `Shpfy Metafield Owner Type` enum in `Enums/ShpfyMetafieldOwnerType.Enum.al`
2. Create a new codeunit in `Codeunits/IOwnerType/` implementing `Shpfy IMetafield Owner Type`
3. Add a case branch in `Shpfy Metafield.GetOwnerType()` to map the new table ID to the owner type
4. Create a corresponding GraphQL query type for retrieving metafield IDs from Shopify
