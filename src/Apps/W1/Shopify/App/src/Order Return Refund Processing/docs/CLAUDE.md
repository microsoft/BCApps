# Order Return Refund Processing

Part of [Shopify Connector](../../CLAUDE.md).

Manages the processing of Shopify returns and refunds into Business Central credit memos (or import-only mode).

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Interface | Shpfy IReturnRefund Process (30240) | Defines processing strategy for returns and refunds |
| Interface | Shpfy IDocument Source (30241) | Provides error tracking for source documents |
| Interface | Shpfy Extended IDocument Source (30242) | Extends IDocument Source with call stack tracking |
| Codeunit | Shpfy RetRefProc Cr.Memo (30243) | Auto create credit memo strategy |
| Codeunit | Shpfy RetRefProc ImportOnly (30245) | Import only strategy (no BC document creation) |
| Codeunit | Shpfy RetRefProc Default (30244) | Default/fallback strategy |
| Codeunit | Shpfy IDocSource Default (30246) | Default document source implementation |
| Codeunit | Shpfy IDocSource Refund (30247) | Refund-specific document source |
| Codeunit | Shpfy Create Sales Doc. Refund (30248) | Creates BC credit memo from refund |
| Codeunit | Shpfy Refund Process Events (30249) | Integration events |
| Enum | Shpfy ReturnRefund ProcessType (30240) | Processing mode selection |
| Enum | Shpfy Source Document Type (30241) | Return or Refund |
| Table Ext. | Shpfy Sales Cr.Memo Header (30244) | Adds Shopify fields to posted credit memo |
| Table Ext. | Shpfy Sales Cr.Memo Line (30245) | Adds Shopify fields to posted credit memo line |
| Table Ext. | Shpfy Return Receipt Header (30246) | Adds Shopify fields to return receipt |
| Table Ext. | Shpfy Return Receipt Line (30247) | Adds Shopify fields to return receipt line |
| Page Ext. | Shpfy Sales Credit Memo (30244) | Shows Shopify fields on credit memo card |
| Page Ext. | Shpfy Sales Credit Memos (30245) | Shows Shopify fields on credit memo list |
| Page Ext. | Shpfy Posted Sales Cr.Memos (30246) | Shows Shopify fields on posted credit memo list |

## Key concepts

- **Processing strategy**: Shop setup field `Return and Refund Process` selects implementation via interface pattern (Auto Create Credit Memo, Import Only, or custom).
- **Auto Create Credit Memo**: Automatically generates BC credit memo when refund is imported; only creates if refund lines have `Can Create Credit Memo` = true.
- **Import Only**: Imports return and refund data to BC tables but does not create credit memos; useful for reporting or manual processing.
- **Refund vs. Return**: Refunds track financial transactions (money back to customer); Returns track physical goods coming back to warehouse. Refunds can exist without returns (e.g., restocking fee waived).
- **Processing trigger**: When shop processes orders (codeunit `Shpfy Process Orders`), it calls `ProcessShopifyRefunds` which iterates unprocessed refunds and calls the selected strategy's `CreateSalesDocument` method.
- **Error tracking**: Document source interfaces store error messages and call stacks on refund/return headers for troubleshooting.
