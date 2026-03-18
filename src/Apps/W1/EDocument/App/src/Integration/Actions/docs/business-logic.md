# Actions Business Logic

This document describes the action execution algorithm, status update rules, error handling, and common action patterns.

## Action invocation algorithm

**Entry point:** `E-Doc. Integration Management.InvokeAction(var EDocument, var EDocumentService, ActionType, ActionContext)`

**Preconditions:**
- EDocument exists with Entry No
- EDocumentService is configured with Service Integration V2
- ActionType is valid Integration Action Type enum value

**Execution steps:**

1. **Validate service configuration**
   ```al
   EDocumentService.TestField("Service Integration V2");
   ```
   Throws error if service not configured. User must assign enum value.

2. **Capture pre-action error count**
   ```al
   ErrorCount := EDocumentErrorHelper.ErrorMessageCount(EDocument);
   ```
   Used later to detect if action logged business errors.

3. **Invoke action runner (commit boundary)**
   ```al
   Commit(); // Isolate transaction
   Telemetry.LogMessage('0000O08', EDocTelemetryActionScopeStartLbl, ...);

   EDocumentActionRunner.SetActionType(ActionType);
   EDocumentActionRunner.SetContext(ActionContext);
   EDocumentActionRunner.SetEDocumentAndService(EDocument, EDocumentService);
   Success := EDocumentActionRunner.Run();

   if not Success then
       EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, GetLastErrorText());

   UpdateStatus := EDocumentActionRunner.ShouldActionUpdateStatus();
   Telemetry.LogMessage('0000O09', EDocTelemetryActionScopeEndLbl, ...);
   ```

4. **Check operation result**
   ```al
   Success := EDocumentErrorHelper.ErrorMessageCount(EDocument) = ErrorCount;
   ```
   Success = true if no errors logged during action execution.

5. **Determine status update**
   - If not Success:
     - Use ActionContext.Status().GetErrorStatus() (if set)
     - Default: no status change if error status not set
   - If Success and UpdateStatus = true:
     - Use ActionContext.Status().GetStatus()
   - If Success and UpdateStatus = false:
     - No status change (informational action)

6. **Update database (conditional)**
   ```al
   if not Success then begin
       AddLogAndUpdateEDocument(EDocument, EDocumentService, ActionContext.Status().GetErrorStatus());
       EDocumentLog.InsertIntegrationLog(EDocument, EDocumentService, HttpRequest, HttpResponse);
       exit;
   end;

   if UpdateStatus then
       AddLogAndUpdateEDocument(EDocument, EDocumentService, ActionContext.Status().GetStatus());

   // Always log HTTP communication regardless of status update
   EDocumentLog.InsertIntegrationLog(EDocument, EDocumentService, HttpRequest, HttpResponse);
   ```

**Status update procedure:**

```al
procedure AddLogAndUpdateEDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; EDocServiceStatus: Enum "E-Document Service Status")
begin
    EDocumentLog.InsertLog(EDocument, EDocumentService, EDocServiceStatus);
    EDocumentProcessing.ModifyServiceStatus(EDocument, EDocumentService, EDocServiceStatus);
    EDocumentProcessing.ModifyEDocumentStatus(EDocument);
end;
```

Inserts E-Document Log entry, updates E-Document Service Status to new status, recalculates E-Document header status from all service statuses.

## Action runner dispatch

**Internal OnRun trigger:**

```al
trigger OnRun()
var
    IAction: Interface IDocumentAction;
begin
    IAction := ActionType; // Enum to interface cast via Implementation clause
    UpdateStatusBool := IAction.InvokeAction(GlobalEDocument, GlobalEDocumentService, GlobalActionContext);
end;
```

AL platform resolves enum value to implementation codeunit at runtime. For default actions ("Sent Document Approval", "Sent Document Cancellation"), implementation codeunits cast to ISentDocumentActions and call specific methods.

## Default action implementations

### Sent Document Approval

**Action type:** "Sent Document Approval" (enum value 1)

**Implementation:** "Sent Document Approval" codeunit implements IDocumentAction

**Algorithm:**

```al
procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
var
    ISentDocumentActions: Interface ISentDocumentActions;
begin
    // Cast service enum to ISentDocumentActions interface
    ISentDocumentActions := EDocumentService."Service Integration V2";

    // Delegate to service-specific implementation
    exit(ISentDocumentActions.GetApprovalStatus(EDocument, EDocumentService, ActionContext));
end;
```

**Service implementation pattern:**

```al
procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
var
    HttpClient: HttpClient;
    ResponseText: Text;
begin
    // Build HTTP GET request for approval status
    HttpRequest := ActionContext.Http().GetHttpRequestMessage();
    HttpRequest.Method := 'GET';
    HttpRequest.SetRequestUri(EDocumentService."Service URL" + '/approval/' + EDocument."Document ID");
    HttpRequest.GetHeaders().Add('Authorization', 'Bearer ' + GetAccessToken());

    // Send request
    if not HttpClient.Send(HttpRequest, HttpResponse) then begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Failed to query approval status');
        exit(false); // No status change, error logged
    end;

    ActionContext.Http().SetHttpResponseMessage(HttpResponse);

    if not HttpResponse.IsSuccessStatusCode() then begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo('HTTP %1', HttpResponse.HttpStatusCode()));
        exit(false);
    end;

    // Parse response
    HttpResponse.Content().ReadAs(ResponseText);
    case GetStatusCode(ResponseText) of
        'APPROVED':
            begin
                ActionContext.Status().SetStatus("E-Document Service Status"::Approved);
                exit(true); // Update status to Approved
            end;
        'REJECTED':
            begin
                ActionContext.Status().SetStatus("E-Document Service Status"::Rejected);
                EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Document rejected: ' + GetReason(ResponseText));
                exit(true); // Update status to Rejected
            end;
        'PENDING':
            exit(false); // No status change, still pending approval
        else
            exit(false); // Unknown status, no change
    end;
end;
```

**Return value semantics:**
- `true` -- Status should update to ActionContext.Status() (Approved or Rejected)
- `false` -- Status unchanged (still pending or error occurred)

**User workflow:**
1. User sends document via service
2. Service transitions to Sent status
3. User clicks "Check Approval Status" action on E-Document Card
4. Integration Management invokes GetApprovalStatus
5. Service queries API for approval state
6. If approved: status becomes Approved, user sees green check
7. If rejected: status becomes Rejected, user sees error with reason
8. If pending: status unchanged, user can check again later

### Sent Document Cancellation

**Action type:** "Sent Document Cancellation" (enum value 2)

**Implementation:** Similar to approval, delegates to ISentDocumentActions.GetCancellationStatus

**Service implementation pattern:**

```al
procedure GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
begin
    // Build POST request to cancel document
    HttpRequest.Method := 'POST';
    HttpRequest.SetRequestUri(EDocumentService."Service URL" + '/cancel/' + EDocument."Document ID");
    HttpClient.Send(HttpRequest, HttpResponse);

    ActionContext.Http().SetHttpResponseMessage(HttpResponse);

    if HttpResponse.IsSuccessStatusCode() then begin
        ActionContext.Status().SetStatus("E-Document Service Status"::Cancelled);
        exit(true); // Successfully cancelled
    end else begin
        ActionContext.Status().SetErrorStatus("E-Document Service Status"::"Cancel Error");
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Cancellation failed: ' + GetErrorMessage(HttpResponse));
        exit(true); // Update to Cancel Error status
    end;
end;
```

**Error status pattern:**

When action should update status even on error:
```al
if not Success then begin
    ActionContext.Status().SetErrorStatus("E-Document Service Status"::"Cancel Error");
    // Log error
    exit(true); // Return true so status updates to Cancel Error
end;
```

Integration Management checks error count:
- If errors logged: uses GetErrorStatus() → Cancel Error
- If no errors: uses GetStatus() → Cancelled

## Custom action patterns

### Informational action (no status change)

**Example:** View document status on service portal

```al
codeunit 50300 "View Portal Status" implements IDocumentAction
{
    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    var
        HttpClient: HttpClient;
        StatusInfo: Text;
    begin
        // Query service for detailed status
        HttpClient.Get(
            EDocumentService."Service URL" + '/status/' + EDocument."Document ID",
            ActionContext.Http().GetHttpResponseMessage()
        );

        if not ActionContext.Http().GetHttpResponseMessage().IsSuccessStatusCode() then begin
            Message('Unable to retrieve status');
            exit(false); // No status change
        end;

        // Parse and display to user
        ActionContext.Http().GetHttpResponseMessage().Content().ReadAs(StatusInfo);
        Message('Document status:\%1', ParseStatusInfo(StatusInfo));

        exit(false); // Informational only, no status change
    end;
}
```

**Behavior:**
- HTTP communication logged automatically
- No E-Document Service Status update
- User sees information in message dialog

### Data retrieval action

**Example:** Download PDF receipt

```al
codeunit 50301 "Download Receipt" implements IDocumentAction
{
    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    var
        EDocLog: Record "E-Document Log";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Download receipt PDF
        HttpClient.Get(
            EDocumentService."Service URL" + '/receipt/' + EDocument."Document ID",
            ActionContext.Http().GetHttpResponseMessage()
        );

        if not ActionContext.Http().GetHttpResponseMessage().IsSuccessStatusCode() then begin
            Message('Receipt not available');
            exit(false);
        end;

        // Store in data storage
        TempBlob.CreateOutStream(OutStream);
        ActionContext.Http().GetHttpResponseMessage().Content().ReadAs(OutStream);

        EDocLog.SetFields(EDocument, EDocumentService);
        EDocLog.SetBlob('Receipt.pdf', "E-Doc. File Format"::PDF, TempBlob);
        EDocLog.InsertLog("E-Document Service Status"::Sent); // Keep current status

        Message('Receipt downloaded and stored');
        exit(false); // No status change
    end;
}
```

**Behavior:**
- PDF stored in E-Document Data Storage
- Linked to E-Document Log entry
- User can view via communication logs
- No status change

### State-changing action

**Example:** Request credit note from service

```al
codeunit 50302 "Request Credit Note" implements IDocumentAction
{
    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    var
        CreditNoteRequest: JsonObject;
        Content: HttpContent;
    begin
        // Build request payload
        CreditNoteRequest.Add('original_document_id', EDocument."Document ID");
        CreditNoteRequest.Add('reason', 'Customer requested');

        Content.WriteFrom(Format(CreditNoteRequest));
        ActionContext.Http().GetHttpRequestMessage().Content := Content;
        ActionContext.Http().GetHttpRequestMessage().Method := 'POST';
        ActionContext.Http().GetHttpRequestMessage().SetRequestUri(EDocumentService."Service URL" + '/credit-note');

        // Send request
        HttpClient.Send(ActionContext.Http().GetHttpRequestMessage(), ActionContext.Http().GetHttpResponseMessage());

        if not ActionContext.Http().GetHttpResponseMessage().IsSuccessStatusCode() then begin
            ActionContext.Status().SetErrorStatus("E-Document Service Status"::Error);
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Credit note request failed');
            exit(true); // Update to Error status
        end;

        // Parse response for credit note ID
        ParseCreditNoteId(ActionContext.Http().GetHttpResponseMessage(), EDocument);

        // Set custom status if available, or use standard
        ActionContext.Status().SetStatus("E-Document Service Status"::"Credit Memo Created");
        exit(true); // Update status
    end;
}
```

**Behavior:**
- Sends API request to create credit note
- On success: status updates to custom "Credit Memo Created" (if service extends status enum)
- On error: status updates to Error with logged message
- User sees status change in service status list

## Error handling

### Runtime errors

Service throws Error():
```al
if not Authenticated() then
    Error('Service authentication failed');
```

Integration Management catches via Commit+Run:
```al
if not EDocumentActionRunner.Run() then
    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, GetLastErrorText());
```

Result: Error logged, action considered failed, status may update to ErrorStatus if set.

### Business errors

Service logs explicitly:
```al
if HttpResponse.HttpStatusCode() = 401 then begin
    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Authentication failed');
    exit(false); // No status change
end;
```

Integration Management detects via error count comparison:
```al
ErrorCount := EDocumentErrorHelper.ErrorMessageCount(EDocument);
Success := EDocumentActionRunner.Run();
Success := EDocumentErrorHelper.ErrorMessageCount(EDocument) = ErrorCount;
```

If count increased: Success = false, use ErrorStatus (if set) or skip status update.

### HTTP logging

Automatic if ActionContext.Http() populated:
```al
// In service implementation
ActionContext.Http().SetHttpRequestMessage(HttpRequest);
ActionContext.Http().SetHttpResponseMessage(HttpResponse);

// In Integration Management (after action completes)
EDocumentLog.InsertIntegrationLog(
    EDocument,
    EDocumentService,
    ActionContext.Http().GetHttpRequestMessage(),
    ActionContext.Http().GetHttpResponseMessage()
);
```

Creates entry visible in E-Document Card → Communication Logs with:
- Timestamp
- HTTP method, URL, headers, body
- Response status code, headers, body

## Status update rules

**Decision matrix:**

| Success | UpdateStatus | ErrorStatus Set | Result |
|---------|-------------|-----------------|--------|
| true    | true        | N/A             | Update to ActionContext.Status() |
| true    | false       | N/A             | No status update |
| false   | true        | Yes             | Update to ActionContext.ErrorStatus() |
| false   | true        | No              | No status update |
| false   | false       | N/A             | No status update |

**Examples:**

1. **Approval action, document approved:**
   - Success = true (no errors logged)
   - UpdateStatus = true (GetApprovalStatus returns true)
   - ActionContext.Status() = Approved
   - Result: Status updates to Approved

2. **Approval action, still pending:**
   - Success = true
   - UpdateStatus = false (GetApprovalStatus returns false)
   - Result: No status update, document remains Sent

3. **Cancellation action, failed:**
   - Success = false (error logged: "Service unavailable")
   - UpdateStatus = true (GetCancellationStatus returns true)
   - ActionContext.ErrorStatus() = Cancel Error
   - Result: Status updates to Cancel Error

4. **View status action:**
   - Success = true
   - UpdateStatus = false (informational action)
   - Result: No status update, HTTP logged, user sees info message

## Idempotency

Actions should handle repeated invocation gracefully:

**Pattern for stateful actions:**

```al
procedure GetApprovalStatus(...): Boolean
begin
    // Check current status first
    if EDocument.Status = "E-Document Status"::Approved then begin
        Message('Document already approved');
        exit(false); // No status change needed
    end;

    // Query service
    ...
end;
```

**Pattern for data retrieval:**

```al
procedure DownloadReceipt(...): Boolean
begin
    // Check if already downloaded
    if ReceiptAlreadyStored(EDocument) then begin
        Message('Receipt already downloaded');
        exit(false);
    end;

    // Download
    ...
end;
```

Users can click action buttons multiple times. Service implementation should detect redundant calls and skip unnecessary API requests.

## Workflow integration

Actions invoked by workflow steps:

**Workflow setup:**
```al
// Approval workflow
Step 1: Send Document → Service Status = Sent
Step 2: Wait (timer or manual)
Step 3: Get Approval Status → Invokes "Sent Document Approval" action
Step 4: If Status = Approved → Continue
        If Status = Rejected → Notify user, halt
```

**Workflow event:**

After action completes, Integration Management triggers:
```al
WorkflowManagement.HandleEventOnKnownWorkflowInstance(
    EDocumentWorkflowSetup.EventEDocStatusChanged(),
    EDocumentServiceStatus,
    EDocument."Workflow Step Instance ID"
);
```

Workflow engine evaluates conditions based on new status, advances to next step or branches.

## Performance considerations

- **Actions are synchronous** -- User waits for API call to complete. Long-running operations should use async pattern (send request, poll status later).
- **No automatic retry** -- Failed actions require manual user retry via button click. Consider implementing retry logic inside action if service is flaky.
- **HTTP communication logged always** -- Even for informational actions. Can generate large logs if action called frequently.
- **Status recalculation** -- Every status update recalculates E-Document header status from all service statuses. For documents with many services, this adds overhead.

Recommend: Keep actions fast (< 5 seconds), use informational actions for frequently checked operations, batch status checks if service supports it.
