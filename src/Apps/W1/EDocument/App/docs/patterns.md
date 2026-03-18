# Patterns

## Service/connector plugin model

**Problem**: Country-specific e-invoicing standards require different serialization formats and different transmission protocols, but the core lifecycle (create, export, send, receive, import) is the same everywhere.

**Solution**: The `E-Document Service` table stores two enum fields: `Document Format` (how to serialize) and `Service Integration V2` (how to transmit). Each enum value maps to an interface implementation resolved at runtime. This means PEPPOL BIS 3.0 format can be paired with any HTTP connector, and a new country only needs to add enum extensions and implement the relevant interfaces.

**Example**: `EDocExport.Codeunit.al` resolves the format interface via `EDocumentInterface := EDocumentService."Document Format"` and then calls `EDocumentInterface.Check(...)` and `EDocumentInterface.Create(...)`. The integration side works the same way in `EDocIntegrationManagement.Codeunit.al`.

**Gotcha**: The enum-to-interface binding is compile-time in AL. You cannot dynamically register implementations -- you must create an enum extension in your app. If two apps extend the same enum value, you get a compile error.

## Dual-level status state machine

**Problem**: An E-Document can be processed by multiple services simultaneously (e.g., sent to both a tax authority and an archival service). Each service can be at a different stage, but the user needs a single overall status.

**Solution**: Three-tier status: `E-Document.Status` (document-level, derived), `E-Document Service Status.Status` (per-service, set directly), and `E-Document Service Status.Import Processing Status` (V2 import pipeline, drives service status via OnValidate trigger). The document-level status is computed by scanning all service statuses -- any error wins, then any in-progress, otherwise processed.

**Example**: `EDocumentProcessing.ModifyEDocumentStatus` iterates service status records using the `IEDocumentStatus` interface (implemented by `EDocErrorStatus`, `EDocInProgressStatus`, `EDocProcessedStatus` in `src/Document/Status/`).

**Gotcha**: The import processing status auto-updates the service status via an OnValidate trigger on the `Import Processing Status` field. If you modify it directly via SQL or skip validation, the service status and document status will be out of sync.

## Staged import processing (V2 pipeline)

**Problem**: Converting a received e-invoice into a BC purchase document involves multiple fallible steps (OCR, vendor matching, item matching, document creation). If any step fails, you want to retry from that point, not start over.

**Solution**: Four independent stages, each wrapped in `Codeunit.Run()` with explicit undo support. `ImportEDocumentProcess.Codeunit.al` dispatches to the correct stage based on the `Import E-Document Steps` enum. Each stage advances the `Import Processing Status` (Unprocessed to Readable to Ready for draft to Draft ready to Processed). Each stage can be undone independently -- `UndoProcessingStep` clears the relevant fields and reverts the status.

**Example**: The "Structure received data" stage calls `IStructureReceivedEDocument.StructureReceivedEDocument`, stores the result, and updates `Structured Data Entry No.`. Undoing it clears `Structured Data Entry No.` back to 0.

**Gotcha**: V1 and V2 coexist. `ImportEDocumentProcess.OnRun` checks `GetImportProcessVersion()` and branches -- V1 skips to "Finish draft" and calls the legacy single-step import. If the service is configured for V1, stages 1-3 are no-ops.

## Provider pattern

**Problem**: Different countries and business configurations need different logic for resolving vendors, items, accounts, and units of measure from external e-document data.

**Solution**: The `IVendorProvider`, `IItemProvider`, `IUnitOfMeasureProvider`, `IPurchaseLineAccountProvider`, and `IPurchaseOrderProvider` interfaces in `src/Processing/Interfaces/` are called during the "Prepare draft" stage. `EDocProviders.Codeunit.al` orchestrates the calls. Default implementations use historical matching tables and BC cross-references; extensions can override with custom lookup logic.

**Example**: `IVendorProvider.GetVendor` receives the E-Document record and returns a `Vendor` record. The default implementation checks `E-Doc. Vendor Assign. History` first, then falls back to VAT registration number lookups.

**Gotcha**: Provider implementations must handle the "not found" case gracefully by returning an empty record, not by throwing an error. The pipeline will log a warning and allow manual resolution via the draft UI.

## Context objects for integration calls

**Problem**: Integration implementations need access to the document blob, HTTP state for logging, and a way to control the resulting status -- but passing all these as separate parameters creates unwieldy signatures.

**Solution**: `SendContext`, `ReceiveContext`, and `ActionContext` codeunits (in `src/Integration/Send/`, `src/Integration/Receive/`, `src/Integration/Actions/`) bundle the blob, HTTP message state, and status control into a single parameter. The framework reads from these after the call to automatically log HTTP exchanges and determine the next status.

**Example**: In `EDocIntegrationManagement.Send`, the framework creates a `SendContext`, sets the blob, and passes it to `IDocumentSender.Send`. After the call, it reads `SendContext.Http().GetHttpRequestMessage()` and `SendContext.Http().GetHttpResponseMessage()` to populate the integration log, and `SendContext.Status().GetStatus()` to determine the service status.

**Gotcha**: If your integration sets `SendContext.Status().SetStatus(Enum::"E-Document Service Status"::"Pending Response")`, you must also implement `IDocumentResponseHandler` or the document will stay in "Pending Response" forever. The framework does not validate this at configuration time.

## Try-commit-run error boundary

**Problem**: Format and integration implementations are third-party code. A runtime error in an implementation would roll back the calling transaction, losing the E-Document record and audit trail.

**Solution**: Before calling any interface implementation, the framework commits the current transaction. The interface call runs via `Codeunit.Run()`, which creates an implicit try-catch. If it fails, `GetLastErrorText()` captures the error and logs it via `EDocumentErrorHelper`. The E-Document and its logs survive because they were committed before the failing call.

**Example**: `EDocIntegrationManagement.Send` commits, then calls `RunSend` (which uses `Codeunit.Run` internally). On failure, it calls `AddLogAndUpdateEDocument` with a "Sending Error" status.

**Gotcha**: This means interface implementations see a committed database state. If they make their own database writes and then fail partway through, those writes are also committed and not rolled back. Extension authors must be aware that partial state from a failed implementation call persists.

## Workflow-driven orchestration

**Problem**: Outbound e-document processing involves multiple steps (export, send, email, batch) that vary by business configuration. Hard-coding the sequence is inflexible.

**Solution**: The framework uses BC's standard Workflow engine. `EDocumentWorkFlowProcessing.Codeunit.al` registers entry points (document created) and response steps (export, send, send via email, evaluate batch). The Document Sending Profile must reference an enabled Workflow that contains E-Document Service steps. This allows administrators to configure multi-step flows like "export with PEPPOL, send to tax authority, then email PDF to customer" without code changes.

**Example**: `EDocumentWorkFlowSetup.Codeunit.al` registers the available workflow events and response steps. `EDocumentCreatedFlow.Codeunit.al` provides the entry point event.

**Gotcha**: Workflows are required even for simple send scenarios. If a Document Sending Profile references an E-Document Service Flow that is not enabled or does not exist, posting will fail with an error from `EDocExport.CheckEDocument`.

## Legacy patterns

### The obsolete `Service Integration` enum and `E-Document Integration` interface

Before v26, there was a single `Service Integration` enum and a monolithic `E-Document Integration` interface that combined send, receive, and response handling. This has been replaced by `Service Integration V2` with split interfaces (`IDocumentSender`, `IDocumentReceiver`, `IDocumentResponseHandler`, `IReceivedDocumentMarker`, `ISentDocumentActions`). Code gated by `#if not CLEAN26` handles backward compatibility. New connectors should always use V2.

### V1 import path

The V1 import path uses `GetBasicInfoFromReceivedDocument` and `GetCompleteInfoFromReceivedDocument` on the `E-Document` format interface to directly create a purchase document in a single step. It does not use the draft tables, the provider pattern, or the staged pipeline. It is preserved for backward compatibility with existing format implementations but should not be used for new development. The V2 path provides better error recovery, user review via the draft UI, and pluggable matching logic.

### Direct table mapping vs. draft tables

V1 used `E-Document Header Mapping` (6102) and `E-Document Line Mapping` (6105) as lightweight mapping records during import. V2 replaced these with the richer `E-Document Purchase Header` (6100) and `E-Document Purchase Line` (6101) tables that carry both raw and resolved data. The V1 mapping tables still exist in the schema but are only populated when the V1 import path runs.
