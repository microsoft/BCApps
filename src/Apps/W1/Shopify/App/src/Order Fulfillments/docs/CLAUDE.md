# Order Fulfillments

This folder models two distinct Shopify concepts that are easy to confuse: **fulfillment orders** (what needs to be shipped) and **fulfillments** (what has been shipped).

## Fulfillment orders vs fulfillments

A **fulfillment order** (`Shpfy FulFillment Order Header` / `Line`) represents Shopify's instruction to ship specific line items from a specific location. It has a status (OPEN, CLOSED, etc.) and a request status tracking the fulfillment service handshake. A single Shopify order can have multiple fulfillment orders -- one per location or fulfillment service.

A **fulfillment** (`Shpfy Order Fulfillment` / `Shpfy Fulfillment Line`) represents an actual shipment that was created. It carries tracking info (number, URL, company) and a status (Success, Cancelled, etc.). Fulfillments are imported during order import via `ShpfyOrderFulfillments.GetFulfillments`.

## Delivery method types

The `Shpfy Delivery Method Type` enum covers: Local, None, Pick Up, Retail, Shipping, Pickup Point. This is stored on the fulfillment order header and propagated to fulfillment order lines and then to order lines.

## Request status lifecycle

The `Shpfy FF Request Status` enum models the fulfillment service protocol: Unsubmitted -> Submitted -> Accepted (or Rejected). Cancellation flows through Cancellation Requested -> Cancellation Accepted/Rejected. The connector auto-accepts pending fulfillment requests during shipment export when the fulfillment order is OPEN with status SUBMITTED (see `AcceptPendingFulfillmentRequests` in `ShpfyExportShipments`).

## How BC shipments become Shopify fulfillments

`ShpfyFulfillmentOrdersAPI.GetShopifyFulfillmentOrdersFromShopifyOrder` fetches fulfillment orders for an order during import. When BC posts a Sales Shipment, `ShpfyExportShipments.CreateShopifyFulfillment` matches shipment lines to fulfillment order lines (by `Line Item Id`), builds a `fulfillmentCreate` GraphQL mutation, and sends it. The resulting fulfillment is imported back and stored. If the shop has a registered fulfillment service (auto-registered on first outgoing request), the connector also queries for assigned fulfillment orders via `GetAssignedFulfillmentOrders`.

## Key files

- `ShpfyFulfillmentOrdersAPI.Codeunit.al` -- GraphQL operations for fulfillment orders, including registration, extraction, and acceptance.
- `ShpfyOrderFulfillments.Codeunit.al` -- imports fulfillment data (tracking, lines, gift card detection).
- `ShpfyFulFillmentOrderHeader.Table.al` / `ShpfyFulFillmentOrderLine.Table.al` -- fulfillment order data model.
- `ShpfyOrderFulfillment.Table.al` / `ShpfyFulfillmentLine.Table.al` -- actual fulfillment data model.
