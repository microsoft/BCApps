# Helpers

Utility codeunits for E-Document processing: import matching (items, UOM, vendors), error logging, JSON manipulation, and log retrieval. These stateless helpers are called from import flows, export workflows, and UI pages to perform focused tasks without side effects.

## Quick reference

- **Parent:** [`src/`](../../CLAUDE.md)
- **Files:** 5 .al files
- **Key objects:** E-Document Import Helper (6109), E-Document Error Helper (6115), E-Document Log Helper (6133), E-Document JSON Helper (6117), E-Document Helper (6112)
- **Usage:** Called as procedures, no state maintained between invocations

## How it works

Import Helper provides RecordRef-based lookup procedures for resolving external identifiers to Business Central records. When an inbound invoice arrives with UOM = "EA" and item reference = "VENDOR-SKU-123", the import flow calls ResolveUnitOfMeasureFromDataImport() to map "EA" → "PCS" using UOM.International Standard Code, then calls FindItemReferenceForLine() to map "VENDOR-SKU-123" → Item No. "1000" using Item Reference table.

Error Helper wraps the Error Message framework with E-Document-specific context. LogErrorMessage(EDocument, RelatedRec, FieldNo, Message) stores the error with Context Record ID = EDocument.RecordId(), enabling drill-down from E-Document page to filtered error list. ErrorMessageCount()/HasErrors() check error state without raising exceptions, allowing import to accumulate validation failures and present them all at once.

Log Helper retrieves log entries by service + status combination. GetDocumentLog(EDocument, Service, Status) returns the most recent log matching all three filters, used when resuming import steps or exporting previously processed documents. GetServiceFromLog(EDocument) returns the service code of the latest log entry, enabling "retry last service" scenarios.

JSON Helper provides JSONToken-based path extraction and field setting. GetJsonToken(JsonText, Path) navigates nested JSON like "invoice.lines[0].item.code" and returns the value token. SetJsonValueInPath(JsonText, Path, Value) replaces values at paths, used for pre-export transformations.

E-Document Helper provides general utilities like GetEDocTok() (feature telemetry key), GetTelemetryDimensions() (standard dimension set for all telemetry), and IsElectronicDocument() checks on document records.

## Key files

- **EDocumentImportHelper.Codeunit.al** -- 51KB, largest helper; resolves UOM, item references, GTIN, account mappings, validates totals
- **EDocumentErrorHelper.Codeunit.al** -- Error Message wrapper with telemetry integration (FeatureTelemetry.LogError on each error)
- **EDocumentLogHelper.Codeunit.al** -- Log retrieval by service/status filters, service code extraction from logs
- **EDocumentJsonHelper.Codeunit.al** -- JSON path navigation, value extraction, value setting (used in Data Exchange format mapping)
- **EDocumentHelper.Codeunit.al** -- General utilities (telemetry keys, SystemId checks, IsElectronicDocument validation)

## Things to know

- **Import Helper methods return bool** -- True = success (item found, UOM resolved), False = failure (logs error, caller decides whether to continue)
- **ResolveUnitOfMeasureFromDataImport() tries 3 lookups** -- UOM.Code exact match → International Standard Code match → Description match; updates FieldRef if found
- **FindItemReferenceForLine() requires vendor context** -- Gets vendor from EDocument."Bill-to/Pay-to No.", filters Item Reference by Reference Type = Vendor + Reference Type No. = Vendor No.
- **FindItemForLine() uses GTIN field** -- Maps Item.GTIN = NoFieldRef.Value, expects GTIN stored in "No." field of temp line record
- **ErrorMessageCount() vs. HasErrors()** -- Count returns int (useful for telemetry: "Document has 5 errors"), HasErrors returns bool (faster for conditional checks)
- **LogErrorMessage() logs to telemetry** -- Calls FeatureTelemetry.LogError('0000LBJ', GetTelemetryFeatureName(), GetTelemetryImplErrLbl(), ErrorText, CallStack) for every error
- **ClearErrorMessages() deletes by RecordId** -- Removes all errors with Context Record ID = EDocument.RecordId() (used when resetting import, starting fresh attempt)
- **GetDocumentLog() requires exact service match** -- Filters by Service Code + Service Integration V2 + Document Format, ensuring log retrieved from correct service (prevents cross-service contamination)
- **JSON Helper handles nested paths** -- "invoice.lines[0].item" navigates through objects and arrays, returns null token if path doesn't exist (caller checks IsNull())

## Integration points

- **Error Message framework** -- ErrorHelper uses System.Utilities."Error Message" table, integrates with Show Errors action on pages
- **Item Reference lookups** -- FindItemReferenceForLine() checks Reference Type + Reference Type No. + Reference No. + Unit of Measure Code for exact match
- **UOM International Standard Code** -- ResolveUnitOfMeasureFromDataImport() uses ISO UOM codes (UN/CEFACT Recommendation 20) for cross-system mapping
- **Account Mapping table** -- FindGLAccountForLine() uses E-Doc. Mapping rules to map external account codes to G/L Account No.
- **Feature Telemetry** -- All errors logged via FeatureTelemetry.LogError with "E-Document" category, "E-Document Implementation Error" event name

## Error handling

- **UOMNotFoundErr** -- Raised by ResolveUnitOfMeasureFromDataImport() if UOM not resolved via any of 3 lookup methods (Code, Int'l Standard Code, Description)
- **ItemNotFoundErr** -- Raised by FindItemReferenceForLine() or FindItemForLine() if item not matched by reference or GTIN
- **AccountNotFoundErr** -- Raised by FindGLAccountForLine() if no E-Doc. Mapping rule matches external account code
- **TotalAmountMismatchErr** -- Raised by VerifyTotals() if sum of lines ≠ document total (used when service."Verify Totals" = true)
- **Errors logged, not raised** -- Import Helper methods call EDocErrorHelper.LogErrorMessage() and return false rather than throwing exceptions; caller accumulates errors and decides whether to abort

## Performance notes

- **Item Reference lookup optimized with filters** -- SetRange(Reference Type, Vendor) + SetRange(Reference Type No., VendorNo) narrows search before checking Reference No.
- **UOM lookup tries cheapest first** -- Code exact match (indexed PK) → Int'l Standard Code (indexed) → Description (full scan, last resort)
- **Error Message context filtering** -- SetContext(EDocument.RecordId) sets filter once, subsequent ErrorMessageCount()/HasErrors() reuse filter
- **JSON Helper avoids reparsing** -- Caller parses JSON once, passes JsonObject/JsonToken to GetJsonToken(); helper navigates in-memory structure
- **Log Helper uses FindLast()** -- GetDocumentLog() relies on Key1 (Entry No.) clustered index for efficient "most recent log" retrieval
