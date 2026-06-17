# Data exchange

An alternative to the interface-based Format module -- this implements the `"E-Document"` interface by delegating to BC's built-in Data Exchange Definition framework for field-by-field XML mapping. Rather than writing custom XML generation code, you configure Data Exchange Definitions and column mappings in the UI. The `PEPPOL Data Exchange Definition/` subfolder provides the pre-mapping codeunits that prepare data before Data Exchange processes it.

## How it works

`EDocDataExchangeImpl` implements the same `"E-Document"` interface as the Format module's PEPPOL codeunit, but its `Create` method works differently. It looks up the `E-Doc. Service Data Exch. Def.` table to find the export Data Exchange Definition for the document type, creates a `Data Exch.` record with line filters, and calls `DataExch.ExportFromDataExch` to run the configured mapping. The resulting XML blob is extracted from the Data Exch record's field 3. For import, `GetCompleteInfoFromReceivedDocument` uses the import Data Exchange Definition to parse incoming XML into `Intermediate Data Import` records, which are then processed by `EDocDEDPEPPOLPreMapping`.

The `E-Doc. Service Data Exch. Def.` table links an E-Document Service code and document type to both an import and export Data Exchange Definition code, displayed via the `E-Doc. Service Data Exch. Sub` subpage on the service card.

**Pre-mapping codeunits** run before Data Exchange processing to transform raw PEPPOL data into BC-compatible values. `EDocDEDPEPPOLPreMapping` is the main import pre-mapper -- it validates currencies, resolves buy-from/pay-to vendors, finds related invoices for credit memos, processes line items, and applies invoice charges. The `PreMapSalesInvLine`, `PreMapSalesCrMemoLine`, `PreMapServiceInvLine`, and `PreMapServiceCrMemoLine` codeunits filter out rounding lines before export to avoid PEPPOL schema violations.

`EDocDEDPEPPOLSubscribers` is a `SingleInstance` codeunit that manages state across the Data Exchange export process. It subscribes to events on `EDocDataExchangeImpl` and `Export Generic XML`, injecting UBL namespace declarations and tracking loop counters for tax subtotals and allowance charges.

## Things to know

- `EDocDEDPEPPOLExternal` is a dummy codeunit with an empty `OnRun` -- it exists solely to be referenced as the "External Data Handling Codeunit" in Data Exchange Definitions, satisfying a BC framework requirement.
- The Data Exchange approach is more configurable but less flexible than the XMLport-based Format approach. Localizations that need complex XML structures often use the Format interface directly.
- The pre-mapping import path validates that referenced purchase invoices are posted before allowing credit memo creation (`YouMustFirstPostTheRelatedInvoiceErr`).
- `EDocDEDPEPPOLSubscribers` uses `SingleInstance` because the Data Exchange framework processes records one at a time through event subscribers, and state (loop counters, VAT amounts) must persist across those calls.
- On export, the `OnAfterDataExchangeInsert` and `OnBeforeDataExchangeExport` integration events let subscribers customize behavior per document type.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
