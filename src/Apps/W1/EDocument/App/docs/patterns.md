# Patterns

This document covers the recurring code patterns used in E-Document Core and, just as importantly, the legacy patterns you should avoid. For the full processing flows, see [business-logic.md](business-logic.md). For extension contracts, see [extensibility.md](extensibility.md).

## Interface polymorphism via enum dispatch

The most pervasive pattern in the codebase. Rather than using abstract codeunits or event-based dispatch, the framework uses AL's enum-implements-interface feature as a strategy + factory pattern. An extensible enum value binds to a codeunit that implements the interface. Configuration stores the enum value; runtime reads it and dispatches.

This pattern appears in:

- `"E-Document Format"` (`enum 6101`) implements `"E-Document"` interface -- format serialization
- `"Service Integration"` (`enum 6151`) implements `IDocumentSender`, `IDocumentReceiver`, `IConsentManager` -- service communication
- `"Integration Action Type"` (`enum 6170`) implements `IDocumentAction` -- extensible actions
- `"E-Document Service Status"` (`enum 6106`) implements `IEDocumentStatus` -- status-dependent behavior
- `"Structure Received E-Doc."` (`enum 6120`) implements `IStructureReceivedEDocument` -- structuring raw data
- `"E-Doc. Read into Draft"` (`enum 6113`) implements `IStructuredFormatReader` -- parsing structured data
- `"E-Doc. Process Draft"` (`enum 6112`) implements `IProcessStructuredData` -- draft preparation
- `"E-Document Type"` (`enum 6105`) implements `IEDocumentFinishDraft` -- document creation per type
- `"Export Eligibility Evaluator"` implements `IExportEligibilityEvaluator` -- export gating
- `"E-Doc. File Format"` implements `IEDocFileFormat`, `IBlobType` -- file type behavior

The enum value is stored on the E-Document or Service table and read at the dispatch site. For example, in `ImportEDocumentProcess.ReadIntoDraft()`:

```al
IStructuredFormatReader := EDocument."Read into Draft Impl.";
EDocument."Process Draft Impl." := IStructuredFormatReader.ReadIntoDraft(EDocument, FromBlob);
```

This is clean but has a consequence: the dispatch decision is locked to a single field value. You cannot chain implementations or compose behaviors without building that into the interface contract.

## Error-trapping codeunit wrapper ("if codeunit.run")

Every call to an external interface implementation is wrapped in a dedicated codeunit that runs inside a `if not Codeunit.Run()` pattern. The framework commits before the call, runs the wrapper codeunit, and catches runtime errors. This isolates interface failures from the calling transaction.

Concrete wrappers include `EDocumentCreate.Codeunit.al` (for format `Create`), `SendRunner.Codeunit.al` (for `IDocumentSender.Send`), `ReceiveDocuments.Codeunit.al`, `DownloadDocument.Codeunit.al`, `MarkFetched.Codeunit.al`, and `EDocumentActionRunner.Codeunit.al`.

The pattern in `EDocIntegrationManagement.RunSend()`:

```al
Commit();
SendRunner.SetDocumentAndService(EDocument, EDocumentService);
SendRunner.SetContext(SendContext);
if not SendRunner.Run() then
    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, GetLastErrorText());
EDocument.Get(EDocument."Entry No");  // re-read after interface call
```

The `Commit()` before the call is essential -- without it, a runtime error in the interface implementation would roll back the E-Document record itself.

## Error accumulation (collecting parameter)

Rather than failing on the first error, the framework counts errors before and after an operation to determine success:

```al
ErrorCount := EDocumentErrorHelper.ErrorMessageCount(EDocument);
RunSend(EDocumentService, EDocument, SendContext, IsAsync);
Success := EDocumentErrorHelper.ErrorMessageCount(EDocument) = ErrorCount;
```

This pattern appears throughout `EDocExport`, `EDocIntegrationManagement`, and `ImportEDocumentProcess`. It allows interface implementations to log multiple error messages (via `EDocumentErrorHelper.LogSimpleErrorMessage`) and the framework to detect whether any new errors were added.

## Context objects for integration calls

Send and receive operations use context codeunits (`SendContext`, `ReceiveContext`, `ActionContext`) that bundle HTTP request/response, TempBlob, status, and metadata. This replaces the older pattern of passing `HttpRequestMessage` and `HttpResponseMessage` as separate parameters.

The context objects provide a fluent API: `SendContext.Http().GetHttpRequestMessage()`, `SendContext.Status().SetStatus()`, `SendContext.GetTempBlob()`. After the interface call, the framework reads the HTTP objects from the context to log them in the integration log.

## Manual event subscribers as stateful context carriers

The AI tool codeunits in `Processing/AI/Tools/` use a non-standard pattern: `EventSubscriberInstance = Manual` combined with instance variables to carry context across an execution lifecycle. This differs from the typical BC event subscriber pattern where subscribers are stateless singletons.

In this pattern, a codeunit declares `EventSubscriberInstance = Manual` and `TableNo = "E-Document Purchase Line"` (or similar). The orchestrator (`EDocAIToolProcessor`) binds the instance, then calls it with row-level context via `OnRun()`. Instance variables like `EDocumentNo: Integer` persist between method calls on the same instance, so the `Execute()` callback (invoked later by the AI function-calling loop) can access state that was set during initialization.

```al
codeunit 6177 "E-Doc. Historical Matching" implements "AOAI Function", IEDocAISystem
{
    EventSubscriberInstance = Manual;
    TableNo = "E-Document Purchase Line";

    var
        EDocumentNo: Integer;  // context set in OnRun, used in Execute

    trigger OnRun()
    begin
        EDocumentNo := Rec."E-Document Entry No.";  // capture context
        EDocumentAIProcessor.Setup(this);            // bind instance
        EDocumentAIProcessor.Process(...);           // AI loop calls Execute()
    end;

    procedure Execute(Arguments: JsonObject): Variant
    begin
        // EDocumentNo is available here from the OnRun context
    end;
}
```

This pattern appears in `EDocHistoricalMatching`, `EDocGLAccountMatching`, `EDocDeferralMatching`, and `EDocSimilarDescriptions`. The key advantage is that state flows through the instance rather than through event parameters, keeping the AI tool interface clean while preserving row-level context across asynchronous function calls.

## Bidirectional state machine (import pipeline)

The V2.0 import pipeline in `ImportEDocumentProcess.Codeunit.al` is a bidirectional state machine. Given a current status and a desired status, `GetEDocumentToDesiredStatus()` calculates the path:

1. If going backward: undo steps from current down to desired + 1
2. If going forward: run steps from current up to desired - 1

The `StatusStepIndex()` function maps each `"Import E-Doc. Proc. Status"` to a numeric index (0-4), and `GetNextStep()` / `GetPreviousStep()` map statuses to the `"Import E-Document Steps"` enum values that transition between them.

This design makes it possible to revert a processed document back to any earlier stage. For example, if a user notices the vendor was resolved incorrectly, they can revert from "Draft Ready" to "Ready for draft", change vendor data, and re-run "Prepare draft".

## Workflow as orchestration layer

The framework delegates flow control to BC's Workflow engine rather than hardcoding the sequence of operations. The E-Document workflow setup (`EDocumentWorkFlowSetup.Codeunit.al`) registers workflow events and responses. The key events are "E-Document Created" and "E-Document Sent". Responses include "Send E-Document to Service", "Send E-Document via Email".

This means the sequence of operations (export -> send -> email -> approval) is configured in the workflow, not in code. `EDocumentCreatedFlow.Codeunit.al` triggers the workflow after document creation, and each workflow step response delegates to the appropriate framework method.

## Blob management (TempBlob and Data Storage)

Blobs flow through the system in two forms: in-memory `TempBlob` codeunits during processing, and persisted `"E-Doc. Data Storage"` records for permanent storage. The conversion happens in `EDocumentLog.InsertLog()`, which writes the TempBlob to a new Data Storage record and links it via `"E-Doc. Data Storage Entry No."` on the log entry.

Inbound documents can accumulate multiple blobs: the original unstructured content, the structured conversion, and document attachments. The E-Document tracks two primary references: `"Unstructured Data Entry No."` and `"Structured Data Entry No."`.

## RecordRef-based generic processing

Export operations work with RecordRef rather than specific table types, enabling a single code path for Sales, Purchase, Service, and other document types. `PopulateEDocument()` in `EDocExport.Codeunit.al` uses `SourceDocumentHeader.Number` to determine the table and then reads fields via `SourceDocumentHeader.Field(FieldNo).Value`. The mapping engine (`EDocMapping.Codeunit.al`) also operates on RecordRefs.

The downside is that field access is by field number, making the code harder to follow and susceptible to breaking if field numbers change.

## IEDocumentStatus: behavior per enum value

The `"E-Document Service Status"` enum uniquely implements `IEDocumentStatus`. Each enum value declares which of three status codeunits handles it:

- Values like `Created`, `Imported`, `Pending Response` use the `DefaultImplementation = "E-Doc In Progress Status"` (they represent in-progress states)
- Values like `Exported`, `Sent`, `Approved`, `Cleared` explicitly set `Implementation = IEDocumentStatus = "E-Doc Processed Status"`
- Error values like `Sending Error`, `Export Error` set `Implementation = IEDocumentStatus = "E-Doc Error Status"`

This lets `EDocumentProcessing.ModifyEDocumentStatus()` call the service status enum value's interface to determine the overall E-Document status without a giant case statement.

---

## Legacy patterns

These patterns exist in the codebase but are deprecated. Understanding them helps when reading code inside `#if not CLEAN26` or `#if not CLEAN27` blocks.

### V1.0 import process

**What**: The original single-stage import where the format interface's `GetBasicInfoFromReceivedDocument()` and `GetCompleteInfoFromReceivedDocument()` methods directly create BC purchase documents in one shot.

**Where**: `EDocImport.V1_ProcessEDocument()`, `EDocImport.V1_BeforeInsertImportedEdocument()`, and the `"E-Document"` interface methods `GetBasicInfoFromReceivedDocument` / `GetCompleteInfoFromReceivedDocument`.

**Why deprecated**: No staging tables, no user review, no reversibility. Format implementations had to know how to create Purchase Invoices, violating separation of concerns.

**What to do instead**: Use V2.0 pipeline with `"Import Process" = "Version 2.0"`. Implement `IStructuredFormatReader` to populate staging tables and let the framework handle BC document creation.

### Old "E-Document Integration" enum and interface

**What**: The original `"E-Document Integration"` enum (`enum 6132`) and its `"E-Document Integration"` interface, which combined send, receive, and action methods into a single interface. Methods took raw `HttpRequestMessage`/`HttpResponseMessage` parameters.

**Where**: `EDocumentIntegration.Interface.al`, `EDocumentIntegration.Enum.al`, and the `"Service Integration"` field (field 4) on `"E-Document Service"`.

**Why deprecated**: Too coarse-grained (one interface for all operations), raw HTTP parameters instead of context objects, no support for the V2.0 receive flow.

**What to do instead**: Extend `"Service Integration"` (`enum 6151`) and implement the granular interfaces: `IDocumentSender`, `IDocumentReceiver`, `IDocumentResponseHandler`, `ISentDocumentActions`, `IReceivedDocumentMarker`.

### GetDocumentCountInBatch()

**What**: V1.0 receive flow called `EDocIntegration.GetDocumentCountInBatch()` to determine how many documents were in a received blob, then called `ReceiveDocument()` to get the blob.

**Where**: `EDocIntegrationManagement.ReceiveDocument()` (inside `#if not CLEAN26`).

**Why deprecated**: Awkward two-step receive pattern that bundled all documents in a single blob. V2.0 uses `ReceiveDocuments()` which returns a `"Temp Blob List"` with one entry per document, and `DownloadDocument()` fetches each individually.

### Manual GetIntegrationSetup()

**What**: Connector apps had to implement a method that returned a setup page ID, called by the service card to open integration-specific settings.

**Why deprecated**: Replaced by the `OnBeforeOpenServiceIntegrationSetupPage` event pattern, which is more flexible and doesn't require interface changes.

### IPurchaseLineAccountProvider

**What**: Earlier interface for determining purchase line account type and number during import.

**Where**: `Processing/Interfaces/IPurchaseLineAccountProvider.Interface.al` (marked `ObsoleteState = Pending`, tag `27.0`).

**Why deprecated**: Too narrow -- only sets account type and number. Replaced by `IPurchaseLineProvider`, which operates on the full `"E-Document Purchase Line"` record and can set any field.

### CLEANSCHEMA and CLEAN version markers

The codebase uses compiler directives to manage deprecation:

- `#if not CLEAN26` -- code to be removed when BC version 26 cleanup happens
- `#if not CLEAN27` -- code to be removed when BC version 27 cleanup happens
- `#if not CLEANSCHEMA26` / `#if not CLEANSCHEMA29` -- table schema changes (field removals) that need separate cleanup due to schema migration constraints

When reading the code, content inside these blocks is legacy. The code outside (or in the `#else` branch) is the current implementation.
