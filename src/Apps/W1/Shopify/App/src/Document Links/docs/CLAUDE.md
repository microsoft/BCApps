# Document links

Provides bidirectional navigation between Shopify documents (orders, returns, refunds) and BC documents (sales orders, invoices, shipments, credit memos). The link table tracks the full document lifecycle so that posting a sales order automatically creates links to the resulting shipment and invoice.

## How it works

`ShpfyDocLinkToDoc` (in `ShpfyDocLinkToDoc.Table.al`) is the central many-to-many link table with a four-part composite key: `(Shopify Document Type, Shopify Document Id, Document Type, Document No.)`. It has two secondary indexes -- one by `(Shopify Document Type, Shopify Document Id)` and one by `(Document Type, Document No.)` -- so lookups are fast from either side. Opening a document dispatches through interface-backed enums: `ShpfyDocumentType` implements `ShpfyIOpenBCDocument` with one codeunit per document type (e.g., `ShpfyOpenSalesOrder`, `ShpfyOpenPostedSalesInvoice`), and `ShpfyShopDocumentType` implements `ShpfyIOpenShopifyDocument`.

The real work happens in `ShpfyDocumentLinkMgt`, which subscribes to Sales-Post events. When a sales order is posted, it finds the existing Shopify-to-SalesOrder link and creates new links for the posted shipment, invoice, return receipt, or credit memo. It also handles the case where an invoice is posted against shipments from a different sales order -- it traces back through `Sales Invoice Line."Shipment No."` to find the Shopify link. When documents are deleted, the corresponding links are cleaned up via `OnAfterDeleteEvent` on `Sales Header`.

## Things to know

- Both enums are extensible with `DefaultImplementation` pointing to a "NotSupported" codeunit, so extensions can add new document types without breaking existing code.
- `ShpfyBCDocumentTypeConvert` handles mapping between BC's `Sales Document Type` enum and the connector's `ShpfyDocumentType` enum, including a `CanConvert` check and record-variant overloads that inspect the table number.
- A single Shopify order can link to many BC documents (order + multiple partial shipments + invoice + credit memo), and a single BC document can link back to multiple Shopify documents in multi-order invoice scenarios.
- The `ShpfyLinkedToDocuments` page surfaces these links as a factbox, letting users navigate from either side.
- Link records use `SystemMetadata` classification -- they contain no customer data, only document identifiers.
