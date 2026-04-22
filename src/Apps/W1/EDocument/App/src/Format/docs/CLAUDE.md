# Format

PEPPOL BIS 3.0 export and import implementation -- the built-in document format that ships with E-Document Core. This module owns the serialization/deserialization of UBL 2.1 XML for invoices, credit memos, reminders, finance charge memos, and shipments. Localizations add their own formats via the extensible `E-Document` enum; this module provides the W1 baseline.

## How it works

The main entry point is `EDocPEPPOLBIS30.Codeunit.al`, which implements the `"E-Document"` interface with five methods: `Check`, `Create`, `CreateBatch`, `GetBasicInfoFromReceivedDocument`, and `GetCompleteInfoFromReceivedDocument`.

**Export path:** `Create` dispatches by document type to dedicated XML generators. Invoices and credit memos use base app XMLports (`Sales Invoice - PEPPOL BIS 3.0`, `Sales Cr.Memo - PEPPOL BIS 3.0`) which produce UBL 2.1 XML with proper `cac`/`cbc` namespaces. Shipments and transfer shipments use custom codeunits (`EDocShipmentExportToXml`, `EDocTransferShptToXML`) that build XML via `XML DOM Management`. Reminders and finance charge memos share the `FinResultsPEPPOLBIS30` XMLport, which wraps them as UBL Invoice documents with special type codes. After generation, `OnAfterCreatePEPPOLXMLDocument` fires as an integration event, letting subscribers modify the XML blob before it leaves the format layer.

**Import path:** `EDocImportPEPPOLBIS30` parses incoming UBL XML into temporary `Purchase Header` / `Purchase Line` records. It uses `XML Buffer` (not DOM) for XPath-style traversal. Vendor resolution cascades through three strategies: GLN/VAT number lookup, then service participant matching, then name+address fuzzy matching.

**Validation:** `Check` delegates to three separate validators depending on source document type: base app `PEPPOL Validation` for sales documents, `PEPPOL Service Validation` for service documents, and `EDocPEPPOLValidation` (in this module) for reminders and finance charge memos. The in-module validator checks company info completeness, country/region codes, currency codes, and customer identification.

## Things to know

- `CreateBatch` is intentionally empty -- PEPPOL BIS 3.0 does not support batch export. The interface method exists only to satisfy the contract.
- The `"Embed PDF in export"` flag on E-Document Service controls whether a base64-encoded PDF is embedded inside the XML. This applies to invoices, credit memos, and shipments.
- Currency on import uses a subtle convention: if the document currency matches `GLSetup."LCY Code"`, it is left blank on the E-Document (BC convention for local currency). Only foreign currencies are stored explicitly.
- The `EDocumentStructuredFormat` enum is marked `ObsoleteState = Pending` for removal in v26 -- it bridges an older structured-format reader pattern that is being replaced by newer processing interfaces.
- When PEPPOL BIS 3.0 is selected as document format on a service, the `OnAfterValidateDocumentFormat` subscriber auto-populates supported document types (Sales Invoice, Sales Credit Memo, Service Invoice, Service Credit Memo).
- Shipment exports use a custom XML schema (not standard UBL Despatch Advice) -- they are simpler, flat structures with supplier/customer/delivery sections rather than full PEPPOL Despatch.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
