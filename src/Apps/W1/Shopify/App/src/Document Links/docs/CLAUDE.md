# Document links

Cross-referencing between Shopify documents and BC documents. This module maintains a many-to-many mapping table that tracks which Shopify orders, returns, and refunds correspond to which BC sales orders, invoices, shipments, credit memos, and return receipts. It is separate from the order-processing modules because it is a shared lookup used by multiple areas.

## How it works

The `Shpfy Doc. Link To Doc.` table (30146) stores links with a composite key of (`Shopify Document Type`, `Shopify Document Id`, `Document Type`, `Document No.`). The Shopify side uses the `Shpfy Shop Document Type` enum (30144) with values for Order, Return, and Refund. The BC side uses the `Shpfy Document Type` enum (30143) covering Sales Order, Sales Invoice, Sales Credit Memo, Sales Return Order, Posted Sales Shipment, Posted Return Receipt, Posted Sales Invoice, and Posted Sales Credit Memo.

Both enums implement interface-driven document opening. `Shpfy Shop Document Type` implements `Shpfy IOpenShopifyDocument` -- each value maps to a codeunit like `ShpfyOpenOrder.Codeunit.al` or `ShpfyOpenRefund.Codeunit.al`. `Shpfy Document Type` implements `Shpfy IOpenBCDocument` with codeunits like `ShpfyOpenSalesOrder.Codeunit.al` and `ShpfyOpenPostedSalesInvoice.Codeunit.al`. The table itself exposes `OpenShopifyDocument` and `OpenBCDocument` methods that dispatch through these interfaces.

The lifecycle management happens in `ShpfyDocumentLinkMgt.Codeunit.al`, which subscribes to Sales-Post events. When a sales order is posted, it automatically creates links to the resulting posted invoice, shipment, credit memo, or return receipt. It also handles the `OnDeleteSalesHeader` event to clean up links, and `OnBeforeDeleteAfterPosting` to transfer links from the unposted document to the posted document. It additionally links invoices back to shipments when posting standalone invoices that reference shipment lines.

## Things to know

- Links propagate automatically on posting -- you do not need to manually create links to posted documents.
- The `CreateNewDocumentLink` helper silently skips blank document numbers and zero IDs, so it is safe to call unconditionally after posting.
- The module uses secondary indexes on both the Shopify side (`Idx01`) and the BC side (`Idx02`) for efficient lookups in either direction.
- Unsupported document types fall through to `ShpfyOpenBCDocNotSupported.Codeunit.al` / `ShpfyOpenDocNotSupported.Codeunit.al`, which are the default implementations.
- Both enums are extensible, so partners can add new Shopify or BC document types.
