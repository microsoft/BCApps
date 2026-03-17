# Base

The Base folder contains the Shopify Connector's core infrastructure -- the Shop configuration table, sync orchestration, tags, installer/upgrade, and UI shell.

## Shpfy Shop table

`ShpfyShop.Table.al` is the central configuration object. Virtually every sync codeunit takes a Shop record as its `TableNo` or via `SetShop`. It holds settings for customers (`Customer Mapping Type`, `Name Source`, `Name 2 Source`, `Contact Source`, `County Source`, `Default Customer No.`, `Auto Create Unknown Customers`), products, orders, companies, inventory, and more. Enabling a shop requires a valid Shopify URL and user consent confirmation. The `Shopify Can Update Customer` / `Can Update Shopify Customer` pair is mutually exclusive -- setting one clears the other -- establishing a clear one-way sync direction per shop.

## Sync orchestration

`ShpfyBackgroundSyncs.Codeunit.al` is the central dispatcher for all sync operations (customers, companies, products, inventory, orders, payouts, images, catalog prices). Each method constructs XML parameters for a report and enqueues a Job Queue Entry. Shops with `Allow Background Syncs = true` run in the background; others run inline. The codeunit also manages user notifications for background jobs and provides a "don't show again" mechanism via `My Notifications`.

## Tag system

`ShpfyTag.Table.al` implements a polymorphic parent-child tag model. Tags are keyed by `(Parent Id, Tag)` with `Parent Table No.` identifying the owner type. `UpdateTags` does a delete-and-reinsert on every update. A hard limit of 250 tags per parent is enforced on insert. The Tag table is used by customers, products, and orders -- any entity with a Shopify `tags` field.

## Initial import

`ShpfyInitialImport.Codeunit.al` manages the first-time sync wizard. It creates `Shpfy Initial Import Line` records for ITEM, CUSTOMER, and ITEM IMAGE, with dependency ordering (ITEM IMAGE depends on ITEM). The `Start` procedure finds lines with all dependencies finished and enqueues them. Job queue entry status changes trigger re-evaluation so dependent jobs start automatically. Demo companies get a capped import of 25 products.

## Synchronization info tracking

`ShpfySynchronizationInfo.Table.al` stores the last sync timestamp per shop and sync type (keyed by Shop Code + Synchronization Type enum). The Shop table's `SetLastSyncTime` method writes here after each sync completes.

## Cues and activities

`ShpfyCue.Table.al` provides FlowFields for the role center: unmapped customers, unmapped products, unprocessed orders, unprocessed shipments, sync errors, and unmapped companies. `ShpfyActivities.Page.al` displays these. The installer sets up color thresholds (green < 1, yellow < 5, red >= 5).

## Installer and upgrade

`ShpfyInstaller.Codeunit.al` runs on install: sets up retention policies (1-month default for log entries, data capture, skipped records) and cue color thresholds. It also disables shops on company copy and environment cleanup to prevent accidental production API calls. `ShpfyUpgradeMgt.Codeunit.al` handles schema migrations across versions.

## Other notable pieces

- `ShpfyCommunicationMgt.Codeunit.al` / `ShpfyCommunicationEvents.Codeunit.al` -- HTTP client wrapper for Shopify API calls with event hooks
- `ShpfyShopMgt.Codeunit.al` -- shop-level helper operations
- `ShpfyConnectorGuide.Page.al` -- the assisted setup wizard
- Role center page extensions (`ShpfyBusinessManagerRC`, `ShpfyOrderProcessorRC`, `ShpfySalesRelMgrRC`) embed the Shopify activities cue
