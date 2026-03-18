# Format

PEPPOL BIS 3.0 format implementation and shipment XML generators. This is the only built-in document format -- all other formats (OIOUBL, Factura-e, FatturaPA, etc.) come from country localization apps that implement the same `E-Document` interface.

## How it works

`EDocPEPPOLBIS30` (codeunit 6165) implements the `E-Document` interface with `Check`, `Create`, `CreateBatch`, and `GetBasicInfo`/`GetCompleteInfo` procedures. The `Check` procedure delegates to existing PEPPOL validation codeunits based on the source document type. The `Create` procedure builds XML by calling the appropriate BC PEPPOL export XMLport (`FinResultsPEPPOLBIS30.XmlPort.al`) and writes the result to a TempBlob. It handles sales invoices, credit memos, service documents, reminders, finance charge memos, and shipments.

`EDocImportPEPPOLBIS30` (codeunit 6166) handles the inbound side. `ParseBasicInfo` reads just enough XML to populate the E-Document header (vendor ID, document number, dates, amounts). `ParseCompleteInfo` fully parses the PEPPOL XML into temporary Purchase Header and Purchase Line records. Both methods detect whether the document is an Invoice or CreditNote from the root XML element.

Two separate codeunits handle non-PEPPOL shipment formats: `EDocShipmentExportToXml` (6130) generates XML for Sales Shipments and `EDocTransferShptToXML` (6127) for Transfer Shipments. These use a simpler custom XML schema rather than PEPPOL, with company info, customer/delivery info, and line details.

`EDocPEPPOLValidation` (codeunit 6172) adds validation for document types not covered by the base BC PEPPOL validation -- specifically Reminders and Finance Charge Memos.

## Things to know

- The `E-Document Structured Format` enum in this directory is obsolete (pending removal in v26). It was part of the V1 import path and is replaced by the V2 pipeline's `Structure Received E-Doc.` and `E-Doc. Read into Draft` interfaces.
- Shipment XML generation optionally embeds a PDF (`GeneratePDF` boolean). When enabled, the report PDF is Base64-encoded and included in the XML payload.
- `EDocPEPPOLBIS30.Create` dispatches to different export methods based on `SourceDocumentHeader.Number` -- there is a large case statement covering every supported document type. Unrecognized table numbers raise an error.
- Import parsing uses `XML Buffer` (temporary table) for XML traversal rather than direct XmlDocument manipulation. This is a BC pattern inherited from the original PEPPOL import code.
- The import side only handles Invoice and CreditNote. Other PEPPOL document types (DespatchAdvice, etc.) are not supported for inbound processing.
