# PEPPOL Data Exchange Definition

The PEPPOL Data Exchange Definition folder provides Data Exchange Framework integration for PEPPOL BIS 3.0 export, using event-driven mapping between Business Central records and UBL XML. It implements pre-mapping transformations and XML namespace handling through event subscribers.

## Quick reference

- **Files:** 7 AL files (4 codeunits for mapping, 3 external interface codeunits)
- **ID range:** 6160-6162 (subscribers), 6163-6166 (pre-mapping)
- **Dependencies:** System.IO (Data Exchange Framework), Microsoft.Sales.Peppol
- **Integration pattern:** Event subscribers on Data Exchange Framework

## How it works

This folder extends the core Data Exchange Framework (used for bank feeds, payroll, etc.) to support PEPPOL BIS 3.0 XML export. The **EDocDEDPEPPOLSubscribers** codeunit is SingleInstance and subscribes to Export Generic XML events, intercepting Data Exchange export operations to inject PEPPOL-specific logic like namespace declarations, VAT calculations, and supplier/customer party information.

Pre-mapping codeunits (PreMapSalesInvLine, PreMapSalesCrMemoLine, etc.) transform Business Central line records before they reach the Data Exchange Framework, handling calculations like VAT amounts, unit prices, and allowance charges. The External codeunit provides an empty hook for partner extensions without breaking core logic.

The mapping flow works backwards from typical Data Exchange scenarios: instead of importing external data into BC, this exports BC data to external XML format. The framework reads Data Exch. Def. and Data Exch. Column Def. records to determine which fields to export and how to structure the XML tree.

## Structure

- `EDocDEDPEPPOLSubscribers.Codeunit.al` -- Event subscribers for XML generation
- `EDocDEDPEPPOLPreMapping.Codeunit.al` -- Pre-export data transformation
- `EDocDEDPEPPOLExternal.Codeunit.al` -- Partner extension hook (empty)
- `PreMapSalesInvLine.Codeunit.al` -- Sales Invoice Line transformation
- `PreMapSalesCrMemoLine.Codeunit.al` -- Sales Credit Memo Line transformation
- `PreMapServiceInvLine.Codeunit.al` -- Service Invoice Line transformation
- `PreMapServiceCrMemoLine.Codeunit.al` -- Service Credit Memo Line transformation

## Documentation

- [Business logic](business-logic.md) -- Event subscriber pattern, pre-mapping transforms, XML namespace handling

## Things to know

- **SingleInstance pattern:** EDocDEDPEPPOLSubscribers is marked SingleInstance to maintain state across multiple event calls during a single export operation (e.g., storing VAT calculations).
- **State initialization:** InitInstance sets TaxSubtotalLoopNumber, AllowanceChargeLoopNumber, DataExchEntryNo, and ProcessedDocType at the start of each export. ClearInstance resets state at completion.
- **IsEDocExport detection:** Event subscribers check if the Data Exch. Def. Code is registered in E-Doc. Service Data Exch. Def. table to determine if this is an e-document export (not a regular data exchange).
- **XML namespace declaration:** OnBeforeCreateRootElement subscriber adds 5 PEPPOL namespaces (cac, cbc, ccts, qdt, udt) as attributes on the root Invoice/CreditNote element.
- **Lazy VAT calculation:** VAT amounts are calculated once per document in PrepareHeaderAndVAT (triggered by /Invoice/cbc:ID or /CreditNote/cbc:ID paths) and cached in module variables for reuse.
- **PEPPOL Management codeunit:** Delegates party info extraction to Microsoft.Sales.Peppol."PEPPOL Management" codeunit, which contains standard PEPPOL business logic.
- **Loop number tracking:** TaxSubtotalLoopNumber and AllowanceChargeLoopNumber increment for each VAT line/charge line to generate unique XML element IDs.
- **Document type enum mapping:** ProcessedDocType stores the E-Document Type enum value to determine which pre-mapping logic to apply.
- **External codeunit hook:** Partners can extend EDocDEDPEPPOLExternal to inject custom logic without modifying sealed subscribers.
- **Pre-mapping vs event subscribers:** Pre-mapping runs before Data Exchange Framework processes records (modifies source data). Event subscribers run during XML generation (modifies XML output).
