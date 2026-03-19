# Patterns

Recurring design patterns in E-Document Core. Each section explains the pattern, why it exists, and where to find concrete examples.

## Interface-based polymorphic dispatch

The most pervasive pattern in the codebase. An extensible enum implements one or more interfaces. The service or document record stores the enum value. At runtime, the enum is cast to the interface and the appropriate implementation is called.

**Format dispatch.** `E-Document Format` enum (enum 6101) implements the `E-Document` interface. When exporting, `EDocumentCreate.Codeunit.al` does:

```
EDocumentInterface := EDocService."Document Format";
EDocumentInterface.Create(EDocService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
```

**Service integration dispatch.** `Service Integration` enum (enum 6151) implements `IDocumentSender`, `IDocumentReceiver`, and `IConsentManager`. When sending, `SendRunner.Codeunit.al` does:

```
IDocumentSender := this.GlobalEDocumentService."Service Integration V2";
IDocumentSender.Send(this.GlobalEDocument, this.GlobalEDocumentService, GlobalSendContext);
```

**Status dispatch.** `E-Document Service Status` enum (enum 6106) implements `IEDocumentStatus`. Each enum value declares which document-level status it maps to. In `EDocumentProcessing.Codeunit.al`:

```
IEDocumentStatus := EDocumentServiceStatus.Status;
case IEDocumentStatus.GetEDocumentStatus() of ...
```

**Import pipeline dispatch.** Several enums participate: `Structure Received E-Doc.` implements `IStructureReceivedEDocument`, `E-Doc. Read into Draft` implements `IStructuredFormatReader`, `E-Doc. Process Draft` implements `IProcessStructuredData`, `E-Doc. Create Purchase Invoice` implements `IEDocumentFinishDraft`. The enum value flows forward through the pipeline -- each step's output determines the next step's implementation.

## Context object pattern

V2 service interfaces use context codeunits (`SendContext`, `ReceiveContext`, `ActionContext`) instead of passing multiple `var` parameters. Each context provides:

- `GetTempBlob()` / `SetTempBlob()` -- document content
- `Http()` -- returns an `Http Message State` codeunit for HTTP request/response
- `Status()` -- returns an `Integration Action Status` codeunit for result status

This pattern was introduced to replace the V1 approach of passing `var HttpRequestMessage`, `var HttpResponseMessage`, `var IsAsync`, `var TempBlob` as separate parameters. It is cleaner, more extensible (new data can be added without breaking the interface signature), and enables automatic logging -- the framework reads `Http().GetHttpRequestMessage()` and `Http().GetHttpResponseMessage()` after the call to insert integration log entries.

See `src/Integration/Send/SendContext.Codeunit.al`, `src/Integration/Receive/ReceiveContext.Codeunit.al`, and `src/Integration/Actions/ActionContext.Codeunit.al`.

## Runner codeunit pattern (error-trapped execution)

Every external interface call is wrapped in a separate "runner" codeunit that is executed via `Codeunit.Run()`. This enables error trapping without rolling back the current transaction.

The canonical pattern from `EDocIntegrationManagement.Codeunit.al`:

```
// 1. Commit to persist state before the interface call
Commit();

// 2. Set up the runner with parameters
SendRunner.SetDocumentAndService(EDocument, EDocumentService);
SendRunner.SetContext(SendContext);

// 3. Run with error trapping
if not SendRunner.Run() then
    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, GetLastErrorText());

// 4. Re-read records (interface may have modified them)
EDocument.Get(EDocument."Entry No");
EDocumentService.Get(EDocumentService.Code);
```

Runner codeunits: `Send Runner` (`src/Integration/Send/SendRunner.Codeunit.al`), `Get Response Runner` (`src/Integration/Send/GetResponseRunner.Codeunit.al`), `Receive Documents` (`src/Integration/Receive/ReceiveDocuments.Codeunit.al`), `Download Document` (`src/Integration/Receive/DownloadDocument.Codeunit.al`), `Mark Fetched` (`src/Integration/Receive/MarkFetched.Codeunit.al`), `E-Document Action Runner` (`src/Integration/Actions/EDocumentActionRunner.Codeunit.al`), `E-Document Create` (`src/Processing/EDocumentCreate.Codeunit.al`), `Import E-Document Process` (`src/Processing/Import/ImportEDocumentProcess.Codeunit.al`).

The `Commit()` before `Run()` is critical. Without it, a runtime error in the interface implementation would roll back the E-Document record, service status, and all prior work.

## State machine with rollback

The V2 import pipeline is a state machine with five ordered states (Unprocessed, Readable, Ready for draft, Draft Ready, Processed) and four steps between them. `ImportEDocumentProcess.Codeunit.al` manages transitions in both directions.

Forward: `GetNextStep(currentStatus)` returns the step to execute. Each step transitions to the next status.

Backward: `GetPreviousStep(currentStatus)` returns the step to undo. `UndoProcessingStep()` performs cleanup appropriate to each step -- deleting mappings, clearing fields, or reverting BC document creation.

The `StatusStepIndex()` and `IndexToStatus()` methods provide an integer mapping for ordinal comparison, enabling `IsEDocumentInStateGE()` to check "is this document at or past state X?".

This design allows the user to move a document backward if they notice a vendor assignment error, fix it, and re-process -- all without deleting and re-importing the document.

## Provider pattern

The V2 import pipeline uses pluggable "provider" interfaces to resolve BC entities from raw e-document data. These are injected via the `E-Doc. Proc. Customizations` enum on the service, which implementations can use to swap in different matching strategies.

Providers defined in `src/Processing/Interfaces/`:

- `IVendorProvider.GetVendor(EDocument)` -- resolve a BC Vendor from raw vendor name/VAT/GLN
- `IItemProvider.GetItem(EDocument, LineId, Vendor, UnitOfMeasure)` -- resolve a BC Item from product codes and descriptions
- `IUnitOfMeasureProvider.GetUnitOfMeasure(EDocument, LineId, ExternalUOM)` -- resolve a BC Unit of Measure from external codes
- `IPurchaseOrderProvider.GetPurchaseOrder(EDocPurchaseHeader)` -- find a matching Purchase Order
- `IPurchaseLineProvider` -- determine purchase line type and account number

The `EDocProviders.Codeunit.al` (`src/Processing/Import/PrepareDraft/`) acts as a factory, resolving the correct provider implementation based on the service's customization enum.

This pattern separates the "what to resolve" (the interface) from "how to resolve it" (the implementation), allowing different matching strategies (exact match, fuzzy match, AI-assisted) to be plugged in without changing the pipeline.

## Log correlation

Every status transition produces an `E-Document Log` entry. Log entries reference:

- The `E-Document` (via `E-Doc. Entry No`)
- The `E-Document Service` (via `Service Code`)
- An `E-Doc. Data Storage` blob (via `E-Doc. Data Storage Entry No.`)
- The service status at that point

HTTP communication is logged separately in `E-Document Integration Log`, which stores request and response blobs, URL, method, and response status code. These are inserted by the framework after every interface call that uses context objects.

`E-Doc. Mapping Log` records are linked to `E-Document Log` entries (via `E-Doc Log Entry No.`) to audit which field transformations were applied during export.

This three-table structure (Log + Data Storage + Integration Log) provides a complete audit trail: what the document looked like, what HTTP calls were made, and what field transformations were applied.

## Legacy patterns (do not follow in new code)

### V1 Integration interface

The `E-Document Integration` interface (`src/Integration/EDocumentIntegration.Interface.al`) is **obsolete since 26.0**. It used raw `HttpRequestMessage`/`HttpResponseMessage` parameters and combined send, receive, cancel, and approval into a single interface.

In V2, these are split into separate focused interfaces (`IDocumentSender`, `IDocumentReceiver`, `IDocumentResponseHandler`, `ISentDocumentActions`, `IDocumentAction`), each using context objects. The V1 interface is preserved behind `#if not CLEAN26` guards and will be removed in version 29.0.

If you see code referencing `EDocumentService."Service Integration"` (not V2) or `E-Document Integration` enum (enum in `src/Integration/EDocumentIntegration.Enum.al`), that is the V1 path. New integrations should use `Service Integration V2` exclusively.

### Direct HttpRequestMessage parameters

The V1 pattern passed `var HttpRequestMessage` and `var HttpResponseMessage` as procedure parameters. This required the framework to manually extract and log them after the call, and made it impossible to add new context data without breaking the interface.

V2 context objects (`SendContext`, `ReceiveContext`, `ActionContext`) replace this. They encapsulate HTTP state, document content, and result status in a single object. The framework reads HTTP state from the context automatically.

### Manual service status updates

In V1, some interface implementations would directly modify `E-Document Service Status` records. In V2, status updates flow through context objects: the implementation sets `SendContext.Status().SetStatus(...)` or `ActionContext.Status().SetStatus(...)`, and the framework handles the actual record updates, log entries, and event firing.

### E-Document Link on Purchase Header

The `E-Document Link` Guid field on the `Purchase Header` table extension is the V1 way to link a purchase document back to its E-Document. It is **obsolete since 27.0**. V2 uses the `E-Doc. Record Link` table with SystemId pairs, which is more flexible (supports linking any draft record to any BC record) and does not pollute BC core tables.
