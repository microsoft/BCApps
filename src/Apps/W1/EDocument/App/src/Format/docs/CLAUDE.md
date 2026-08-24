# Format

PEPPOL BIS 3.0 adapter for E-Document Core. The reusable PEPPOL 3.0 validation and XMLport implementations now live in the standalone `Microsoft.Peppol` app; this module keeps the E-Document interface wrapper, the incoming PEPPOL reader, and the E-Document-specific financial result and shipment exporters. Localizations add their own formats via the extensible `E-Document` enum; this module provides the W1 baseline.

## How it works

*Updated: 2026-07-29 -- Reflected the standalone PEPPOL app split, purchase-order export, scoped file extension, and prefixed-root import support.*

The main entry point is `EDocPEPPOLBIS30.Codeunit.al`, which implements the `"E-Document"` interface with five methods: `Check`, `Create`, `CreateBatch`, `GetBasicInfoFromReceivedDocument`, and `GetCompleteInfoFromReceivedDocument`.

**Export path:** `Create` dispatches by document type to dedicated XML generators. Sales and service invoices and credit memos use the standalone PEPPOL 3.0 XMLports (`Sales Invoice - PEPPOL30`, `Sales Cr.Memo - PEPPOL30`) and pass the sales or service format selected in `PEPPOL 3.0 Setup`. Purchase orders use `Export Purchase Order PEPPOL30` with the purchase format from the same setup table. Shipments and transfer shipments still use E-Document Core codeunits (`EDocShipmentExportToXml`, `EDocTransferShptToXML`) that build XML via `XML DOM Management`. Reminders and finance charge memos share the `FinResultsPEPPOLBIS30` XMLport, which wraps them as UBL Invoice documents with special type codes. After generation, `OnAfterCreatePEPPOLXMLDocument` fires as an integration event, letting subscribers modify the XML blob before it leaves the format layer.

**Import path:** `EDocImportPEPPOLBIS30` parses incoming UBL XML into temporary `Purchase Header` / `Purchase Line` records. It uses `XML Buffer` (not DOM) for XPath-style traversal. The reader detects the root element path once and builds all invoice or credit memo lookups from that path, so PEPPOL files whose root element has a namespace prefix are handled the same as unprefixed roots. Vendor resolution cascades through GLN/VAT number lookup, service participant matching, then name+address fuzzy matching.

**Validation:** `Check` uses the `PEPPOL30 Validation` interface implementation selected by `PEPPOL 3.0 Setup` for sales and service documents, and keeps `EDocPEPPOLValidation` in this module for reminders and finance charge memos. The in-module validator checks company info completeness, country/region codes, currency codes, and customer identification.

## Things to know

*Updated: 2026-07-29 -- Added current PEPPOL setup and file-extension behavior.*

- `CreateBatch` is intentionally empty -- PEPPOL BIS 3.0 does not support batch export. The interface method exists only to satisfy the contract.
- The `"Embed PDF in export"` flag on E-Document Service controls whether a base64-encoded PDF is embedded inside the XML. This applies to invoices, credit memos, shipments, and purchase orders.
- `SetFileExt` appends `.xml` only when the E-Document log's `Document Format` is `PEPPOL BIS 3.0`, so other formats that export through the log are not forced to use the PEPPOL extension.
- Currency on import uses a subtle convention: if the document currency matches `GLSetup."LCY Code"`, it is left blank on the E-Document (BC convention for local currency). Only foreign currencies are stored explicitly.
- The `EDocumentStructuredFormat` enum is marked `ObsoleteState = Pending` for removal in v26 -- it bridges an older structured-format reader pattern that is being replaced by newer processing interfaces.
- When PEPPOL BIS 3.0 is selected as document format on a service, the `OnAfterValidateDocumentFormat` subscriber auto-populates only Sales Invoice, Sales Credit Memo, Service Invoice, and Service Credit Memo. Purchase-order export exists, but this subscriber does not add that type automatically.
- Shipment exports use a custom XML schema (not standard UBL Despatch Advice) -- they are simpler, flat structures with supplier/customer/delivery sections rather than full PEPPOL Despatch.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
