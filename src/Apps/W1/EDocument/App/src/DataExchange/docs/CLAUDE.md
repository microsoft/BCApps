# DataExchange

Bridges the E-Document framework to BC's standard Data Exchange Framework for PEPPOL BIS 3.0 import and export. This module is the older, Data Exchange Definition-based approach to format handling -- the newer approach is the `IEDocument` interface in the Format module. Both coexist and can be selected per service.

## How it works

`EDocDataExchangeImpl.Codeunit.al` implements the `IEDocument` interface using Data Exchange Definitions. On export, it looks up the correct Data Exchange Definition from `E-Doc. Service Data Exch. Def.` for the service + document type combination, creates a `Data Exch.` record, and runs `ExportFromDataExch`. On import, `GetBasicInfoFromReceivedDocument` tries every registered import definition to find the best match (the one producing the most intermediate data records), then `GetCompleteInfoFromReceivedDocument` processes that intermediate data into Purchase Header/Line records.

The `PEPPOL Data Exchange Definition` subfolder contains pre-mapping codeunits (`PreMapSalesInvLine`, `PreMapSalesCrMemoLine`, `PreMapServiceInvLine`, `PreMapServiceCrMemoLine`) that transform BC records before export. `EDocDEDPEPPOLSubscribers.Codeunit.al` is a SingleInstance codeunit that hooks into data exchange events to handle PEPPOL-specific logic like tax subtotals and allowance charges. `EDocDEDPEPPOLExternal.Codeunit.al` provides external handler entry points.

## Things to know

- The `FindDataExchAndDocumentType` method is a brute-force approach: it runs every registered import definition against the incoming blob and picks the one yielding the most intermediate records. This involves Commit() calls inside a loop.
- Batch processing is explicitly not supported (`BatchNotSupportedErr`) -- this implementation works document-by-document only.
- The `OnBeforeCheckRecRefCount` subscriber suppresses empty-record-count errors for e-document exports, since not all related data (e.g., Document Attachments) will exist for every document.
- Import creates temporary Purchase Header/Line records from intermediate data, handling field type conversion via `Config. Validate Management`. Document attachments embedded as Base64 in the XML are also extracted.
- `E-Doc. Service Data Exch. Def.` (`EDocServiceDataExchDef.Table.al`) links a service code + document type to separate import and export Data Exchange Definition codes.
- The import intermediate table safety check (`DataExchDefUsesIntermediate`) ensures that only definitions using intermediate tables are considered, preventing accidental direct database inserts.
- Header field extraction during `GetBasicInfo` uses XPath navigation with namespace handling -- the root element's default namespace and all `xmlns:` prefixed namespaces are registered on the namespace manager before queries.
- Integration events `OnAfterDataExchangeInsert` and `OnBeforeDataExchangeExport` let extensions modify the Data Exch. record or inject additional processing before the actual export runs.
