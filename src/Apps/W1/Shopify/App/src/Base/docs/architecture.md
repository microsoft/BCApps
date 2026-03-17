# Base module architecture

## ShpfyShop table -- central configuration entity

`Shpfy Shop` (table 30102) is the single source of truth for a Shopify store connection. Each record represents one Shopify store and holds:

- **Connection settings** -- Shopify URL, Enabled flag, API access tokens (via `Shpfy Registered Store New`), Shop Id (hash-based)
- **Product sync config** -- Sync Item direction (To/From Shopify), image sync, extended text, attributes, marketing text, SKU mapping, variant prefix, UoM-as-variant
- **Customer sync config** -- Import range, mapping type, template code, name/contact source enums, customer creation flags
- **Order sync config** -- Auto-create orders, auto-release, shipping/tip/gift card G/L accounts, Shopify order number on doc lines
- **B2B / Company config** -- B2B Enabled, company import range, catalog auto-creation, contact permissions
- **Financial config** -- Currency code, posting groups (Gen. Bus., VAT Bus., Customer), tax area, prices including VAT
- **Return/refund config** -- Return location, location priority enum, refund accounts, return process type
- **Operational settings** -- Allow Background Syncs, Allow Outgoing Requests, Logging Mode, webhook IDs and user assignments

The table has keys on Code (PK), Shop Id, Shopify URL, and Enabled. The `OnDelete` trigger cleans up webhook subscriptions.

Key methods on the table:

- `GetLastSyncTime` / `SetLastSyncTime` -- read/write per-type sync timestamps from `Shpfy Synchronization Info`
- `RequestAccessToken` / `HasAccessToken` / `TestConnection` -- OAuth lifecycle
- `GetShopSettings` -- fetches plan info and weight unit from Shopify via GraphQL
- `CheckApiVersionExpiryDate` -- warns or blocks based on API version support window
- `CalcShopId` -- deterministic hash of the Shopify URL, with collision resolution

## ShpfyCommunicationMgt -- SingleInstance API hub

`Shpfy Communication Mgt.` (codeunit 30103) is declared `SingleInstance = true`, meaning one instance lives for the entire session. It:

1. Holds the current `Shop` record (set via `SetShop`)
2. Constructs API URLs from the shop's Shopify URL + version token (`2026-01`)
3. Executes GraphQL queries via `ExecuteGraphQL` overloads that accept either raw query text or a `Shpfy GraphQL Type` enum value
4. Manages HTTP retry logic (up to 5 retries for 429/5xx responses with exponential backoff)
5. Enforces outgoing request checks -- mutations require `Allow Outgoing Requests` on the shop
6. Logs requests to `Shpfy Log Entry` based on the shop's `Logging Mode` setting
7. Validates API version expiry against Azure Key Vault with a 10-day cache in `IsolatedStorage`
8. Enforces a 50,000-character query length limit

The GraphQL execution flow:

```
ExecuteGraphQL(GraphQLType, Parameters)
  -> GraphQLQueries.GetQuery(type, params, expectedCost)  -- resolves IGraphQL interface
  -> ShpfyGraphQLRateLimit.WaitForRequestAvailable(cost)  -- token bucket wait
  -> ExecuteWebRequest(url, "POST", query, headers, 3)    -- HTTP call with retry
  -> Parse JSON, check for THROTTLED, retry if needed
  -> ShpfyGraphQLRateLimit.SetQueryCost(throttleStatus)   -- update rate limiter
```

Test isolation is supported via `SetTestInProgress(true)`, which routes HTTP calls through `ShpfyCommunicationEvents` (internal events) instead of real HTTP clients.

## Background sync orchestration

`Shpfy Background Syncs` (codeunit 30101) dispatches all sync operations. For each sync type (Products, Customers, Companies, Orders, Inventory, Payouts, Disputes, Product Images, Catalog Prices):

1. Accepts a `Shop` record (or shop code)
2. Splits shops into two groups: `Allow Background Syncs = true` and `false`
3. For background-enabled shops, creates a `Job Queue Entry` with:
   - Report ID matching the sync report (e.g., `Report::"Shpfy Sync Products"`)
   - XML parameters encoding the shop filter
   - Job Queue Category `SHPFY`
   - 5 retry attempts
   - Success notification (if GUI available)
4. For foreground shops, runs the report synchronously via `Report.Execute`

The `EnqueueJobEntry` procedure:

- Checks `TaskScheduler.CanCreateTask()` (with an internal event override)
- Creates and enqueues the Job Queue Entry
- Sets XML parameters on the entry
- Sends a dismissible notification with a "Show log" action

A `My Notifications` record (`2c7a0265-...`) controls whether the user sees the background sync notification.

## Connector setup guide flow

`Shpfy Connector Guide` (page 30136) is a `NavigatePage` with 10 steps:

1. **Welcome** -- introduction text, demo company warning
2. **Consent** -- privacy consent with link to Microsoft privacy policy
3. **Shop URL** -- enter/validate the `*.myshopify.com` URL (pre-filled for Shopify signup context)
4. **Import choices** -- select products and/or customers to import (non-demo only)
5. **Manual setup needed** -- shown if BC already has items (skip auto-import)
6. **Item template** -- select `Item Templ.` for auto-creating items from Shopify products
7. **Customer template** -- select `Customer Templ.` for auto-creating customers
8. **Order settings** -- auto-create orders toggle, shipping charges G/L account
9. **Finish (demo)** -- for evaluation companies (imports up to 25 products)
10. **Finish (production)** -- for real companies

On Step 2 -> 3 transition, the wizard calls `CreateShop` (creates/updates the `Shpfy Shop` record), `RequestAccessToken` (OAuth flow), and enables the shop. The finish step calls `ScheduleInitialImport`, which uses `Shpfy Initial Import` to create dependency-ordered job queue entries (items first, then images depend on items, customers independent).

## Event subscriber patterns

12 event subscribers across 4 codeunits handle lifecycle concerns:

**ShpfyInstaller** (5 subscribers):

- `OnRefreshAllowedTables` -- re-registers retention policy tables
- `OnBeforeOnRun` (Company-Initialize) -- registers retention policy tables on company init
- `OnAfterCreatedNewCompanyByCopyCompany` (x2) -- disables all shops in copied company
- `OnClearCompanyConfiguration` -- disables all shops on environment cleanup

**ShpfyGuidedExperience** (5 subscribers):

- `OnAfterLogin` -- initializes checklist for Shopify signup context
- `OnRegisterAssistedSetup` / `OnRegisterGuidedExperienceItem` -- registers the connector guide in assisted setup
- `OnSetSignupContext` -- captures Shopify context from signup flow
- `OnAfterInsertEvent` (Signup Context Values) -- validates shop URL consistency

**ShpfyBackgroundSyncs** (1 subscriber):

- `OnBeforeModifyEvent` (Job Queue Entry) -- monitors job completion to trigger dependent initial import jobs

**ShpfyUpgradeMgt** (1 subscriber):

- Upgrade trigger for data migration

## Sync scheduling and job queue integration

Sync operations follow a consistent pattern:

1. User triggers sync from the Shop Card (or it runs on schedule)
2. `ShpfyBackgroundSyncs` builds XML parameters encoding the shop filter and any options
3. A `Job Queue Entry` is created with category `SHPFY`, the appropriate Report ID, and 5 retry attempts
4. The report (e.g., `Shpfy Sync Products`) runs in the job queue session
5. Inside the report, `ShpfyCommunicationMgt` handles all API calls with rate limiting

For initial import, `Shpfy Initial Import` adds a dependency layer: `ITEM IMAGE` depends on `ITEM` completing first. The `OnBeforeModifyJobQueueEntry` subscriber monitors job status changes and starts dependent jobs when parents finish.

Sync timestamps are stored in `Shpfy Synchronization Info` (keyed by shop code + sync type). For orders, the key uses `Shop Id` (integer) instead of `Code` to handle shop renames. The base timestamp for "never synced" is `2004-01-01T00:00:00`.

## Key enums and their role in configuration

- **ShpfySynchronizationType** -- identifies what is being synced (Products, Orders, Customers, Companies); used as key in `Shpfy Synchronization Info`
- **ShpfyLoggingMode** -- controls API request logging granularity (Error Only, All, Disabled); enabling "All" auto-enables the retention policy for `Shpfy Log Entry`
- **ShpfyImportAction** -- distinguishes new vs. update during import processing
- **ShpfyMappingDirection** -- ShopifyToBC or BCToShopify; controls data flow direction
- **ShpfyReturnLocationPriority** -- determines whether returns use the default location or attempt to use the original fulfillment location first
- **ShpfyWeightUnit** -- maps to Shopify's weight units (Grams, Kilograms, Ounces, Pounds); fetched from shop settings via GraphQL
