# Business logic

## Overview

The GraphQL module handles all API communication with Shopify using GraphQL queries and mutations. It manages query construction, parameter substitution, rate limiting, and cost tracking.

## Key codeunits

### Shpfy GraphQL Queries (30154)

- **Key procedures**: GetQuery (two overloads with/without cost output)
- **Data flow**:
  1. Receives GraphQLType enum and parameters dictionary
  2. Instantiates IGraphQL interface from enum
  3. Calls GetGraphQL and GetExpectedCost on interface
  4. Replaces `{{ParamName}}` placeholders with values from dictionary
  5. Returns query text and expected cost

### Shpfy GraphQL Rate Limit (30153)

- **Key procedures**: SetQueryCost, WaitForRequestAvailable
- **Data flow**:
  1. Tracks last request time, restore rate (points/sec), and currently available points
  2. Before each request: calculates if sufficient points available
  3. If insufficient: calculates wait time = `(needed - available) / restoreRate * 1000ms`
  4. Sleeps until sufficient points restored
  5. After response: updates available points from throttleStatus

## Processing flows

### Query execution

1. Caller identifies GraphQLType enum value (e.g., GetCustomer, GetCustomerIds)
2. Caller builds parameters dictionary with keys matching template placeholders
3. ShpfyGraphQLQueries.GetQuery resolves interface, extracts template, substitutes parameters
4. Rate limiter checks cost vs available quota
5. Query executes via Communication Mgt
6. Response includes throttleStatus with currentlyAvailable and restoreRate
7. Rate limiter updates state for next request

### Query structure

- **Simple retrieval**: Single object by ID (e.g., GQL Customer: `customer(id: "gid://shopify/Customer/{{CustomerId}}")`)
- **Paginated retrieval**: Returns edges with cursor (e.g., GQL CustomerIds: `customers(first:200, query: "updated_at:>''{{LastSync}}''")`)
- **Next page**: Uses cursor from previous response (NextCustomerIds pattern)
- **Mutations**: Modify data (e.g., MetafieldsSet: `mutation { metafieldsSet(metafields: [{{Metafields}}]) }`)
- **Bulk operations**: Long-running queries that return URL to download results

### Parameter substitution

- Query templates contain `{{ParameterName}}` placeholders
- Parameters dictionary maps names to values
- ShpfyGraphQLQueries replaces all `{{Key}}` with dictionary values
- No validation -- missing parameters result in malformed queries

### Categories of queries

- **Get**: Initial retrieval with filters (e.g., GetCustomerIds, GetLocations)
- **GetNext**: Pagination continuation using cursor (e.g., GetNextCustomerIds)
- **Create/Update/Delete**: Mutations (e.g., CreateWebhookSubscription, UpdateOrderAttributes)
- **Bulk**: Async operations for large datasets (RunBulkOperationMutation, GetBulkOperation)
