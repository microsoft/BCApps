# Document Links

Maintains cross-references between Shopify documents (orders, returns, refunds) and Business Central documents (sales orders, invoices, credit memos, shipments, return receipts).

## How it works

The central table `Shpfy Doc. Link To Doc.` (table 30146) has a composite key of `(Shopify Document Type, Shopify Document Id, Document Type, Document No.)`. The Shopify side uses the `Shpfy Shop Document Type` enum (Order, Return, Refund), and the BC side uses the `Shpfy Document Type` enum (Sales Order, Sales Invoice, Sales Return Order, Sales Credit Memo, Posted Sales Shipment, Posted Return Receipt, Posted Sales Invoice, Posted Sales Credit Memo). This composite key allows multiple BC documents per Shopify document, which is the normal case: a single Shopify order produces a sales order, then a posted shipment, then a posted invoice.

Navigation is interface-driven. Both enums carry interface implementations. `Shpfy Shop Document Type` implements `IOpenShopifyDocument` with codeunits like `ShpfyOpenOrder`, `ShpfyOpenReturn`, `ShpfyOpenRefund`. `Shpfy Document Type` implements `IOpenBCDocument` with codeunits like `ShpfyOpenSalesOrder`, `ShpfyOpenPostedSalesInvoice`, and so on. The table's `OpenShopifyDocument()` and `OpenBCDocument()` procedures dispatch to the correct codeunit through the enum's interface implementation.

`ShpfyDocumentLinkMgt` (codeunit 30262) subscribes to Sales Header deletion, Sales-Post events, and PostSales-Delete to automatically maintain the links. When a sales order is posted, it creates links to the resulting posted shipment, posted invoice, return receipt, and/or posted credit memo. When a sales document is deleted after posting, it transfers the Shopify link to the posted documents. It also handles the invoice-from-shipment scenario by tracing invoice lines back to their shipment numbers.

`ShpfyBCDocumentTypeConvert` (codeunit 30259) converts between BC record types / Sales Document Type enum and the `Shpfy Document Type` enum, and can also convert back. This is used everywhere a link is created.

## Things to know

- The `Linked To Documents` page (page 30148) is a ListPart designed to be embedded as a factbox. Drilling down on `Document No.` calls `OpenBCDocument()`, which dispatches through the interface.
- Both enums are `Extensible = true`, so third-party apps can add new Shopify document types or BC document types with their own navigation codeunits.
- The link records are created by the modules that create the BC documents (`ShpfyProcessOrder`, `ShpfyCreateSalesDocRefund`), not by this module. This module is responsible for lifecycle management (propagating links when documents are posted or deleted) and navigation.
- `Order Header.IsProcessed()` checks `Doc. Link To Doc.` in addition to the `Processed` flag, so the link table is load-bearing for import conflict detection.
