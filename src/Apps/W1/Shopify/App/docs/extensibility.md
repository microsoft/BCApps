# Extensibility

The Shopify Connector exposes extension points through two mechanisms: **integration events** (subscribable from any extension) and **interfaces** (implementable by adding enum values). Events follow a Before/After pattern where Before events carry an `IsHandled`/`Handled` boolean to let subscribers take over the default logic.

Important: many events are marked `[InternalEvent(false)]` rather than `[IntegrationEvent(false, false)]`. Internal events can only be subscribed to by extensions listed in `internalsVisibleTo` in app.json (currently only the test app). Check the attribute before planning your subscription.

## Customize order creation

The order processing pipeline in `Shpfy Process Order` (codeunit 30166) and `Shpfy Order Events` (codeunit 30162) offers the most extension points.

**Take over sales header creation entirely** -- subscribe to `OnBeforeCreateSalesHeader`. Set `Handled := true` to skip the default header creation. You receive the `ShopifyOrderHeader` and a `var SalesHeader` to populate yourself.

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnBeforeCreateSalesHeader', '', false, false)]
local procedure MyBeforeCreateSalesHeader(ShopifyOrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header"; var LastCreatedDocumentId: Guid; var Handled: Boolean)
```

**Modify the sales header after default creation** -- subscribe to `OnAfterCreateSalesHeader`:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnAfterCreateSalesHeader', '', false, false)]
local procedure MyAfterCreateSalesHeader(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")
```

**Control individual item line creation** -- subscribe to `OnBeforeCreateItemSalesLine` (set `Handled` to skip default logic) or `OnAfterCreateItemSalesLine` to modify the created line:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnBeforeCreateItemSalesLine', '', false, false)]
local procedure MyBeforeItemLine(ShopifyOrderHeader: Record "Shpfy Order Header"; ShopifyOrderLine: Record "Shpfy Order Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Handled: Boolean)

[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnAfterCreateItemSalesLine', '', false, false)]
local procedure MyAfterItemLine(ShopifyOrderHeader: Record "Shpfy Order Header"; ShopifyOrderLine: Record "Shpfy Order Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
```

**Control shipping cost line creation** -- same Before/After pattern with `OnBeforeCreateShippingCostSalesLine` and `OnAfterCreateShippingCostSalesLine`.

**Hook into the full process** -- `OnBeforeProcessSalesDocument` fires before any mapping or document creation. `OnAfterProcessSalesDocument` fires after the complete sales document (header + lines) is created and optionally released.

## Override customer mapping

Customer mapping runs during order import and can be overridden at two levels.

**Replace the entire mapping** -- subscribe to `OnBeforeMapCustomer` on `Shpfy Order Events` and set `Handled := true`. Populate `ShopifyOrderHeader."Sell-to Customer No."` yourself:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnBeforeMapCustomer', '', false, false)]
local procedure MyCustomerMapping(var ShopifyOrderHeader: Record "Shpfy Order Header"; var Handled: Boolean)
```

**Adjust after default mapping** -- subscribe to `OnAfterMapCustomer`:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnAfterMapCustomer', '', false, false)]
local procedure MyAfterMapCustomer(var ShopifyOrderHeader: Record "Shpfy Order Header")
```

**Plug in a custom mapping strategy** -- the `ICustomerMapping` interface (in `src/Customers/Interfaces/`) defines `DoMapping(CustomerId, JCustomerInfo, ShopCode)`. Add a new value to the `Shpfy Customer Mapping` enum and implement the interface. Your strategy will be selectable in the Shop card's `Customer Mapping Type` field.

**Override customer find/create** -- `Shpfy Customer Events` (codeunit 30115) has:

- `OnBeforeFindMapping` / `OnAfterFindMapping` -- control how Shopify customers map to BC customers
- `OnBeforeCreateCustomer` / `OnAfterCreateCustomer` -- intercept or modify BC customer creation from Shopify data
- `OnBeforeUpdateCustomer` / `OnAfterUpdateCustomer` -- control how Shopify updates flow to BC customer records
- `OnBeforeFindCustomerTemplate` / `OnAfterFindCustomerTemplate` -- override template selection for new customers

## Override company mapping (B2B)

Same pattern as customers. The `ICompanyMapping` interface supports custom strategies via the `Shpfy Company Mapping` enum. Events on `Shpfy Order Events`:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnBeforeMapCompany', '', false, false)]
local procedure MyCompanyMapping(var ShopifyOrderHeader: Record "Shpfy Order Header"; var Handled: Boolean)
```

The `IFindCompanyMapping` interface and `Shpfy Comp. Tax Id Mapping` enum provide pluggable strategies for finding existing BC customers by tax registration ID.

## Customize product sync

`Shpfy Product Events` (codeunit 30177) is the richest event codeunit. Key extension points organized by goal:

**Control how items map to products** -- `OnBeforeFindProductMapping` lets you override the SKU/barcode/item-no matching. Set `Handled := true` and populate the `Item` and `ItemVariant` records yourself.

**Customize product data sent to Shopify** -- `OnAfterCreateTempShopifyProduct` fires after the temp product/variant/tag records are built from a BC Item. Modify them before they are diffed and sent. `OnAfterFillInShopifyProductFields` fires after standard fields are populated on the Shopify product record. `OnBeforeSendCreateShopifyProduct` and `OnBeforeSendUpdateShopifyProduct` fire right before the API call.

**Override product body HTML** -- `OnBeforeCreateProductBodyHtml` (set `Handled`) or `OnAfterCreateProductBodyHtml` to modify the generated HTML description.

**Override product title** -- `OnBeforSetProductTitle` (set `Handled`) or `OnAfterSetProductTitle`.

**Override pricing** -- `OnBeforeCalculateUnitPrice` (set `Handled` to skip default price calculation) or `OnAfterCalculateUnitPrice` to adjust computed prices. Both receive `Item`, `VariantCode`, `UnitOfMeasure`, `Shop`, `Catalog`, and `var` price/compare-price/unit-cost parameters.

**Override barcode lookup** -- `OnBeforGetBarcode` / `OnAfterGetBarcode`.

**Control item creation from Shopify** -- `OnBeforeCreateItem` (set `Handled`) and `OnAfterCreateItem`. Same for variants: `OnBeforeCreateItemVariant` / `OnAfterCreateItemVariant`. `OnBeforeCreateItemVariantCode` lets you override variant code generation.

**Control item update from Shopify** -- `OnBeforeUpdateItem` / `OnAfterUpdateItem`, `OnBeforeUpdateItemVariant` / `OnAfterUpdateItemVariant`. `OnDoUpdateItemBeforeModify` fires after fields are set but before the Item.Modify, with a `var IsModifiedByEvent` flag.

**Override template selection** -- `OnBeforeFindItemTemplate` / `OnAfterFindItemTemplate`.

**Filter products for export** -- `OnAfterProductsToSynchronizeFiltersSet` fires after the product record set is filtered but before iteration. Add additional filters to exclude products.

## Custom stock calculation

The `Shpfy Stock Calculation` interface (in `src/Inventory/Interface/`) defines `GetStock(var Item): Decimal`. Implement this interface on a new enum value in the `Shpfy Stock Calculation` enum. Your implementation will be selectable per Shopify location in the `Shpfy Shop Location` table's `Stock Calculation` field.

There is also `Shpfy ExtendedStockCalculation` for extended scenarios, and `Shpfy IStock Available` for determining whether a variant can carry stock.

After stock calculation, the `OnAfterCalculationStock` event on `Shpfy Inventory Events` (codeunit 30196) fires:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Inventory Events", 'OnAfterCalculationStock', '', false, false)]
local procedure MyStockAdjustment(Item: Record Item; ShopifyShop: Record "Shpfy Shop"; LocationFilter: Text; var StockResult: Decimal)
```

## Customize shipping and fulfillment

`Shpfy Shipping Events` (codeunit 30192) provides:

- `OnBeforeRetrieveTrackingUrl` -- override tracking URL resolution for a sales shipment. Set `IsHandled := true` and populate `TrackingUrl`.
- `OnGetNotifyCustomer` -- control whether Shopify sends a shipping notification email per fulfillment.

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Shipping Events", 'OnBeforeRetrieveTrackingUrl', '', false, false)]
local procedure MyTrackingUrl(var SalesShipmentHeader: Record "Sales Shipment Header"; var TrackingUrl: Text; var IsHandled: Boolean)
```

## Customize shipment method and payment method mapping

`Shpfy Order Events` provides Before/After pairs for both:

- `OnBeforeMapShipmentMethod` / `OnAfterMapShipmentMethod`
- `OnBeforeMapShipmentAgent` / `OnAfterMapShipmentAgent`
- `OnBeforeMapPaymentMethod` / `OnAfterMapPaymentMethod`

Set `Handled := true` on the Before events and populate the mapping fields on the order header yourself.

## Customize refund/return processing

`Shpfy Refund Process Events` (codeunit 30247) provides:

- `OnBeforeCreateSalesHeader` / `OnAfterCreateSalesHeader` -- control credit memo header creation from refunds
- `OnBeforeCreateItemSalesLine` / `OnAfterCreateItemSalesLine` -- control credit memo line creation from refund lines
- `OnAfterProcessSalesDocument` -- hook after the complete credit memo is created
- `OnBeforeCreateSalesLinesFromRemainingAmount` -- control or skip the auto-balance line that catches remaining refund amounts not covered by item lines (set `SkipBalancing := true`)

The `IReturnRefundProcess` interface (in `src/Order Return Refund Processing/Interfaces/`) allows adding new processing strategies via the `Shpfy ReturnRefund ProcessType` enum.

## Customize metafield handling

The `IMetafieldType` interface validates metafield values and provides example values. The `IMetafieldOwnerType` interface resolves owner type to table ID and shop code. Both are extended by adding values to their respective enums.

## Override order import behavior

`OnAfterImportShopifyOrderHeader` fires after an order header is imported/updated from Shopify, with an `IsNew` flag. `OnAfterCreateShopifyOrderAndLines` fires after both header and lines are created.

These events let you reject orders (by modifying fields that will fail mapping), enrich order data from external sources, or trigger custom workflows.

## Intercept API communication

`Shpfy Communication Events` (codeunit 30200) provides internal events for HTTP interception -- `OnClientSend`, `OnClientPost`, `OnClientGet`, `OnGetAccessToken`, `OnGetContent`. These are `[InternalEvent]` so only available to apps in the `internalsVisibleTo` list (the test app). They are primarily used for test mocking.
