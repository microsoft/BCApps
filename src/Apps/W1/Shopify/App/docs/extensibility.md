# Extensibility

The Shopify Connector is designed for extension through two mechanisms: **integration events** with the IsHandled pattern (for overriding default behavior) and **interfaces** on enums (for adding new strategy implementations). Events are organized in domain-specific codeunits, each responsible for a single area of the connector.

## The IsHandled pattern

Most `OnBefore*` events include a `var Handled: Boolean` parameter. If a subscriber sets `Handled := true`, the connector skips its default logic for that operation. This lets you completely replace built-in behavior -- for example, taking over customer creation, item mapping, or price calculation -- without touching the connector's source code.

Some events use `[InternalEvent]` (only subscribable from within the same app/internals-visible-to apps) while others use `[IntegrationEvent]` (subscribable from any extension). Check the attribute on each event to know which is available to you.

## Customize product mapping

Events in `ShpfyProductEvents` (`src/Products/Codeunits/ShpfyProductEvents.Codeunit.al`, codeunit 30177).

**Override how Shopify products map to BC items**: Subscribe to `OnBeforeFindProductMapping`. You receive the `ShopifyProduct`, `ShopifyVariant`, and empty `Item`/`ItemVariant` records. Set the item/variant and mark `Handled := true` to bypass the default SKU-based lookup.

**Override item creation from Shopify**: `OnBeforeCreateItem` lets you take over BC Item creation when importing a Shopify product. `OnAfterCreateItem` lets you modify the newly created item. Similarly, `OnBeforeCreateItemVariant` / `OnAfterCreateItemVariant` control variant creation.

**Override item template selection**: `OnBeforeFindItemTemplate` / `OnAfterFindItemTemplate` let you control which BC item template is used when auto-creating items from Shopify.

**Modify product data before Shopify sync**: `OnBeforeSendCreateShopifyProduct` and `OnBeforeSendUpdateShopifyProduct` fire right before the GraphQL mutation is sent, letting you tweak product fields. `OnAfterCreateTempShopifyProduct` fires after the connector builds the temporary product/variant data from the BC item, letting you modify what will be synced.

**Customize product body HTML**: `OnBeforeCreateProductBodyHtml` (with `Handled`) lets you completely replace how the product description is generated. `OnAfterCreateProductBodyHtml` lets you append or modify it.

**Customize product title**: `OnBeforSetProductTitle` (with `Handled`) / `OnAfterSetProductTitle`.

**Control variant data**: `OnAfterFillInProductVariantData` and `OnAfterFillInProductVariantDataFromVariant` fire after the connector fills variant fields from the BC item, letting you customize variant attributes.

**Customize product filters for export**: `OnAfterProductsToSynchronizeFiltersSet` lets you add additional filters to the product record set before sync runs.

## Customize pricing

Events in `ShpfyProductEvents` (same codeunit as above).

**Override price calculation**: `OnBeforeCalculateUnitPrice` (with `Handled`) gives you the Item, variant code, UoM, shop, and catalog. Set `Price`, `ComparePrice`, and `UnitCost` and mark handled to bypass BC's standard price calculation. `OnAfterCalculateUnitPrice` lets you adjust prices after the default calculation runs.

## Customize order creation

Events in `ShpfyOrderEvents` (`src/Order handling/Codeunits/ShpfyOrderEvents.Codeunit.al`, codeunit 30162).

**Override sales header creation**: `OnBeforeCreateSalesHeader` (with `Handled`) lets you create the BC Sales Header yourself. `OnAfterCreateSalesHeader` lets you modify it after the connector creates it.

**Override sales line creation**: `OnBeforeCreateItemSalesLine` (with `Handled`) / `OnAfterCreateItemSalesLine` for item lines. `OnBeforeCreateShippingCostSalesLine` (with `Handled`) / `OnAfterCreateShippingCostSalesLine` for shipping charge lines.

**Override customer mapping during order import**: `OnBeforeMapCustomer` (with `Handled`) / `OnAfterMapCustomer`. Similarly, `OnBeforeMapCompany` / `OnAfterMapCompany` for B2B orders.

**Override shipment and payment mapping**: `OnBeforeMapShipmentMethod` / `OnAfterMapShipmentMethod`, `OnBeforeMapShipmentAgent` / `OnAfterMapShipmentAgent`, `OnBeforeMapPaymentMethod` / `OnAfterMapPaymentMethod` -- all with `Handled` on the Before events.

**Hook into the full document lifecycle**: `OnBeforeProcessSalesDocument` fires before the order header is processed into a BC document. `OnAfterProcessSalesDocument` fires after, giving you the created `SalesHeader` and the source `OrderHeader`.

**Override status conversions**: `OnBeforeConvertToFinancialStatus`, `OnBeforeConvertToFulfillmentStatus`, `OnBeforeConvertToOrderReturnStatus` let you handle custom or unexpected status values from Shopify.

**Adjust refund deductions**: `OnAfterConsiderRefundsInQuantityAndAmounts` fires after refund quantities are deducted from order lines, letting you adjust the final quantities.

**After order data is fetched**: `OnAfterImportShopifyOrderHeader` and `OnAfterCreateShopifyOrderAndLines` fire after the connector populates the staging tables, before document creation begins.

## Customize customer handling

Events in `ShpfyCustomerEvents` (`src/Customers/Codeunits/ShpfyCustomerEvents.Codeunit.al`, codeunit 30115).

**Override customer mapping**: `OnBeforeFindMapping` (with `Handled`) lets you implement your own BC customer lookup logic. `OnAfterFindMapping` lets you adjust the result.

**Override customer creation**: `OnBeforeCreateCustomer` (with `Handled`) / `OnAfterCreateCustomer`.

**Override customer template**: `OnBeforeFindCustomerTemplate` (with `Handled`) / `OnAfterFindCustomerTemplate`.

**Override customer updates**: `OnBeforeUpdateCustomer` (with `Handled`) / `OnAfterUpdateCustomer`.

**Customize data sent to Shopify**: `OnBeforeSendCreateShopifyCustomer` and `OnBeforeSendUpdateShopifyCustomer` fire right before the GraphQL mutations, letting you modify customer and address data.

## Customize stock calculation

Events in `ShpfyInventoryEvents` (`src/Inventory/Codeunits/ShpfyInventoryEvents.Codeunit.al`, codeunit 30196).

**Adjust calculated stock**: `OnAfterCalculationStock` fires after the connector calculates available stock for an item at a location. You can modify `StockResult` to add safety stock deductions, include external warehouse quantities, or apply any other adjustment.

For more fundamental changes to stock calculation, implement the `Shpfy Stock Calculation` interface (`src/Inventory/Interface/ShpfyStockCalculation.Interface.al`) on a new enum value and add it to the `Shpfy Stock Calculation` enum.

## Customize item updates from Shopify

Events in `ShpfyProductEvents`.

**Modify items before save**: `OnDoUpdateItemBeforeModify` fires just before the Item record is modified during a Shopify-to-BC sync. You can set additional fields on the Item and set `IsModifiedByEvent := true` to signal that you made changes. `OnDoUpdateItemVariantBeforeModify` does the same for item variants.

**Override the entire update**: `OnBeforeUpdateItem` / `OnAfterUpdateItem` and `OnBeforeUpdateItemVariant` / `OnAfterUpdateItemVariant` give full control over the update lifecycle.

## Interface-based strategies

Beyond events, the connector uses interfaces on enums for pluggable strategies. To add a new strategy:

1. Extend the relevant enum with a new value
2. Implement the corresponding interface on a codeunit
3. The Shop's configuration field will automatically include your new option

Key interfaces:

- `Shpfy ICustomer Mapping` -- customer matching strategy
- `Shpfy ICustomer Name` -- customer name formatting
- `Shpfy ICompany Mapping` -- B2B company matching
- `Shpfy Stock Calculation` -- inventory calculation method
- `Shpfy IStock Available` -- whether a product type can carry stock
- `Shpfy IMetafield Type` / `Shpfy IMetafield Owner Type` -- metafield type validation
- `Shpfy IDocument Source` / `Shpfy Extended IDocument Source` -- credit memo source document
- `Shpfy IReturn Refund Process` -- return/refund automation strategy
- `Shpfy IBulk Operation` -- bulk async mutation implementation
- `Shpfy IRemove Product Action` -- what happens when a product is removed or item is blocked
- `Shpfy ICreate Product Status Value` -- initial Shopify status for new products
- `Shpfy IGraphQL` -- GraphQL query/mutation definition

## Communication layer

Events in `ShpfyCommunicationEvents` (`src/Base/Codeunits/ShpfyCommunicationEvents.Codeunit.al`, codeunit 30200). These are `[InternalEvent]` -- only available to the connector's test app and `internalsVisibleTo` apps.

- `OnClientSend` -- intercept HTTP requests (used by tests to mock API calls)
- `OnGetAccessToken` -- override the access token (used by tests)
- `OnGetContent` -- override response content parsing (used by tests)
- `OnClientPost` / `OnClientGet` -- intercept POST/GET requests
