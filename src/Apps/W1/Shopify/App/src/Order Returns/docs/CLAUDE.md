# Order Returns

Shopify return records -- physical goods coming back from the customer. Returns are separate from refunds; a return tracks what items are being sent back, while a refund (in `Order Refunds`) tracks the money going out. A refund may optionally link to a return, but they can exist independently.

## How it works

`ShpfyReturnsAPI.Codeunit.al` fetches returns from Shopify and populates `Shpfy Return Header` and `Shpfy Return Line`. The header carries the return status, total quantity, and optional decline information (reason enum plus a blob-stored decline note). Return lines link back to order lines via `Order Line Id` and to fulfillment lines via `Fulfillment Line Id`, establishing the chain from what was shipped to what is coming back.

Each return line has `Refundable Quantity` and `Refunded Quantity` fields, tracking how much of the returned goods have been financially resolved. The `Type` field distinguishes between regular returns and exchanges via the `Shpfy Return Line Type` enum. Return reason details are stored in three fields: the deprecated `Return Reason` enum, plus the newer `Return Reason Name` and `Return Reason Handle` text fields that align with Shopify's customizable return reasons.

## Things to know

- Return lines carry dual-currency `Discounted Total Amount` and `Presentment Disc. Total Amt.` with a SumIndexField key for efficient aggregation at the header level via FlowField.
- The `Decline Note` and `Return Reason Note` fields are blobs with explicit Get/Set procedures that handle InStream/OutStream -- they are not simple text fields.
- The `Return Reason` enum field (field 6) is marked as deprecated in its caption ("Return Reason (deprecated)"). Use `Return Reason Name` and `Return Reason Handle` instead.
- Return lines include `Location Id` for identifying which Shopify location the goods are returning to, used by `Order Return Refund Processing` when determining the BC location code on credit memo lines.
- `ShpfyReturnEnumConvertor.Codeunit.al` handles the conversion of Shopify API status and reason strings to AL enum values.
