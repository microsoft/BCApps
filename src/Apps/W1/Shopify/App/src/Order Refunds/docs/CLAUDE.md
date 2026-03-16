# Order Refunds

Part of [Shopify Connector](../../CLAUDE.md).

Tracks financial refunds issued to customers, including refunded line items, shipping costs, and restock information.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Refund Header (30142) | Refund header with total amounts and status |
| Table | Shpfy Refund Line (30145) | Refunded line items with amounts and quantities |
| Table | Shpfy Refund Shipping Line (30146) | Refunded shipping costs |
| Codeunit | Shpfy Refunds API (30174) | GraphQL operations for refunds |
| Codeunit | Shpfy Refund Enum Convertor (30175) | Converts Shopify refund enums to BC enums |
| Enum | Shpfy Restock Type (30140) | How refunded items are restocked |
| Page | Shpfy Refunds (30142) | List of refunds |
| Page | Shpfy Refund (30143) | Refund details card |
| Page | Shpfy Refund Lines (30144) | Refund line subpage |
| Page | Shpfy Refund Shipping Lines (30145) | Refund shipping line subpage |

## Key concepts

- **Refund**: Financial transaction returning money to customer; can be partial or full.
- **Refund header**: Stores total refunded amount (shop and presentment currency), creation date, related order ID, optional return ID, and notes.
- **Refund line**: Records which order line was refunded, quantity, amount, subtotal, tax amounts, and restock information.
- **Refund shipping line**: Tracks refunded shipping costs, including amount and tax amounts.
- **Restock type**: Enum values (Cancel, Legacy Restock, No Restock, Return) indicate how inventory should be adjusted. Cancel = order was cancelled before fulfillment; Return = goods physically returned; No Restock = no inventory adjustment.
- **Processing error tracking**: Refund header has fields `Has Processing Error`, `Last Error Description` (Blob), `Last Error Call Stack` (Blob) for troubleshooting auto-credit-memo failures.
- **Can Create Credit Memo**: Boolean field on refund line determines if line is eligible for auto-credit-memo creation. Set to false for lines that cannot be mapped to BC sales lines.
- **Import control**: Shop setting `Return and Refund Process` determines if refunds are imported and whether they auto-create credit memos.
- **FlowFields**: Refund header calculates `Is Processed` by checking if any BC credit memo links exist for the refund.
