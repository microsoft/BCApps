# GraphQL

This folder is the typed query catalog for all Shopify Admin API calls. Every GraphQL query or mutation the connector can issue is encapsulated in its own codeunit implementing the `Shpfy IGraphQL` interface. The folder exists so that API surface changes (field renames, pagination tweaks, new endpoints) are isolated to small, single-purpose files rather than scattered across business logic.

## How it works

The `Shpfy IGraphQL` interface defines two methods: `GetGraphQL()` returns the raw JSON-encoded GraphQL query string with `{{Param}}` placeholders, and `GetExpectedCost()` returns an integer estimate of the query's point cost for rate limiting. Each implementing codeunit is registered in the `Shpfy GraphQL Type` enum (`ShpfyGraphQLType.Enum.al`), which maps enum values to implementations via AL's `implements` keyword.

Callers never instantiate these codeunits directly. The flow is: caller passes a `Shpfy GraphQL Type` enum value plus a `Dictionary of [Text, Text]` of parameters to `CommunicationMgt.ExecuteGraphQL`. That method delegates to `ShpfyGraphQLQueries.GetQuery`, which resolves the enum to its `IGraphQL` implementation, calls `GetGraphQL()` and `GetExpectedCost()`, then does string replacement of `{{key}}` placeholders with the provided parameter values. The assembled query and cost are returned to `CommunicationMgt`, which feeds the cost to `ShpfyGraphQLRateLimit.WaitForRequestAvailable` before posting the HTTP request to Shopify's `graphql.json` endpoint.

Rate limiting is cooperative. `ShpfyGraphQLRateLimit` is a SingleInstance codeunit that tracks the `currentlyAvailable` cost bucket and `restoreRate` from Shopify's `extensions.cost.throttleStatus` response. Before each request, it compares the expected cost to available points and sleeps if necessary. This avoids 429s without requiring retry loops for most queries.

## Things to know

- Each codeunit is deliberately tiny -- typically just `GetGraphQL` returning a string literal and `GetExpectedCost` returning a small integer (commonly 2-12). Do not refactor them into a single file; the one-codeunit-per-query pattern is intentional for discoverability and diff isolation.
- Naming convention: codeunit names use the `ShpfyGQL` prefix (e.g. `ShpfyGQLFindVariantBySKU`). Pagination queries use a `Next` prefix variant (e.g. `ShpfyGQLNextCustomerIds`).
- The `ShpfyGraphQLQueries` codeunit is SingleInstance and fires several internal events (`OnBeforeSetInterfaceCodeunit`, `OnBeforeGetGrapQLInfo`, `OnBeforeReplaceParameters`, etc.) that allow other modules or tests to intercept or replace queries at runtime.
- Parameter substitution is plain string replacement of `{{ParamName}}`. There is no escaping at this layer -- callers are responsible for passing already-escaped values (the `CommunicationMgt.EscapeGraphQLData` helper exists for this).
- The enum is `Extensible = true`, so partner extensions can add new query types without modifying the base connector.
- The `GraphQL Type` enum currently has ~145 values spanning products, orders, customers, companies, inventory, fulfillment, returns, refunds, catalogs, webhooks, payments, disputes, translations, metafields, and bulk operations. If you are adding a new Shopify API call, add a new enum value, a new codeunit implementing `IGraphQL`, and call it via `CommunicationMgt.ExecuteGraphQL`.
- Bulk operations use a separate path (`ShpfyBulkOperationAPI`) but still go through the same `ExecuteGraphQL` mechanism for the initial mutation and polling queries.
