# GraphQL

The API communication layer for the Shopify Connector. Every interaction with Shopify's Admin API goes through this module as GraphQL queries or mutations -- the connector does not use REST, except for legacy gift card endpoints handled specially in `ShpfyCommunicationMgt.CreateWebRequestURL`.

## How it works

Each GraphQL operation is its own codeunit implementing the `ShpfyIGraphQL` interface (in `ShpfyIGraphQL.Interface.al`). The interface has two methods: `GetGraphQL` returns the query/mutation text with `{{placeholder}}` tokens for parameters, and `GetExpectedCost` returns the estimated Shopify cost-budget units. `ShpfyGraphQLQueries` resolves a `ShpfyGraphQLType` enum value to the correct interface implementation, substitutes parameters into the template, and hands the result to `ShpfyCommunicationMgt.ExecuteGraphQL`.

Rate limiting is managed by `ShpfyGraphQLRateLimit`, a SingleInstance codeunit that tracks Shopify's `currentlyAvailable` token budget and `restoreRate` from the `extensions.cost.throttleStatus` response. Before each request it calculates whether to sleep based on the expected cost. If a request still comes back `THROTTLED`, `CommunicationMgt` retries in a loop, updating the rate-limit state each time. The communication layer also enforces a 50,000-character query length cap and retries on HTTP 429/5xx responses with backoff.

`ShpfyCommunicationMgt` is SingleInstance and holds the current shop context. It builds URLs with the pinned API version (currently `2026-01` via `VersionTok`), attaches the access token from `ShpfyRegisteredStoreNew`, and checks the API version expiry date from an Azure Key Vault secret cached in IsolatedStorage for 10 days.

## Things to know

- There are roughly 145 codeunits here because each query/mutation gets its own file. This is deliberate -- it keeps cost tracking per-operation, makes test mocking straightforward via `OnBeforeSetInterfaceCodeunit`, and gives clear ownership.
- Paginated queries follow a naming pattern: `ShpfyGQLCustomerIds` for the first page, `ShpfyGQLNextCustomerIds` for subsequent pages, passing a cursor via the `After` parameter.
- `ShpfyGraphQLQueries` fires several integration events (`OnBeforeGetGrapQLInfo`, `OnAfterReplaceParameters`, etc.) that let extensions override or modify any query before execution.
- The API version is hard-coded as a label constant, not configurable. Expiry is checked against an AKV secret; when it lapses the connector errors out with `ApiVersionOutOfSupportErr` rather than silently using an unsupported version.
- `IsTestInProgress` on `CommunicationMgt` reroutes all HTTP calls through `ShpfyCommunicationEvents`, allowing tests to inject canned responses without network access.
- Gift card URLs skip the `/api/VERSION/` path segment entirely -- see the `StartsWith('gift_cards')` branch in `CreateWebRequestURL`.
