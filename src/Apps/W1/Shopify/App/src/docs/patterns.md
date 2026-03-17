# Patterns

## GraphQL query abstraction

Every Shopify API query is encapsulated in its own codeunit implementing `Shpfy IGraphQL`. This interface has two methods: `GetGraphQL()` returns the raw query string (with `{{placeholder}}` tokens for dynamic values), and `GetExpectedCost()` returns the estimated cost in Shopify's query cost units. There are roughly 145 such codeunits in the GraphQL module.

The dispatcher (`Shpfy GraphQL Queries`) resolves an enum value to the correct interface implementation and substitutes placeholders before execution. The rate limiter (`Shpfy GraphQL Rate Limit`, also SingleInstance) reads `currentlyAvailable` and `restoreRate` from each response's throttle status and calculates sleep time before the next request based on the upcoming query's declared cost.

This one-codeunit-per-query pattern looks unusual but provides precise cost tracking and makes each query independently testable. When adding queries, get the expected cost right -- the rate limiter formula is `waitTime = max(expectedCost - available, 0) / restoreRate * 1000 - elapsed`, with a default restore rate of 50 points/second.

## SystemId linking

All entity links between Shopify and BC use `SystemId` (Guid) rather than Code or No. For example, `Shpfy Product."Item SystemId"` is a Guid field, and `Shpfy Product."Item No."` is a FlowField with `CalcFormula = lookup(Item."No." where(SystemId = field("Item SystemId")))`. The same pattern appears on Variant (Item SystemId + Item Variant SystemId), Customer (Customer SystemId), Company (Customer SystemId), and Catalog (Company SystemId).

This design survives BC entity renumbering and avoids the brittle Code-based linking that older BC integrations used. The tradeoff is that you cannot filter or join on the linked entity's Code directly in queries -- you must either CalcFields the FlowField or do a separate lookup.

## Hash-based change detection

The Product table stores `Image Hash`, `Tags Hash`, and `Description Html Hash` as Integer fields. During export, the connector computes a hash of the current value and compares it to the stored hash. If they match, the export skips the API call for that field/entity.

The hash is computed by `Shpfy Hash` (a utility codeunit) and is a non-cryptographic integer hash. It is purely an optimization -- the connector does not use it for conflict resolution or versioning. If the hash logic produces a collision, the worst case is a skipped update, which will be caught on the next sync when the stored hash is overwritten.

## Dual currency architecture

Orders, refunds, and returns carry every monetary field in two currencies: shop currency (`Currency Code`) and presentment currency (`Presentment Currency Code`). The shop currency is the store's base currency; the presentment currency is what the buyer saw at checkout (which may differ if the store supports multi-currency).

The `Currency Handling` enum on the Shop table (`Shop Currency` vs. `Presentment Currency`) determines which set of amounts is used when creating BC sales documents. This selection happens in `Shpfy Process Order.CreateHeaderFromShopifyOrder` and flows through to all line amount assignments.

This dual-currency pattern means any code that reads order amounts must be aware of which currency it is working with. The naming convention is consistent: presentment fields are prefixed with "Presentment" or "Pres." (e.g. `Presentment Total Amount`, `Pres. Shipping Charges Amount`).

## Negative auto-incrementing IDs

Several staging and pre-sync tables use negative BigInteger IDs as temporary identifiers. The most visible example is `Shpfy Orders to Import`, where records receive a negative ID during the initial webhook notification or manual import trigger. The real Shopify ID replaces this negative value after the full order data is fetched.

This pattern avoids conflicts with real Shopify IDs (which are always positive) and makes it easy to identify records that are still in the staging phase (negative = not yet synced).

## Extensible enums with interface implementation

The app uses AL's extensible enum + interface pattern extensively for strategy selection. Key examples:

- `Shpfy Customer Mapping` enum -> `ICustomerMapping` interface
- `Shpfy Company Mapping` enum -> `ICompanyMapping` interface
- `Shpfy Stock Calculation` (on Shop Location) -> `Shpfy Stock Calculation` interface
- `Shpfy ReturnRefund ProcessType` enum -> `IReturnRefundProcess` interface
- `Shpfy Remove Product Action` enum -> `IRemoveProductAction` interface
- `Shpfy GraphQL Type` enum -> `IGraphQL` interface
- `Shpfy Cr. Prod. Status Value` enum -> `ICreateProductStatusValue` interface

The pattern is always the same: the Shop or related configuration table stores the enum value, and the business logic resolves it to an interface implementation at runtime. This is how third-party extensions plug in custom behavior without modifying the base app.

## Data capture for debugging

The `Shpfy Log Entry` table records API interactions when `Logging Mode` is set to "All" on the Shop. Each entry captures the URL, request body, response body, status code, and duration. The logging infrastructure also integrates with BC's retention policy framework -- when logging is enabled, a retention policy setup is automatically activated to prevent unbounded growth.

The `Data Capture` blob fields on various tables (e.g. Order Header, Order Line) store the raw JSON from the Shopify API response that was used to populate the record. This is invaluable for debugging mapping issues: you can compare the captured JSON against the table fields to see exactly what was parsed.

## Webhook-driven job queue (multi-company)

Webhooks in the Shopify Connector use BC's built-in `Webhook Notification` infrastructure. The `Shpfy Webhook Notification` codeunit (30363) is registered as the handler. When a notification arrives, it extracts the shop domain from the subscription ID, then queries `Shpfy Shop` across the current company for a matching enabled shop.

The multi-company aspect is handled by BC's webhook infrastructure itself, which dispatches to each company that registered the subscription. Within a company, if multiple Shop records match (unusual but possible with different shop codes pointing to the same URL), the handler iterates all of them.

Webhook subscriptions are managed by `Shpfy Webhooks Mgt.`, which creates/deletes subscriptions via GraphQL mutations and stores the webhook ID and user ID on the Shop record. The user whose credentials created the subscription is the user under whose context the background task runs.

## Bulk operations pattern

For high-volume mutations (product image updates, price updates), the connector uses Shopify's bulk operations API. The `IBulk Operation` interface defines the contract: `GetGraphQL()` for the mutation template, `GetInput()` for the JSONL payload, and `RevertFailedRequests()` / `RevertAllRequests()` for handling failures.

The flow is: submit mutation via `bulkOperationRunMutation` -> receive a bulk operation ID -> poll for completion (or receive a `BULK_OPERATIONS_FINISH` webhook) -> download results -> process successes and revert failures.

The `Shpfy Bulk Operation` table tracks the lifecycle. Current implementations include `Shpfy Bulk Update Product Image` and `Shpfy Bulk Update Product Price`.

## SingleInstance communication codeunit

`Shpfy Communication Mgt.` (30103) is marked `SingleInstance = true`, meaning one instance persists for the lifetime of the session. It holds the current Shop record, the API version string, and coordinates with the also-SingleInstance `Shpfy GraphQL Rate Limit` codeunit.

This design ensures that rate-limiting state (available points, restore rate, last request time) survives across multiple API calls within the same session. The tradeoff is that you must call `SetShop()` before any API call to ensure the codeunit is operating against the correct shop -- forgetting this will send requests to whichever shop was last configured.

---

## Legacy patterns to avoid

These patterns exist in the codebase but should not be replicated in new code.

**Large monolithic codeunits** -- Some older codeunits (e.g. `Shpfy Order Mgt.`) have grown to 50+ procedures covering multiple responsibilities. New code should split logic into focused codeunits with clear single responsibilities.

**Pragma warning disable for obsolete events** -- Several event publishers use `#pragma warning disable AS0025` to suppress signature-change warnings on integration events. This was needed for backward compatibility during event evolution, but new events should be designed with stable signatures from the start.

**Direct field assignment without Validate()** -- The order processing code copies many address fields from the Shopify order header to the BC sales header using direct assignment (`:=`) rather than `Validate()`. This is intentional for address fields (to avoid triggering address validation cascades) but can be confusing. New field mappings should use `Validate()` unless there is a specific reason not to, and that reason should be commented.

**InternalEvent where IntegrationEvent should be used** -- Some events are marked `[InternalEvent(false)]` when they should be `[IntegrationEvent(false, false)]`. Internal events are only visible within the app, which prevents third-party extensions from subscribing. Use `IntegrationEvent` for any event that an extension might need.

**Overly complex event parameter lists** -- Some events pass 5-8+ parameters (the order header, order line, sales header, sales line, plus a handled flag). This makes subscribers brittle. New events should prefer passing record parameters and letting subscribers read what they need, rather than passing individual field values.
