# Patterns

## Interface-based strategy

The connector uses AL's "enum implements interface" pattern extensively. An enum value on the Shop table selects the behavior at runtime. The pattern looks like this:

The `Shpfy Customer Mapping` enum declares `implements "Shpfy ICustomer Mapping"`. Each enum value (`"By EMail/Phone"`, `"By Billto Info"`, `"By Default Customer"`) maps to a codeunit that implements the interface. At runtime, `ShpfyCustomerMapping.DoMapping` does:

```
IMapping := LocalShop."Customer Mapping Type";
exit(IMapping.DoMapping(...));
```

This pattern appears in at least 10 places:

- **Customer mapping**: `Shpfy Customer Mapping` enum / `Shpfy ICustomer Mapping` interface -- `ShpfyCustByEmailPhone`, `ShpfyCustByBillto`, `ShpfyCustByDefaultCust`
- **Company mapping**: `Shpfy Company Mapping` enum / `Shpfy ICompany Mapping` -- `ShpfyCompByTaxId`, `ShpfyCompByEmailPhone`, `ShpfyCompByDefaultComp`
- **Name formatting**: `Shpfy Name Source` enum / `Shpfy ICustomer Name` -- `ShpfyNameisCompanyName`, `ShpfyNameisFirstLastName`, `ShpfyNameisLastFirstName`, `ShpfyNameisEmpty`
- **County resolution**: `Shpfy County Source` enum / `Shpfy ICounty From Json` -- `ShpfyCountyFromJsonCode`, `ShpfyCountyFromJsonName`
- **Stock calculation**: `Shpfy Stock Calculation` enum / `Shpfy IStock Available` -- `ShpfyCanHaveStock`, `ShpfyCanNotHaveStock`, `ShpfyFreeInventory`, `ShpfyBalanceToday`, `ShpfyDisabledValue`
- **Product status on create**: `Shpfy Cr. Prod. Status Value` enum / `Shpfy ICreateProductStatusValue` -- `ShpfyCreateProdStatusActive`, `ShpfyCreateProdStatusDraft`
- **Remove product action**: `Shpfy Remove Product Action` enum / `Shpfy IRemoveProductAction` -- `ShpfyRemoveProductDoNothing`, `ShpfyToArchivedProduct`, `ShpfyToDraftProduct`
- **Return/refund processing**: `Shpfy ReturnRefund ProcessType` enum / `Shpfy IReturnRefund Process`
- **Bulk operations**: `Shpfy Bulk Operation Type` enum / `Shpfy IBulk Operation` -- `ShpfyBulkUpdateProductPrice`, `ShpfyBulkUpdateProductImage`
- **Metafield types**: `Shpfy Metafield Type` enum / `Shpfy IMetafield Type` -- type validation and example values
- **Metafield owner types**: `Shpfy Metafield Owner Type` enum / `Shpfy IMetafield Owner Type` -- resolves table ID and shop code from owner

The key advantage: new strategies can be added by extending the enum from another extension without modifying connector code.

## GraphQL communication

All Shopify API calls go through `ShpfyCommunicationMgt` (30103), a `SingleInstance` codeunit. You must call `SetShop()` before any API call -- this sets the internal `Shop` record variable that provides the URL and access token.

The `ExecuteGraphQL` overloads accept either a raw query string or a `Shpfy GraphQL Type` enum value. The enum-based path calls `GraphQLQueries.GetQuery(GraphQLType, Parameters, ExpectedCost)`, which dispatches to one of ~130 `ShpfyGQL*` codeunits in `src/GraphQL/Codeunits/`. Each codeunit implements the `Shpfy IGraphQL` interface and returns the query string, parameter substitution, and expected cost.

Rate limiting is handled by `ShpfyGraphQLRateLimit` (also `SingleInstance`). After each response, `SetQueryCost` reads the `extensions.cost.throttleStatus` from the response JSON to track `RestoreRate` and `currentlyAvailable` tokens. Before each request, `WaitForRequestAvailable(ExpectedCost)` calculates the needed wait:

```
WaitTime = Max(ExpectedCost - LastAvailable, 0) / RestoreRate * 1000 - (CurrentDateTime - LastRequestedOn)
```

If the request still gets throttled (response contains `THROTTLED`), the main loop in `ExecuteGraphQL` retries:

```
while JResponse.AsObject().Contains('errors') and Format(JResponse).Contains('THROTTLED') do begin
    ShpfyGraphQLRateLimit.WaitForRequestAvailable(ExpectedCost);
    // re-execute query...
end;
```

For REST-level throttling (HTTP 429) and server errors (5xx), `EvaluateResponse` returns `Retry = true` with a 2-second or 10-second sleep, up to `MaxRetries` (default 5 for web requests, 3 for GraphQL).

The API version is a hardcoded label (`VersionTok: Label '2026-01'`). Version expiry is checked via Azure Key Vault on SaaS (with a 10-day cache in IsolatedStorage). If the version is expired, the connector raises an error and refuses all API calls.

Query length is capped at 50,000 characters (`GetGraphQueryLengthThreshold`). Product create mutations get a special error message mentioning marketing text and embedded images as likely causes.

## Bulk operations

For large batches (>100 items, per `GetBulkOperationThreshold`), the connector uses Shopify's Bulk Operation API instead of individual mutations. The flow:

1. The caller (e.g., `ShpfyProductExport`) accumulates mutation inputs as JSONL in a `TextBuilder` and request metadata in a `JsonArray`.
2. At the end, it calls `BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType, Jsonl, RequestData)`.
3. `SendBulkMutation` checks if another bulk operation of the same type is already running. If so, it returns `false` and the caller falls back to individual mutations.
4. If no conflict, `BulkOperationAPI.CreateBulkOperationMutation` uploads the JSONL via staged upload (GraphQL `createUploadUrl` mutation, then POST to the S3 URL), then calls `bulkOperationRunMutation`.
5. Shopify processes asynchronously. When done, it fires a webhook to the BC endpoint.
6. `ProcessBulkOperationNotification` handles the webhook, updating the `Shpfy Bulk Operation` record with status, result URL, and error code.

The `Shpfy IBulk Operation` interface provides `GetGraphQL()` (the mutation template), `GetType()` (mutation vs query), and `GetName()`. Current implementations: `ShpfyBulkUpdateProductPrice` and `ShpfyBulkUpdateProductImage`.

## Data capture and audit trail

The `Shpfy Data Capture` table (30114) stores a copy of every API response linked to the record it pertains to. The `Add()` method takes a table number, the record's SystemId, and the data (text, JsonToken, or JsonObject). It computes a hash via `Shpfy Hash.CalcHash()` and compares it to the hash of the last entry for the same `(Linked To Table, Linked To Id)`. If the hashes match, the insert is skipped entirely. This means the table only grows when data actually changes.

The data is stored as a UTF-8 Blob. `GetData()` reads it back through an InStream via `TypeHelper.ReadAsTextWithSeparator`.

Data capture is used during order import (both header and each line), product import, and other API-driven operations. Combined with the `Shpfy Log Entry` table (which stores request/response at the HTTP level), this gives two layers of auditability: the raw API traffic and the parsed data per business record.

## Error handling philosophy

The connector does not throw exceptions from its main processing loops. Instead, it wraps processing in `Codeunit.Run()` / TryFunction patterns and captures failures:

In `ShpfyProcessOrders.ProcessShopifyOrder`:
```
if not ProcessOrder.Run(ShopifyOrderHeader) then begin
    ShopifyOrderHeader."Has Error" := true;
    ShopifyOrderHeader."Error Message" := CopyStr(Format(Time) + ' ' + GetLastErrorText(), ...);
    ProcessOrder.CleanUpLastCreatedDocument();
end else begin
    ShopifyOrderHeader."Has Error" := false;
    ShopifyOrderHeader.Processed := true;
end;
ShopifyOrderHeader.Modify(true);
Commit();
```

The `Commit()` after each order is deliberate -- it ensures one failed order doesn't roll back successfully processed ones. The `CleanUpLastCreatedDocument()` call deletes the partially-created Sales document on failure, tracked via the `LastCreatedDocumentId` Guid variable.

In product import, item creation follows the same pattern:
```
Commit();
ItemCreated := CreateItem.Run(ShopifyVariant);
SetProductConflict(ShopifyProduct.Id, ItemCreated);
```

The `Commit()` before `CreateItem.Run()` isolates the transaction so that if item creation fails, only that item is rolled back.

The `Shpfy Skipped Record` table captures records that were skipped during sync with the reason (blocked item, missing mapping, etc.) for user review.

## Hash-based change detection

The `Shpfy Hash` codeunit produces integer hashes used throughout:

- `Product."Description Html Hash"` -- set in `SetDescriptionHtml()` to detect body changes without comparing potentially large HTML blobs
- `Product."Tags Hash"` -- `CalcTagsHash()` hashes the comma-separated tag string
- `Product."Image Hash"` / `Variant."Image Hash"` -- detect image changes
- `DataCapture."Hash No."` -- dedup identical API responses
- `OrderHeader."Line Items Redundancy Code"` -- hash of pipe-separated sorted line IDs for edit detection
- `Shop."Shop Id"` -- hash of the Shopify URL for stable identity

The hash is a standard integer hash, not cryptographic. It is used purely for equality comparison to avoid expensive string operations on potentially large texts.

## Dual-currency architecture

Every monetary amount on orders carries two values: shop currency and presentment currency. For example, `Shpfy Order Header` has `"Total Amount"` and `"Presentment Total Amount"`, `"VAT Amount"` and `"Presentment VAT Amount"`, etc. `Shpfy Order Line` has `"Unit Price"` and `"Presentment Unit Price"`, `"Discount Amount"` and `"Presentment Discount Amount"`.

The Shop's `Currency Handling` enum (`Shop Currency` or `Presentment Currency`) controls which value feeds into the BC Sales document. This is consistently applied in `ShpfyProcessOrder.CreateLinesFromShopifyOrder`:

```
case ShopifyShop."Currency Handling" of
    "Shop Currency":
        begin
            SalesLine.Validate("Unit Price", ShopifyOrderLine."Unit Price");
            SalesLine.Validate("Line Discount Amount", ShopifyOrderLine."Discount Amount");
        end;
    "Presentment Currency":
        begin
            SalesLine.Validate("Unit Price", ShopifyOrderLine."Presentment Unit Price");
            SalesLine.Validate("Line Discount Amount", ShopifyOrderLine."Presentment Discount Amount");
        end;
end;
```

Currency codes from Shopify (ISO codes) are translated to BC currency codes via `TranslateCurrencyCode`, which matches on `Currency."ISO Code"`. If the resulting code matches BC's LCY Code, it is cleared to empty (BC convention for local currency).

## Negative ID strategy for new records

New metafields that have not yet been synced to Shopify receive negative IDs. In `Shpfy Metafield.OnInsert`:

```
if Id = 0 then
    if Metafield.FindFirst() and (Metafield.Id < 0) then
        Id := Metafield.Id - 1
    else
        Id := -1;
```

This ensures new records are valid (non-zero primary key) and cannot collide with Shopify-assigned positive IDs. When the metafield is synced and Shopify returns a real ID, the connector updates it.

## Polymorphic relationships via ParentTableNo

Several tables use an integer `Parent Table No.` field to create polymorphic relationships. The `Shpfy Metafield` table stores metafields for products, variants, customers, and companies in a single table, discriminated by `Parent Table No.` (which holds the AL database table number, e.g., `Database::"Shpfy Product"`) and `Owner Id` (the Shopify entity ID).

The `Shpfy Tag` table follows the same pattern. `ShpfyTag.UpdateTags(Database::"Shpfy Product", Id, CommaSeparatedTags)` stores product tags, while the same table can hold tags for other entity types.

This avoids the need for separate metafield/tag tables per entity type, at the cost of losing strong foreign key relationships. The connector compensates by having OnDelete triggers that clean up related metafields and tags -- see `Shpfy Product.OnDelete` and `Shpfy Variant.OnDelete`.
