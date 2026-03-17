# Order fulfillments

Imports and tracks Shopify fulfillment data (both fulfillments and fulfillment orders) for synced orders, including line items, tracking info, and gift card detection.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyOrderFulfillments.Codeunit.al`, `Codeunits/ShpfyFulfillmentOrdersAPI.Codeunit.al`
- **Key patterns**: GraphQL paginated import, RecordRef field mapping, DataCapture snapshots

## Structure

- Codeunits (2): OrderFulfillments (fulfillment import), FulfillmentOrdersAPI (fulfillment order import)
- Tables (4): FulFillmentOrderHeader, FulFillmentOrderLine, FulfillmentLine, OrderFulfillment
- Enums (4): DeliveryMethodType, FFRequestStatus, FulFillmentStatus, OrderFulfillStatus
- Pages (6): FulFillmentOrders, FulfillmentOrderCard, FulfillmentOrderLines, OrderFulfillment, OrderFulfillmentLines, OrderFulfillments

## Key concepts

- `OrderFulfillments.GetFulfillments` fetches all fulfillments for an order and imports their line items, paging through `fulfillmentLineItems` using cursor-based pagination
- Each fulfillment stores consolidated tracking info (numbers, URLs, companies) from potentially multiple tracking entries
- If a fulfillment contains gift card lines, the gift card import is triggered automatically after fulfillment import
- Fulfillment orders (`FulFillmentOrderHeader/Line`) represent the pre-fulfillment state -- they track request status (SUBMITTED, ACCEPTED), remaining quantities, and the assigned Shopify location
- The fulfillment order line's `Remaining Quantity` and `Quantity to Fulfill` are used during shipment export to match BC shipment lines to Shopify fulfillment order lines
