# Document links

This folder tracks the relationship between Shopify documents (orders, returns, refunds) and BC documents (sales orders, invoices, shipments, credit memos, return receipts) through the `Shpfy Doc. Link To Doc.` table.

## Core table

`ShpfyDocLinkToDoc.Table.al` has a four-part key: `(Shopify Document Type, Shopify Document Id, Document Type, Document No.)`. This is a many-to-many link -- one Shopify order can produce multiple BC documents (a sales order, then a posted shipment, then a posted invoice), and the table accumulates all of them. Two secondary indexes support lookup from either side. The table exposes `OpenShopifyDocument` and `OpenBCDocument` which dispatch to the appropriate interface implementation to open the relevant card page.

## Interface-driven navigation

Two interfaces handle document opening:

- `Shpfy IOpenShopifyDocument` -- implemented by the `Shpfy Shop Document Type` enum. Values are `Shopify Shop Order`, `Shopify Shop Return`, `Shopify Shop Refund`, each with a codeunit that opens the corresponding Shopify record card. Unsupported types fall through to `Shpfy OpenDoc NotSupported`.
- `Shpfy IOpenBCDocument` -- implemented by the `Shpfy Document Type` enum. Covers `Sales Order`, `Sales Invoice`, `Sales Return Order`, `Sales Credit Memo`, `Posted Sales Shipment`, `Posted Return Receipt`, `Posted Sales Invoice`, `Posted Sales Credit Memo`. Each has a dedicated codeunit (e.g., `ShpfyOpenSalesOrder.Codeunit.al`) that runs the appropriate page.

Both enums are extensible, so third-party extensions can add new document types.

## Automatic link propagation

`ShpfyDocumentLinkMgt.Codeunit.al` subscribes to sales posting events to propagate links as documents move through the BC lifecycle. When a sales order is posted, links are created to the resulting posted shipment, posted invoice, posted return receipt, and posted credit memo. When a sales header is deleted after posting (via `PostSales-Delete`), existing links are carried forward to the posted documents. The `OnAfterSalesPosting` handler also traces shipment-to-invoice relationships for standalone invoice posting, walking `Sales Invoice Line."Shipment No."` to find the originating Shopify order link.

## IsProcessed

Order processing status is determined by the existence of document links -- a Shopify order is considered processed once at least one BC document link exists for it. This is why link creation is critical to the overall sync workflow.
