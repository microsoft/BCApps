# GraphQL

*Updated: 2026-03-24 -- GraphQL resource file refactoring*

Type-safe query infrastructure for the Shopify Admin API. Every API call
the connector makes passes through this layer.

## How it works

Each API operation lives in a `.graphql` resource file under
`.resources/graphql/{Area}/{QueryName}.graphql`. Line 1 is a
`# cost: N` comment declaring the expected cost points for rate limiting;
lines 2+ contain the JSON-encoded GraphQL request body. The enum
`Shpfy GraphQL Type` (`Enums/ShpfyGraphQLType.Enum.al`) maps 143 values
to their resource files -- it is a plain enum (`Extensible = false`)
with no `implements` clause.

The dispatcher `Shpfy GraphQL Queries`
(`Codeunits/ShpfyGraphQLQueries.Codeunit.al`) loads the query text at
runtime via `NavApp.GetResourceAsText()`, parses the cost from line 1,
and returns the query body. Parameters use named `{{placeholder}}`
tokens; the dispatcher accepts a `Dictionary of [Text, Text]` and does
literal string replacement -- no escaping, no StrSubstNo. Callers
format values correctly within the query template itself.

Rate limiting is handled by `Shpfy GraphQL Rate Limit`, a SingleInstance
codeunit that tracks Shopify's `restoreRate` and `currentlyAvailable`
from throttle status and sleeps before requests that would exceed budget.

## Things to know

- 143 `.graphql` resource files replace the former query-builder
  codeunits. Only `ShpfyGraphQLQueries` (dispatcher) and
  `ShpfyGraphQLRateLimit` remain as codeunits in this folder.
- The enum is `Extensible = false`. The dispatcher fires no events --
  extensions cannot intercept or replace queries at runtime.
- Enum values follow `{Area}_{QueryName}` naming (e.g.,
  `Customers_GetCustomerIds`). Resource files live at
  `.resources/graphql/{Area}/{QueryName}.graphql`.
- 14 obsolete stub codeunits exist for previously-public GQL codeunits
  (ObsoleteState = Pending). They delegate to the new dispatcher and
  will be removed after the CLEAN29 transition.
- Adding a new query is two steps: create the `.graphql` file and add
  the enum value. No codeunit, no interface, no permission set entry.
- Many operations come in pairs for cursor-based pagination (e.g.,
  `Customers_GetCustomerIds` / `Customers_GetNextCustomerIds`).
- Cost values are hand-tuned integers, not computed. The API version is
  pinned in `ShpfyCommunicationMgt` (currently `2026-01`), not here.
