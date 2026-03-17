# Patterns

## GraphQL gateway pattern

The connector communicates with Shopify exclusively through GraphQL. The `Shpfy IGraphQL` interface (in `src/GraphQL/Interfaces/`) defines two methods:

- `GetGraphQL(): Text` -- returns the JSON-encoded GraphQL query or mutation string
- `GetExpectedCost(): Integer` -- returns the estimated query cost for rate limit budgeting

There are 145+ codeunits in `src/GraphQL/Codeunits/` that implement this interface, each encapsulating a single query or mutation. For example, `Shpfy GQL CustomerIds` (codeunit 30128):

```al
codeunit 30128 "Shpfy GQL CustomerIds" implements "Shpfy IGraphQL"
{
    internal procedure GetGraphQL(): Text
    begin
        exit('{"query":"{customers(first:200, query: \"updated_at:>''{{LastSync}}''\"){pageInfo{hasNextPage} edges{cursor node{id updatedAt}}}}"}');
    end;

    internal procedure GetExpectedCost(): Integer
    begin
        exit(12);
    end;
}
```

The `Shpfy GraphQL Queries` codeunit (30xxx) acts as a registry, mapping enum values to interface implementations. Callers never instantiate query codeunits directly -- they go through the communication layer which handles rate limiting, retry, and logging.

`Shpfy GraphQL Rate Limit` manages Shopify's cost-based rate limiting. Each query declares its expected cost, and the rate limiter ensures the bucket has sufficient capacity before sending.

Naming convention: query codeunits are prefixed `ShpfyGQL` followed by a descriptive name. Paginated queries come in pairs: `ShpfyGQLCustomerIds` for the first page and `ShpfyGQLNextCustomerIds` for subsequent pages (using cursor-based pagination).

This pattern has clear benefits -- each query is independently versioned and testable. The downside is the sheer number of codeunits (145+), which can be overwhelming when searching for a specific query.

## Timestamp-based incremental sync

Every entity sync follows the same pattern to avoid re-processing unchanged records.

The connector fetches a list of `(Id, UpdatedAt)` pairs from Shopify. For each ID, it compares two timestamps:

```al
if ((Product."Updated At" < UpdatedAt) and (Product."Last Updated by BC" < UpdatedAt)) then
    // needs import
```

- `Updated At` -- when Shopify last changed the record. If the local copy is older, Shopify has changes to import.
- `Last Updated by BC` -- when BC last pushed an update. If this is recent, the Shopify change was caused by BC itself, so skip it.

Both conditions must be true to trigger an import. This prevents the "ping-pong" problem where BC exports a change, Shopify bumps its `Updated At`, and the next sync imports the same change back.

The `Last Updated by BC` field exists on `Shpfy Product`, `Shpfy Variant`, `Shpfy Customer`, `Shpfy Company`, and `Shpfy Metafield`.

Sync start times are tracked in `Shpfy Synchronization Info` via `Shop.GetLastSyncTime()` / `Shop.SetLastSyncTime()`. Order sync uses `Shop Id` (integer hash of URL) as the key rather than `Shop Code`, so renaming a shop doesn't reset the sync watermark.

## Temporary record batching with error isolation

All bulk import operations use the same structure:

```al
// Phase 1: Build temporary record set
Clear(TempRecord);
if TempRecord.FindSet(false) then begin
    repeat
        ImportCodeunit.SetRecord(TempRecord);
        Commit();                    // save prior successful work
        ClearLastError();            // reset error state
        if not ImportCodeunit.Run() then  // Run() catches runtime errors
            ErrMsg := GetLastErrorText;   // capture but continue
    until TempRecord.Next() = 0;
end;
```

This pattern appears in `Shpfy Sync Products.ImportProductsFromShopify`, `Shpfy Sync Customers.ImportCustomersFromShopify`, `Shpfy Sync Companies`, and `Shpfy Process Orders.ProcessShopifyOrders`.

The `Commit()` before `Run()` is essential -- without it, a failure in `Run()` would roll back all prior successful imports in the same transaction. The `ClearLastError()` resets the error state so `GetLastErrorText` correctly reflects the current iteration's error.

The temporary record set acts as a filter -- only IDs that need processing are included. This keeps the actual API/database work inside the `Run()` call, where failures are isolated.

Gotcha: the `Commit()` means partial progress is saved even if the entire batch fails partway through. There is no rollback-the-whole-batch option. Each record either succeeds permanently or fails with an error message.

## Event-based mapping with fallback (IsHandled pattern)

The connector uses the standard BC "IsHandled" pattern for extensible mapping. The general structure:

```al
OnBeforeMapCustomer(ShopifyOrderHeader, Handled);
if not Handled then begin
    // default mapping logic
end;
OnAfterMapCustomer(ShopifyOrderHeader);
```

The Before event lets subscribers set `Handled := true` to completely replace the default logic. The After event lets subscribers adjust the result. This pattern is used for:

- Customer mapping (`OnBeforeMapCustomer` / `OnAfterMapCustomer`)
- Company mapping (`OnBeforeMapCompany` / `OnAfterMapCompany`)
- Shipment method mapping (`OnBeforeMapShipmentMethod` / `OnAfterMapShipmentMethod`)
- Payment method mapping (`OnBeforeMapPaymentMethod` / `OnAfterMapPaymentMethod`)
- Sales header creation (`OnBeforeCreateSalesHeader` with `var Handled`)
- Sales line creation (`OnBeforeCreateItemSalesLine` with `var Handled`)
- Item creation from Shopify (`OnBeforeCreateItem` with `var Handled`)
- Product body HTML generation (`OnBeforeCreateProductBodyHtml` with `var Handled`)

When subscribing to Before events, always set `Handled` explicitly. If you don't set it to `true`, the default logic runs AND your modifications may be overwritten.

## Multi-strategy factory pattern

Several domains use AL interfaces as strategy patterns, with the Shop table holding an enum that selects the implementation.

**Customer mapping**: `ICustomerMapping` interface, `Shpfy Customer Mapping` enum on `Shop."Customer Mapping Type"`. Implementations handle different matching strategies (by email, by phone, by name+address).

**Company mapping**: `ICompanyMapping` interface, `Shpfy Company Mapping` enum on `Shop."Company Mapping Type"`.

**Stock calculation**: `Shpfy Stock Calculation` interface, `Shpfy Stock Calculation` enum on `ShpfyShopLocation."Stock Calculation"`. Each Shopify location can use a different stock calculation method.

**Product status on creation**: `ICreateProductStatusValue` interface, `Shpfy Cr. Prod. Status Value` enum on `Shop."Status for Created Products"`.

**Action for removed products**: `IRemoveProductAction` interface, `Shpfy Remove Product Action` enum on `Shop."Action for Removed Products"`. Called in `Shpfy Product.OnDelete()`.

**Return/refund processing**: `IReturnRefundProcess` interface, `Shpfy ReturnRefund ProcessType` enum on `Shop."Return and Refund Process"`.

**Metafield types**: `IMetafieldType` interface, `Shpfy Metafield Type` enum on `Shpfy Metafield."Type"`. Validates values and provides examples.

**Metafield owner types**: `IMetafieldOwnerType` interface, `Shpfy Metafield Owner Type` enum on `Shpfy Metafield."Owner Type"`. Resolves table IDs and shop codes.

**Customer name formatting**: `ICustomerName` interface for different name composition strategies (FirstAndLastName, CompanyName, etc.).

**County resolution**: `ICounty` / `ICountyFromJson` interfaces for parsing county/province data from Shopify responses.

**Document navigation**: `IOpenBCDocument` / `IOpenShopifyDocument` interfaces on the `Shpfy Doc. Link To Doc.` table's enum fields.

To add a new strategy: extend the relevant enum, implement the interface on your enum value, and the Shop card's dropdown will automatically include your option.

## Bulk operations async pattern

For large data sets, the connector uses Shopify's bulk operations API. The flow:

1. Submit a bulk operation mutation via `GQL BulkOpMutation`
2. Register a webhook to receive completion notification (`Shpfy Webhooks Mgt.`)
3. Store the operation in `Shpfy Bulk Operation` table with status tracking
4. When the webhook fires, download the JSONL result file and process it

The `IBulkOperation` interface (in `src/Bulk Operations/Interfaces/`) defines the contract for bulk operation handlers. The Shop table stores `Bulk Operation Webhook Id` and `Bulk Operation Webhook User Id` for the webhook context.

This pattern is used for large product catalog syncs where paginated GraphQL queries would be too slow or hit rate limits.

## SystemId linking

The connector links Shopify records to BC records using `SystemId` (Guid) fields rather than `No.` (Code) fields. Examples:

- `Shpfy Product."Item SystemId"` -> `Item.SystemId`
- `Shpfy Variant."Item SystemId"` -> `Item.SystemId`
- `Shpfy Variant."Item Variant SystemId"` -> `Item Variant.SystemId`
- `Shpfy Customer."Customer SystemId"` -> `Customer.SystemId`
- `Shpfy Company."Customer SystemId"` -> `Customer.SystemId`

Each table also has a FlowField (e.g., `"Item No."`, `"Customer No."`) that resolves the human-readable code via CalcFormula lookup. This means renumbering a BC entity does not break the Shopify link, since SystemId is immutable.

The tradeoff: you cannot just look at the table data and know which Item an entry points to without calculating the FlowField.

## Negative ID allocation for new records

When creating metafields locally in BC (before syncing to Shopify), the `Shpfy Metafield.OnInsert` trigger assigns negative IDs:

```al
if Id = 0 then
    if Metafield.FindFirst() and (Metafield.Id < 0) then
        Id := Metafield.Id - 1
    else
        Id := -1;
```

This avoids collision with Shopify-assigned positive IDs. When the metafield is synced to Shopify, the real positive ID replaces the negative one.

## Polymorphic tag table

`Shpfy Tag` (table 30104) uses `Parent Table No.` (Integer) + `Parent Id` (BigInteger) to attach tags to any entity. The table is shared across products, orders, and customers. The `UpdateTags` procedure takes a comma-separated string, deletes all existing tags for the parent, and re-inserts them. There is no incremental diff -- it's always a full replace.

The OnInsert trigger enforces a maximum of 250 tags per parent (Shopify's limit).

## Dual-currency branching

Throughout the order processing pipeline, monetary values branch on `Shop."Currency Handling"`:

```al
case ShopifyShop."Currency Handling" of
    Enum::"Shpfy Currency Handling"::"Shop Currency":
        SalesLine.Validate("Unit Price", ShopifyOrderLine."Unit Price");
    Enum::"Shpfy Currency Handling"::"Presentment Currency":
        SalesLine.Validate("Unit Price", ShopifyOrderLine."Presentment Unit Price");
end;
```

This pattern repeats for every monetary field assignment -- line prices, discounts, shipping charges, rounding amounts, refund totals. It appears in `CreateHeaderFromShopifyOrder`, `CreateLinesFromShopifyOrder`, `CreateRoundingLine`, and the refund processing codeunits.

The order header stamps `Processed Currency Handling` after processing, so display logic on already-processed orders uses the setting that was active at processing time, not the current shop setting.

## Legacy patterns to avoid

**Mixed-responsibility sync codeunits**: Some older sync codeunits (e.g., the original product sync flow) handle both API communication and data transformation in the same codeunit. Newer code separates API calls (in dedicated codeunits) from import/export logic.

**Large case statements in tax area lookup**: The tax area resolution (`Shpfy Order Mgt.FindTaxArea`) uses a priority-based lookup controlled by `Shop."Tax Area Priority"` that cascades through city, county, state, and country combinations. The logic involves nested conditional checks that are hard to extend. If you need custom tax area logic, override it via events rather than trying to understand the cascade.

**Repeated Commit/ClearLastError without abstraction**: The `Commit(); ClearLastError(); if not Codeunit.Run() then ErrMsg := GetLastErrorText` pattern is duplicated verbatim in every sync codeunit. There is no shared helper -- each sync codeunit reimplements the same loop structure. When adding new sync logic, copy the pattern from an existing sync codeunit (e.g., `Shpfy Sync Products.ImportProductsFromShopify`) to ensure consistency.

**Delete-all/re-insert for tags**: `Shpfy Tag.UpdateTags` deletes all tags and reinserts them on every update. This works but generates unnecessary delete/insert operations for unchanged tags. If you're debugging tag-related performance issues, this is a likely contributor.

**Blob fields for error details**: Refund headers use Blob fields (`Last Error Description`, `Last Error Call Stack`) for error storage, requiring stream-based read/write helpers. Order headers use `Text[2048]` for `Error Message`. The inconsistency means different error retrieval patterns depending on which entity you're looking at.
