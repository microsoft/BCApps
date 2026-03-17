# Order refunds

Imports Shopify refund data (headers, line items, shipping lines) and tracks whether each refund has been processed into a BC credit memo.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyRefundsAPI.Codeunit.al`
- **Key patterns**: GraphQL paginated import, RecordRef-based field mapping, DataCapture for raw JSON

## Structure

- Codeunits (2): RefundsAPI (import and processing logic), RefundEnumConvertor
- Tables (3): RefundHeader, RefundLine, RefundShippingLine
- Enums (1): RestockType
- Pages (4): Refund, RefundLines, RefundShippingLines, Refunds

## Key concepts

- Refund import fetches header via `GetRefundHeader`, then paginates through refund lines and shipping lines using cursor-based GraphQL queries
- Each refund line tracks `Can Create Credit Memo` -- set to true only if the refund has a non-zero amount or is linked to a return (prevents duplicate processing of order-level adjustments)
- Refund lines collect return locations from the associated return's reverse fulfillment orders to determine the correct BC location for restocking
- `RefundHeader` stores error state (`Has Processing Error`, `Last Error Description`, `Last Error Call Stack`) as blob fields for debugging failed credit memo creation
- The `Is Processed` FlowField checks for existence in the Document Links table to determine if a credit memo has already been created
