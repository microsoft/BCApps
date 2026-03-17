# Document Links

Bidirectional navigation between Shopify documents (orders, returns, refunds) and BC documents (sales orders, invoices, credit memos, shipments, return receipts). The junction table `Shpfy Doc. Link To Doc.` creates an N:M relationship that survives the BC document lifecycle from draft through posting.

## How it works

`ShpfyDocumentLinkMgt.Codeunit.al` subscribes to BC sales posting events to propagate links as documents move through their lifecycle. When a Sales Order is posted, the codeunit hooks into `OnAfterPostSalesDoc` and creates new link records for the resulting Posted Sales Shipment, Posted Sales Invoice, Posted Return Receipt, and Posted Sales Credit Memo. It also handles the `OnBeforeDeleteAfterPosting` event to create links before BC deletes the original sales header. For standalone invoices that reference shipments, it traces back through `Sales Invoice Line."Shipment No."` to find the originating Shopify document.

The two enums `ShpfyDocumentType.Enum.al` and `ShpfyShopDocumentType.Enum.al` implement `IOpenBCDocument` and `IOpenShopifyDocument` respectively, enabling polymorphic document opening. Each enum value maps to a dedicated codeunit (like `Shpfy Open SalesOrder` or `Shpfy Open Refund`) that opens the correct page. Unrecognized types fall through to `Shpfy OpenBCDoc NotSupported` or `Shpfy OpenDoc NotSupported`.

## Things to know

- The table has a four-part composite key: (Shopify Document Type, Shopify Document Id, Document Type, Document No.) with secondary indexes for lookups from either side.
- Link creation is guarded -- `CreateNewDocumentLink` silently skips when any key field is blank or zero, so partial posting scenarios don't produce orphaned links.
- Both enums are `Extensible = true`, so partners can add new Shopify or BC document types without modifying base code.
- The `OpenShopifyDocument` and `OpenBCDocument` methods on the table itself resolve the interface from the enum value and delegate, keeping the page layer clean of conditional logic.
- When a Sales Header is deleted directly (not via posting), the `OnDeleteSalesHeader` subscriber cleans up associated link records.
