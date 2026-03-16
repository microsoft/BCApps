# Order refunds

Refund data model for Shopify refunds. This module stores the financial side of the return/refund flow -- how much money is being refunded, for which line items, and any shipping cost refunds. It is separate from Order Returns (the physical-return side) and Order Return Refund Processing (which creates BC documents).

## How it works

The data model is `Shpfy Refund Header` (table 30142) -> `Shpfy Refund Line` (table 30145) + `Shpfy Refund Shipping Line` (table 30162). A refund header links to its parent order via `Order Id` and optionally to a return via `Return Id`. It stores `Total Refunded Amount` in shop currency and `Pres. Tot. Refunded Amount` in presentment currency, plus timestamps, a note blob, and currency codes. The `Is Processed` FlowField checks `DocLinkToDoc` for the existence of a linked Shopify Shop Refund document.

Each refund line links to the original order line via `Order Line Id` and carries quantity, restock type (`ShpfyRestockType.Enum.al`: Return, Cancel, No Restock, Legacy Restock), a restocked boolean, and amounts in both shop and presentment currency (amount, subtotal, total tax). FlowFields resolve `Item No.`, `Description`, `Variant Code`, `Gift Card`, and `Unit of Measure Code` from the linked order line. The `Can Create Credit Memo` boolean flag controls whether the processing module should include this line.

Refund shipping lines are separate records with their own subtotal and tax amounts in both currencies, identified by title. `ShpfyRefundsAPI.Codeunit.al` handles import from the Shopify API, and `ShpfyRefundEnumConvertor.Codeunit.al` converts API strings to enum values.

Error handling is built into the header: `Has Processing Error` is a boolean flag, and `Last Error Description` / `Last Error Call Stack` are blobs that store the full error details from failed credit memo creation attempts.

## Things to know

- A refund can exist without a return (`Return Id = 0`) -- for example, a merchant may issue a refund without requiring the customer to send anything back.
- The `Restock Type` on refund lines drives different sales line creation in the processing module: `No Restock` uses a G/L account instead of an item, `Cancel` uses the refund account.
- Refund lines resolve their currency code by traversing `Order Line` -> `Order Header`, not from the refund header directly, because the order carries the shop currency.
- Presentment currency on refund lines comes from the refund header's `Presentment Currency Code` field.
- The `Location Id` on refund lines maps to a Shopify location, used by the processing module to set the BC return location on credit memo lines.
- Error blobs are set via `SetLastErrorDescription` which also toggles the `Has Processing Error` flag -- clearing the error text clears the flag.
- Data captures are stored and cleaned up on delete for headers, lines, and shipping lines.
