# Base

Core infrastructure for the Shopify connector. Contains the Shpfy Shop table (ID 30102) -- the central configuration record that nearly every other module reads -- plus the sync orchestration framework, tag storage, communication layer, and role center integration.

## How it works

The Shop table is the god object of the connector. It holds 60+ settings covering customer mapping type, product sync direction, stock calculation mode, order processing options, B2B company settings, webhook configuration, currency handling, template references, logging mode, and more. Enabling a shop (`Enabled` field in `ShpfyShop.Table.al`) triggers consent validation via `CustomerConsentMgt.ConfirmUserConsent()` and logs an audit entry. Disabling it first deactivates order-created webhooks and bulk operation webhooks before clearing the Enabled flag.

`ShpfyBackgroundSyncs.Codeunit.al` is the central dispatcher for all sync operations. Each sync type (customers, companies, products, inventory, orders, payouts, etc.) follows the same pattern: build XML parameters embedding the Shop record view, then call `EnqueueJobEntry` which either schedules a Job Queue Entry (if `Allow Background Syncs` is true and `TaskScheduler.CanCreateTask()` succeeds) or runs the report synchronously. The codeunit splits shops into two passes -- background-capable and foreground-only -- so a single call handles mixed configurations.

`ShpfySynchronizationInfo.Table.al` tracks the last successful sync timestamp per shop and sync type (Products, Orders, Customers, Companies), keyed by `[Shop Code, Synchronization Type]`. Each sync codeunit records its start time and writes it back after completion.

Tags (`ShpfyTag.Table.al`) are stored as normalized rows with a `[Parent Id, Tag]` composite key. The `OnInsert` trigger enforces Shopify's 250-tag-per-entity limit. `UpdateTags` does a full replace -- it deletes all existing tags for the parent, then re-inserts from a comma-separated string.

## Things to know

- `ShpfyCommunicationEvents.Codeunit.al` publishes internal events for every HTTP interaction (OnClientSend, OnClientPost, OnClientGet, OnGetAccessToken, OnGetContent). These are the hooks test codeunits use to mock the Shopify API.
- `ShpfyShopMgt.Codeunit.al` manages notification lifecycle for API version expiration and blocking, not shop CRUD. The actual shop lifecycle is mostly handled by the Shop table's field triggers.
- The `ShpfyInitialImport` page and codeunit provide a guided first-time sync experience, and `ShpfyBackgroundSyncs` subscribes to `Job Queue Entry.OnBeforeModifyEvent` to track initial import progress.
- Page extensions on Business Manager RC, Order Processor RC, and Sales Rel Mgr RC inject the Shopify Activities cue group, driven by `ShpfyCue.Table.al`.
- The `ShpfyFilterMgt.Codeunit.al` handles filter serialization for passing record views through job queue XML parameters.
- `ShpfyUpgradeMgt.Codeunit.al` handles data migrations across versions; `ShpfyInstaller.Codeunit.al` runs on first install.
