# GraphQL

Contains all Shopify GraphQL query and mutation definitions used by the connector. This is the largest module (~145 codeunits) but is intentionally mechanical -- it defines *what* to ask Shopify, not *how* to communicate. The HTTP layer lives in `Base/ShpfyCommunicationMgt`.

## How it works

Every query or mutation is a codeunit implementing the `IGraphQL` interface (`ShpfyIGraphQL.Interface.al`), which requires two methods: `GetGraphQL()` returns the raw JSON-wrapped GraphQL string, and `GetExpectedCost()` returns the estimated query cost for rate limiting. The `ShpfyGraphQLType` enum maps each variant to its implementing codeunit, so callers pass an enum value and a parameters dictionary to `ShpfyCommunicationMgt.ExecuteGraphQL`, which delegates to `ShpfyGraphQLQueries` to resolve the query text. Parameters are injected by simple `{{ParamName}}` placeholder replacement.

Pagination follows a "base + Next" convention: `ShpfyGQLCustomerIds` fetches the first page, `ShpfyGQLNextCustomerIds` adds an `after:"{{After}}"` cursor argument for subsequent pages. The calling code (e.g., `ShpfyCustomerAPI.RetrieveShopifyCustomerIds`) loops, switching from the base enum value to the Next variant after the first response, checking `pageInfo.hasNextPage` to terminate.

Rate limiting is handled by `ShpfyGraphQLRateLimit`, a `SingleInstance` codeunit that tracks Shopify's `currentlyAvailable` and `restoreRate` from the throttle status in each response. Before every request, `WaitForRequestAvailable` calculates the required sleep time based on the expected cost vs. available budget, then calls `Sleep()` if needed.

## Things to know

- The naming convention is `ShpfyGQL[Entity][Action]` -- e.g., `ShpfyGQLFulfillOrder`, `ShpfyGQLCustomerIds`, `ShpfyGQLMetafieldsSet`. "Next" prefixed variants handle cursor pagination.
- `ShpfyGraphQLQueries` fires several `InternalEvent` hooks (`OnBeforeSetInterfaceCodeunit`, `OnBeforeGetGrapQLInfo`, `OnBeforeReplaceParameters`, etc.) that allow internal extensions to override queries or parameters without modifying the GQL codeunits.
- Each codeunit's `GetExpectedCost` is a hardcoded estimate, not computed from the query. If Shopify changes its cost model, these values become stale, but the rate limiter self-corrects from the response's `currentlyAvailable`.
- The API version is a `Label` constant in `ShpfyCommunicationMgt` (`VersionTok: Label '2026-01'`), not in this module. All queries are version-agnostic text.
- The `MetafieldSet` mutation accepts batches of up to 25 metafields per call -- the batching logic lives in `Metafields/ShpfyMetafieldAPI`, not here.
- `ShpfyGQLBulkOperation` and `ShpfyGQLBulkOpMutation` support Shopify's async bulk operations for large data sets.
