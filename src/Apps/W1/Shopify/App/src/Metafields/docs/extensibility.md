# Metafields extensibility

## IMetafieldType interface

The `Shpfy IMetafield Type` interface defines four methods:

- `HasAssistEdit(): Boolean` -- whether a dialog-based editor exists for
  this type.
- `IsValidValue(Value: Text): Boolean` -- validates a raw text value
  against the type's rules.
- `AssistEdit(var Value: Text[2048]): Boolean` -- opens an assist-edit
  dialog and returns the modified value. Only called when `HasAssistEdit`
  returns true.
- `GetExampleValue(): Text` -- returns a sample value shown in error
  messages when validation fails.

Each enum value in `Shpfy Metafield Type` maps to a codeunit in
`Codeunits/IMetafieldType/`. For example, `ShpfyMtfldTypeMoney` parses
JSON with `amount` and `currency_code`, validates that the currency exists
in BC's Currency table, and provides an assist-edit page. Simpler types
like `ShpfyMtfldTypeBoolean` just check for `"true"` or `"false"`.

The enum is `Extensible = false`, so third parties cannot currently add
new metafield value types through enum extension. To support a new
Shopify metafield type, the enum and a new implementing codeunit must be
added to the base connector code.

## IMetafieldOwnerType interface

The `Shpfy IMetafield Owner Type` interface defines four methods:

- `GetTableId(): Integer` -- returns the BC table ID where the owner
  entity lives (e.g., `Database::"Shpfy Product"`).
- `RetrieveMetafieldIdsFromShopify(OwnerId: BigInteger): Dictionary of [BigInteger, DateTime]`
  -- calls the Shopify API to get current metafield IDs and their last
  update timestamps for a specific owner.
- `GetShopCode(OwnerId: BigInteger): Code[20]` -- resolves which shop
  record the owner belongs to.
- `CanEditMetafields(Shop: Record "Shpfy Shop"): Boolean` -- checks
  whether metafield editing is allowed for this owner type in the given
  shop configuration.

Four implementations exist in `Codeunits/IOwnerType/`: Customer, Product,
Variant, and Company. Each knows how to look up its entity table, call the
right GraphQL query for metafield IDs (e.g., `ProductMetafieldIds`,
`CustomerMetafieldIds`), and extract the shop code from the owner record.

## How the type system works at runtime

When a user edits the Value field on a metafield record, the table's
OnValidate trigger does:

```
IMetafieldType := Rec.Type;
if not IMetafieldType.IsValidValue(Value) then
    Error(ValueNotValidErr + IMetafieldType.GetExampleValue());
```

AL resolves `Rec.Type` (the enum value) to the matching interface
implementation, so each type's validation runs automatically. The same
dispatch pattern applies when the UI calls `AssistEdit`.

## Registering new owner types

Adding a new owner type (if the enum were extensible) would require:

- A new enum value in `Shpfy Metafield Owner Type` pointing to a new
  codeunit.
- The codeunit implements all four `IMetafieldOwnerType` methods.
- A corresponding GraphQL query codeunit to fetch metafield IDs from
  Shopify for that entity type.
- An entry in the `GetOwnerType` case statement in the Metafield table
  to map the BC table number back to the enum value.
