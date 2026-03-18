# Format

The Format folder implements PEPPOL BIS 3.0 format handlers for bidirectional e-invoice exchange. It provides both export (BC documents → UBL XML) and import (UBL XML → BC purchase documents) capabilities for PEPPOL-compliant electronic invoicing.

## Quick reference

- **Files:** 7 AL files (5 codeunits, 1 enum, 1 XMLport)
- **ID range:** 6165-6166 (codeunits), 6385 (XMLport)
- **Dependencies:** Microsoft.Sales.Peppol, System.Utilities
- **Interface implementations:** IEDocument (6165), IStructureReceivedEDocument (implicit)

## How it works

This folder implements the IEDocument interface to provide PEPPOL BIS 3.0 format support. The **EDoc PEPPOL BIS 3.0** codeunit orchestrates document lifecycle across 5 document types (sales/service invoices, credit memos, financial results, shipments, transfer shipments). For exports, it delegates to specialized XMLports and codeunits that generate UBL-compliant XML. For imports, **EDoc Import PEPPOL BIS 3.0** parses incoming XML using XML Buffer and extracts vendor identification via GLN, VAT registration, or service participant ID.

The validation layer uses existing PEPPOL validation codeunits from Microsoft.Sales.Peppol to enforce BIS 3.0 business rules before export. Import logic includes vendor matching via 3-pass fallback (GLN → VAT → name+address), attachment extraction from embedded base64 documents, and allowance/charge handling as separate G/L account lines.

Format selection is enum-driven: EDocumentStructuredFormat enum values map to IEDocument implementations, allowing partners to add custom formats without modifying core logic.

## Structure

- `EDocPEPPOLBIS30.Codeunit.al` -- Main format orchestrator implementing IEDocument
- `EDocImportPEPPOLBIS30.Codeunit.al` -- Inbound XML parser with vendor matching
- `EDocPEPPOLValidation.Codeunit.al` -- BIS 3.0 business rule validation
- `EDocShipmentExportToXml.Codeunit.al` -- Sales Shipment → PEPPOL DespatchAdvice
- `EDocTransferShptToXML.Codeunit.al` -- Transfer Shipment → PEPPOL DespatchAdvice
- `EDocumentStructuredFormat.Enum.al` -- Format enum with extensibility
- `FinResultsPEPPOLBIS30.XmlPort.al` -- Reminder/Finance Charge Memo → UBL

## Documentation

- [Business logic](business-logic.md) -- Export orchestration, import parsing, validation
- No data-model.md (stateless format transformation)
- No extensibility.md (covered in core docs)

## Things to know

- **Interface contract:** IEDocument.Create receives RecordRef for both header and lines; the codeunit extracts table type via RecordRef.Number and delegates to format-specific methods.
- **XML namespace handling:** All exports declare 5 PEPPOL namespaces (cac, cbc, ccts, qdt, udt) in root elements for UBL 2.1 compliance.
- **PDF embedding:** When service configuration enables "Embed PDF in export", the XMLport/codeunit generates a PDF report blob and embeds it as base64 in AdditionalDocumentReference elements.
- **Vendor matching priority:** Import tries (1) GLN from EndpointID with schemeID=0088, (2) VAT Registration No. from PartyTaxScheme/CompanyID, (3) name+address text match, (4) service participant ID lookup if configured.
- **Allowance/charge mapping:** Import handles document-level AllowanceCharge elements by creating synthetic purchase lines with Type = G/L Account, using E-Document Import Helper to resolve the account number.
- **Line type inference:** Import sets Purchase Line Type based on cbc:Note field content (values: 'ITEM', 'CHARGE (ITEM)', 'RESOURCE', 'G/L ACCOUNT').
- **Currency handling:** If DocumentCurrencyCode matches LCY, E-Document."Currency Code" remains blank (BC convention for local currency).
- **Attachment file type detection:** Uses MIME type mapping (image/jpeg → jpeg, application/pdf → pdf, vnd.openxmlformats → xlsx).
- **Event-driven customization:** OnAfterCreatePEPPOLXMLDocument event allows extensions to modify TempBlob before it's sent to services.
- **RecordRef isolation:** Import populates temporary Purchase Header/Line records via RecordRef, allowing multi-step transformation before final insert.
