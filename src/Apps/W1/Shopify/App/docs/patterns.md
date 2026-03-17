# Patterns

## Interface-based strategy

The connector's most pervasive pattern. Behavior that varies by configuration is modeled as an enum that implements an interface. The Shop table has a field whose type is that enum. At runtime, the selected enum value is cast to the interface and its method is called.

For example, customer mapping works like this: the `Shpfy Customer Mapping` enum has values like "By Email/Phone", "By Bill-to Info", "By Default Customer". Each value is backed by a codeunit implementing `Shpfy ICustomer Mapping`. The Shop's `Customer Mapping Type` field stores the selected value. When the connector needs to find a BC customer for a Shopify customer, it reads the enum from the Shop, casts it to the interface, and calls the mapping method.

This pattern appears in at least 15 places across the connector -- customer mapping, customer name formatting, company mapping, county handling, stock calculation, product status, remove product action, return/refund processing, document source, bulk operations, metafield types, metafield owner types, and translation creation.

To extend: add a new enum extension value, create a codeunit implementing the interface, and the new option appears automatically in the Shop configuration.

## GraphQL abstraction

All Shopify API calls go through `ShpfyCommunicationMgt` (30103), which is a `SingleInstance` codeunit holding the current shop context. The connector uses Shopify's GraphQL Admin API exclusively -- there are no REST calls.

Each distinct query or mutation is wrapped in its own codeunit under `src/GraphQL/Codeunits/`. These codeunits implement `Shpfy IGraphQL`, which has two methods: `GetGraphQL()` returns the query text (with parameter placeholders) and `GetExpectedCost()` returns the estimated query cost for rate limiting. There are 100+ of these codeunits, named with the `ShpfyGQL` prefix (e.g., `ShpfyGQLCustomer`, `ShpfyGQLFulfillOrder`, `ShpfyGQLModifyInventory`).

The `ShpfyGraphQLQueries` codeunit acts as a dispatcher -- it receives a `Shpfy GraphQL Type` enum value and a parameters dictionary, looks up the corresponding `IGraphQL` implementation, substitutes parameters into the query text, and returns the ready-to-send query string with its expected cost.

`ExecuteGraphQL` on `ShpfyCommunicationMgt` then sends the query, handles rate limiting, checks for errors (including the `THROTTLED` error code, which triggers an automatic retry loop), logs the request, and returns the parsed JSON response.

## Rate limiting

Shopify's GraphQL API uses a token bucket rate limiter. Each query has a cost (reported by Shopify in the response's `extensions.cost` object), and the bucket refills at a steady rate.

The `ShpfyGraphQLRateLimit` codeunit (30153) is a `SingleInstance` that tracks the bucket state across requests. After each response, `SetQueryCost` reads `currentlyAvailable` and `restoreRate` from the throttle status. Before each request, `WaitForRequestAvailable` calculates whether the expected cost would exceed the available tokens. If so, it sleeps for the calculated wait time: `max(expectedCost - available, 0) / restoreRate * 1000 - timeSinceLastRequest`.

This preemptive wait avoids most `THROTTLED` errors. But when throttling does occur (the response contains `"errors"` with `THROTTLED`), `ExecuteGraphQL` retries in a loop, waiting for tokens to restore between attempts.

For HTTP-level rate limiting (429 status codes), the retry logic lives in `EvaluateResponse` -- it sleeps 2 seconds and retries. For 5xx server errors, it sleeps 10 seconds and retries, up to the configured max retries (default 5 for general requests, 3 for GraphQL).

## Hash-based change detection

The connector avoids unnecessary API calls by hashing content and comparing before syncing. This pattern appears in several places:

- **Product images**: Each `Shpfy Product Image` stores a hash of the image content. During sync, the connector recalculates the hash from the BC item's picture and compares it to the stored hash. If they match, the image upload is skipped.
- **Product descriptions**: The HTML body of a product is hashed (`Description Html Hash`) to detect changes without comparing potentially large HTML blobs.
- **Tags**: A `Tags Hash` field allows quick detection of tag changes.
- **Variant data**: The `Shpfy Variant` stores a redundancy code (effectively a hash of key fields) to detect when variant data has changed.

The hash calculation lives in the `Shpfy Hash` codeunit in the `Helpers/` folder. It is also used for non-sync purposes -- the `Shop Id` field on the Shop table is calculated as a hash of the Shopify URL.

## Bulk operations

For operations that would require hundreds or thousands of individual mutations (price updates, image uploads), the connector uses Shopify's Bulk Operations API. This is an asynchronous pattern:

1. The connector implements `Shpfy IBulk Operation` on a codeunit. `GetGraphQL()` returns the bulk mutation query, `GetInput()` builds a JSONL payload with all the individual operations, `GetName()` and `GetType()` provide metadata.
2. The connector submits the bulk operation via the `bulkOperationRunMutation` GraphQL mutation.
3. Shopify processes the operations asynchronously. A webhook (`BULK_OPERATIONS_FINISH`) notifies BC when it completes.
4. On failure, `RevertFailedRequests` or `RevertAllRequests` rolls back the connector's local state to match reality.

Current implementations include `ShpfyBulkUpdateProductImage` for image syncs and the catalog price sync in `ShpfySyncCatalogPrices`. Bulk operations are tracked in the `Shpfy Bulk Operation` table with statuses: Created, Running, Completed, Failed, Canceled.

## Per-entity error handling

The connector never fails an entire batch because one entity has an error. Instead, errors are captured at the individual entity level:

- `Shpfy Orders to Import` has `Has Error`, `Error Message` (blob), and `Error Call Stack` (blob) fields. When processing an order fails, `SetErrorInfo()` captures `GetLastErrorText` and `GetLastErrorCallStack` into the blobs.
- Product sync similarly tracks errors per product.
- The `ShpfyBackgroundSyncs` codeunit configures Job Queue entries with `No. of Attempts to Run := 5`, providing automatic retry for transient failures.

This pattern means users can review failed entities individually, fix the underlying issue (missing customer template, unmapped payment method, etc.), and re-process just the failed records.

## Background sync orchestration

`ShpfyBackgroundSyncs` (30101) is the central coordinator for all sync operations. For each sync type, it:

1. Splits shops into two groups: those with `Allow Background Syncs = true` and those without
2. For background-enabled shops, creates a Job Queue Entry with the sync report's XML parameters and enqueues it
3. For foreground shops, runs the report inline via `Report.Execute`

Each sync is implemented as a Report object (not a codeunit) because BC's Job Queue natively supports running reports with saved parameters. The XML parameter strings are built using `StrSubstNo` with locked label templates -- a pattern that is fragile but effective.

The codeunit also handles user notifications: when a background sync is enqueued, it shows a notification with a "Show log" action that opens the Job Queue Log Entries filtered to that specific job.

## Test isolation via communication events

The test app (`Shopify Connector Test`, declared in `internalsVisibleTo`) hooks into `ShpfyCommunicationEvents` to mock all Shopify API calls. When `ShpfyCommunicationMgt.SetTestInProgress(true)` is called:

- `OnClientSend` replaces the real HTTP call, letting tests provide canned responses
- `OnGetAccessToken` provides a fake token
- `OnGetContent` controls response parsing
- `OnClientPost` / `OnClientGet` intercept specific HTTP methods

This means tests never call the real Shopify API. The `IsTestInProgress` flag is checked throughout `ShpfyCommunicationMgt` to route calls through events instead of HTTP.

## Legacy patterns

**Obsolete fields with CLEANSCHEMA guards**: The connector uses BC's `#if not CLEANSCHEMA<version>` preprocessor directives to phase out old fields. For example, `Log Enabled` (field 5 on the Shop table) was replaced by `Logging Mode` and removed in version 26. The field definition is only compiled when `CLEANSCHEMA26` is not defined, allowing old databases to still function until they upgrade. When working with the Shop table, be aware that some fields exist only for schema compatibility and are not functional.

**XML parameters for sync reports**: The `ShpfyBackgroundSyncs` codeunit builds report parameters as XML strings using `StrSubstNo` with hardcoded XML templates. This is a holdover from how BC's Job Queue works -- it expects XML-formatted report parameters. The pattern is brittle (parameter order matters, escaping is manual) but is used consistently across all sync types.

**Option fields instead of enums**: Some older fields on the Shop table (like `Sync Item` and `Sync Item Images`) use the AL `Option` type rather than proper enums. This means they cannot be extended by other apps. Newer fields use enum types with interfaces.
