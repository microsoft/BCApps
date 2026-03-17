# Document links

Maintains bidirectional links between Shopify documents (orders, refunds, returns) and BC documents (sales orders, invoices, shipments, credit memos, return receipts). Automatically creates links when BC documents are posted or deleted.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyDocumentLinkMgt.Codeunit.al`
- **Key patterns**: Event subscribers on Sales-Post / PostSales-Delete, interface-based document openers

## Structure

- Codeunits (15): DocumentLinkMgt (event-driven link management), BCDocumentTypeConvert, 12 Open* codeunits (OpenOrder, OpenPostedSalesInvoice, OpenSalesOrder, OpenRefund, OpenReturn, etc.), OpenDocNotSupported, OpenBCDocNotSupported
- Tables (1): DocLinkToDoc
- Enums (2): DocumentType (BC side), ShopDocumentType (Shopify side)
- Interfaces (2): IOpenBCDocument, IOpenShopifyDocument
- Pages (1): LinkedToDocuments

## Key concepts

- `DocumentLinkMgt` subscribes to Sales Header delete, Sales-Post, and PostSales-Delete events to automatically propagate document links from source documents (e.g., sales order) to posted documents (e.g., posted invoice, shipment)
- `DocLinkToDoc` table uses a composite key of (Shopify Document Type, Shopify Document Id, Document Type, Document No.) and supports opening either side via interface dispatch
- Each `Shpfy Shop Document Type` enum value implements `IOpenShopifyDocument`; each `Shpfy Document Type` enum value implements `IOpenBCDocument`
- When a combined invoice is created from multiple shipments, the codeunit traces back through shipment lines to find the original Shopify order link
