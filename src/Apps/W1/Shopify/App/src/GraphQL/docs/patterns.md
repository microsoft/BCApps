# GraphQL query builder pattern

## The interface

`Shpfy IGraphQL` defines the contract every query must fulfill:

- `GetGraphQL(): Text` -- returns the complete JSON-encoded GraphQL
  request body, including the `"query"` key and optionally `"variables"`.
- `GetExpectedCost(): Integer` -- returns the estimated cost points for
  Shopify's rate limiter.

That is the entire interface. No setup, no state, no dependencies.

## Enum-to-codeunit mapping

AL's interface-implementing enums do the dispatch. The `Shpfy GraphQL Type`
enum declares ~143 values, each with an `Implementation` clause pointing
to a specific codeunit. When code needs to execute a query, it passes the
enum value to `ShpfyGraphQLQueries.GetQuery()`, which resolves the
interface implementation via `IGraphQL := GraphQLType` (AL's implicit
interface cast from enum to interface).

This means adding a new API operation requires exactly two things: a new
codeunit implementing `Shpfy IGraphQL`, and a new enum value pointing to
it.

## Parameter substitution

Parameters use named `{{placeholder}}` tokens inside the query string.
The dispatcher receives a `Dictionary of [Text, Text]` and does literal
string replacement:

```
GraphQL := GraphQL.Replace('{{' + Param + '}}', Parameters.Get(Param));
```

This is deliberately simple. No escaping, no type coercion, no query
builder DSL. The caller is responsible for formatting values correctly
(e.g., wrapping strings in quotes within the GraphQL body itself, or
formatting GIDs as `gid://shopify/Customer/{{CustomerId}}`).

## Concrete example: ShpfyGQLCustomer

`Codeunits/ShpfyGQLCustomer.Codeunit.al` fetches a single customer by ID.

`GetGraphQL()` returns a JSON string containing a query that takes a
`{{CustomerId}}` parameter embedded in a GID path:
`gid://shopify/Customer/{{CustomerId}}`. The query requests
`legacyResourceId`, name fields, addresses, tax info, tags, and up to 50
metafields in a single call.

`GetExpectedCost()` returns 12, reflecting the nested address and
metafield connections.

The caller provides `Parameters.Add('CustomerId', Format(ShopifyCustomerId))`
and the dispatcher substitutes it into the GID.

## Mutations follow the same pattern

`Codeunits/ShpfyGQLModifyInventory.Codeunit.al` is a mutation, not a
query. It returns a JSON body with both `"query"` (containing the mutation
text) and `"variables"` (containing the input structure). The variables
include an empty `quantities` array that the `InventoryAPI` codeunit
populates after parsing the template. It also uses `{{IdempotencyKey}}`
for retry safety, substituted with a fresh GUID on each attempt.

## Why not string concatenation or direct HTTP calls

The alternative would be building GraphQL strings inline wherever they
are needed. This pattern avoids that because:

- Each query is isolated in its own codeunit, making it easy to find,
  read, and update when the Shopify API changes.
- The expected cost travels with the query, so rate limiting is automatic.
- The dispatcher fires events (`OnBeforeSetInterfaceCodeunit`,
  `OnBeforeGetGrapQLInfo`, `OnAfterGetGrapQLInfo`,
  `OnBeforeReplaceParameters`, `OnAfterReplaceParameters`) that let
  extensions intercept or replace any query without modifying the
  original codeunit.
- The enum is extensible, so extensions can add entirely new operations.

## Cost tracking

Each codeunit declares its cost as a hand-tuned integer. The rate limiter
(`ShpfyGraphQLRateLimit`) compares the expected cost against the available
budget from Shopify's throttle status and sleeps when needed. If the
available budget is unknown (first request), the restore rate defaults to
50 points/second.

There is no automatic cost calculation. If Shopify changes query pricing,
the constants need manual adjustment.
