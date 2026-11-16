# Data exchange

An alternative to the interface-based Format module -- this implements the `"E-Document"` interface by delegating to BC's built-in Data Exchange Definition framework for field-by-field XML mapping. Rather than writing custom XML generation code, you configure Data Exchange Definitions and column mappings in the UI. The `PEPPOL Data Exchange Definition/` subfolder provides the pre-mapping codeunits that prepare data before Data Exchange processes it.

## How it works

*Updated: 2026-07-29 -- Added resource-backed definitions and the Data Exchange to import v2 bridge.*

`EDocDataExchangeImpl` implements the same `"E-Document"` interface as the Format module's PEPPOL codeunit, but its `Create` method works differently. It looks up the `E-Doc. Service Data Exch. Def.` table to find the export Data Exchange Definition for the document type, creates a `Data Exch.` record with line filters, and calls `DataExch.ExportFromDataExch` to run the configured mapping. The resulting XML blob is extracted from the Data Exch record's field 3.

For import, Data Exchange is now a bridge into the v2 import pipeline. `GetBasicInfoFromReceivedDocument` tests import Data Exchange Definitions that map only through `Intermediate Data Import`, picks the definition that yields the most intermediate rows, stores that definition code and document type on the E-Document, and then extracts header fields by reusing the Data Exchange paths. `GetCompleteInfoFromReceivedDocument` runs the selected definition, processes the Data Exchange, and converts the intermediate rows into temporary purchase header, purchase line, and attachment records for the caller.

The definitions are packaged as app resource files under `.resources/DataExchange/*.xml`. `E-Document Install` loads them with `NavApp.GetResource` and XMLport `Imp / Exp Data Exch Def & Map`; upgrade code also imports the v2 invoice and credit memo definitions so existing tenants receive the bridge definitions. The AL labels now name resource paths rather than carrying the XML payload.

The `E-Doc. Service Data Exch. Def.` table links an E-Document Service code and document type to both an import and export Data Exchange Definition code, displayed via the `E-Doc. Service Data Exch. Sub` subpage on the service card.

**Pre-mapping codeunits** run before Data Exchange processing to transform raw PEPPOL data into BC-compatible values. `EDocDEDPEPPOLPreMapping` is the main import pre-mapper -- it validates currencies, resolves buy-from/pay-to vendors, finds related invoices for credit memos, processes line items, and applies invoice charges. The `PreMapSalesInvLine`, `PreMapSalesCrMemoLine`, `PreMapServiceInvLine`, and `PreMapServiceCrMemoLine` codeunits filter out rounding lines before export to avoid PEPPOL schema violations.

`EDocDEDPEPPOLSubscribers` is a `SingleInstance` codeunit that manages state across the Data Exchange export process. It subscribes to events on `EDocDataExchangeImpl` and `Export Generic XML`, injecting UBL namespace declarations and tracking loop counters for tax subtotals and allowance charges.

## Things to know

*Updated: 2026-07-29 -- Noted the public Data Exchange implementation surface and v2 definitions.*

- `EDocDEDPEPPOLExternal` is a dummy codeunit with an empty `OnRun` -- it exists solely to be referenced as the "External Data Handling Codeunit" in Data Exchange Definitions, satisfying a BC framework requirement.
- `E-Doc. Data Exchange Impl.` is no longer marked `Access = Internal`, so the Data Exchange implementation is part of the app surface instead of being confined to this module.
- The v2 PEPPOL import resources create purchase-draft definitions (`EDOCPEPINVPURCHDRAFT` and `EDOCPEPCMPURCHDRAFT`) that target `Purchase Header`, `Purchase Line`, and `Document Attachment` through `Intermediate Data Import`.
- The Data Exchange approach is more configurable but less flexible than the XMLport-based Format approach. Localizations that need complex XML structures often use the Format interface directly.
- The pre-mapping import path validates that referenced purchase invoices are posted before allowing credit memo creation (`YouMustFirstPostTheRelatedInvoiceErr`).
- `EDocDEDPEPPOLSubscribers` uses `SingleInstance` because the Data Exchange framework processes records one at a time through event subscribers, and state (loop counters, VAT amounts) must persist across those calls.
- On export, the `OnAfterDataExchangeInsert` and `OnBeforeDataExchangeExport` integration events let subscribers customize behavior per document type.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
