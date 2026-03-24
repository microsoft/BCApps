# Extensibility

All events are published by `ShpfyOrderEvents` (codeunit 30162). Events marked `[InternalEvent]` use the Handled pattern for complete override; events marked `[IntegrationEvent]` are observe-only (before/after pairs).

## Customer and company mapping

- `OnBeforeMapCustomer` / `OnAfterMapCustomer` -- wrap the customer resolution for B2C orders. Setting `Handled = true` on the Before event skips the built-in mapping entirely, letting you assign `Sell-to Customer No.` and `Bill-to Customer No.` yourself.
- `OnBeforeMapCompany` / `OnAfterMapCompany` -- same pattern for B2B orders.

## Shipping and payment mapping

- `OnBeforeMapShipmentMethod` / `OnAfterMapShipmentMethod` -- override how the shipping charge title maps to a BC shipment method code.
- `OnBeforeMapShipmentAgent` / `OnAfterMapShipmentAgent` -- override shipping agent resolution.
- `OnBeforeMapPaymentMethod` / `OnAfterMapPaymentMethod` -- override how order transactions map to a BC payment method code.

## Sales document creation

- `OnBeforeCreateSalesHeader` / `OnAfterCreateSalesHeader` -- the Before event exposes the Handled pattern via the `IsHandled` parameter. Set it to true to create the Sales Header yourself (you must also set `LastCreatedDocumentId` so cleanup works on failure). The After event lets you modify the header after the built-in logic runs.
- `OnBeforeProcessSalesDocument` / `OnAfterProcessSalesDocument` -- wrap the entire processing pipeline (mapping + document creation + release). The After event receives both the Sales Header and the Order Header.

## Sales line creation

- `OnBeforeCreateItemSalesLine` / `OnAfterCreateItemSalesLine` -- wrap the creation of each item/tip/gift card sales line. The Before event supports the Handled pattern. When handled, the built-in line creation is skipped but the After event still fires. Use this to customize pricing, account assignment, or to skip specific lines entirely.
- `OnBeforeCreateShippingCostSalesLine` / `OnAfterCreateShippingCostSalesLine` -- wrap the creation of each shipping charge line. Also supports the Handled pattern.

## Import and status conversion

- `OnAfterImportShopifyOrderHeader` -- fires after the order header JSON is parsed and the header record is updated. The `IsNew` parameter indicates first import vs. update.
- `OnAfterCreateShopifyOrderAndLines` -- fires after both header and lines are fully imported and related records (tax lines, attributes, fulfillments) are created.
- `OnAfterConsiderRefundsInQuantityAndAmounts` -- fires after each order line's quantity and the header's amounts are adjusted for refunds.
- `OnBeforeConvertToFinancialStatus`, `OnBeforeConvertToFulfillmentStatus`, `OnBeforeConvertToOrderReturnStatus` -- internal events that let you override enum conversion from Shopify's status strings, useful when Shopify adds new status values before the enum is updated.
