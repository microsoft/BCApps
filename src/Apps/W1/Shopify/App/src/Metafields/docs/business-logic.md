# Business logic

## Overview

Metafields enable storing custom structured data on Shopify resources. The module handles type conversion, bidirectional synchronization, and owner-specific logic.

## Key codeunits

### Shpfy Metafield API (30316)

- **Key procedures**:
  - SyncMetafieldToShopify (single record)
  - SyncMetafieldsToShopify (batch for owner)
  - UpdateMetafieldsFromShopify (import from JSON)
  - GetMetafieldDefinitions (retrieve schema)
- **Data flow**:
  1. Sync to Shopify: CollectMetafieldsInBC filters changed records, CreateMetafieldQuery builds GraphQL, UpdateMetafields executes
  2. Sync from Shopify: UpdateMetafieldsFromShopify parses JSON array, UpdateMetadataField creates/updates records
  3. Definitions: GetMetafieldDefinitions creates empty metafield records from Shopify schema

### Shpfy Metafields (30418)

- **Key procedures**: GetMetafieldDefinitions, SyncMetafieldToShopify, SyncMetafieldsToShopify
- **Purpose**: Public API wrapper for MetafieldAPI codeunit

## Processing flows

### Sync to Shopify

1. Caller invokes SyncMetafieldsToShopify with ParentTableNo, OwnerId, ShopCode
2. RetrieveMetafieldsFromShopify calls owner-specific interface to get metafield IDs + timestamps
3. CollectMetafieldsInBC filters local metafields: changed since last sync OR new (not in retrieved list)
4. CreateMetafieldQuery builds JSON for each metafield: `{key, namespace, ownerId, value, type}`
5. UpdateMetafields sends batches of 25 to MetafieldsSet mutation
6. Shopify returns legacyResourceId for new metafields

### Sync from Shopify

1. Caller invokes UpdateMetafieldsFromShopify with JMetafields JSON array, ParentTableNo, OwnerId
2. CollectMetafieldIds builds list of existing BC metafield IDs
3. For each JSON node: UpdateMetadataField creates/modifies record, removes from list
4. DeleteUnusedMetafields removes IDs still in list (deleted in Shopify)
5. Skips metafields with value > 2048 chars or unsupported types

### Type conversion

- Each metafield type implements IMetafield Type interface
- IsValidValue: checks if value matches type format (e.g., boolean validator uses Evaluate(DummyBoolean, Value, 9))
- GetExampleValue: provides sample for error messages (e.g., "true" for boolean)
- HasAssistEdit/AssistEdit: optional UI for complex types
- GetTypeName: converts enum to Shopify API string (e.g., "boolean", "money", "product_reference")

### Owner types

- **Customer**: Table 30105, retrieves via GQL CustomerMetafieldIds, editable if sync enabled
- **Product**: Table 30108, retrieves via GQL ProductMetafieldIds, editable if "Sync Item = To Shopify" and "Can Update Shopify Products"
- **ProductVariant**: Table 30109, retrieves via GQL VariantMetafieldIds, same edit rules as Product
- **Company**: Table 30126, retrieves via GQL CompanyMetafieldIds, editable if B2B enabled

Each owner type codeunit provides:
- GetTableId: returns BC table number
- RetrieveMetafieldIdsFromShopify: executes GraphQL query, parses IDs + timestamps
- GetShopCode: retrieves shop from owner record
- CanEditMetafields: checks shop settings for permission
