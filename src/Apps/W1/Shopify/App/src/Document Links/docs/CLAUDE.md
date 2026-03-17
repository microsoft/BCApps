# Document Links

M:N bridge table linking Shopify documents (orders, returns, refunds) to BC documents (sales orders, invoices, credit memos, shipments, return receipts). This enables bidirectional navigation between the two systems from any linked document.

## How it works

The core is `ShpfyDocLinkToDoc.Table.al` (30146), a four-column junction table keyed by (Shopify Document Type, Shopify Document Id, Document Type, Document No.). Two enum-based interfaces drive document opening: `Shpfy IOpenBCDocument` (implemented by `Shpfy Document Type` enum with values for Sales Order, Sales Invoice, Posted Sales Shipment, etc.) and `Shpfy IOpenShopifyDocument` (implemented by `Shpfy Shop Document Type` enum with values for Shopify Order, Return, Refund). When a user clicks a linked document, the table dispatches to the correct codeunit via the interface -- for example, `Shpfy Open PostedSalesInvoice` opens the posted invoice page.

`ShpfyDocumentLinkMgt.Codeunit.al` (30262) subscribes to Sales-Post and PostSales-Delete events to automatically create new links when a sales document is posted. When a Sales Order is posted into a Sales Invoice and Sales Shipment, the codeunit copies the Shopify link from the original document to the posted documents. It also handles combined invoice scenarios where invoices are created from multiple shipments.

## Things to know

- Links are created automatically during posting via event subscribers in `ShpfyDocumentLinkMgt` -- you never need to manually insert link records for standard order flows.
- Both enums are `Extensible = true`, so third-party extensions can add new BC or Shopify document types with their own open-document implementations.
- The default implementation for unrecognized enum values (`ShpfyOpenBCDocNotSupported`, `ShpfyOpenDocNotSupported`) does nothing -- it silently handles unknown document types without errors.
- The `Linked To Documents` page (30148) is a ListPart designed to embed in other pages, filtered by Shopify document type and ID. DrillDown on the Document No. field opens the BC document directly.
- When a sales document is deleted before posting, the link records are cleaned up via the `OnAfterDeleteEvent` subscriber on the Sales Header table.
