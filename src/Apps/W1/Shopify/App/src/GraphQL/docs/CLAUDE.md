# GraphQL

Part of [Shopify Connector](../../CLAUDE.md).

Provides GraphQL query execution infrastructure for communicating with the Shopify API, including query dispatch, rate limiting, and cost management.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Interface | Shpfy IGraphQL | Defines contract for GraphQL query providers (GetGraphQL, GetExpectedCost) |
| Enum | Shpfy GraphQL Type | Registry of 147 query types, each implementing IGraphQL for specific operations |
| Codeunit | Shpfy GraphQL Queries (30154) | Central dispatcher for GraphQL queries with parameter substitution |
| Codeunit | Shpfy GraphQL Rate Limit (30153) | Rate limit enforcement using restore rate and cost tracking |
| Codeunit | Shpfy GQL Customer (30127) | Example: retrieves customer data with metafields |
| Codeunit | Shpfy GQL CustomerIds (30128) | Example: retrieves updated customer IDs with pagination |
| Codeunit | Shpfy GQL MetafieldsSet (30350) | Mutation: sets metafields in batch |
| Codeunit | Shpfy GQL BulkOperation (30282) | Retrieves bulk operation status |
| Codeunit | Shpfy GQL CreateWebhookSub (30393) | Creates webhook subscriptions |

## Key concepts

- Each GraphQL query type is implemented as a separate codeunit implementing the IGraphQL interface
- The Shpfy GraphQL Type enum binds each query type to its implementation codeunit
- Queries use double-brace parameter substitution (e.g., `{{CustomerId}}`) replaced at runtime
- Rate limiting uses Shopify's restore rate (points per second) and cost tracking to prevent throttling
- The ExecuteGraphQL pattern delegates to ShpfyGraphQLQueries.GetQuery for parameter replacement
- Expected cost is declared per query type and used for rate limit scheduling
- Queries are categorized by operation: retrieval (Get*), pagination (GetNext*), mutations (Create*, Update*, Delete*)
