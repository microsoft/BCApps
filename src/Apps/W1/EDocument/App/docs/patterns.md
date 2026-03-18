# Patterns

This document covers recurring code patterns you'll encounter when reading or extending the E-Document Core codebase. Understanding these patterns prevents you from fighting the framework.

## Active patterns

### Commit-before-Run for error isolation

The most important pattern in this codebase. Whenever the framework calls third-party code (format interfaces, connectors), it follows this sequence:

```
Commit();
EDocumentCreate.SetSource(...);
if not EDocumentCreate.Run() then
    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, GetLastErrorText());
```

The `Commit()` persists the E-Document record and its current state. The `Codeunit.Run()` executes the interface code in an implicit error boundary -- if it throws a runtime error, the transaction inside `Run` is rolled back, but the committed E-Document survives. The error text is captured and logged.

You'll see this in `EDocExport.CreateEDocument` (line ~399), `EDocExport.CreateEDocumentBatch`, `EDocIntegrationManagement.Send`, and throughout the integration layer. Never remove these `Commit()` calls -- they're load-bearing.

**Gotcha**: Because of the commit, any changes made to the E-Document *before* the `Codeunit.Run` call are persisted even if the interface code fails. The framework re-reads the record after the call: `EDocument.Get(EDocument."Entry No")`.

### Dual status model

The E-Document has two status systems that must stay in sync:

1. **`E-Document.Status`** -- 3 values: In Progress, Processed, Error. This is what the user sees.
2. **`E-Document Service Status.Status`** -- 24+ values: Created, Exported, Sending Error, Sent, Pending Response, Imported, etc. This is the real state machine.

The bridge is the `IEDocumentStatus` interface implemented by each enum value of `E-Document Service Status`:

- Values like Created, Exported (via `E-Doc Processed Status`), Imported use `E-Doc In Progress Status` (default) -- maps to "In Progress"
- Values like Sent, Approved, Imported Document Created use `E-Doc Processed Status` -- maps to "Processed"
- Values like Sending Error, Export Error use `E-Doc Error Status` -- maps to "Error"

The aggregate is computed in `EDocumentProcessing.ModifyEDocumentStatus`. It iterates all `E-Document Service Status` records for the document. If any is Error, the aggregate is Error. If all are Processed, the aggregate is Processed. Otherwise, In Progress.

**Rule**: Never set `E-Document.Status` directly. Always update the service status and call `ModifyEDocumentStatus`.

### Context object pattern

Send, receive, and action operations pass state through context codeunits rather than loose parameters:

- **`SendContext`** (`Integration/Send/SendContext.Codeunit.al`) -- Holds TempBlob (document content), HttpMessageState (request/response for logging), and IntegrationActionStatus (resulting status).
- **`ReceiveContext`** (`Integration/Receive/ReceiveContext.Codeunit.al`) -- Same structure for the receive path.
- **`ActionContext`** (`Integration/Actions/ActionContext.Codeunit.al`) -- Same structure for post-send actions.

These codeunits are `Access = Public` and use `this.` prefixed globals. They act as mutable state containers passed by reference to interface implementations. The pattern keeps interface method signatures clean and lets the framework automatically log HTTP communication after the call returns.

**Key behavior**: `SendContext.Status()` defaults to `Sent` before `IDocumentSender.Send` is called. If the connector doesn't explicitly change it, the document goes to "Sent." If it also implements `IDocumentResponseHandler`, the framework overrides this to "Pending Response" (see `SendRunner.SendV2`).

### V1 vs V2 integration architecture

V1 and V2 coexist behind conditional compilation guards:

- `#if not CLEAN26` -- V1 integration code (the monolithic `E-Document Integration` interface)
- `#if not CLEAN27` -- V1 import processing code (direct Purchase Header linking via `E-Document Link` GUID field)

In `SendRunner.OnRun()`:

```al
#if not CLEAN26
    if GlobalEDocumentService."Service Integration V2" <> Enum::"Service Integration"::"No Integration" then
        SendV2()
    else
        if GlobalEDocumentService."Use Batch Processing" then
            SendBatch()
        else
            Send();
#else
    SendV2();
#endif
```

V1 checks the old `Service Integration` enum field; V2 checks `Service Integration V2`. When `CLEAN26` is defined, V1 code is removed entirely.

**Rule**: All new development should use V2 interfaces. V1 exists only for backward compatibility during the migration period.

### IsHandled pattern in events

Integration events use the standard BC `IsHandled` pattern:

```al
OnBeforeEDocumentCheck(EDocSourceRecRef, EDocumentProcessingPhase, IsHandled);
if IsHandled then
    exit;
```

Subscribers set `IsHandled := true` to completely replace the default behavior. This is used sparingly in E-Document Core -- mainly in the export check path. Most events are notification-only (no `IsHandled` parameter).

### RecordRef-based mapping

The `E-Doc. Mapping` system operates entirely on `RecordRef` and `FieldRef` to be table-agnostic. The `EDocMapping.MapRecord` codeunit:

1. Opens a temporary RecordRef of the same table as the source.
2. Copies all fields from the source record to the temp record.
3. For each matching mapping rule (same table ID, field ID), reads the field value, applies the find/replace, and writes it back.
4. Inserts the temp record into the temporary table.

The mapped temp records are what the format interface receives -- never the original data. This means format implementations don't need to know about mappings at all. The mapping rules reference tables and fields by integer IDs, making them resilient to code changes but opaque to read.

The `For Import` boolean on `E-Doc. Mapping` distinguishes export-time mappings from import-time ones. The same service can have different mappings for each direction.

### Telemetry scopes

The codebase follows a consistent Start/End scope pattern for telemetry:

```al
Telemetry.LogMessage('0000LBF', EDocTelemetryCreateScopeStartLbl, Verbosity::Normal,
    DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, TelemetryDimensions);
// ... actual work ...
Telemetry.LogMessage('0000LBG', EDocTelemetryCreateScopeEndLbl, Verbosity::Normal,
    DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All);
```

Each scope has a unique telemetry ID pair (start/end). Dimensions are built via `EDocumentProcessing.GetTelemetryDimensions` and include service and document identifiers. The `Locked = true` labels prevent translation of telemetry strings.

Feature uptake telemetry (`EDocTok: Label 'W1 E-Document'`) tracks overall module adoption.

### Import step state machine

The V2 import pipeline uses a linear state machine where each step's output determines the next step's implementation. The chain lives on the E-Document record itself:

1. `Structure Data Impl.` (enum) -- set by the receive path or auto-detected from file format
2. `Read into Draft Impl.` (enum) -- set by the `IStructuredDataType` returned from step 1
3. `Process Draft Impl.` (enum) -- set by `IStructuredFormatReader.ReadIntoDraft` in step 2

Each enum value implements the corresponding interface. This is runtime polymorphism via enum dispatch -- the E-Document record carries its own processing pipeline configuration.

`ImportEDocumentProcess.GetNextStep` and `GetPreviousStep` implement bidirectional navigation. `StatusStepIndex` maps each status to a numeric index (0-4) for comparison. `IsEDocumentInStateGE` checks if the document has reached or passed a given state.

## Legacy patterns (avoid in new code)

### V1 Integration Interface

The `E-Document Integration` interface (in `Integration/EDocumentIntegration.Interface.al`) was the original monolithic connector interface. It combined send, receive, batch send, and response handling into a single interface with many methods. It's registered on the `E-Document Integration` enum (field 4 on E-Document Service).

**Why to avoid**: V2 splits this into focused interfaces (`IDocumentSender`, `IDocumentReceiver`, `IDocumentResponseHandler`). This allows connectors to implement only what they need, and it enables the context object pattern for cleaner state management. The V1 interface passes raw `HttpRequestMessage`/`HttpResponseMessage` as var parameters rather than using contexts.

### Direct error message manipulation

Older code sometimes creates error messages directly or uses `Error()` calls. The modern pattern is to use `EDocumentErrorHelper`:

- `LogSimpleErrorMessage(EDocument, ErrorText)` -- logs a text error
- `LogErrorMessage(EDocument, Record, FieldNo, ErrorText)` -- logs an error with field context
- `LogWarningMessage(EDocument, Record, FieldNo, WarningText)` -- logs a warning
- `ErrorMessageCount(EDocument)` -- counts errors (used to detect if an operation added new errors)

The error helper integrates with BC's Error Message framework, making errors visible on the E-Document page's error factbox. Direct `Error()` calls bypass this and lose the audit trail.

### Hardcoded workflow steps

Early implementations sometimes hardcoded service routing logic. The correct approach is to use BC Workflow with the `EDOC` category. The `EDocumentWorkFlowSetup` codeunit registers the workflow events and responses. The `Workflow Step Argument` extension adds the `E-Document Service` field so each workflow step can target a different service.

This allows administrators to configure multi-service flows (e.g., "export via PEPPOL, then email a PDF copy") without code changes.

### Purchase Header E-Document Link field

The V1 import path linked E-Documents to purchase headers via a GUID field (`E-Document Link`) on the Purchase Header table extension. This is a direct table relationship that bypasses the standard `Document Record ID` mechanism.

V2 uses `E-Document.Document Record ID` exclusively, which works with any table (not just Purchase Header) and follows the standard BC pattern for cross-table references. The old field is behind `#if not CLEAN27` guards.
