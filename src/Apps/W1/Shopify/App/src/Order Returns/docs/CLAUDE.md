# Order returns

Return data model for Shopify returns. This module stores the physical-return side of the return/refund flow -- which items a customer is sending back, why, and in what quantities. It is separate from Order Refunds (the financial side) and Order Return Refund Processing (which creates BC documents from either).

## How it works

The data model is `Shpfy Return Header` (table 30147) -> `Shpfy Return Line` (table 30141). A return header links to its parent order via `Order Id`, carries a `Return No.`, status (Open, Closed, Requested, Declined via `ShpfyReturnStatus.Enum.al`), total quantity, and an optional decline reason with a decline note blob. FlowFields pull customer names and the Shopify order number from the order header.

Each return line links back to the original order via `Fulfillment Line Id` and `Order Line Id`, so the system knows exactly which fulfilled item is being returned. Lines carry quantity, refundable quantity, refunded quantity, weight, and a discounted total amount in both shop and presentment currency. Return reason tracking uses three fields: `Return Reason Name` (human-readable), `Return Reason Handle` (machine key), and a `Return Reason Note` blob for free-text explanation. There is also a per-line `Customer Note` blob for the buyer's comments. The `Type` field (`ShpfyReturnLineType.Enum.al`) distinguishes default return lines from other types.

`ShpfyReturnsAPI.Codeunit.al` handles the API import of return data from Shopify. `ShpfyReturnEnumConvertor.Codeunit.al` converts Shopify API string values to the corresponding AL enum values for status, decline reason, and return reason.

## Things to know

- Return lines use FlowFields for `Item No.`, `Description`, `Variant Code`, and `Unit of Measure Code` -- all resolved from the linked `Shpfy Order Line`, not stored directly.
- The `Discounted Total Amount` on the header is a SumIndexField CalcFormula summing line amounts, enabling efficient totals without iterating lines.
- Decline notes and return reason notes are stored as blobs with UTF-8 encoding, accessed via `GetDeclineNote`/`SetDeclineNote` and `GetReturnReasonNote`/`SetReturnReasonNote` helper methods.
- The `Location Id` on return lines is used by the processing module to map returns to BC warehouse locations via `ShpfyShopLocation`.
- A return is a physical concept; the financial refund may or may not exist. The `Return Id` field on `Shpfy Refund Header` links the two when both exist.
- Data captures are cleaned up on delete for both headers and lines.
