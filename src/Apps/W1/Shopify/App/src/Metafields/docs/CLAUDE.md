# Metafields

Part of [Shopify Connector](../../CLAUDE.md).

Synchronizes custom metadata fields between Business Central and Shopify for customers, products, variants, and companies.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Metafield (30101) | Stores metafield data with namespace, key, value, type, and owner reference |
| Interface | Shpfy IMetafield Type | Validates and assists editing values for a metafield type |
| Interface | Shpfy IMetafield Owner Type | Handles owner-specific operations (retrieve IDs, get shop code, check edit permission) |
| Enum | Shpfy Metafield Type | 25+ supported types (boolean, date, integer, money, url, references, etc.) |
| Enum | Shpfy Metafield Owner Type | Owner resources: Customer, Product, ProductVariant, Company |
| Codeunit | Shpfy Metafield API (30316) | Bidirectional sync logic between BC and Shopify |
| Codeunit | Shpfy Metafields (30418) | Public API for metafield operations |
| Codeunit | Shpfy Mtfld Type Boolean (30338) | Example type validator for boolean values |
| Codeunit | Shpfy Metafield Owner Product (30334) | Owner-specific logic for products |

## Key concepts

- Metafields are custom key-value pairs attached to Shopify resources (products, customers, etc.)
- Each metafield has a namespace (default: "Microsoft.Dynamics365.BusinessCentral"), key, value, and type
- Type validation ensures values match Shopify's expected format (e.g., boolean must be "true"/"false")
- Owner type determines parent table, retrieval logic, and edit permissions
- Synchronization is bidirectional: BC to Shopify (create/update) and Shopify to BC (import)
- Batch updates use MetafieldsSet mutation (max 25 metafields per call)
- Only metafields updated in BC since last Shopify update are synced (timestamp comparison)
