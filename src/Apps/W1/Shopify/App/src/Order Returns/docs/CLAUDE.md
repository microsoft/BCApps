# Order Returns

This folder models Shopify returns -- the customer's request to send items back. Returns are distinct from refunds: a return tracks what is being sent back, while a refund tracks the money.

## Data model

`Shpfy Return Header` (table 30147) holds the return metadata: status, total quantity, decline reason/note, and links to the parent order. FlowFields pull customer names and order numbers from the order header.

`Shpfy Return Line` (table 30141) has two types controlled by the `Type` field:

- **Default** -- a verified return line item linked to a fulfillment line and order line. Carries quantity, refundable/refunded quantities, weight, discounted total amounts (shop and presentment currency), return reason name/handle, and customer/return reason notes (stored as blobs).
- **Unverified** -- an `UnverifiedReturnLineItem` from Shopify's API, which lacks a fulfillment line link and instead carries a unit price and currency. These represent items not yet verified against a fulfillment.

## Return status lifecycle

The `Shpfy Return Status` enum models: Open, Closed, Cancelled, Requested, Declined. The `Shpfy Return Decline Reason` enum captures why a return was declined (e.g. FinalSale, ReturnPeriodEnded, Other).

## Import flow

`ShpfyReturnsAPI.GetReturns` is called during order import (if the return/refund processing mode requires it). It:

1. Iterates return nodes from the order JSON, fetching each return header via `GetReturnHeader`.
2. Resolves return locations by querying reverse fulfillment orders (`GetReturnLocations`). This determines which BC location the returned items go back to. If an item was restocked to multiple locations, the location is intentionally left unresolved (logged via telemetry).
3. Fetches return lines with pagination. Default lines are linked to fulfillment lines and order lines. Unverified lines lack these links.

## Relationship to refunds

A return can be associated with a refund through the refund header's `"Return Id"` field. The refund processing code uses return lines as a fallback source for credit memo lines when refund lines are absent (see Order Return Refund Processing).

## Location resolution

The `GetReturnLocations` procedure queries Shopify's `reverseFulfillmentOrders` to find where items were restocked. It collects disposition locations per order line ID. If dispositions disagree (restocked to multiple locations), the order line is excluded from the dictionary and the location remains unknown on the return/refund line.
