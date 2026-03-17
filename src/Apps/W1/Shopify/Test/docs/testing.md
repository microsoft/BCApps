# Testing guide

## Overview

The Shopify Connector test suite contains 91 AL test files organized into 25 module directories that mirror the `App/src/` structure. All tests mock Shopify API calls -- no real HTTP requests are made. Two mocking mechanisms exist: **HttpClientHandler** (correct, framework-level) and **IsTestInProgress events** (legacy, app-level). Use HttpClientHandler for all new tests.

## API mocking

### HttpClientHandler (correct approach)

This is the framework-level HTTP interception mechanism. The test runtime intercepts outbound HTTP calls and routes them to a handler procedure you define, without any application-level branching.

**Codeunit properties required:**

```al
codeunit 139551 "Shpfy Staff Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;  // Required -- blocks real HTTP calls
    ...
}
```

`TestHttpRequestPolicy = BlockOutboundRequests` tells the test framework to block all outbound HTTP requests and route them to registered handler functions instead.

**Declaring the handler:**

Mark a procedure with `[HttpClientHandler]`. It receives a `TestHttpRequestMessage` and a `var TestHttpResponseMessage`, and returns a Boolean:

```al
[HttpClientHandler]
internal procedure GetProductsHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
begin
    if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
        exit(true);  // Not our request -- pass through

    // Load a JSON response from .resources/
    Response.Content.WriteFrom(NavApp.GetResourceAsText('Products/ProductDetailsResponse.txt', TextEncoding::UTF8));
    exit(false);  // false = handled, do not make a real HTTP call
end;
```

Return values:

- `false` -- the request is handled; the framework uses the response you set
- `true` -- the request is not handled; passes through (will be blocked by `BlockOutboundRequests`)

**Connecting handler to test:**

Use `[HandlerFunctions('HandlerName')]` on the test procedure:

```al
[Test]
[HandlerFunctions('GetProductsHttpHandler')]
procedure UnitTestErrorClearOnSuccessfulItemCreation()
begin
    Initialize();
    // ... test body ...
end;
```

**Tracking expected calls with Variable Storage:**

Use `Library - Variable Storage` to enforce the expected number and order of API calls. The handler dequeues on each call; if the queue is empty, it raises an error:

```al
var
    OutboundHttpRequests: Codeunit "Library - Variable Storage";

local procedure RegExpectedOutboundHttpRequestsForGetProducts()
begin
    OutboundHttpRequests.Enqueue('GQL Get Product Details');
    OutboundHttpRequests.Enqueue('GQL Get Product Variants');
    OutboundHttpRequests.Enqueue('GQL Get Product Variant Details');
end;

[HttpClientHandler]
internal procedure GetProductsHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
begin
    if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
        exit(true);

    case OutboundHttpRequests.Length() of
        3:
            LoadResourceIntoHttpResponse('Products/ProductDetailsResponse.txt', Response);
        2:
            LoadResourceIntoHttpResponse('Products/ProductVariantsResponse.txt', Response);
        1:
            LoadResourceIntoHttpResponse('Products/ProductVariantDetailsResponse.txt', Response);
        0:
            Error('More than expected API calls to Shopify detected.');
    end;
    exit(false);
end;
```

This pattern comes from `Products/ShpfyCreateItemAPITest.Codeunit.al` and is the recommended way to sequence multiple API responses.

**Parameterized responses:**

Replace placeholders in resource text before writing the response:

```al
ResultTxt := NavApp.GetResourceAsText('Products/ProductVariantsResponse.txt', TextEncoding::UTF8);
ResultTxt := ResultTxt.Replace('{{ProductId}}', ProductId.ToText());
ResultTxt := ResultTxt.Replace('{{VariantId}}', VariantId.ToText());
Response.Content.WriteFrom(ResultTxt);
```

**Full HttpHandler examples:**

- `Products/ShpfyCreateItemAPITest.Codeunit.al` -- multi-call sequencing with Variable Storage
- `Staff/ShpfyStaffTest.Codeunit.al` -- simple single-response handler
- `Shipping/ShpfyShippingTest.Codeunit.al` -- shipping fulfillment tests
- `Products/ShpfySyncVariantImagesTest.Codeunit.al` -- image sync
- `Products/ShpfyItemAttrAsOptionTest.Codeunit.al` -- product options
- `Companies/ShpfyCompanyLocationsTest.Codeunit.al` -- company location tests
- `Catalogs/ShpfyMarketCatalogAPITest.Codeunit.al` -- catalog market tests

### IsTestInProgress events (legacy -- do not use for new tests)

This is an app-level mocking mechanism built into `Shpfy Communication Mgt.` (codeunit 30103). When `CommunicationMgt.SetTestInProgress(true)` is called, the production code branches: instead of making real HTTP calls via `HttpClient`, it raises events on `Shpfy Communication Events` (codeunit 30200). Test subscriber codeunits then handle these events to return mock responses.

**How it works in the production code:**

In `ShpfyCommunicationMgt.Codeunit.al`, every HTTP operation checks `IsTestInProgress`:

```al
if IsTestInProgress then
    CommunicationEvents.OnClientSend(HttpRequestMessage, HttpResponseMessage)
else
    if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then ...
```

Similarly for `Post`, `Get`, `GetContent`, and `GetAccessToken`:

```al
if IsTestInProgress then
    CommunicationEvents.OnClientPost(Url, Content, Response)
else
    Client.Post(Url, Content, Response);
```

**Events published by `Shpfy Communication Events`:**

| Event | Purpose |
|-------|---------|
| `OnClientSend` | Intercepts `HttpClient.Send()` -- the main GraphQL POST path |
| `OnGetContent` | Intercepts reading response content |
| `OnGetAccessToken` | Provides a fake access token |
| `OnClientPost` | Intercepts `HttpClient.Post()` (used by bulk operations for file uploads) |
| `OnClientGet` | Intercepts `HttpClient.Get()` (used by bulk operations for result download) |

**Test subscriber pattern:**

Legacy test subscribers are codeunits with `SingleInstance = true` and `EventSubscriberInstance = Manual`. They must be explicitly bound and unbound:

```al
codeunit 139593 "Shpfy Inventory Subscriber"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Communication Events", 'OnClientSend', '', true, false)]
    local procedure OnClientSend(HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage)
    begin
        MakeResponse(HttpRequestMessage, HttpResponseMessage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Communication Events", 'OnGetContent', '', true, false)]
    local procedure OnGetContent(HttpResponseMessage: HttpResponseMessage; var Response: Text)
    begin
        HttpResponseMessage.Content.ReadAs(Response);
    end;

    local procedure MakeResponse(HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage)
    begin
        // Inspect URI and GraphQL query to determine which response to return
        // Route based on URL suffix, GraphQL mutation/query text, etc.
    end;
}
```

Usage in a test:

```al
BindSubscription(InventorySubscriber);
// ... execute the code under test ...
UnbindSubscription(InventorySubscriber);
```

**Legacy subscriber examples:**

- `Inventory/ShpfyInventorySubscriber.Codeunit.al` -- retry scenario testing with call counting
- `Companies/ShpfyCompanyAPISubs.Codeunit.al` -- company location mutation mocking
- `Order Handling/ShpfyOrdersAPISubscriber.Codeunit.al` -- order transaction and company location responses from .resources/
- `Bulk Operations/Codeunits/ShpfyBulkOpSubscriber.Codeunit.al` -- multi-event subscriber (OnClientSend, OnClientPost, OnClientGet, OnGetContent)
- `Catalogs/ShpfyCatalogAPISubscribers.Codeunit.al` -- catalog creation mocking

### Why HttpClientHandler is preferred

- **Framework-level interception** -- does not depend on `if IsTestInProgress then` branching baked into production code
- **Declarative** -- `[HandlerFunctions('Name')]` on the test procedure makes the mock relationship explicit and visible
- **No event subscription management** -- no need for `BindSubscription` / `UnbindSubscription` calls or `SingleInstance` / `EventSubscriberInstance = Manual` boilerplate
- **Better test isolation** -- each test declares its own handler; no shared singleton state across tests
- **Enforces call count expectations** -- combined with `Library - Variable Storage`, you get explicit tracking of how many API calls were made
- **Blocks real requests** -- `TestHttpRequestPolicy = BlockOutboundRequests` guarantees no accidental outbound calls, even if the handler returns `true`

## Test initialization

All tests use `ShpfyInitializeTest.CreateShop()` (codeunit 139561 in `Base/ShpfyInitializeTest.Codeunit.al`) to create a fully configured test shop. This procedure:

- Creates a `Shpfy Shop` record with a random code and URL
- Sets up customer posting groups, general business posting groups, and VAT posting groups
- Creates customer and item templates with proper posting group assignments
- Creates VAT and general posting setups
- Creates a GL account for refunds and shipping charges
- Creates a dummy customer (with email `dummy@customer.com`) and a dummy item
- Calls `CommunicationMgt.SetTestInProgress(true)` by default (for legacy compatibility)
- Returns the created `Shop` record

**For HttpHandler tests**, the initialization procedure should look like this:

```al
local procedure Initialize()
var
    CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
    AccessToken: SecretText;
begin
    LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy My Test");
    ClearLastError();

    if IsInitialized then
        exit;

    LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy My Test");

    LibraryRandom.Init();
    IsInitialized := true;
    Commit();

    // Create the shop (this sets TestInProgress to true internally)
    Shop := InitializeTest.CreateShop();

    // Disable event-based mocking -- HttpClientHandler handles interception instead
    CommunicationMgt.SetTestInProgress(false);

    // Register a fake access token so the production code can authenticate
    AccessToken := LibraryRandom.RandText(20);
    InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

    LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy My Test");
end;
```

The key steps are:

1. Call `CreateShop()` to get a configured shop
2. Call `CommunicationMgt.SetTestInProgress(false)` to disable event-based interception
3. Call `InitializeTest.RegisterAccessTokenForShop()` to register a fake access token in the `Shpfy Registered Store New` table so the production code's `GetAccessToken()` succeeds

**Helper utilities on ShpfyInitializeTest:**

- `GetDummyCustomer()` -- returns the dummy customer record (filtered by email)
- `GetDummyItem()` -- returns the dummy item record (filtered by description)
- `VerifyRequestUrl(RequestPath, ShopUrl)` -- verifies that a request URL matches the expected Shopify GraphQL endpoint format (`{ShopUrl}/admin/api/{version}/graphql.json`)

## Test fixtures

Test fixtures are JSON response files stored in `.resources/` and declared in `app.json` via `"resourceFolders": [".resources"]`. They are organized into subdirectories that correspond to test modules:

| Directory | Files | Contents |
|-----------|-------|----------|
| Bulk Operations/ | 5 | Staged upload, bulk mutation, and bulk operation results |
| Catalogs/ | 9 | Catalog, market, price list, and product responses |
| Companies/ | 8 | Company create/update requests, location data, contact assignment |
| Invoices/ | 5 | Draft order creation/completion, fulfillment results |
| Locations/ | 1 | Fulfillment service update response |
| Logs/ | 5 | Customer, catalog, fulfillment, and metafield responses for log testing |
| Metafields/ | 1 | Customer metafield response |
| Order Handling/ | 2 | Order transaction and company location results |
| Products/ | 18 | Product details, variants, images, options, sales channels, creation responses |
| Shipping/ | 1 | Fulfillment order accept response |
| Staff/ | 1 | Staff member list response |

**Loading fixtures:**

Use `NavApp.GetResourceAsText()` for simple text loading:

```al
Response.Content.WriteFrom(NavApp.GetResourceAsText('Products/ProductDetailsResponse.txt', TextEncoding::UTF8));
```

Use `NavApp.GetResource()` with `InStream` for multi-line or streamed reading:

```al
var
    ResInStream: InStream;
    Body: Text;
begin
    NavApp.GetResource('Order Handling/OrderTransactionResult.txt', ResInStream, TextEncoding::UTF8);
    ResInStream.ReadText(Body);
    HttpResponseMessage.Content.WriteFrom(Body);
end;
```

**Parameterized fixtures:**

Many fixture files contain `{{Placeholder}}` tokens that are replaced at runtime with test-specific values:

```al
ResultTxt := NavApp.GetResourceAsText('Products/ProductVariantsResponse.txt', TextEncoding::UTF8);
ResultTxt := ResultTxt.Replace('{{ProductId}}', ProductId.ToText());
```

For `StrSubstNo`-style parameters (using `%1`, `%2`), some fixtures use the standard AL substitution:

```al
Body := StrSubstNo(Body, UploadUrlLbl);  // Replaces %1 in the resource text
```

## Writing a new test

Follow these steps to create a new test using the HttpClientHandler approach.

### 1. Create the test codeunit

```al
codeunit 139XXX "Shpfy My Feature Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        LibraryAssert: Codeunit "Library Assert";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
```

Required properties:

- `Subtype = Test` -- marks this as a test codeunit
- `TestPermissions = Disabled` -- tests run with full permissions
- `TestHttpRequestPolicy = BlockOutboundRequests` -- blocks all outbound HTTP and routes to handlers

### 2. Add the Initialize procedure

```al
    local procedure Initialize()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        AccessToken: SecretText;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy My Feature Test");
        ClearLastError();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy My Feature Test");
        LibraryRandom.Init();
        IsInitialized := true;
        Commit();

        Shop := InitializeTest.CreateShop();
        CommunicationMgt.SetTestInProgress(false);
        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy My Feature Test");
    end;
```

### 3. Create fixture files in .resources/

Add JSON response files under `.resources/MyFeature/`. For example, `.resources/MyFeature/QueryResponse.txt`:

```json
{"data":{"myQuery":{"id":"gid://shopify/MyObject/{{ObjectId}}","name":"Test Object"}}}
```

### 4. Write the HttpClientHandler procedure

```al
    [HttpClientHandler]
    internal procedure MyFeatureHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);  // Not a Shopify API call -- pass through

        Response.Content.WriteFrom(NavApp.GetResourceAsText('MyFeature/QueryResponse.txt', TextEncoding::UTF8));
        exit(false);  // Handled
    end;
```

To route different responses based on the request, read the request content and inspect the GraphQL query:

```al
    [HttpClientHandler]
    internal procedure MyFeatureHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RequestContent: Text;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        Request.Content.ReadAs(RequestContent);
        if RequestContent.Contains('myMutation') then
            Response.Content.WriteFrom(NavApp.GetResourceAsText('MyFeature/MutationResponse.txt', TextEncoding::UTF8))
        else
            Response.Content.WriteFrom(NavApp.GetResourceAsText('MyFeature/QueryResponse.txt', TextEncoding::UTF8));

        exit(false);
    end;
```

### 5. Write the test procedure

```al
    [Test]
    [HandlerFunctions('MyFeatureHttpHandler')]
    procedure TestMyFeatureDoesExpectedThing()
    begin
        Initialize();

        // [GIVEN] Set up test preconditions
        // ...

        // [WHEN] Execute the code under test
        // ...

        // [THEN] Verify results
        LibraryAssert.AreEqual(Expected, Actual, 'Description of what should match');
    end;
```

### 6. Track expected calls (optional)

If you need to verify the number of API calls or sequence multiple responses, add a `Library - Variable Storage` variable:

```al
    var
        OutboundHttpRequests: Codeunit "Library - Variable Storage";

    // In your test:
    OutboundHttpRequests.Clear();
    OutboundHttpRequests.Enqueue('First call');
    OutboundHttpRequests.Enqueue('Second call');

    // In your handler:
    case OutboundHttpRequests.Length() of
        2: // First call
            LoadResponse('FirstResponse.txt', Response);
        1: // Second call
            LoadResponse('SecondResponse.txt', Response);
        0:
            Error('More API calls than expected.');
    end;
    OutboundHttpRequests.DequeueText();
```

## Test modules

| Directory | AL files | What it tests |
|-----------|----------|---------------|
| Base/ | 5 | Shared initialization, shop creation, helper base codeunits |
| Bulk Operations/ | 4 | Bulk GraphQL mutations, staged uploads, operation polling |
| Catalogs/ | 5 | B2B catalog creation, price lists, publications, market catalogs |
| Companies/ | 10 | Company import/export, location updates, contact roles, tax registration |
| Customers/ | 7 | Customer sync, mapping by email/phone, template application |
| DisabledTests/ | 0 | Placeholder for temporarily disabled tests |
| Gift Cards/ | 1 | Gift card transaction import |
| GraphQL/ | 1 | GraphQL query construction and parameter handling |
| Helpers/ | 4 | Reusable test helpers (order handling, product init, test data builders) |
| Integration/ | 2 | End-to-end integration scenarios |
| Inventory/ | 7 | Inventory sync, quantity adjustments, retry logic for concurrent requests |
| Invoices/ | 2 | Draft order creation, invoice completion, fulfillment |
| Logs/ | 3 | Log entry creation, error detection, log page behavior |
| Metafields/ | 5 | Metafield definition sync, value mapping |
| Order Fulfillments/ | 1 | Fulfillment order creation and tracking |
| Order Handling/ | 4 | Order import, transaction mapping, company order handling |
| Order Refunds/ | 2 | Refund import and refund line processing |
| Order Risks/ | 1 | Order risk level assessment |
| Payments/ | 2 | Payment gateway resolution, transaction type mapping |
| Permission Sets/ | 1 | Permission set completeness validation |
| Products/ | 18 | Product import/export, variant sync, images, options, sales channels, item creation |
| Shipping/ | 3 | Shipping method mapping, fulfillment service sync |
| Staff/ | 1 | B2B staff member import, salesperson mapping |
| Translations/ | 0 | Translation sync (fixture files only, tests may be in Products/) |
| Webhooks/ | 2 | Webhook registration, notification processing |
