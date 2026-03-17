# Shopify Connector tests

Test suite for the Shopify Connector extension, covering product sync, order handling, inventory, B2B companies, catalogs, and all other integration features. The 91 AL test files mirror the structure of `App/src/` and mock all Shopify API calls without making real HTTP requests.

## Quick reference

- **App name**: Shopify Connector Test
- **App ID**: 32f586f0-69fd-41bb-8e97-98c869856360
- **Dependencies**: Shopify Connector, Tests-TestLibraries, System Application Test Library, Any, Library Assert, Library Variable Storage
- **Run tests**: compile with `dispatch 'Build-Application "Shopify Connector Test" -CountryCode W1'`, publish to the server, then run with `dispatch 'Run-Tests ...'` (see al-testing.md in Eng/Docs/)

## Structure

| Directory | Files | Purpose |
|-----------|-------|---------|
| Base/ | 5 | Shared test initialization (`ShpfyInitializeTest`) and base helpers |
| Bulk Operations/ | 4 | Bulk mutation and staged upload tests |
| Catalogs/ | 5 | B2B catalog, price list, and publication sync |
| Companies/ | 10 | B2B company import/export, location updates, tax registration |
| Customers/ | 7 | Customer sync, mapping, and template application |
| DisabledTests/ | 0 | Placeholder for temporarily disabled tests |
| Gift Cards/ | 1 | Gift card transaction handling |
| GraphQL/ | 1 | GraphQL query construction and validation |
| Helpers/ | 4 | Shared test helper codeunits (order handling, product init) |
| Integration/ | 2 | End-to-end integration scenarios |
| Inventory/ | 7 | Inventory sync, retry logic, quantity adjustments |
| Invoices/ | 2 | Draft order / invoice creation tests |
| Logs/ | 3 | Logging and error entry tests |
| Metafields/ | 5 | Metafield mapping and sync |
| Order Fulfillments/ | 1 | Fulfillment creation and tracking |
| Order Handling/ | 4 | Order import, processing, and transaction mapping |
| Order Refunds/ | 2 | Refund import and processing |
| Order Risks/ | 1 | Order risk assessment |
| Payments/ | 2 | Payment gateway and transaction tests |
| Permission Sets/ | 1 | Permission set validation |
| Products/ | 18 | Product sync, variant creation, images, options, sales channels |
| Shipping/ | 3 | Shipping methods and fulfillment service tests |
| Staff/ | 1 | B2B staff member import and salesperson mapping |
| Translations/ | 0 | Translation sync (resources only) |
| Webhooks/ | 2 | Webhook registration and processing |

## Documentation

- [testing.md](testing.md) -- API mocking patterns, test fixtures, and writing new tests

## Key concepts

- **HttpClientHandler is the correct way to mock Shopify API calls** in new tests. It uses the `[HttpClientHandler]` attribute with `TestHttpRequestMessage`/`TestHttpResponseMessage` and requires `TestHttpRequestPolicy = BlockOutboundRequests` on the test codeunit.
- **IsTestInProgress event-based mocking is legacy** -- it exists in many older tests but should not be used for new ones.
- `ShpfyInitializeTest.CreateShop()` sets up a complete test shop with customer/item templates, posting groups, VAT setup, GL accounts, and a dummy customer/item.
- Test fixtures live in `.resources/` as JSON text files, loaded via `NavApp.GetResourceAsText()` or `NavApp.GetResource()`.
- Each test module directory mirrors the corresponding `App/src/` module it tests.
- For HttpHandler tests, always call `CommunicationMgt.SetTestInProgress(false)` and `InitializeTest.RegisterAccessTokenForShop()` during initialization.
- The `Library - Variable Storage` codeunit is used to track expected API call counts and enforce call ordering.
