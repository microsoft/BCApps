# Order Refunds

This folder models Shopify refunds -- the financial side of returning money to a customer. A refund may or may not be associated with a return.

## Data model

`Shpfy Refund Header` (table 30142) carries the refund total (`"Total Refunded Amount"` / `"Pres. Tot. Refunded Amount"`), timestamps, a link to the parent order and optionally to a return, a note (blob), and error tracking fields (`"Has Processing Error"`, `"Last Error Description"`, `"Last Error Call Stack"` -- all blobs). The `"Is Processed"` field is a FlowField checking for a linked BC document in `Shpfy Doc. Link To Doc.`.

`Shpfy Refund Line` (table 30145) stores per-line-item refund data:

- Quantity and restock type (`Shpfy Restock Type`: NoRestock, Cancel, Return, LegacyRestock).
- Amounts in dual currencies: `Amount` / `"Presentment Amount"` (price), `"Subtotal Amount"` / `"Presentment Subtotal Amount"`, and `"Total Tax Amount"` / `"Presentment Total Tax Amount"`.
- `"Can Create Credit Memo"` -- a critical flag. It is true when the refund has a non-zero refunded amount or is linked to a return, or when the restock type is Return. Lines without this flag are the ones that were already deducted from the order during import (see `ConsiderRefundsInQuantityAndAmounts` in the order import logic) and should not produce duplicate credit memo lines.
- `"Location Id"` -- resolved from the refund JSON or, for return-based refunds, from the return's reverse fulfillment order locations.

`Shpfy Refund Shipping Line` (table in this folder) captures refunded shipping amounts with subtotal and tax in dual currencies.

## Import flow

`ShpfyRefundsAPI.GetRefunds` processes refund nodes from the order JSON. For each refund:

1. Fetches or updates the refund header via GraphQL, including currency translation through `ImportOrder.TranslateCurrencyCode`.
2. Collects return locations if the refund is linked to a return (delegates to `ReturnsAPI.GetReturnLocations`).
3. Fetches refund lines with pagination, setting `"Can Create Credit Memo"` based on `IsNonZeroOrReturnRefund`.
4. Fetches refund shipping lines.
5. Links refund transactions back to order transactions by setting `"Refund Id"` on matching `Shpfy Order Transaction` records.

## The "Can Create Credit Memo" flag

This is the key to understanding how refunds interact with orders. During order import, refund line quantities are subtracted from order line quantities. Those "absorbed" refund lines get `"Can Create Credit Memo" = false`. Only refund lines that represent actual returns or have a non-zero total refunded amount (i.e., money was actually sent back to the customer beyond what was absorbed into the order) get `true`. The credit memo creation code in Order Return Refund Processing skips refunds where any line has this flag set to false.
