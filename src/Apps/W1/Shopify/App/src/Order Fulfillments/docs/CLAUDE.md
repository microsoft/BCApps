# Order Fulfillments

Part of [Shopify Connector](../../CLAUDE.md).

Tracks fulfillment orders and fulfillment lines, which represent assigned inventory locations and delivery methods for order lines.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy FulFillment Order Header (30143) | Fulfillment order header (assigned to location) |
| Table | Shpfy FulFillment Order Line (30144) | Line items within fulfillment order |
| Table | Shpfy Order Fulfillment (30144) | Completed fulfillments (shipments) |
| Table | Shpfy Fulfillment Line (30145) | Line items within completed fulfillment |
| Codeunit | Shpfy Order Fulfillments (30170) | Processes fulfillments and updates order status |
| Codeunit | Shpfy Fulfillment Orders API (30171) | GraphQL operations for fulfillment orders |
| Enum | Shpfy FulFillment Status (30140) | Status of fulfillment (Open, In Progress, Success, Cancelled, etc.) |
| Enum | Shpfy Order Fulfill. Status (30118) | Order-level fulfillment status (Unfulfilled, Partial, Fulfilled) |
| Enum | Shpfy Delivery Method Type (30141) | Shipping, local delivery, pickup, etc. |
| Enum | Shpfy FF Request Status (30142) | Fulfillment request status |
| Page | Shpfy Fulfillment Orders (30143) | List of fulfillment orders |
| Page | Shpfy Fulfillment Order Card (30144) | Details of fulfillment order |
| Page | Shpfy Order Fulfillments (30145) | List of completed fulfillments |
| Page | Shpfy Order Fulfillment (30146) | Details of completed fulfillment |

## Key concepts

- **Fulfillment order**: Shopify assigns each order line to a fulfillment location (warehouse, store, 3PL) based on inventory availability and business rules. Each assignment is a fulfillment order.
- **Fulfillment order line**: Individual line item within a fulfillment order, linking to the original order line and specifying quantity to fulfill from that location.
- **Fulfillment**: A completed shipment or handoff, recording tracking info, carrier, and shipment status. Multiple fulfillments can exist per order (split shipments).
- **Fulfillment line**: Line item within a fulfillment, recording quantity shipped.
- **Delivery method type**: Enum values Shipping, PickUp, Local, None, Retail track how the order will be delivered.
- **Status tracking**: Fulfillment orders have status (Open, In Progress, Closed), fulfillments have status (Success, Cancelled, Failure), orders have fulfillment status (Unfulfilled, Partial, Fulfilled).
- **Relationship to BC**: Fulfillment orders are imported during order import and used to set `Location Id` and `Delivery Method Type` on order lines. Fulfillments can be created from BC posted shipments.
