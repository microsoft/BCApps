# Inventory

Tests for inventory synchronization between Business Central and Shopify -- stock calculation, inventory export with retry/idempotency logic, location sync, and fulfillment service management. This module is separate from Products because inventory sync operates on the "Shpfy Shop Inventory" record (the junction between variants and locations) rather than on product records directly.

## How it works

ShpfyInventoryAPITest and ShpfyInventorySyncTest are the simpler unit-level tests. InventoryAPITest verifies that `GetStock` correctly returns zero when a location's stock calculation is Disabled, and returns actual inventory when set to "Projected Available Balance Today". It posts item journal lines to create real inventory. InventorySyncTest confirms that running the full sync codeunit produces no Shop Inventory records for disabled locations.

ShpfyInventoryExportTest is the most important file -- it tests the `ExportStock` method with a focus on retry behavior and idempotency. The tests use `ShpfyInventoryRetryScenario`, a custom enum with three values: Success, FailOnceThenSucceed, and AlwaysFail. The HTTP handler uses a `CallCount` variable to switch behavior between calls -- for FailOnceThenSucceed, the first call returns a GraphQL user error with a configurable error code, and subsequent calls succeed. This pattern tests two retryable Shopify errors: `IDEMPOTENCY_CONCURRENT_REQUEST` and `CHANGE_FROM_QUANTITY_STALE`. The max-retries test verifies that after 4 total calls (1 initial + 3 retries), the system logs a Shpfy Skipped Record rather than failing silently. There are also tests for the ForceExport flag -- when false, export is skipped if stock matches Shopify stock; when true, export always happens.

ShpfyTestLocations covers Shopify location import (both single location and full-cycle random 1-5 locations) and fulfillment service callback URL updates. Locations are built as in-memory JSON objects rather than loaded from resource files, using `CreateShopifyLocation` which generates unique IDs via a `KnownIds` list to avoid collisions.

## Things to know

- The retry/idempotency pattern in ShpfyInventoryExportTest is a state machine: `SetRetryState` configures scenario, error code, and resets the call counter. The HTTP handler checks `CallCount` against the scenario to decide whether to return success or error JSON. This is the only place in the test app that explicitly tests GraphQL user error retry logic.
- ShpfyInventoryExportTest uses `GetNextId()` with a module-level `NextId` counter to generate unique IDs, avoiding the `Any.IntegerInRange` approach used elsewhere -- this prevents ID collisions when creating multiple products/variants in the same test.
- The `IDEMPOTENCY_CONCURRENT_REQUEST` and `CHANGE_FROM_QUANTITY_STALE` error codes in the handler correspond to real Shopify API error codes from the `inventorySetQuantities` mutation.
- ShpfyTestLocations builds JSON responses programmatically (not from resource files) and uses `KnownIds: List of [Integer]` to guarantee unique location IDs across a test run.
- Both ShpfyInventoryAPITest and ShpfyInventorySyncTest use `EventSubscriberInstance = Manual` and `SingleInstance = true`, though neither currently binds manual subscribers -- this is likely scaffolding for future event-based stock calculation overrides.
- The ForceExport tests verify an important edge case: normal export skips when calculated stock equals Shopify stock (0 GraphQL calls), but force export sends the mutation regardless (1 call).
