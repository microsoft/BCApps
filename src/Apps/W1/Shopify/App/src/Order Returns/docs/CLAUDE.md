# Order returns

Imports Shopify return data including return headers, verified return lines, unverified return lines, and return locations from reverse fulfillment orders.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyReturnsAPI.Codeunit.al`
- **Key patterns**: GraphQL paginated import, reverse fulfillment order location resolution, polymorphic line types (Default vs Unverified)

## Structure

- Codeunits (2): ReturnsAPI (import logic), ReturnEnumConvertor
- Tables (2): ReturnHeader, ReturnLine
- Enums (5): OrderReturnStatus, ReturnDeclineReason, ReturnLineType, ReturnReason, ReturnStatus
- Pages (3): Return, ReturnLines, Returns

## Key concepts

- `GetReturns` processes returns from an order's GraphQL response, paging through return IDs, then fetching each return's header and lines separately
- Return lines come in two types: `ReturnLineItem` (verified, linked to a fulfillment line) and `UnverifiedReturnLineItem` (not yet verified, has unit price instead)
- Return locations are resolved by querying reverse fulfillment orders and their line item dispositions; if an item was restocked to multiple locations, the location is left unresolved
- Each return line stores return reason (name + handle), customer note, and return reason note as blob fields
- `ReturnHeader` computes `Discounted Total Amount` as a FlowField summing across return lines, in both shop and presentment currencies
