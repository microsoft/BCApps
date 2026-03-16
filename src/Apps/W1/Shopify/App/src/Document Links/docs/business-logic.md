# Business logic

## Overview

Document Links maintain referential integrity between Shopify and Business Central documents as they transition through states (unposted -> posted, combined documents, etc.).

## Key codeunits

### Shpfy Document Link Mgt. (30262)

- **Key procedures**: CreateNewDocumentLink (internal)
- **Event subscribers**:
  - OnAfterDeleteEvent (Sales Header): deletes links when order deleted
  - OnAfterDelete (PostSales-Delete): creates links to posted documents before source deleted
  - OnBeforeDeleteAfterPosting: creates links for "Ship and Invoice" scenario
  - OnAfterPostSalesDoc: creates links to posted documents, handles invoice-from-shipment scenario
- **Data flow**: Listens for posting events, reads existing links, creates new links to posted documents

### Shpfy BC Document Type Convert (30259)

- **Key procedures**:
  - Convert (Sales Document Type -> Shpfy Document Type)
  - Convert (Variant -> Shpfy Document Type): accepts Sales Header, Shipment Header, Invoice Header, etc.
  - Convert (Shpfy Document Type -> Sales Document Type): reverse direction
  - CanConvert: validates conversion is supported
- **Mapping**: Order <-> Sales Order, Invoice <-> Sales Invoice, Return Order <-> Sales Return Order, Credit Memo <-> Sales Credit Memo

## Processing flows

### Link creation on import

1. Shopify order imported to BC
2. Sales Order created with Shopify Order ID
3. CreateNewDocumentLink called with (Shopify Shop Order, OrderId, Sales Order, OrderNo)
4. Link record inserted

### Link update on posting (Ship and Invoice)

1. Sales Order posted with Ship and Invoice
2. OnAfterPostSalesDoc event fires
3. Event finds existing link for Sales Order
4. Calls CreateNewDocumentLink for Posted Sales Shipment
5. Calls CreateNewDocumentLink for Posted Sales Invoice
6. Original Sales Order link remains until deletion

### Link update on deletion

1. Sales Order deleted (or auto-deleted after posting)
2. OnAfterDelete or OnBeforeDeleteAfterPosting fires
3. Event reads Shopify document type and ID from existing link
4. Calls CreateNewDocumentLink for each posted document (Shipment, Invoice, Return Receipt, Credit Memo)
5. Original link deleted by DeleteAll

### Invoice from shipment scenario

1. Sales Shipment posted with link to Shopify Order
2. Later: Invoice created and posted, references Shipment No. in lines
3. OnAfterPostSalesDoc event fires
4. Event reads shipment lines to find related shipments
5. For each shipment with existing link: creates link from same Shopify document to new Invoice
6. Result: Shopify Order linked to both Posted Shipment and Posted Invoice

### Document type conversion

- **Sales Document Type** (BC standard): Quote, Order, Invoice, Credit Memo, Blanket Order, Return Order
- **Shpfy Document Type** (internal): Sales Order, Sales Invoice, Sales Return Order, Sales Credit Memo, Posted Sales Shipment, Posted Return Receipt, Posted Sales Invoice, Posted Sales Credit Memo
- Conversion required because Shpfy tracks both unposted and posted states
- CanConvert checks if enum value is supported (e.g., Quote not supported)

### Supported types

#### BC document types (Shpfy Document Type enum)

- Sales Order -> Sales Order page
- Sales Invoice -> Sales Invoice page
- Sales Return Order -> Sales Return Order page
- Sales Credit Memo -> Sales Credit Memo page
- Posted Sales Shipment -> Posted Sales Shipment page
- Posted Return Receipt -> Posted Return Receipt page
- Posted Sales Invoice -> Posted Sales Invoice page
- Posted Sales Credit Memo -> Posted Sales Credit Memo page

#### Shopify document types (Shpfy Shop Document Type enum)

- Shopify Shop Order -> Shpfy Order page
- Shopify Shop Return -> Shpfy Return page
- Shopify Shop Refund -> Shpfy Refund page

Each enum value bound to interface implementation codeunit that opens the appropriate page.
