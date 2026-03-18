# Format

PEPPOL BIS 3.0 implementation -- the built-in format that ships with E-Document Core. This is the reference implementation that localization teams study when building country-specific formats.

## Two format paths

E-Document Core supports two fundamentally different approaches to XML generation:

- **Code-based** (this folder) -- AL codeunits directly build/parse XML. `EDocPEPPOLBIS30.Codeunit.al` implements the "E-Document" interface for export. `EDocImportPEPPOLBIS30.Codeunit.al` implements `IStructuredFormatReader` for import. Full control, straightforward debugging.
- **Data-exchange-based** (see `src/DataExchange/`) -- uses BC's Data Exchange Framework with transformation rules configured in the UI. More flexible for non-developers but harder to troubleshoot.

The `EDocumentStructuredFormat.Enum.al` enum ("E-Document Structured Format") is the extensible enum that localizations extend to register their own formats. PEPPOL BIS 3.0 is registered via `EDocPEPPOLBIS30.EnumExt.al`.

## Key files

`EDocPEPPOLBIS30.Codeunit.al` is the export workhorse -- it builds the full UBL 2.1 XML structure. `EDocImportPEPPOLBIS30.Codeunit.al` handles import by reading structured XML fields into the e-document's intermediate representation. `EDocPEPPOLValidation.Codeunit.al` validates PEPPOL-specific business rules before export.

`EDocShipmentExportToXml.Codeunit.al` and `EDocTransferShptToXML.Codeunit.al` handle shipment document types, which use a different UBL schema than invoices and credit memos. `FinResultsPEPPOLBIS30.XmlPort.al` handles financial charge memo export.

Most country localizations bypass this folder entirely and implement their own format codeunit registered against their own enum value. PEPPOL BIS 3.0 serves as the W1 default and the pattern to follow.
