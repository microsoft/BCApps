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
versioned URLs (currently `2026-01`), handling auth, and dispatching
GraphQL queries. `Shpfy Communication Events` publishes internal events
for every API interaction (`OnClientSend`, `OnClientPost`, `OnClientGet`,
`OnGetContent`, `OnGetAccessToken`) -- tests use these to mock responses.

`Shpfy Background Syncs` orchestrates all sync operations via Job Queue,
splitting between background-allowed and foreground-only shops.

`Shpfy Installer` sets up retention policies and Cue thresholds on
install, and disables all shops on company copy or environment cleanup.

## Things to know

- The `Shpfy Cue` table uses FlowFields for role center counts: unmapped
  customers/products/companies, unprocessed orders/shipments, sync errors.
- Empty sync time sentinel is `2004-01-01` (`GetEmptySyncTime()`), not `0DT`.
- Three page extensions embed Shopify Activities into standard role centers.
- `ShpfyConnectorGuide` and `ShpfyInitialImport` provide first-time setup.
