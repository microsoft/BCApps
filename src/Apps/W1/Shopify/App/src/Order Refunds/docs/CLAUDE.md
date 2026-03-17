# Order Refunds

Shopify refund data -- the money going back to the customer. Refunds are separate from returns (physical goods); a refund can exist without a return (appeasement refund) or be linked to one via `Return Id`. The actual BC credit memo creation lives in `Order Return Refund Processing` -- this area just holds the data model and API import logic.

## How it works

`ShpfyRefundsAPI.Codeunit.al` imports refund headers, refund lines, and refund shipping lines from Shopify. The `Shpfy Refund Header` carries dual-currency totals (`Total Refunded Amount` and `Pres. Tot. Refunded Amount`), an optional `Return Id` link, and error tracking via blob fields (`Last Error Description`, `Last Error Call Stack`). The `Is Processed` FlowField checks the `Shpfy Doc. Link To Doc.` table for a matching refund document link, which is how the system knows whether a BC credit memo already exists.

Refund lines (`ShpfyRefundLine.Table.al`) carry per-line amounts at several granularities: `Amount` (unit price), `Subtotal Amount` (quantity times price after discounts), and `Total Tax Amount`, all in both shop and presentment currencies. The `Restock Type` enum (`no_restock`, `cancel`, `return`, `legacy_restock`) controls how `Order Return Refund Processing` creates the credit memo line -- this is one of the most important fields for understanding refund behavior. Refund shipping lines (`ShpfyRefundShippingLine.Table.al`) are separate records that capture shipping cost refunds with their own subtotal and tax amounts.

## Things to know

- `Has Processing Error` is a regular boolean field (not a FlowField) that gets set to true/false inside `SetLastErrorDescription` based on whether the description text is non-empty.
- The `Can Create Credit Memo` boolean on refund lines gates processing -- when false, `ShpfyRetRefProcCrMemo` skips the entire refund. This field is set during import based on Shopify data.
- Many FlowFields on the header (`Sell-to Customer No.`, `Bill-to Customer Name`, `Shopify Order No.`, `Return No.`) resolve through the parent order or linked return, so querying these requires the related records to exist.
- The header's `CheckCanCreateDocument` method queries the document link table directly, providing a public-facing check independent of the `Is Processed` FlowField.
- The `Note` field is a blob with Get/Set procedures, consistent with the pattern used across returns and other areas for storing variable-length text from Shopify.
