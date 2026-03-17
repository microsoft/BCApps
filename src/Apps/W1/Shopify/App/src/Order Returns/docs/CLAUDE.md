# Order Returns

Stores Shopify return data imported during order sync. A return represents items a customer wants to send back, with status tracking, decline reasons, and links to the originating Shopify order.

## How it works

`Shpfy Return Header` (30147) holds return-level data: Return Id, Order Id, Status, Total Quantity, Decline Reason, and a BLOB-based Decline Note. Return Lines track per-item quantities along with `Discounted Total Amount` in both shop and presentment currencies (as FlowField sums from the line table). The header has FlowFields for customer names and Shopify order number that pull from the parent order header.

Returns are imported from Shopify as part of the order sync pipeline. The Return Status enum tracks the lifecycle (e.g., open, closed, declined). When a return has an associated refund, the refund's `Return Id` field links the two -- this connection is used by the Order Return Refund Processing framework to fall back to return lines when creating credit memos from refunds that have no refund lines.

## Things to know

- A return can exist without a refund, and a refund can exist without a return. They are linked by the `Return Id` field on the refund header, not by a mandatory parent-child relationship.
- The `Decline Reason` enum and `Decline Note` BLOB capture why a return was rejected. The note is stored as a BLOB with UTF-8 encoding and accessed via `GetDeclineNote()`/`SetDeclineNote()` helper methods.
- Dual-currency FlowFields (`Discounted Total Amount` and `Presentment Disc. Total Amt.`) use `AutoFormatExpression` that dynamically resolves the currency code from the parent order, ensuring correct formatting in the UI.
- The return header's `OnDelete` trigger cascades to delete return lines and associated data capture records.
- Return lines are used as a fallback source for credit memo line creation in the refund processing framework -- when a refund has no refund lines but has a linked Return Id, the processor creates credit memo lines from the return's line items instead.
