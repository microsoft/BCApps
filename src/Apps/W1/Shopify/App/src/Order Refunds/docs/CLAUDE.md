# Order refunds

Imports refund data from Shopify into BC. Refunds represent the financial side of returns -- money refunded to the customer, potentially with shipping refund lines. This is separate from the Returns module which handles the physical goods.

## How it works

`ShpfyRefundsAPI.Codeunit.al` processes refunds by first fetching the header (with `totalRefundedSet` in both shop and presentment currencies), then the refund lines, then shipping refund lines. Each refund line records the quantity, restock type, amounts (with presentment equivalents), and a `Can Create Credit Memo` flag. The `Can Create Credit Memo` logic is key: a line is eligible only if the refund has a non-zero total amount or is linked to a return (`Return Id > 0`), or if the line's restock type is explicitly `Return`. This prevents creating credit memos for refunds that were already factored into the original order import as quantity reductions.

Refund lines need location information for inventory tracking. The code first checks the refund line's own `location.legacyResourceId` from Shopify. If that is zero (common when the refund was created from a return), it falls back to location data collected from the return's line items via `CollectReturnLocations`. The `UpdateTransactions` procedure stamps `Refund Id` onto related `ShpfyOrderTransaction` records so transactions can be linked back to their refund.

## Things to know

- The `RefundHeader` stores processing errors in BLOB fields (`Last Error Description`, `Last Error Call Stack`) and exposes `Has Processing Error` as a boolean, giving users visibility into failed credit memo creation attempts.
- `Is Processed` is a FlowField that checks `Shpfy Doc. Link To Doc.` for a linked credit memo -- this is how the UI knows whether a refund has already been handled.
- Refund headers skip re-import if the existing `Updated At` timestamp is newer than or equal to the incoming one, providing idempotent sync behavior.
- Shipping refund lines have their own table (`ShpfyRefundShippingLine`) with subtotal and tax amounts in both shop and presentment currencies.
- The `VerifyRefundCanCreateCreditMemo` procedure blocks credit memo creation if any line has `Can Create Credit Memo = false`, enforcing an all-or-nothing approach per refund.
