# Base

Core infrastructure for the Shopify Connector -- shop configuration, sync bookkeeping, tags, installation, and shared utilities. If something is used across multiple modules and does not belong to a specific Shopify domain (products, orders, etc.), it lives here.

## How it works

The `ShpfyShop` table (in `ShpfyShop.Table.al`) is the central configuration record. It holds sync-direction flags, template codes, G/L account mappings, webhook settings, B2B state, and currency/tax configuration. Many settings come in mutually exclusive pairs -- for example `Shopify Can Update Customer` and `Can Update Shopify Customer` each disable the other on validate, enforcing one-way sync. The `Shop Id` field is computed as a hash of the Shopify URL via `CalcShopId`, with collision resolution by incrementing. This means order sync timestamps (keyed by Shop Id in `ShpfySynchronizationInfo`) survive shop code renames.

`ShpfySynchronizationInfo` tracks the last sync time per sync type per shop, keyed on `(Shop Code, Synchronization Type)`. Orders are special -- they key on the numeric Shop Id rather than the Code, so renaming a shop does not lose the order sync watermark. `ShpfyFilterMgt` provides a `CleanFilterValue` helper that escapes AL filter metacharacters (`(`, `)`, `*`, `.`, `<`, `>`, `=`) to `?` and prepends `@` for case-insensitive matching.

`ShpfyInstaller` handles first-install and company-copy scenarios. On install it registers retention policies for log entries, data captures, and skipped records (1-month default), and sets up cue thresholds. It also subscribes to `OnAfterCreatedNewCompanyByCopyCompany` and `OnClearCompanyConfig` to disable all shops in copied/sandbox environments, preventing accidental sync against production Shopify stores.

## Things to know

- The `ShpfyTag` table enforces a 250-tag limit per parent on insert and provides `GetCommaSeparatedTags` / `UpdateTags` helpers for the comma-delimited format Shopify expects. Tags are keyed on `(Parent Id, Tag)` with no table-number in the PK -- the parent table number is stored but not part of the clustered key.
- `Currency Handling` enum controls whether prices use the shop's base currency or Shopify's presentment (customer-facing) currency. `SKU Mapping` controls how Shopify SKUs resolve to BC items -- by item no., vendor item no., bar code, or a compound key using the `SKU Field Separator`.
- The `Logging Mode` field (off / error only / all) controls API request logging. Switching to "All" automatically enables the retention policy for the Shopify log table.
- `ShpfyCommunicationEvents` lives here and provides the test-double seam for all HTTP calls -- every module's API layer checks `IsTestInProgress` and dispatches through these events instead of real HTTP when true.
- `ShpfyBackgroundSyncs`, `ShpfyShopReview`, and `ShpfyGuidedExperience` handle the assisted setup wizard, background job scheduling, and shop health checks respectively.
