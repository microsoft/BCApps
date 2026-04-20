# GraphQL query builder pattern

*Updated: 2026-03-24 -- GraphQL resource file refactoring*

## Resource file pattern

Each API operation lives in a `.graphql` file under
`.resources/graphql/{Area}/{QueryName}.graphql`. The file format is:

- **Line 1**: `# cost: N` -- the expected cost points for rate limiting
- **Lines 2+**: the complete JSON-encoded GraphQL request body, including
  the `"query"` key and optionally `"variables"`

That is the entire contract. No codeunit, no interface, no state.

## Enum-to-resource mapping

The `Shpfy GraphQL Type` enum declares 143 values using
`{Area}_{QueryName}` naming (e.g., `Customers_GetCustomerIds`). The enum
is `Extensible = false` -- extensions cannot add new query types.

When code needs to execute a query, it passes the enum value to
`ShpfyGraphQLQueries.GetQuery()`. The dispatcher calls
`NavApp.GetResourceAsText()` to load the `.graphql` file, parses the
cost from line 1, performs parameter substitution, and returns the query
body.

Adding a new API operation requires two things: a `.graphql` resource
file and a new enum value.

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

## Concrete example: Customers_GetCustomer

`.resources/graphql/Customers/GetCustomer.graphql` fetches a single
customer by ID. The query takes a `{{CustomerId}}` parameter embedded in
a GID path: `gid://shopify/Customer/{{CustomerId}}`. It requests
`legacyResourceId`, name fields, addresses, tax info, tags, and up to 50
metafields in a single call. Line 1 declares `# cost: 12`, reflecting
the nested address and metafield connections.

The caller provides `Parameters.Add('CustomerId', Format(ShopifyCustomerId))`
and the dispatcher substitutes it into the GID.

## Mutations follow the same pattern

`Inventory/ModifyInventory.graphql` is a mutation, not a query. It
contains a JSON body with both `"query"` (containing the mutation text)
and `"variables"` (containing the input structure). The variables include
an empty `quantities` array that the `InventoryAPI` codeunit populates
after parsing the template. It also uses `{{IdempotencyKey}}` for retry
safety, substituted with a fresh GUID on each attempt.

## Why resource files instead of inline strings

The alternative would be building GraphQL strings inline wherever they
are needed. This pattern avoids that because:

- Each query is isolated in its own file, making it easy to find, read,
  and update when the Shopify API changes.
- The expected cost travels with the query (line 1), so rate limiting is
  automatic.
- Resource files are plain text -- no AL compilation needed to review or
  edit query bodies.

The dispatcher no longer fires any events. Extensions cannot intercept,
replace, or extend queries at runtime. The enum is not extensible.

## Cost tracking

Each `.graphql` file declares its cost as a `# cost: N` comment on
line 1. The rate limiter (`ShpfyGraphQLRateLimit`) compares the expected
cost against the available budget from Shopify's throttle status and
sleeps when needed. If the available budget is unknown (first request),
the restore rate defaults to 50 points/second.

There is no automatic cost calculation. If Shopify changes query pricing,
the constants need manual adjustment.

## Obsolete stub codeunits

*Updated: 2026-03-24 -- GraphQL resource file refactoring*

14 previously-public GQL codeunits (e.g., `ShpfyGQLCustomer`) have been
replaced by obsolete stubs with `ObsoleteState = Pending`. These stubs
delegate to the new dispatcher so dependent extensions continue to
compile during the CLEAN29 transition. They will be removed once the
obsolete-pending period expires. Do not add new references to these
codeunits.

## Legacy patterns (pre-refactoring)

Before the resource file refactoring, each API operation was a separate
codeunit implementing the `Shpfy IGraphQL` interface, which required
`GetGraphQL(): Text` and `GetExpectedCost(): Integer`. The enum used AL's
`implements` keyword to dispatch via `IGraphQL := GraphQLType`. The
dispatcher fired five extension events (`OnBeforeSetInterfaceCodeunit`,
`OnBeforeGetGrapQLInfo`, `OnAfterGetGrapQLInfo`,
`OnBeforeReplaceParameters`, `OnAfterReplaceParameters`) and the enum was
`Extensible = true`. Adding a query required four steps: create a
codeunit, implement the interface, add an enum value with
`Implementation` clause, and register in the permission set.

This pattern no longer exists in the codebase. Dependent extensions that
subscribed to the dispatcher events or extended the enum will need to
adapt during the CLEAN29 transition.
