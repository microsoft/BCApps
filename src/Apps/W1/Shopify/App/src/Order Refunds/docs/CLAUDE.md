# Order Refunds

Stores Shopify refund data: header, item lines, and shipping refund lines. A refund can exist independently of a return (e.g., price adjustments, order cancellations) and carries dual-currency amounts plus structured error tracking for processing failures.

## How it works

`Shpfy Refund Header` (30142) stores the refund's total amounts, timestamps, and optional link to a return via `Return Id`. It tracks processing state through `Is Processed` (a FlowField checking Doc Link existence), `Has Processing Error`, and BLOB fields for `Last Error Description` and `Last Error Call Stack`. `Shpfy Refund Line` (30145) holds per-item data including quantity, restock type, amounts in shop and presentment currencies, and a `Can Create Credit Memo` flag. `Shpfy Refund Shipping Line` captures shipping-related refund amounts separately.

The `ShpfyRefundsAPI` codeunit imports refund data from Shopify's GraphQL API, while `ShpfyRefundEnumConvertor` handles enum value mapping. The `Shpfy Restock Type` enum (Legacy Restock, No Restock, Cancel, Return) determines how each refund line is processed into a BC credit memo line.

## Things to know

- Refund lines use FlowFields for `Item No.`, `Description`, `Variant Code`, `Gift Card`, and `Unit of Measure Code` that all look up from the original `Shpfy Order Line` via the `Order Line Id` field -- the refund line itself does not store product information.
- The `Restock Type` is critical for credit memo creation: `Return` and `Legacy Restock` create item lines, `Cancel` creates a G/L account line using the shop's `Refund Account`, and `No Restock` uses `Refund Acc. non-restock Items`.
- Error tracking stores both the error description and full AL call stack as BLOBs on the refund header, enabling debugging without reproducing the failure. The `Shpfy Extended IDocument Source` interface writes the call stack.
- The `Can Create Credit Memo` flag on refund lines (field 13) acts as a gate: if any line has this set to false, the auto-create credit memo strategy skips the entire refund.
- Cascading delete on the refund header removes all child refund lines, refund shipping lines, and associated data capture records.
