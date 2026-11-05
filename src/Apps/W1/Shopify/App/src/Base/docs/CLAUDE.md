# Base

Core infrastructure: shop configuration, sync tracking, API communication,
role center integration, installation, and background sync orchestration.

## How it works

`Shpfy Shop` (`Tables/ShpfyShop.Table.al`) is the central configuration
object with 100+ fields controlling sync directions, mapping strategies,
G/L account mappings, B2B flags, webhook settings, and more. Multiple
shops per BC company, each identified by a `Code` primary key. `Shop Id`
is an integer hash of the Shopify URL for efficient lookups.

`Shpfy Synchronization Info` tracks incremental sync cursors, keyed by
shop code and sync type. Order sync specifically keys by `Shop Id` hash
so multiple BC companies sharing a Shopify shop share the cursor.

`Shpfy Communication Mgt.` is the single API entry point, constructing
versioned URLs (currently `2026-07`), handling auth, and dispatching
GraphQL queries. `Shpfy Communication Events` publishes internal events
for every API interaction (`OnClientSend`, `OnClientPost`, `OnClientGet`,
`OnGetContent`, `OnGetAccessToken`) -- tests use these to mock responses.

`GetAccessToken` ensures a valid expiring offline access token before each
request via `ShpfyAuthenticationMgt.EnsureValidAccessToken` (refresh a
near-expiry token or migrate a legacy non-expiring one, on demand), and
`ExecuteWebRequest` forces a single token refresh and retry on an
unexpected 401. A lapsed 90-day refresh token is terminal: the Shop Card
shows a reconnect notification. See the app-level business-logic.md for
the full token lifecycle.

*Updated: 2026-07-11 -- Expiring offline access token support (slice 637954)*

`Shpfy Background Syncs` orchestrates all sync operations via Job Queue,
splitting between background-allowed and foreground-only shops.

`Shpfy Installer` sets up retention policies and Cue thresholds on
install, and disables all shops on company copy or environment cleanup.
`Shpfy Shop Mgt.` handles user-facing notifications, including the
Belgian localization prompt shown from the Shops list when the tenant is
in the BE application family and the localization extension is missing.

*Updated: 2026-07-29 -- Shop Mgt. now owns the Belgian localization prompt*

## B2B enabled to Advanced Shopify Plan migration

The `B2B Enabled` field (117) on the Shop table is obsoleted with
`CLEAN29`/`CLEANSCHEMA32` guards. It is replaced by a new field
`Advanced Shopify Plan` (207), which is set to true for Plus, Plus Trial,
Development, and Advanced plans.

*Updated: 2026-04-08 -- B2B Enabled obsoleted, replaced by Advanced Shopify Plan*

`GetShopSettings()` still queries the Shopify plan info but now sets
`Advanced Shopify Plan` instead of `B2B Enabled`. It validates the field,
so dependent settings react to plan changes instead of silently keeping
stale values. The plan name check includes "Advanced" in addition to the
previous Plus/Development values.

*Updated: 2026-07-29 -- plan refresh now runs validation for dependent settings*

`ShpfyUpgradeMgt` has a new `HasAdvancedShopifyPlanUpgrade()` procedure
that uses DataTransfer to copy `B2B Enabled` to `Advanced Shopify Plan`
(with a source filter on true and a constant value).

## Activities page and Shop Card visibility changes

`ShpfyActivities` page: the `B2BEnabled` variable and B2B shop filter
have been removed -- the Unmapped Companies cue is now always visible.

*Updated: 2026-04-08 -- B2B visibility gates removed from Activities and Shop Card*

`ShpfyShopCard` page: six `Visible = Rec."B2B Enabled"` gates on B2B
groups/actions have been removed. The StaffMembers action is now gated on
`Advanced Shopify Plan` instead. The "Sync All" action now unconditionally
syncs companies and catalog prices regardless of plan.

The `Auto Create Catalog` field is captioned as `Auto Create B2B Catalog`
and is visible in the B2B company synchronization group. Enabling it now
validates the cached `Advanced Shopify Plan` flag and errors unless the
shop is Plus, Plus Trial, Development, or Advanced. If a later plan
refresh clears `Advanced Shopify Plan`, the table validation turns
`Auto Create Catalog` off.

*Updated: 2026-07-29 -- Auto Create B2B Catalog is visible but plan-validated*

## Shop settings added for product sync

`Find Mapping by Barcode` controls the product mapping fallback that uses
item references by barcode after SKU and variant matching fail. It
defaults to true to preserve the legacy fallback, but it can be disabled
when duplicate or unreliable Shopify barcodes would create wrong links.

`Sync HS Code and Country` controls whether tariff numbers and country of
origin flow between Business Central items and Shopify inventory items.
When importing to BC, the code only applies values that resolve to an
existing Tariff Number or Country/Region; `Shpfy Filter Mgt.` normalizes
tariff comparisons to digits so `6104.43` and `610443` are treated as the
same HS code.

*Updated: 2026-07-29 -- barcode fallback and HS code/country sync settings added*

## Things to know

- The `Shpfy Cue` table uses FlowFields for role center counts: unmapped
  customers/products/companies, unprocessed orders/shipments, sync errors.
- Empty sync time sentinel is `2004-01-01` (`GetEmptySyncTime()`), not `0DT`.
- Authentication uses expiring offline access tokens: `EnsureValidAccessToken` (from `GetAccessToken`) refreshes before expiry and migrates legacy non-expiring tokens on demand. A lapsed 90-day refresh token requires reconnecting the shop from the Shop Card.
- Three page extensions embed Shopify Activities into standard role centers
  and add Shops, Customers, Companies, Products, Orders, Refunds, Returns,
  Gift Cards, Transactions, and Payouts to the Shopify navigation group.
- `ShpfyConnectorGuide` and `ShpfyInitialImport` provide first-time setup.
- Order sync refreshes and saves `GetShopSettings()` before retrieving
  orders, so plan-gated order details such as staff member fields use the
  current Shopify plan instead of a stale cached value.

*Updated: 2026-07-29 -- role center navigation and order plan refresh notes added*
