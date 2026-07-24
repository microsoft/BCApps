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
unexpected 401. The `Shpfy Token Refresh` dispatcher plus
`Shpfy Token Refresh Shop` worker are a recurring backstop that keeps
tokens and their 90-day refresh tokens alive; that Job Queue entry is
scheduled from `Shpfy Shop Card` on open (`ScheduleRefreshJob`), not from
install/upgrade, since enqueuing implicitly commits. See the app-level
business-logic.md for the full token lifecycle.

*Updated: 2026-07-11 -- Expiring offline access token support (slice 637954)*

`Shpfy Background Syncs` orchestrates all sync operations via Job Queue,
splitting between background-allowed and foreground-only shops.

`Shpfy Installer` sets up retention policies and Cue thresholds on
install, and disables all shops on company copy or environment cleanup.

## B2B Enabled → Advanced Shopify Plan migration

The `B2B Enabled` field (117) on the Shop table is obsoleted with
`CLEAN29`/`CLEANSCHEMA32` guards. It is replaced by a new field
`Advanced Shopify Plan` (207), which is set to true for Plus, Plus Trial,
Development, and Advanced plans.

*Updated: 2026-04-08 -- B2B Enabled obsoleted, replaced by Advanced Shopify Plan*

`GetShopSettings()` still queries the Shopify plan info but now sets
`Advanced Shopify Plan` instead of `B2B Enabled`. The plan name check
includes "Advanced" in addition to the previous Plus/Development values.

`ShpfyUpgradeMgt` has a new `HasAdvancedShopifyPlanUpgrade()` procedure
that uses DataTransfer to copy `B2B Enabled` → `Advanced Shopify Plan`
(with a source filter on true and a constant value).

## Activities page and Shop Card visibility changes

`ShpfyActivities` page: the `B2BEnabled` variable and B2B shop filter
have been removed -- the Unmapped Companies cue is now always visible.

*Updated: 2026-04-08 -- B2B visibility gates removed from Activities and Shop Card*

`ShpfyShopCard` page: six `Visible = Rec."B2B Enabled"` gates on B2B
groups/actions have been removed. The StaffMembers action is now gated on
`Advanced Shopify Plan` instead. The "Sync All" action now unconditionally
syncs companies and catalog prices regardless of plan.

## Things to know

- The `Shpfy Cue` table uses FlowFields for role center counts: unmapped
  customers/products/companies, unprocessed orders/shipments, sync errors.
- Empty sync time sentinel is `2004-01-01` (`GetEmptySyncTime()`), not `0DT`.
- Authentication uses expiring offline access tokens: `EnsureValidAccessToken` (from `GetAccessToken`) refreshes before expiry and migrates legacy non-expiring tokens; the `Shpfy Token Refresh` dispatcher + `Shpfy Token Refresh Shop` worker are the proactive backstop, scheduled as a Job Queue entry from the Shop Card on open. A lapsed 90-day refresh token requires reconnecting the shop from the Shop Card.
- Three page extensions embed Shopify Activities into standard role centers.
- `ShpfyConnectorGuide` and `ShpfyInitialImport` provide first-time setup.
