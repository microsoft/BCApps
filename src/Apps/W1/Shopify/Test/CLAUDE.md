# Shopify Connector Test

This app is the test suite for the Shopify Connector. It verifies the connector's data mapping, API interaction, and order processing logic without ever calling the real Shopify API -- all HTTP traffic is intercepted by `[HttpClientHandler]` procedures or blocked outright via `TestHttpRequestPolicy = BlockOutboundRequests`. The test app creates its own self-contained Business Central environment (posting groups, VAT setup, customer/item templates) so tests are isolated from whatever demo data exists in the database.

## Quick reference

- **ID ranges**: 134241-134247, 139537-139549, 139551-139589, 139593-139594, 139596, 139601-139609, 139611-139639, 139645-139649, 139695-139699
- **Dependencies**: Shopify Connector, Tests-TestLibraries, System Application Test Library, Any, Library Assert, Library Variable Storage

## How it works

The central piece of infrastructure is `ShpfyInitializeTest` (codeunit 139561). It creates a fully configured Shpfy Shop record with randomized codes -- posting groups, VAT setup, customer and item templates, GL accounts, number series, and a dummy customer and item. The shop is cached in a temporary record so subsequent calls in the same session return the same shop instead of creating duplicates. Every domain-specific test codeunit calls `Initialize()` which runs this codeunit exactly once via the `isInitialized` boolean flag pattern.

HTTP mocking uses `[HttpClientHandler]` exclusively -- test codeunits declare a handler procedure that intercepts outbound HTTP requests at the platform level. The handler inspects the request URL (via `InitializeTest.VerifyRequestUrl`), decides what mock response to return, and writes it into `TestHttpResponseMessage`. Mock response payloads come from two sources: JSON built programmatically in helper codeunits (like `ShpfyOrderHandlingHelper.CreateShopifyOrderAsJson`) or loaded from `.resources/` files via `NavApp.GetResource()`. The `.resources/` folder mirrors the test folder structure (e.g., `.resources/Bulk Operations/`, `.resources/Products/`, `.resources/Shipping/`). The newer product and shipping mocks cover variant retrieval, product/variant update mutations, and market-driven shipping method responses. The earlier `IsTestInProgress` pattern for mocking has been fully replaced by `[HttpClientHandler]` (PR #7204); the only remaining `IsTestInProgress` usage is in the webhooks test, where it serves a different purpose (suppressing task scheduling). For testing interface contracts, the app uses enum extensions -- `ShpfyStockCalculationExt` adds a "Return Const" value that maps to `ShpfyConstToReturn`, a trivial implementation that returns a configurable decimal. Similarly, `ShpfyBulkOperationType` is extended with `AddProduct` backed by `ShpfyMockBulkProductCreate`.

*Updated: 2026-04-08 -- IsTestInProgress mocking fully replaced by HttpClientHandler (PR #7204)*

*Updated: 2026-07-29 -- Resource mocks now include product variant, product update, and shipping-market responses*

The app does not test the Shopify admin UI, webhooks delivery, or actual GraphQL network round-trips. It tests the AL-side logic: data transformation, record creation, field mapping, GraphQL query generation, retry/idempotency handling, and error flows. The boundary is always at the HTTP layer.

## Structure

- **Base/** -- Shop initialization (`ShpfyInitializeTest`), core smoke tests (`ShpfyTestShopify` -- currently commented out), filter management tests, checklist and connector guide tests
- **Products/** -- Largest area (15 files). Item creation, product mapping, price calculation, variant API retrieval, collections, sales channels, image sync. Has its own init codeunit `ShpfyProductInitTest`. See [Products/docs/CLAUDE.md](Products/docs/CLAUDE.md)
- **Companies/** -- B2B company sync: import, export, mapping, locations, tax ID. Init in `ShpfyCompanyInitialize`. See [Companies/docs/CLAUDE.md](Companies/docs/CLAUDE.md)
- **Customers/** -- Customer mapping, export, API query generation, name resolution. Init in `ShpfyCustomerInitTest`
- **Inventory/** -- Stock calculation, sync, export with retry/idempotency, location mapping. Uses the `ShpfyInventoryRetryScenario` enum for state-machine testing. See [Inventory/docs/CLAUDE.md](Inventory/docs/CLAUDE.md)
- **Bulk Operations/** -- Tests for Shopify's bulk mutation API. Uses `ShpfyBulkOpSubscriber` for event isolation and `ShpfyMockBulkProductCreate` as a mock interface implementation. See [Bulk Operations/docs/CLAUDE.md](Bulk%20Operations/docs/CLAUDE.md)
- **Shipping/** -- Shipping charge, fulfillment, and market-driven shipping method tests. Uses resource-backed responses under `.resources/Shipping/` for market feature detection and method sync
- **Transactions/** -- Currency and amount mapping tests for Shopify order transactions. This is a small area with one codeunit, so it is documented here rather than in its own docs folder
- **Order Handling/** -- Order import and processing. `ShpfyOrderHandlingHelper` builds complex JSON order structures programmatically
- **Integration/** -- The `ShpfyConstToReturn` codeunit and its enum extension. This is the mock stock calculation implementation
- **Helpers/** -- JSON helper tests, Base64/hash tests, and the `ShpfyTestFields` temporary table (used to test the filter codeunit against every AL field type)
- **.resources/** -- Mock JSON response files organized by domain subfolder, including Products, Bulk Operations, and Shipping

*Updated: 2026-07-29 -- Added variant API, Transactions, Shipping resources, and removed the stale app-local DisabledTests folder reference*

## Documentation

- [docs/business-logic.md](docs/business-logic.md) -- Test infrastructure flows and setup
- [docs/patterns.md](docs/patterns.md) -- Test patterns and legacy patterns to avoid

## Things to know

- The `isInitialized` boolean flag appears in nearly every test codeunit. It gates a one-time `Initialize()` call that runs `ShpfyInitializeTest` and caches the shop. If you add a new test codeunit, copy this pattern or your tests will fail from missing setup data.

- `ShpfyInitializeTest.CreateShop()` calls `Commit()` twice -- once after inserting the shop, once after caching it in the temporary record. This is intentional: the shop must be committed before the communication management codeunit can use it, and the temporary record prevents duplicate creation across test methods in the same session.

- `TestHttpRequestPolicy = BlockOutboundRequests` is set at the codeunit level. If your test makes HTTP calls and you forget this property, the test will attempt real network calls and fail in CI. Pair it with `[HandlerFunctions('YourHttpHandler')]` on each test method.

- The `[HttpClientHandler]` procedure must return `false` to indicate it handled the request. Returning `true` means "I didn't handle this, let it through" -- which will hit the block policy and fail.

- Manual event subscriber codeunits like `ShpfySkippedRecordLogSub` use `EventSubscriberInstance = Manual` and `SingleInstance = true`; bind and unbind them around the test that needs them. `ShpfyBulkOpSubscriber` is the same kind of subscriber for `OnInvalidUser`, but it is bound in `ShpfyWebhooksTest` rather than in `ShpfyBulkOperationsTest` -- the webhook tests are the ones that drive a bulk operation callback without a real Shopify user context. Look there for the binding pattern.

- `ShpfyCustomerInitTest.ModifyFields()` uses RecordRef to prepend "!" to every text field on any record. This is used to create "changed" versions of records for update-query testing without hardcoding field names.

- The app-local `DisabledTests/` folder no longer exists. Disabled-test filtering still exists in the build tooling: `RunTestsInBcContainer.ps1` looks for central `DisabledTests/<app name>/*.json` folders under the repository base folder and passes those entries to the test runner. Do not add new app-local `Test/DisabledTests/*.json` files.

*Updated: 2026-07-29 -- DisabledTests guidance now points to the central build-tool mechanism*

- The `.resources/` folder is declared in `app.json` under `resourceFolders` and accessed via `NavApp.GetResource()`. If you add a new mock response file, it must go under `.resources/` to be included in the compiled app.

- B2B company features are now unconditionally available on all Shopify plans -- the old `"B2B Enabled"` field has been obsoleted. Tests no longer set `Shop."B2B Enabled" := true`. Staff member visibility and Auto Create Catalog validation still use `Shop."Advanced Shopify Plan"`: staff actions are hidden for unsupported plans, enabling Auto Create Catalog errors on non-advanced plans, and downgrading the plan clears Auto Create Catalog.

*Updated: 2026-04-08 -- B2B Enabled removed from tests; staff tests use Advanced Shopify Plan*

*Updated: 2026-07-29 -- Auto Create Catalog plan-gating tests now share the Advanced Shopify Plan setup*

- `ShpfyOrderHandlingHelper` is the most complex helper -- it builds complete order JSON structures including nested customer, address, tax, line item, and B2B company data. It also creates real BC records (items, shop locations, Shopify products/variants) as side effects of building the JSON.

- The `ShpfyInventoryRetryScenario` enum is a state machine for testing retry logic: `Success`, `FailOnceThenSucceed`, `AlwaysFail`. The test codeunit tracks `CallCount` to verify that retries actually happened (e.g., expecting exactly 4 calls for "always fail" = 1 initial + 3 retries).
