# Format

PEPPOL BIS 3.0 format implementation -- the built-in `IEDocument` interface implementation that ships with the E-Document Core app. This is the reference implementation that connector and format developers can study to understand how to build their own.

## How it works

`EDocPEPPOLBIS30.Codeunit.al` implements the `IEDocument` interface. On export (`Create`), it dispatches by document type to XMLport-based generators for invoices, credit memos, and financial results (reminders, finance charge memos), or to codeunit-based generators for sales shipments and transfer shipments. It also fires `OnAfterCreatePEPPOLXMLDocument` so extensions can modify the generated XML. On import (`GetBasicInfoFromReceivedDocument` / `GetCompleteInfoFromReceivedDocument`), it delegates to `EDocImportPEPPOLBIS30.Codeunit.al`.

`EDocImportPEPPOLBIS30.Codeunit.al` parses PEPPOL XML using `XML Buffer` (not XmlDocument directly). `ParseBasicInfo` detects the document type from the root element name (Invoice vs CreditNote), extracts header fields (vendor, dates, amounts, currency), and resolves the vendor through a multi-step chain: GLN, VAT number, service participant, then name+address. `ParseCompleteInfo` builds temporary Purchase Header/Line records by walking the XML buffer path-by-path. It also extracts embedded Base64 document attachments.

`EDocPEPPOLValidation.Codeunit.al` validates Reminders and Finance Charge Memos for PEPPOL compliance (required fields, currency code length, country ISO code length, company/customer GLN or VAT). Sales invoice and credit memo validation reuses the standard `PEPPOL Validation` codeunit. `EDocShipmentExportToXml.Codeunit.al` and `EDocTransferShptToXML.Codeunit.al` generate custom XML for shipment document types that are not covered by the standard PEPPOL XMLports.

## Things to know

- When `Document Format` is set to "PEPPOL BIS 3.0" on a service, the `OnAfterValidateDocumentFormat` subscriber auto-populates supported document types (Sales Invoice, Sales Credit Memo, Service Invoice, Service Credit Memo) if none exist.
- The import parser determines Invoice vs Credit Memo from the XML root element name, not from any content inside the document.
- Currency codes are compared against `LCY Code` from General Ledger Setup -- if the document currency matches LCY, the Currency Code field is left blank (BC convention).
- The `OnAfterParseInvoice` and `OnAfterParseCreditMemo` integration events fire for every XML buffer row, letting extensions handle custom PEPPOL paths.
- Shipment and Transfer Shipment exports build XML programmatically via `XML DOM Management` rather than using XMLports, because the standard PEPPOL XMLports do not cover these document types.
- The `Embed PDF in export` service flag is passed through to the XMLport generators, which embed a report-generated PDF as a Base64 attachment in the PEPPOL XML.
- `FinResultsPEPPOLBIS30.XmlPort.al` handles the Financial Results export (Issued Reminders and Issued Finance Charge Memos) as a separate XMLport.
