# Patterns

## Interface-driven plugin architecture

**Problem:** The framework needs to support arbitrary document formats and service connectors without modification.

**How it works:** Format and service implementations are wired via AL enum extensions with interface implementations. The `E-Document Format` enum maps to the `"E-Document"` interface (format serialization). The `Service Integration` enum maps to multiple integration interfaces (IDocumentSender, IDocumentReceiver, etc.). Adding a new format or connector means extending the enum and providing implementations -- no framework code changes needed.

The same pattern repeats throughout the import pipeline: `Structure Received E-Doc.` enum maps to IStructureReceivedEDocument, `E-Doc. Read into Draft` maps to IStructuredFormatReader, `E-Doc. Process Draft` maps to IProcessStructuredData, and `E-Doc. Create Purchase Invoice` maps to IEDocumentFinishDraft.

**Key files:** `src/Document/EDocumentFormat.Enum.al`, `src/Integration/ServiceIntegration.Enum.al`, `src/Processing/Import/StructureReceivedEDoc.Enum.al`, `src/Processing/Import/EDocReadIntoDraft.Enum.al`, `src/Processing/Import/EDocProcessDraft.Enum.al`.

**Gotcha:** The enum value on the E-Document record determines which implementation runs. During import, these values cascade -- the output of one stage can override the implementation selector for the next stage. This means the actual execution path is determined at runtime, not by static configuration alone. See `ImportEDocumentProcess.StructureReceivedData` where the returned IStructuredDataType can set `Read into Draft Impl.`.

## Dual status pattern

**Problem:** An e-document can be sent to multiple services, each with its own lifecycle. The framework needs document-level status for the user and per-service status for processing.

**How it works:** Three parallel state machines operate simultaneously:

1. `E-Document.Status` -- the document-level rollup (Error, In Progress, Processed). Computed by iterating all service status records and applying worst-case logic (any error = error, any in-progress = in-progress, all done = processed).
2. `E-Document Service Status.Status` -- per-service lifecycle (Created, Exported, Sent, Imported, etc.). This is what the processing logic actually reads and writes.
3. `E-Document Service Status."Import Processing Status"` -- import-specific sub-status (Received, Structured, Read, Prepared, Processed). Auto-cascades to Service Status via OnValidate.

**Key files:** `src/Document/Status/EDocumentServiceStatus.Enum.al` (each value implements `IEDocumentStatus` to map back to document-level status), `src/Processing/EDocumentProcessing.Codeunit.al` (the rollup logic in `ModifyEDocumentStatus`), `src/Service/EDocumentServiceStatus.Table.al` (the OnValidate cascade).

**Gotcha:** Adding a new service status enum value requires implementing the `IEDocumentStatus` interface to specify which document-level status it maps to. The status codeunits in `src/Document/Status/` (EDocErrorStatus, EDocInProgressStatus, EDocProcessedStatus) show how existing values are mapped.

## Commit-Run-Log error handling

**Problem:** Interface implementations can fail with runtime errors. The framework needs to catch these failures without rolling back previously committed work, especially in batch scenarios.

**How it works:** Before calling any interface implementation, the framework calls `Commit()` to persist the current transaction. Then it calls the implementation via `Codeunit.Run()`, which creates an implicit savepoint. If the run fails, the error is caught via `GetLastErrorText()`, logged using `EDocumentErrorHelper`, and processing continues to the next document or step.

**Key files:** `src/Integration/EDocIntegrationManagement.Codeunit.al` (RunSend, RunReceive methods), `src/Processing/Import/ImportEDocumentProcess.Codeunit.al` (the OnRun trigger wraps the step execution).

**Gotcha:** The `Commit()` before `Codeunit.Run()` means you cannot roll back work done before the commit. This is by design -- it prevents a failing document from undoing the processing of previously successful documents in a batch. But it also means interface implementations should not assume they can roll back framework-level state changes.

## Context objects

**Problem:** Interface implementations need access to HTTP state, blob content, and status-setting capabilities, but these should be framework-managed with automatic logging.

**How it works:** Three context codeunits -- `SendContext`, `ReceiveContext`, and `ActionContext` -- carry state between the framework and connector implementations. Each context provides:

- `GetTempBlob()` / `SetTempBlob()` -- the document blob being sent or received
- `Http()` -- returns an `HttpMessageState` codeunit holding the request and response messages
- `Status()` -- returns an `IntegrationActionStatus` codeunit for setting the resulting service status

The framework pre-populates the context (e.g., setting the blob from the export log) and post-processes it (e.g., logging the HTTP messages to the integration log). Connector implementations just need to fill in the HTTP request and call the API.

**Key files:** `src/Integration/Send/SendContext.Codeunit.al`, `src/Integration/Receive/ReceiveContext.Codeunit.al`, `src/Integration/Actions/ActionContext.Codeunit.al`, `src/Integration/Actions/HttpMessageState.Codeunit.al`.

**Gotcha:** If a connector implementation does not populate the HTTP request/response on the context, no communication log entry is created. The framework logs whatever is on the context's Http() state after the call returns, so make sure to set it even for non-standard HTTP flows.

## Draft-based import with ephemeral staging tables

**Problem:** Incoming e-documents need human review before becoming BC documents. The raw external data and BC-resolved data need to coexist during review.

**How it works:** The V2 import pipeline uses `E-Document Purchase Header` and `E-Document Purchase Line` as staging areas. These tables have a deliberate dual-field design: external fields hold raw data from the sender (vendor name, external item IDs, free-text descriptions) while `[BC]`-prefixed fields hold resolved BC values (vendor no., item no., G/L account). The Prepare Draft stage populates the BC fields; the user can review and override them on the draft page; the Finish Draft stage reads the BC fields to create the actual document.

After Finish Draft succeeds, the staging records are deleted by `IProcessStructuredData.CleanUpDraft`. The `E-Doc. Record Link` table that connected staging records to BC records via SystemId is also cleaned up.

**Key files:** `src/Processing/Import/Purchase/EDocumentPurchaseHeader.Table.al`, `src/Processing/Import/Purchase/EDocumentPurchaseLine.Table.al`, `src/Processing/EDocRecordLink.Table.al`.

**Gotcha:** Draft tables are ephemeral -- if you need to debug or audit what the draft contained, you must look at the E-Document logs and data storage, not the staging tables (they are gone after processing). Also, `E-Document Purchase Line.OnDelete` cascades to clean up PO match records, so deleting draft lines has side effects.

## Metadata-driven mapping system

**Problem:** Different services and countries need different field transformations during export without writing custom code.

**How it works:** The `E-Doc. Mapping` table stores user-defined rules per service, specifying a table/field, a find value, a replace value, and an optional transformation rule (from BC's standard Transformation Rule table). During export, `EDocExport` applies all active mappings for the service. Each application is logged to `E-Doc. Mapping Log` for audit.

Mappings can be flagged `For Import` to apply during inbound processing as well. The `Indent` field controls ordering within a mapping set. The `Used` flag tracks whether a mapping actually fired during processing.

**Key files:** `src/Mapping/EDocMapping.Table.al`, `src/Mapping/EDocMappingLog.Table.al`.

**Gotcha:** Mappings apply to field values after the format interface has created the blob. For code-based formats, this means they operate on the serialized output. For Data Exchange Definitions, they operate on the intermediate data. The interaction between mapping and format is format-specific.

## Historical learning system

**Problem:** Repeated imports from the same vendor should improve over time -- auto-matching vendors and line items based on past decisions.

**How it works:** Two history tables accumulate knowledge:

- `E-Doc. Purchase Line History` records how each incoming line was resolved (which BC item or account, which vendor, what description matched). It has indices for fuzzy matching by vendor + description, vendor + item reference, and vendor + external item code.
- `E-Doc. Vendor Assign. History` records how external vendor identifiers were resolved to BC vendor numbers.

During Prepare Draft, the provider interfaces query these tables before falling back to other resolution strategies. The Copilot AI tools (`EDocHistoricalMatching` in `src/Processing/AI/Tools/`) also query history as a function calling tool.

**Key files:** `src/Processing/Import/Purchase/History/EDocPurchaseLineHistory.Table.al`, `src/Processing/Import/Purchase/History/EDocVendorAssignHistory.Table.al`, `src/Processing/Import/Purchase/History/EDocPurchaseHistMapping.Codeunit.al`.

**Gotcha:** History is append-only. There is no deduplication or aging. Over time, history tables can grow large for high-volume vendors. The matching queries use multiple index paths, so query performance depends on having the right keys -- check the table's key definitions if you see slow matching.

## AI tool provider pattern

**Problem:** Copilot needs structured access to matching logic, but the AI system should not embed business logic directly.

**How it works:** Four codeunits in `src/Processing/AI/Tools/` implement AI function calling tools that Copilot can invoke: `EDocDeferralMatching` (spread amounts across periods), `EDocGLAccountMatching` (find G/L accounts), `EDocHistoricalMatching` (query purchase line history), and `EDocSimilarDescriptions` (fuzzy-match item descriptions). The AI processor in `src/Processing/AI/EDocAIToolProcessor.Codeunit.al` registers these tools with the AI runtime and handles the function call dispatch.

**Key files:** `src/Processing/AI/Tools/`, `src/Processing/AI/EDocAIToolProcessor.Codeunit.al`.

**Gotcha:** The AI tools use buffer tables (`EDocHistoricalMatchBuffer`, `EDocLineMatchBuffer`) to communicate results back to the Copilot runtime. These are temporary tables, not persisted. The `IEDocAISystem` interface (in `src/Processing/Interfaces/`) allows overriding the AI system configuration.

## Legacy patterns

### V1 "E-Document Integration" interface

The original integration interface (`src/Integration/EDocumentIntegration.Interface.al`) combined sending and receiving into a single interface. It is obsolete and wrapped behind `CLEAN26` compiler directives. New connectors should implement IDocumentSender and IDocumentReceiver separately. The V1 interface required connectors to manage HTTP requests directly and return blobs, while V2 connectors use context objects that handle logging automatically.

### V1 import process

The V1 import (`ImportEDocumentProcess.ProcessEDocumentV1`) is a single-step process that directly creates a purchase document from the received blob without staging tables. It uses the `E-Document Integration` interface's `GetBasicInfo` and then `EDocImport` (in `src/Processing/EDocImport.Codeunit.al`) to create the document. V1 does not support undo/redo, draft review, or AI matching. It is still the default when `E-Document Service."Import Process"` is set to "Version 1.0".

### Direct Error Message manipulation

Older parts of the codebase manipulate `Error Message` records directly. This is fragile because it requires knowing the correct context and filtering. All new code should use `EDocumentErrorHelper` (in `src/Helpers/EDocumentErrorHelper.Codeunit.al`), which provides properly scoped methods: `LogSimpleErrorMessage`, `LogErrorMessage` (with field reference), `LogWarningMessage`, and `ErrorMessageCount`. The helper ensures errors are linked to the correct E-Document and visible on the document card.
