# Metafields

Manages Shopify metafields -- custom key-value data attached to products, variants, customers, and companies. Uses interface-driven type handling for validation and editing of 25+ metafield types.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyMetafields.Codeunit.al` (public API), `Codeunits/ShpfyMetafieldAPI.Codeunit.al`
- **Key patterns**: Interface-based type system (IMetafieldType, IMetafieldOwnerType), enum-implements-interface

## Structure

- Codeunits (28): Metafields (public facade), MetafieldAPI, 22 IMetafieldType implementations (Boolean, Color, Date, DateTime, Dimension, Integer, Json, Money, Url, etc.), 4 IOwnerType implementations (Company, Customer, Product, Variant)
- Tables (1): Metafield
- Enums (6): MetafieldDimensionType, MetafieldOwnerType, MetafieldType, MetafieldValueType, MetafieldVolumeType, MetafieldWeightType
- Interfaces (2): IMetafieldType, IMetafieldOwnerType
- Pages (2): Metafields, MetafieldAssistEdit

## Documentation

- [implementation.md](implementation.md) -- Type system, owner types, sync flow, and extensibility

## Key concepts

- `Shpfy Metafields` codeunit is the **public API** (Access = Public) -- it exposes `GetMetafieldDefinitions`, `SyncMetafieldToShopify`, and `SyncMetafieldsToShopify`
- Each `Shpfy Metafield Type` enum value implements `Shpfy IMetafield Type`, providing `IsValidValue`, `AssistEdit`, `HasAssistEdit`, and `GetExampleValue`
- Each `Shpfy Metafield Owner Type` enum value implements `Shpfy IMetafield Owner Type`, mapping owner types to BC table IDs and shop codes
- New metafields get auto-assigned negative IDs (decremented from the lowest existing) until synced to Shopify
- The `Last Updated by BC` timestamp on modify controls which metafields are pushed during sync
- Money-type metafields validate that the currency matches the shop currency
