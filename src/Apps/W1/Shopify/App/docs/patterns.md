# Patterns

This document covers the recurring code patterns in the Shopify Connector, with concrete examples from the codebase. The last section covers legacy patterns that are being phased out.

## Hash-based change detection

The connector uses a custom hash algorithm (`ShpfyHash` codeunit in `src/Helpers/`) to detect changes in product data before making API calls. The Product table stores three hash fields: `"Image Hash"`, `"Tags Hash"`, and `"Description Html Hash"`. The Variant table stores its own `"Image Hash"`.

The pattern works like this: when a product is imported or last exported, the hash is computed and stored. On the next export, the connector recomputes the hash from the current BC data and compares it to the stored value. Only if the hashes differ does it make the API call.

In `ShpfyProduct.Table.al`, the `SetDescriptionHtml()` method shows this clearly -- after writing the HTML to the blob field, it immediately computes and stores the hash:

```
"Description Html Hash" := Hash.CalcHash(NewDescriptionHtml);
```

The `CalcTagsHash()` method on the same table computes the hash from the comma-separated tag string. This means adding, removing, or reordering tags will change the hash and trigger an update.

This pattern is essential for performance. A store with thousands of products would exhaust Shopify's GraphQL rate limit within minutes if every product triggered an API call on every sync. The hash comparison keeps the actual API calls proportional to the number of changes.

## GraphQL query builder pattern

*Updated: 2026-03-24 -- GraphQL resource file refactoring*

Queries are stored as `.graphql` resource files under `.resources/graphql/{Area}/{QueryName}.graphql`. Each file has two parts:

- Line 1: `# cost: N` -- the estimated query cost for rate limiting (replaces the old `GetExpectedCost()` method)
- Line 2+: the JSON query body with parameter placeholders

The `ShpfyGraphQLQueries.Codeunit.al` dispatcher receives a `"Shpfy GraphQL Type"` enum value and a `Dictionary of [Text, Text]` of parameters, loads the query via `NavApp.GetResourceAsText()`, substitutes parameters into the query string, and returns the final query along with the expected cost.

The `"Shpfy GraphQL Type"` enum is `Extensible = false` and uses `{Area}_{QueryName}` naming for its values (e.g., `Products_GetProductById`, `Customers_NextCustomerIds`). There are 143 resource files covering all query types.

Adding a new query requires two steps:

1. Create a `.graphql` file in the appropriate `.resources/graphql/{Area}/` folder
2. Add a corresponding enum value to `"Shpfy GraphQL Type"`

The `ShpfyCommunicationMgt.Codeunit.al` is the single entry point for all API calls. Its `ExecuteGraphQL()` overloads accept either a `"Shpfy GraphQL Type"` (type-safe) or a raw query string (for ad-hoc queries). Before executing, it calls `WaitForRequestAvailable()` on the rate limiter with the expected cost. This layer and the rate limiter are unchanged.

The old `IGraphQL` interface pattern (where each query was a codeunit implementing `GetGraphQL()` and `GetExpectedCost()`) was removed in this refactoring. 14 obsolete stub codeunits remain with `ObsoleteState = Pending; ObsoleteTag = '29.0'` for backward compatibility and will be cleaned up in the CLEAN29 cycle.

## SystemId-based linking

The connector consistently uses GUIDs (SystemId) rather than Code/No. to link Shopify records to BC master data. This is unusual in the BC ecosystem where most integrations use the business key.

The pattern appears on Product (`"Item SystemId"`), Variant (`"Item SystemId"` + `"Item Variant SystemId"`), Customer (`"Customer SystemId"`), and Company (`"Customer SystemId"`). In each case, a FlowField provides the human-readable value via CalcFormula:

```
field(103; "Item No."; Code[20])
{
    CalcFormula = lookup(Item."No." where(SystemId = field("Item SystemId")));
    FieldClass = FlowField;
}
```

This design has a concrete advantage: if a merchant renumbers items (changes item numbers), the Shopify links survive because the SystemId is immutable. The tradeoff is that you cannot look up the Shopify product for an item using the item number directly -- you must use the SystemId.

The FlowField pattern means `"Item No."` is not stored in the database -- it is computed on demand. Code that needs the item number must call `CalcFields("Item No.")` first, which is a common gotcha.

## Rate limiting

The `ShpfyGraphQLRateLimit.Codeunit.al` is a SingleInstance codeunit that tracks Shopify's cost-based rate limit. It is critical infrastructure because Shopify throttles based on query cost, not request count.

After each API call, `SetQueryCost()` reads the `restoreRate` and `currentlyAvailable` values from the response's throttle status. Before each call, `WaitForRequestAvailable(ExpectedCost)` checks whether enough budget is available. If not, it computes the sleep duration:

```
WaitTime := (Max(ExpectedCost - LastAvailable, 0) / RestoreRate * 1000) - (CurrentDateTime - LastRequestedOn)
```

This formula accounts for the time elapsed since the last request (during which budget has been restoring at `RestoreRate` points per second). If `RestoreRate` is zero (no data yet), it defaults to 50 -- Shopify's standard restore rate.

The `GoToSleep()` method uses AL's `Sleep()` function with a TryFunction wrapper. If the calculated sleep time causes an error (e.g., negative duration), it falls back to a 100ms sleep.

The API version is hardcoded as `'2026-01'` in `ShpfyCommunicationMgt.Codeunit.al`. The connector validates the API version expiry date and shows warnings/errors when it is approaching or has passed expiry, pulling the date from Azure Key Vault.

## Webhook multi-company fan-out

Shopify webhooks are registered per-shop, but a single Shopify shop can be connected to multiple BC companies. The `ShpfyWebhookNotification.Codeunit.al` handles this fan-out.

When a webhook fires, the notification arrives with a subscription ID that encodes the shop domain. The codeunit reconstructs the Shopify URL from this ID, then queries the Shop table filtered by `Enabled = true` and matching URL. Because multiple BC companies might have an enabled Shop record pointing to the same Shopify store, the `FindSet()` loop processes the notification once per matching shop:

```
if Shop.FindSet() then
    repeat
        case WebhookNotification."Resource Type Name" of
            Format("Shpfy Webhook Topic"::ORDERS_CREATE):
                ...
            Format("Shpfy Webhook Topic"::BULK_OPERATIONS_FINISH):
                ...
        end;
    until Shop.Next() = 0;
```

Each iteration processes the notification in the context of that shop's BC company, with a `Commit()` after each to isolate failures.

## Bulk operations framework

For operations that would require many individual API calls (like updating prices across thousands of variants), the connector uses Shopify's bulk mutation API. The framework lives in `src/Bulk Operations/`.

The flow is:

1. `ShpfyBulkOperationMgt.Codeunit.al` collects the input data as JSONL lines
2. It calls `bulkOperationRunMutation` via GraphQL, passing the mutation template and JSONL input
3. Shopify processes the mutation asynchronously and fires a `BULK_OPERATIONS_FINISH` webhook when done
4. The webhook handler calls back into the `IBulkOperation` implementation to process results or revert failures

The `IBulkOperation` interface requires `RevertFailedRequests()` and `RevertAllRequests()` methods because the bulk operation is async -- by the time results arrive, the original transaction is long committed. If the bulk operation fails entirely, all changes must be reverted. If it partially succeeds, only the failed entries are reverted.

The `ShpfyBulkOperation.Table.al` tracks the state of each bulk operation: type, status (Created, Running, Completed, Failed), shop code, and the request/response data.

## Shop-scoped multi-tenancy

Every data table in the connector includes a `"Shop Code"` field, and every operation filters by it. This is the multi-tenancy boundary -- a single BC company can connect to multiple Shopify shops (e.g., different storefronts or brands) and the data never mixes.

The pattern is consistent: codeunits that operate on shop data accept a Shop record or Shop Code and use it to filter all queries. The `SetShop()` pattern appears across API codeunits -- it sets the shop context once, and all subsequent operations use it.

This design means you cannot query "all products across all shops" without explicitly iterating shops. It also means that the same BC item can be linked to different Shopify products in different shops.

## Timestamp-based incremental sync

The Synchronization Info table (`ShpfySynchronizationInfo.Table.al`) stores one timestamp per shop-code + sync-type pair. The empty-date sentinel is `2004-01-01T00:00:00` (not `0DT`), chosen to be old enough to import all data but avoid zero-date edge cases.

The pattern in the Shop table:

```
GetLastSyncTime(Type) -- reads the stored timestamp, returns sentinel if none
SetLastSyncTime(Type) -- stores CurrentDateTime after successful sync
```

For order sync specifically, the key uses the Shop's integer hash (`"Shop Id"`) instead of the Shop Code. This is because multiple BC companies connected to the same Shopify store should share the order sync cursor -- without this, each company would re-import all orders.

Sync timestamps are passed to Shopify's `updated_at` filter in API queries. This means the sync is truly incremental -- only records changed since the last sync are fetched. The risk is that if a sync fails partway through, the timestamp may not be updated, causing the next sync to re-process some records. The connector handles this gracefully because most operations are idempotent (updating a local record with the same data is a no-op).

## Interface-driven strategy selection

The connector's most distinctive pattern is using AL enum + interface to implement the strategy pattern. The flow is:

1. An enum type is defined with an interface implementation attribute
2. Each enum value maps to a codeunit implementing the interface
3. The Shop table has a field of that enum type
4. At runtime, the code reads the enum value and dispatches through the interface

Example with customer mapping:

```
// Enum declaration links values to implementations
enum 30105 "Shpfy Customer Mapping" implements "Shpfy ICustomer Mapping"
{
    value(0; "By Email/Phone") { Implementation = "Shpfy ICustomer Mapping" = "Shpfy Cust. By Email/Phone"; }
    value(1; "By Bill-to Info") { Implementation = "Shpfy ICustomer Mapping" = "Shpfy Cust. By Bill-to"; }
    value(2; "By Default Customer") { Implementation = "Shpfy ICustomer Mapping" = "Shpfy Cust. By Default Cust."; }
}

// Usage at runtime
ICustomerMapping := Shop."Customer Mapping Type";  // enum-to-interface dispatch
CustomerNo := ICustomerMapping.DoMapping(...);
```

This pattern repeats for stock calculation, product status, removal actions, customer name formatting, county resolution, company mapping, return/refund processing, metafield types, metafield owners, bulk operations, and document link handlers. Once you understand one instance, you understand them all.

## Legacy patterns

### Config Template Header (removed in v25)

Before v25, the connector used BC's Config. Template Header system for item and customer creation templates. Fields like `"Item Template Code"` and `"Customer Template Code"` had `TableRelation` to Config. Template Header and are now removed with `ObsoleteState = Removed; ObsoleteTag = '25.0'`. The replacement is the `"Item Templ. Code"` and `"Customer Templ. Code"` fields that reference the newer Item Templ. and Customer Templ. tables.

If you see `#if not CLEANSCHEMA25` guards in the source, these protect the removed fields until the schema cleanup version. Code should never reference these fields.

### Obsolete REST API fields

Several fields on Order Header that existed for the REST API era have been removed: Token, Cart Token, Checkout Token, Reference, Session Hash, Contact Email, and Buyer Accepts Marketing. These carried `ObsoleteReason = 'Not available in GraphQL data.'` and were removed in v25. The connector is fully committed to GraphQL.

### Obsolete Tax Code on Variant

The `"Tax Code"` field on Shpfy Variant was deprecated in v28 because Shopify's API version 2025-10 removed `taxCode` from ProductVariant. This field is pending removal with `ObsoleteTag = '28.0'`.
