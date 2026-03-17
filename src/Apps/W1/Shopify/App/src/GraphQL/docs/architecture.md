# GraphQL module architecture

## The IGraphQL interface contract

`Shpfy IGraphQL` (in `Interfaces/ShpfyIGraphQL.Interface.al`) defines two methods:

```al
interface "Shpfy IGraphQL"
    procedure GetGraphQL(): Text;       // Returns the JSON-encoded GraphQL query or mutation
    procedure GetExpectedCost(): Integer; // Returns the expected query cost for rate limiting
```

Every GraphQL operation in the connector implements this interface. The query text is returned as a raw JSON string containing either a `"query"` (for reads) or `"mutation"` (for writes) field. Parameters are embedded as `{{placeholders}}` that get substituted before execution.

## Query builder codeunit pattern

Each codeunit follows the same structure:

1. Declare `implements "Shpfy IGraphQL"` on the codeunit
2. `GetGraphQL()` returns a hardcoded JSON string with the GraphQL query and `{{parameter}}` placeholders
3. `GetExpectedCost()` returns a static integer representing the anticipated Shopify query cost

Example -- `Shpfy GQL CustomerIds` (codeunit 30128):

```al
procedure GetGraphQL(): Text
begin
    exit('{"query":"{customers(first:200, query: \"updated_at:>''{{LastSync}}''\"){pageInfo{hasNextPage} edges{cursor node{id updatedAt}}}}"}');
end;

procedure GetExpectedCost(): Integer
begin
    exit(12);
end;
```

Mutation example -- `Shpfy GQL CloseOrder` (codeunit 30217):

```al
procedure GetGraphQL(): Text
begin
    exit('{"query": "mutation { orderClose(input: { id: \"gid://shopify/Order/{{OrderId}}\" }) { order { legacyResourceId closed closedAt }, userErrors {field, message}}}"}');
end;
```

Some codeunits use the `"variables"` JSON field for complex mutations (e.g., `Shpfy GQL Modify Inventory` uses `InventorySetQuantitiesInput`).

## Naming conventions

Codeunit names follow a strict pattern:

- **Prefix**: `Shpfy GQL` (abbreviated from "Shopify GraphQL")
- **Operation**: descriptive name matching the Shopify API operation
- **Pagination**: `Next` prefix for cursor-based pagination follow-up queries

Examples:

| Codeunit | Purpose |
|----------|---------|
| `Shpfy GQL CustomerIds` | First page of customer IDs |
| `Shpfy GQL NextCustomerIds` | Subsequent pages of customer IDs |
| `Shpfy GQL CloseOrder` | `orderClose` mutation |
| `Shpfy GQL FindCustByEMail` | Customer lookup by email |
| `Shpfy GQL ModifyInventory` | `inventorySetQuantities` mutation |
| `Shpfy GQL RevFulfillOrders` | Reverse fulfillment orders query |

Abbreviated forms are used when names would exceed AL's 30-character limit (e.g., `FFOrders` for "Fulfillment Orders", `CompLoc` for "Company Location", `NextRevFulfillOrdLns` for "Next Reverse Fulfillment Order Lines").

## Rate limiting (ShpfyGraphQLRateLimit)

`Shpfy GraphQL Rate Limit` (codeunit 30153) is a `SingleInstance` codeunit implementing a token bucket algorithm:

1. After each request, `SetQueryCost` reads the `extensions.cost.throttleStatus` from Shopify's response, capturing `currentlyAvailable` tokens and `restoreRate` (tokens per second)
2. Before each request, `WaitForRequestAvailable(ExpectedCost)` checks if enough tokens are available
3. If not, it calculates wait time: `(ExpectedCost - LastAvailable) / RestoreRate * 1000 - timeSinceLastRequest`
4. Calls `Sleep(waitTime)` to throttle the request

The default restore rate (when not yet known from Shopify) is 50 tokens/second. The rate limiter is separate from the HTTP-level retry logic in `ShpfyCommunicationMgt`, which handles `THROTTLED` responses by re-checking rate limits and retrying.

## How GraphQL codeunits are selected and dispatched

The dispatch chain is:

```
Caller code
  -> CommunicationMgt.ExecuteGraphQL(GraphQLType, Parameters)
    -> GraphQLQueries.GetQuery(GraphQLType, Parameters, ExpectedCost)
      -> [Event] OnBeforeSetInterfaceCodeunit  -- allows overriding the interface
      -> IGraphQL := GraphQLType               -- AL enum-to-interface resolution
      -> [Event] OnBeforeGetGrapQLInfo         -- allows overriding query/cost
      -> GraphQL := IGraphQL.GetGraphQL()
      -> ExpectedCost := IGraphQL.GetExpectedCost()
      -> [Event] OnAfterGetGrapQLInfo
      -> [Event] OnBeforeReplaceParameters     -- allows custom parameter handling
      -> Replace all {{param}} placeholders from the Parameters dictionary
      -> [Event] OnAfterReplaceParameters
    -> CommunicationMgt handles rate limiting, HTTP execution, retry, logging
```

The `GraphQLQueries` codeunit is also `SingleInstance = true` and provides 5 internal events for extensibility. The `OnBeforeSetInterfaceCodeunit` event allows replacing the implementation codeunit entirely, which is useful for testing or partner customization.

## Enum-driven query selection

`Shpfy GraphQL Type` (enum 30111) is the central dispatch table. It is declared `Extensible = true`, allowing partners to add custom queries. Each enum value specifies:

- An integer ordinal (0-147 currently)
- A caption for display purposes
- An `Implementation` clause mapping to the codeunit that implements `Shpfy IGraphQL`

Example:

```al
value(1; GetCustomerIds)
{
    Caption = 'Get Customer Ids';
    Implementation = "Shpfy IGraphQL" = "Shpfy GQL CustomerIds";
}
```

The enum currently has ~147 values covering:

- **Queries**: Customer IDs/details, product IDs/details/images/options, order headers/lines/fulfillments/transactions, inventory entries, locations, catalogs, companies, disputes, payouts, payment terms, delivery profiles, metafields, staff members, sales channels, webhook subscriptions
- **Mutations**: Close/cancel/fulfill orders, modify inventory, create/update fulfillment services, manage catalogs/price lists/publications, set metafields, manage webhooks, update product images/options, assign company contacts, register translations, mark orders as paid, create upload URLs, complete draft orders

Pagination pairs follow the pattern: `GetCustomerIds` (value 1) for the first page and `GetNextCustomerIds` (value 2) for subsequent pages, where the "Next" variant accepts a `{{Cursor}}` parameter.
