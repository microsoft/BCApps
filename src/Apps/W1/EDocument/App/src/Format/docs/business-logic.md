# Format business logic

## Export flow

When an E-Document is exported, the format interface's `Create` procedure is called with the source document RecordRef and an empty TempBlob. The flow depends on the document type.

```mermaid
flowchart TD
    A[Create called with SourceDocumentHeader] --> B{Document type?}
    B -->|Sales Invoice/Cr.Memo| C[Run PEPPOL XMLport]
    B -->|Service Invoice/Cr.Memo| D[Run PEPPOL Service XMLport]
    B -->|Reminder/Fin.Charge| E[Run PEPPOL Debit Note XMLport]
    B -->|Sales Shipment| F[Run EDocShipmentExportToXml]
    B -->|Transfer Shipment| G[Run EDocTransferShptToXML]
    B -->|Unposted Sales/Service| H[Error - must post first]
    C --> I[Write XML to TempBlob]
    D --> I
    E --> I
    F --> I
    G --> I
```

For standard PEPPOL documents, the codeunit runs the `FinResultsPEPPOLBIS30` XMLport which produces UBL 2.1 compliant XML. Shipment documents use custom XML structures generated programmatically via `XML DOM Management`.

## Import flow

The import side has two entry points: `ParseBasicInfo` for initial document identification and `ParseCompleteInfo` for full document parsing into purchase structures.

```mermaid
flowchart TD
    A[ParseBasicInfo] --> B[Load XML into TempXMLBuffer]
    B --> C{Root element type?}
    C -->|Invoice| D[Parse invoice header fields]
    C -->|CreditNote| E[Parse credit memo header fields]
    D --> F[Set E-Document fields: vendor, dates, amounts, currency]
    E --> F
    G[ParseCompleteInfo] --> H[Load XML into TempXMLBuffer]
    H --> I{Root element type?}
    I -->|Invoice| J[CreateInvoice: populate temp PurchaseHeader + PurchaseLines]
    I -->|CreditNote| K[CreateCreditMemo: populate temp PurchaseHeader + PurchaseLines]
```

`ParseBasicInfo` extracts vendor identification (VAT number, GLN, name), document reference numbers, dates, currency, and total amounts. `ParseCompleteInfo` fully populates temporary Purchase Header and Purchase Line records including line-level details (item descriptions, quantities, unit prices, tax amounts). The parsed output is consumed by the import pipeline to create actual BC purchase documents.

## Validation

The `Check` procedure runs before export. It delegates to three different validation codeunits depending on document type: `PEPPOL Validation` (from the base app, for sales documents), `PEPPOL Service Validation` (for service documents), and `E-Doc. PEPPOL Validation` (local to this module, for reminders and finance charge memos). Validation failures raise errors that block the export.
