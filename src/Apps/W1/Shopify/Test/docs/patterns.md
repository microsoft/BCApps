# Patterns

## HttpClientHandler mocking

The `[HttpClientHandler]` attribute on an internal procedure intercepts all outbound HTTP requests from the test codeunit. This is the correct way to mock Shopify API calls -- it operates at the platform level so the connector's communication code runs unmodified.

**Example**: In `ShpfyInventoryExportTest`, the `InventoryExportHttpHandler` procedure checks `Request.Path` against the shop URL, increments a `CallCount`, and returns different JSON based on the `RetryScenario` enum. Each test method declares `[HandlerFunctions('InventoryExportHttpHandler')]` and configures the scenario via `SetRetryState()` before calling the connector's export logic.

**Gotcha**: The handler must return `false` when it handles the request and `true` when it doesn't. Returning `true` means "pass through" -- but with `TestHttpRequestPolicy = BlockOutboundRequests`, unhandled requests will error. Also, the handler is matched by the `[HandlerFunctions]` attribute name, not by the procedure signature.

## Lazy initialization with boolean flag

Nearly every test codeunit uses a module-level `isInitialized: Boolean` that gates the `Initialize()` procedure. This ensures the expensive shop creation (with all its posting groups and templates) runs exactly once per test codeunit execution, not once per test method.

**Example**: In `ShpfyInventoryAPITest`, the `Initialize()` procedure checks `isInitialized`, and if false, runs `Codeunit.Run(Codeunit::"Shpfy Initialize Test")` and sets the flag to true. All test methods call `Initialize()` as their first line.

**Gotcha**: The flag resets when the codeunit's `OnRun` trigger fires (many codeunits set `isInitialized := false` in OnRun). If you're running tests in an environment where codeunits are re-instantiated between methods, each method will re-initialize. The `SingleInstance` property on some codeunits prevents this -- but not all test codeunits use `SingleInstance`.

## Resource-based mock responses

Complex or stable JSON response payloads are stored as `.txt` files under `.resources/` and loaded via `NavApp.GetResource()`. This avoids embedding large JSON strings in AL code and makes it easy to update response formats.

**Example**: In `ShpfyBulkOperationsTest`, the `BulkOperationHttpHandler` loads different resources based on which GraphQL operation was requested. It uses `Library - Variable Storage` as a queue (`GraphQLResponses.Enqueue('StagedUpload')`) to control which response to return for each sequential API call. The handler dequeues the next expected response type and loads the corresponding resource file. Product export tests use the same pattern for `ProductUpdateResponse.txt` and `ProductVariantsBulkUpdateResponse.txt`, while shipping tests use it for market-driven feature detection before loading market shipping methods.

*Updated: 2026-07-29 -- Product export and shipping tests now use additional resource-backed mock responses*

**Gotcha**: Resource files use `%1`, `%2` placeholders filled by `StrSubstNo`. If your response needs a literal `%` character, you must escape it. Also, resource files must be under the `.resources/` path declared in `app.json`'s `resourceFolders` -- putting them elsewhere means they won't be compiled into the app.

## Retry state machine testing

For testing retry/idempotency logic, the test codeunit maintains mutable state (scenario enum + call counter) that the HTTP handler reads to decide what to return.

**Example**: `ShpfyInventoryExportTest` declares `RetryScenario: Enum "Shpfy Inventory Retry Scenario"`, `CallCount: Integer`, and `ErrorCode: Text`. The test method calls `SetRetryState(FailOnceThenSucceed, 'IDEMPOTENCY_CONCURRENT_REQUEST')` before invoking the export. The handler increments `CallCount` and returns an error response on the first call, then success on subsequent calls. The test asserts `CallCount = 2` to verify the retry happened. For `AlwaysFail`, it asserts `CallCount = 4` (1 initial + 3 retries) and checks that a skipped record was logged.

**Gotcha**: The `CallCount` is on the codeunit instance, not the handler. Since the test codeunit and handler are the same object (the handler is a procedure on the test codeunit), this works. But if you extract the handler to a separate codeunit, you'd need to pass state differently.

## Interface mocking via enum extensions

When the main app defines an AL interface dispatched through an enum, the test app can provide mock implementations by extending that enum with a test-only value backed by a mock codeunit.

**Example**: The main app's `"Shpfy Stock Calculation"` interface is extended by `ShpfyStockCalculationExt` (enum extension 139560) adding value "Shpfy Return Const" implemented by `ShpfyConstToReturn`. This codeunit stores a decimal and returns it from `GetStock()`. Tests configure a shop location with this stock calculation type, call `SetConstToReturn(42)`, and verify the connector uses the returned value.

**Gotcha**: The enum extension value (139560) must be in the test app's ID range. The mock codeunit must implement the full interface -- even if most methods are no-ops (like `RevertFailedRequests` and `RevertAllRequests` in `ShpfyMockBulkProductCreate`).

## Manual event subscriber binding

Some tests need to intercept events from the main app to control behavior. They use codeunits with `EventSubscriberInstance = Manual` and `SingleInstance = true`, which must be explicitly bound.

**Example**: `ShpfySkippedRecordLogSub` subscribes to `OnBeforeFindMapping` on the customer events codeunit. It sets `Handled := true` and injects a specific `ShopifyCustomerId`, bypassing the real customer mapping logic. The test creates an instance, calls `SetShopifyCustomerId()`, and binds it with `BindSubscription`. Similarly, `ShpfyBulkOpSubscriber` subscribes to `OnInvalidUser` and sets `IsHandled := true` to skip user validation that would fail in a test context.

**Gotcha**: Forgetting to unbind after the test can leak state into subsequent tests. The `SingleInstance` property means the subscriber persists for the session -- its state carries over unless explicitly reset.

## Variable Storage queue for GraphQL response dispatch

All Shopify GraphQL requests hit the same endpoint (`/admin/api/graphql.json`), and `TestHttpRequestMessage` does not expose the request body -- so the `[HttpClientHandler]` cannot inspect the query to decide which mock response to return. The workaround is a pre-loaded queue: the test enqueues response type identifiers into `Library - Variable Storage` before running the code under test, and the HTTP handler dequeues to know which response to serve next.

**Example**: In `ShpfyBulkOperationsTest`, sending a bulk mutation requires two API calls: first a staged upload, then the actual bulk mutation. The test calls `EnqueueGraphQLResponsesForSendBulkMutation()` which enqueues `'StagedUpload'` then `'BulkMutation'`. The handler calls `GraphQLResponses.DequeueText()` to get the next expected type and loads the appropriate resource file.

**Gotcha**: If the code under test makes more API calls than you enqueued, the dequeue will error with an empty-storage exception. If it makes fewer, leftover items in the queue may confuse the next test method. Some test methods call `ClearSetup()` which clears the storage.

## Disabled tests tracking

Known-failing test methods are still tracked as JSON, but not inside the Shopify test app folder. The local `Test/DisabledTests/` directory was removed; `RunTestsInBcContainer.ps1` now searches for central `DisabledTests/<app name>/*.json` folders and passes those entries to the test runner. For this app, the app-name folder is `Shopify_Connector_Test`.

**Example**: A central entry contains `codeunitId`, `codeunitName`, and `method`; the build script derives the folder name by replacing spaces in the app name with underscores.

**Gotcha**: Do not add new `Test/DisabledTests/*.json` files. If you rename a test method or codeunit, update the central app-name disabled-test file, otherwise the filter will not match the intended method.

*Updated: 2026-07-29 -- App-local DisabledTests JSON files were removed and the build uses the central app-name folder mechanism*

## Price calculation state isolation

Price calculation tests are sensitive to cached state because `Shpfy Product Price Calc.` is SingleInstance and keeps temporary sales context. Tests that depend on Work Date must change `WorkDate()` deliberately, call `SetShop()` for each calculation, and restore the original Work Date before asserting so failures do not leak state into later tests.

**Example**: `ShpfyProductPriceCalcTest.UnitTestCalcPriceUsesCurrentWorkDate` creates two dated All Customers discounts around a boundary date, calculates once after the boundary and once before it, and proves the second call uses the current Work Date instead of a stale cached document date.

**Gotcha**: Legacy price tests that exercise Sales Price / Sales Line Discount data should explicitly choose the V15 handler with `LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 15.0)")`. Disabling extended pricing is not enough when the tenant defaults have already moved to the newer price engine.

*Updated: 2026-07-29 -- Price calculation tests now guard against stale Work Date and explicit legacy handler selection*

## Suppressing duplicate-contact confirmations

Customer creation and update tests can cascade into contact creation. In demo or localized data, Marketing Setup may have duplicate-contact auto-search enabled, which raises an interactive confirm while tests run with UI handlers enabled.

**Example**: `ShpfyCreateCustomerTest.Initialize()` turns off `Marketing Setup."Autosearch for Duplicates"` and `"Maintain Dupl. Search Strings"` before committing setup. The tests then verify no-default-address customer creation and update paths without needing a confirm handler.

**Gotcha**: Prefer disabling the data-dependent confirmation at setup time for these integration tests. A confirm handler would hide the source of the prompt and could accidentally approve unrelated confirmations.

*Updated: 2026-07-29 -- Customer creation tests now avoid duplicate-contact confirms through setup data*

## GraphQL rate-limit elapsed-time checks

The rate limiter tests measure elapsed time, so they use broad tolerances and explicit sleeps only where the production behavior is time-based.

**Example**: `ShpfyGraphQLRateLimitTest.UnitTestWaitForRequestAvailableAfterElapsedTime` sets availability below the next query cost, sleeps for part of the restore interval, then asserts that `WaitForRequestAvailable` waits only the remaining time.

**Gotcha**: These tests should verify a range around the expected wait rather than exact milliseconds. The purpose is to catch under-waiting or restarting the full wait after elapsed time, not scheduler jitter.

*Updated: 2026-07-29 -- Rate-limit tests now cover elapsed restore time*

## Legacy patterns

### RecordRef-based field mutation

**What it is**: `ShpfyCustomerInitTest.ModifyFields()` takes a Variant, opens it as a RecordRef, iterates all fields, and prepends "!" to every text field value. `TextFieldsContainsFieldName()` does a similar loop to verify that text fields contain their own field name.

**Where it appears**: `ShpfyCustomerInitTest` (codeunit 139585), used by `ShpfyCustomerAPITest` and `ShpfyCustomerExportTest`.

**Why it exists**: It was written to generically modify any record for update-query testing without hardcoding each field. This was convenient when the customer record had few text fields.

**What to do instead**: For new test helpers, prefer explicit field assignments. The RecordRef approach makes it hard to understand what changed when reading a test, and it silently modifies fields you may not intend to change. It also produces odd values like "!111" for phone numbers (which the test then special-cases: the validation strips invalid characters, leaving " .").

### Temporary table for field-type coverage

**What it is**: `ShpfyTestFields` (table 139560) is a temporary table with one field of every AL data type (Integer, Blob, Boolean, Code, Text, Date, DateTime, Decimal, Duration, Guid, Option, Time). Each field has a validation trigger that shows a message.

**Where it appears**: `Helpers/Tables/ShpfyTestFields.Table.al`, used by `ShpfyFilterMgtTest`.

**Why it exists**: The filter management test needed to verify that `CleanFilterValue` works correctly for values of every type. The temporary table provides a convenient fixture.

**What to do instead**: This pattern is fine for its purpose. If you need to test type-agnostic code, a similar approach is reasonable. Just keep the table temporary to avoid polluting the database schema.
