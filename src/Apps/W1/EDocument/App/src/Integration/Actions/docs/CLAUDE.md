# Integration Actions

The Actions subdirectory implements the post-send action execution infrastructure, allowing users and workflows to trigger service-specific operations like approval status checks, cancellation requests, custom actions (download receipt, update invoice), and QR clearance validation. This layer provides the runner pattern for IDocumentAction interface dispatch, context management for action state, and the enum framework that makes actions extensible without modifying core code.

## Quick reference

- **Files:** 5 files (1 runner, 2 context codeunits, 1 status codeunit, 1 action type enum)
- **Key operations:** InvokeAction (generic), GetApprovalStatus, GetCancellationStatus
- **Context:** ActionContext carries HTTP state and status targets
- **Extensibility:** Integration Action Type enum with IDocumentAction implementations

## What it does

E-Document Action Runner is the interface dispatcher for IDocumentAction implementations. Integration Management calls ActionRunner.Run() within a Commit+Run error boundary, which selects the action implementation from the Integration Action Type enum value, invokes InvokeAction with the EDocument and service configuration, and returns a Boolean indicating whether the action should update the document's Service Status. Some actions are informational (query current state) and return false; others modify state (approve, reject, cancel) and return true.

ActionContext is the state carrier for action operations, parallel to SendContext but without document content (actions operate on already-sent documents). It provides access to HTTP message state (request/response for communication logging) and Integration Action Status (target status and error status). Service implementations write to ActionContext to indicate the result of the action, and Integration Management reads the context to determine database updates.

Integration Action Status manages two status values: the target status (where the document should transition to if action succeeds) and the error status (where it should transition to if action fails). Default behavior is no status change (action is informational). Implementations set these explicitly when state should change.

Http Message State is shared infrastructure used by both SendContext and ActionContext. It wraps HttpRequestMessage and HttpResponseMessage with get/set accessors, allowing service implementations to populate HTTP communication for automatic logging by Integration Management. This eliminates duplicate logging code across interface implementations.

Integration Action Type is an extensible enum that implements IDocumentAction interface. Default values include "No Action" (no-op), "Sent Document Approval" (maps to ISentDocumentActions.GetApprovalStatus), and "Sent Document Cancellation" (maps to ISentDocumentActions.GetCancellationStatus). Partner extensions add enum values with custom Implementation assignments to register new actions.

## Key files

**EDocumentActionRunner.Codeunit.al** (3KB, 72 lines) -- Internal access runner for action dispatch. OnRun trigger casts ActionType enum to IDocumentAction interface, calls InvokeAction(EDocument, EDocumentService, ActionContext), stores return value in UpdateStatusBool. SetEDocumentAndService, SetActionType, and SetContext methods populate instance variables before Run is called. ShouldActionUpdateStatus returns the stored Boolean to Integration Management for status update decision.

**ActionContext.Codeunit.al** (1KB, 40 lines) -- Public API for action state. Provides Http() accessor for HttpMessageState and Status() accessor for IntegrationActionStatus. Simpler than SendContext because actions don't carry document content (no GetTempBlob). Service implementations set HTTP messages for logging and status for result indication.

**HttpMessageState.Codeunit.al** (2KB, 51 lines) -- Shared HTTP communication wrapper used by SendContext, ActionContext, and ReceiveContext. Stores HttpRequestMessage and HttpResponseMessage with get/set accessors. Integration Management reads these after interface call completes and logs to E-Document Integration Log if populated. Service implementations never log directly.

**IntegrationActionStatus.Codeunit.al** (2KB, 54 lines) -- Status result container with two enum fields: GlobalStatus (target status if action succeeds) and GlobalErrorStatus (status if action fails with error). Get/Set methods for each. Integration Management checks if errors were logged during action execution; if yes, uses ErrorStatus; if no, uses Status.

**IntegrationActionType.Enum.al** (1KB, 31 lines) -- Extensible enum implementing IDocumentAction. Default values: "No Action" (Implementation = "Empty Integration Action"), "Sent Document Approval" (Implementation = "Sent Document Approval"), "Sent Document Cancellation" (Implementation = "Sent Document Cancellation"). Partners extend enum with custom values and Implementation assignments to add service-specific actions.

## Action execution flow

1. **User or workflow triggers action**
   - User clicks action button on E-Document Card (e.g., "Check Approval Status")
   - Or workflow step invokes action automatically (e.g., approval check after send)

2. **Integration Management entry point**
   - Call InvokeAction(EDocument, EDocumentService, ActionType enum value, ActionContext)
   - Create ActionContext instance
   - Capture pre-action error count

3. **Validate service configuration**
   - Check EDocumentService."Service Integration V2" is configured
   - If "No Integration", skip action execution

4. **Invoke action runner (commit boundary)**
   - Call RunAction(ActionType, EDocument, EDocumentService, ActionContext) within Commit+Run:
     ```al
     Commit(); // Isolate transaction
     EDocumentActionRunner.SetActionType(ActionType);
     EDocumentActionRunner.SetContext(ActionContext);
     EDocumentActionRunner.SetEDocumentAndService(EDocument, EDocumentService);
     Success := EDocumentActionRunner.Run();
     UpdateStatus := EDocumentActionRunner.ShouldActionUpdateStatus();
     ```
   - Emit telemetry start/end messages

5. **Action runner dispatch**
   - ActionRunner.OnRun casts ActionType to IDocumentAction interface:
     ```al
     IAction := ActionType; // Enum to interface cast
     UpdateStatusBool := IAction.InvokeAction(EDocument, EDocumentService, ActionContext);
     ```

6. **Service implementation executes**
   - For default actions (Approval, Cancellation):
     - Codeunit implementing ISentDocumentActions is invoked
     - GetApprovalStatus or GetCancellationStatus called based on enum value
   - For custom actions:
     - Custom codeunit implementing IDocumentAction is invoked
     - InvokeAction method executes service-specific logic
   - Implementation sets ActionContext.Status() if state should change
   - Implementation returns true if status update needed, false otherwise

7. **Check operation success**
   - Compare current error count to pre-action count
   - Success := (ErrorCount unchanged)

8. **Determine status update**
   - If not Success: use ActionContext.Status().GetErrorStatus()
   - If Success and UpdateStatus = true: use ActionContext.Status().GetStatus()
   - If Success and UpdateStatus = false: no status update

9. **Update database (if needed)**
   - If status should update:
     - Insert E-Document Log with new status
     - Update E-Document Service Status
   - Always insert E-Document Integration Log with HTTP communication (if ActionContext.Http() populated)

10. **Return to caller**
    - User sees updated status and any logged errors
    - Workflow continues to next step

## Default action implementations

**Sent Document Approval:**

Mapped to Integration Action Type enum value "Sent Document Approval" with Implementation = "Sent Document Approval" codeunit. This codeunit implements IDocumentAction interface:

```al
procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
var
    ISentDocumentActions: Interface ISentDocumentActions;
begin
    // Cast service to ISentDocumentActions
    ISentDocumentActions := EDocumentService."Service Integration V2";

    // Call GetApprovalStatus on the service implementation
    exit(ISentDocumentActions.GetApprovalStatus(EDocument, EDocumentService, ActionContext));
end;
```

Service implementation of ISentDocumentActions.GetApprovalStatus:
- Query service API for approval status
- If approved: set ActionContext.Status() to Approved, return true
- If rejected: set ActionContext.Status() to Rejected, log error reason, return true
- If pending: return false (no status change)

**Sent Document Cancellation:**

Similar pattern but calls ISentDocumentActions.GetCancellationStatus:
- Query service API for cancellation status
- If cancelled: set ActionContext.Status() to Cancelled, return true
- If cancel failed: set ActionContext.Status() to Cancel Error, log error, return true
- If cancellation pending: return false

## Custom action registration

Partners extend Integration Action Type enum to add service-specific actions:

```al
enumextension 50200 "My Custom Actions" extends "Integration Action Type"
{
    value(50200; "Download Receipt")
    {
        Caption = 'Download Receipt';
        Implementation = IDocumentAction = "Download Receipt Action";
    }

    value(50201; "Update Invoice")
    {
        Caption = 'Update Invoice';
        Implementation = IDocumentAction = "Update Invoice Action";
    }
}
```

Implement action codeunit:

```al
codeunit 50200 "Download Receipt Action" implements IDocumentAction
{
    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        HttpClient: HttpClient;
    begin
        // Download receipt PDF from service
        HttpClient.Get(
            EDocumentService."Service URL" + '/receipt/' + EDocument."Document ID",
            ActionContext.Http().GetHttpResponseMessage()
        );

        if not ActionContext.Http().GetHttpResponseMessage().IsSuccessStatusCode() then begin
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Receipt not available');
            exit(false); // No status change, error logged
        end;

        // Store PDF in data storage
        TempBlob.CreateOutStream(OutStr);
        ActionContext.Http().GetHttpResponseMessage().Content().ReadAs(OutStr);
        EDocLog.InsertDataStorage(TempBlob);

        Message('Receipt downloaded');
        exit(false); // Informational action, no status change
    end;
}
```

Add page action to E-Document Card:

```al
pageextension 50200 "My Actions" extends "E-Document"
{
    actions
    {
        addlast(Processing)
        {
            action(DownloadReceipt)
            {
                Caption = 'Download Receipt';
                Image = Document;

                trigger OnAction()
                var
                    IntMgmt: Codeunit "E-Doc. Integration Management";
                    ActionContext: Codeunit ActionContext;
                begin
                    IntMgmt.InvokeAction(
                        Rec,
                        EDocService,
                        "Integration Action Type"::"Download Receipt",
                        ActionContext
                    );
                end;
            }
        }
    }
}
```

## How it connects

Integration Management (parent directory) invokes E-Document Action Runner for all action operations. Runner is Internal access, never called directly from UI. UI actions call Integration Management.InvokeAction or Integration Management.GetApprovalStatus/GetCancellationStatus (wrappers that internally invoke actions).

ActionContext and SendContext (Send subdirectory) share similar structure. Both use HttpMessageState for HTTP communication and IntegrationActionStatus for status management. SendContext adds TempBlob for document content; ActionContext omits it because actions operate on already-sent documents.

E-Document Workflow Processing invokes GetApprovalStatus and GetCancellationStatus as workflow steps. Approval workflow: Send → Wait → GetApprovalStatus → If Approved, continue; if Rejected, notify user. Cancellation workflow: User requests cancellation → GetCancellationStatus → If Cancelled, update accounting.

E-Document Card page provides UI actions that trigger Integration Management.InvokeAction with specific action types. Page reads Integration Action Type enum extensions to dynamically show available actions.

## Things to know

- **Action return value controls update** -- InvokeAction returns Boolean indicating if status should change. True means write ActionContext.Status() to database; false means informational only (no update). Integration Management respects this flag.
- **Error status is separate from success status** -- IntegrationActionStatus has two fields: Status (success path) and ErrorStatus (failure path). Integration Management checks error count to decide which to use.
- **HTTP logging is automatic** -- If ActionContext.Http() contains request/response, Integration Management logs them after action completes. Service implementations never log directly.
- **Actions are idempotent** -- User can click action button repeatedly. Implementation should handle redundant calls gracefully (e.g., return current status if already resolved).
- **No automatic retry** -- Unlike GetResponse polling, actions are triggered only when user clicks button or workflow step executes. No background job retries failed actions.
- **Enum-based dispatch** -- Integration Management receives enum value (Integration Action Type), casts to IDocumentAction interface, invokes InvokeAction. AL platform binds enum value to implementation codeunit via Implementation clause.
- **V1 actions are obsolete** -- Legacy code contains GetApproval and Cancel methods on E-Document Integration interface. V2 migrates these to ISentDocumentActions. Conditional compilation blocks handle fallback during migration.

## Extensibility

Actions are extended via Integration Action Type enum extensions and IDocumentAction implementations. No events at this layer; extensibility is interface-based.

**Pattern for informational actions** (no status change):

```al
procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
begin
    // Query service, show result to user
    HttpClient.Get(ServiceUrl + '/info/' + EDocument."Document ID", HttpResponse);
    Message('Status: %1', ParseStatus(HttpResponse));

    exit(false); // Don't change status
end;
```

**Pattern for state-changing actions:**

```al
procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
begin
    // Submit request to service
    HttpClient.Post(ServiceUrl + '/cancel/' + EDocument."Document ID", HttpResponse);

    if HttpResponse.IsSuccessStatusCode() then begin
        ActionContext.Status().SetStatus("E-Document Service Status"::Cancelled);
        exit(true); // Update status
    end else begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Cancellation failed');
        ActionContext.Status().SetErrorStatus("E-Document Service Status"::"Cancel Error");
        exit(true); // Update to error status
    end;
end;
```

See parent directory extensibility.md for complete action implementation examples.
