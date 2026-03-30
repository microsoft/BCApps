# GraphQL

Type-safe query infrastructure for the Shopify Admin API. Every API call
the connector makes passes through this layer.

## How it works

`Shpfy IGraphQL` (`Interfaces/ShpfyIGraphQL.Interface.al`) defines two
methods: `GetGraphQL()` returns a JSON-encoded GraphQL request body, and
`GetExpectedCost()` returns cost points for rate limiting. Each API
operation is a separate codeunit implementing this interface. The enum
`Shpfy GraphQL Type` (`Enums/ShpfyGraphQLType.Enum.al`) maps ~143 values
to their implementing codeunits via AL's `implements` keyword.

Parameters use named `{{placeholder}}` tokens. The dispatcher
`Shpfy GraphQL Queries` (`Codeunits/ShpfyGraphQLQueries.Codeunit.al`)
accepts a `Dictionary of [Text, Text]` and does literal string
replacement -- no escaping, no StrSubstNo. Callers format values
correctly within the query template itself.

Rate limiting is handled by `Shpfy GraphQL Rate Limit`, a SingleInstance
codeunit that tracks Shopify's `restoreRate` and `currentlyAvailable`
from throttle status and sleeps before requests that would exceed budget.

## Things to know

- 143 query-builder codeunits, each unique -- not copy-paste templates.
  Plus `ShpfyGraphQLQueries` (dispatcher) and `ShpfyGraphQLRateLimit`.
- The enum is `Extensible = true`. The dispatcher fires events like
  `OnBeforeSetInterfaceCodeunit` so extensions can swap implementations.
- Many operations come in pairs for cursor-based pagination (e.g.,
  `GetCustomerIds` / `GetNextCustomerIds`).
- Naming convention: `ShpfyGQL[Operation].Codeunit.al`.
- Cost values are hand-tuned integers, not computed. The API version is
  pinned in `ShpfyCommunicationMgt` (currently `2026-01`), not here.
