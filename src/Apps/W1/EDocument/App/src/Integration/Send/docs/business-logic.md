# Send Business Logic

This document describes the send operation execution flow, async response polling algorithm, batch send processing, and error handling patterns.

## Single document send

**Entry point:** `E-Doc. Integration Management.Send(var EDocument, EDocumentService, SendContext, var IsAsync)`

**Preconditions:**
- EDocument status is "In Progress" or "Error"
- E-Document Service Status is "Exported" or "Sending Error"
- E-Document Log contains entry with status Exported and attached Data Storage blob
- Service Integration V2 is configured (not "No Integration")

**Execution steps:**

1. **Validate send eligibility**
   - Check EDocument Service Status is Exported or Sending Error
   - If service is "No Integration", exit false
   - If status is not sendable (e.g., already Sent), show message and exit false

2. **Retrieve exported blob**
   - Call E-Document Log.GetDocumentBlobFromLog with status filter Exported
   - If blob not found, log error "Failed to get exported blob from EDocument {Entry No}", set status to Sending Error, exit false

3. **Initialize SendContext**
   - Set TempBlob from exported blob
   - Set default status to Sent

4. **Capture pre-send error count**
   - Get error count for EDocument via E-Document Error Helper
   - Used later to detect if Send operation logged errors

5. **Invoke interface (commit boundary)**
   - Call RunSend(EDocumentService, EDocument, SendContext, IsAsync)
   - RunSend wraps Send Runner in Commit+Run error isolation:
     ```al
     Commit(); // Isolate transaction
     SendRunner.SetDocumentAndService(EDocument, EDocumentService);
     SendRunner.SetContext(SendContext);
     if not SendRunner.Run() then
         EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, GetLastErrorText());
     ```
   - Emit telemetry start/end messages with service dimensions
   - Fire OnBeforeSendDocument and OnAfterSendDocument events

6. **Check operation success**
   - Compare current error count to pre-send count
   - Success := (ErrorCount unchanged)

7. **Determine service status**
   - If not Success: Sending Error
   - If IsAsync: Pending Response
   - Otherwise: SendContext.Status().GetStatus() (default: Sent)

8. **Update database**
   - Insert E-Document Log entry with determined status
   - Insert E-Document Integration Log with HTTP request/response
   - Update E-Document Service Status to determined status
   - Recalculate E-Document header status from all service statuses

9. **Return Success flag**

**Async detection:**

SendRunner checks if IDocumentSender implements IDocumentResponseHandler:
```al
IDocumentSender := EDocumentService."Service Integration V2";
IDocumentSender.Send(EDocument, EDocumentService, SendContext);
IsAsync := IDocumentSender is IDocumentResponseHandler;
```

If true, Integration Management:
- Transitions EDocument Service Status to Pending Response (overrides Sent)
- E-Document Background Jobs schedules Get Response job
- User sees "Pending Response" in service status list
- Background job polls GetResponse every 5 minutes until ready

## Async response polling

**Entry point:** `E-Document Get Response.OnRun()` (job queue codeunit)

**Scheduling:**
- Job is created by E-Document Background Jobs.ScheduleGetResponseJob
- Runs earliest 5 minutes after last completion (configurable via job queue)
- Job reschedules itself if documents remain Pending Response after processing

**Algorithm:**

1. **Check for pending documents**
   - Query E-Document Service Status where Status = Pending Response
   - If empty, exit (job does not reschedule)

2. **Process each pending document**
   - For each Service Status record:
     - Get EDocument record
     - Get EDocumentService record
     - Call HandleResponse(EDocument, EDocumentService, ServiceStatus)

3. **HandleResponse per document**
   - Create new SendContext, set default status to Sent
   - Capture pre-poll error count
   - Call RunGetResponse (commit+run boundary):
     ```al
     Commit();
     GetResponseRunner.SetDocumentAndService(EDocument, EDocumentService);
     GetResponseRunner.SetContext(SendContext);
     Success := GetResponseRunner.Run();
     GotResponse := GetResponseRunner.GetResponseResult();
     ```
   - Check if errors logged (compare error counts)
   - Determine service status via GetServiceStatusFromResponse:
     - If errors logged: Sending Error
     - If GotResponse = true: use SendContext.Status() (Sent, Approved, Rejected)
     - If GotResponse = false: remain Pending Response
   - Insert E-Document Log with determined status
   - Insert E-Document Integration Log with HTTP communication
   - Update E-Document Service Status
   - Recalculate E-Document header status
   - Fire workflow event EDocStatusChanged

4. **Check if documents remain pending**
   - Query E-Document Service Status for Pending Response after processing
   - If any remain, call E-Document Background Jobs.ScheduleGetResponseJob(false) to reschedule
   - If none remain, job exits without rescheduling

**GetResponse return value semantics:**

Interface implementation returns Boolean:
- `true` -- Response is ready, use SendContext.Status() for final state
  - Service sets status to Sent, Approved, Rejected, or custom status
  - Document transitions out of Pending Response
  - No further polling for this document
- `false` -- Response not ready yet
  - Document remains in Pending Response
  - Will be polled again in next job run (5 minutes)
  - Continues until service returns true or error occurs

**Timeout behavior:**

No built-in timeout. Document remains Pending Response indefinitely if service never returns ready status. User interventions:
- Manual "Check Status" action (triggers GetResponse immediately)
- "Resend" action (resets to Exported, starts send over)
- "Cancel" workflow action (moves to Error state)

## Batch send

**Entry point:** `E-Doc. Recurrent Batch Send.OnRun()` (job queue codeunit)

**Trigger:** User posts multiple sales documents with same service configured, service has "Use Batch Processing" enabled, workflow transitions documents to Pending Batch status, background job is scheduled.

**Algorithm:**

1. **Get service from job queue**
   - TableNo is "Job Queue Entry"
   - Rec."Record ID to Process" contains E-Document Service record ID
   - Service.Get(Rec."Record ID to Process")

2. **Query pending batch documents**
   - E-Document Service Status where Status = Pending Batch and Service Code = {Service.Code}
   - If empty, exit (no work)

3. **Build filter for all documents**
   - Iterate Service Status records, accumulate Entry No values into filter string
   - Produces filter like "1|2|3|4|5" for EDocument.SetFilter("Entry No", ...)

4. **Process by Document Type**
   - For each Document Type enum value (Sales Invoice, Sales Credit Memo, etc.):
     - EDocument.SetFilter("Entry No", {accumulated filter})
     - EDocument.SetRange("Document Type", {current type})
     - If FindSet:
       - Initialize temp tables and tracking dictionaries
       - Call E-Doc Export.ExportEDocumentBatch(EDocuments, EDocumentService, TempMappingLogs, TempBlob, ErrorCountDict)
         - Export iterates documents, generates formatted content for each, concatenates into single TempBlob
         - Stores mapping logs in temp table keyed by Entry No
       - Iterate exported documents:
         - Compare error count before/after export
         - If errors increased: set status to Export Error
         - If no errors: set status to Exported, add to "exported filter" string
         - Copy mapping logs from temp table to permanent table
         - Update E-Document Service Status
         - Update E-Document header status
       - If any documents exported successfully:
         - Create single Data Storage entry with shared TempBlob
         - Update all E-Document Log entries to reference shared Data Storage Entry No
         - Call Integration Management.SendBatch(EDocuments filtered to exported, EDocumentService, IsAsync)
         - If IsAsync: schedule Get Response job
         - Fire HandleNextEvent for workflow progression

**Batch send execution:**

Integration Management.SendBatch similar to Send but operates on filtered recordset:

1. Validate service is not "No Integration"
2. Retrieve exported blob (shared for all documents)
3. Set SendContext.TempBlob and default status
4. Capture error count for each document in batch (dictionary keyed by Entry No)
5. Call RunSendBatch (commit+run with SendRunner):
   - SendRunner checks service."Use Batch Processing"
   - If true: calls interface Send once with recordset containing all documents
   - If false: iterates recordset, calls Send for each document individually
6. Check success for each document (compare error counts)
7. Determine status per document:
   - If errors: Sending Error
   - If IsAsync: Pending Response
   - Otherwise: SendContext.Status()
8. Update database for each document:
   - Insert E-Document Log
   - Insert E-Document Integration Log (shared HTTP communication)
   - Update E-Document Service Status
   - Update E-Document header status

**Batch interface implementation:**

Service can process batch as single API call or iterate individually:

**Option A: True batch API**
```al
procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
var
    DocumentIds: List of [Text];
    BatchPayload: Text;
begin
    // Build array of documents
    if EDocument.FindSet() then
        repeat
            DocumentIds.Add(EDocument."Entry No");
        until EDocument.Next() = 0;

    // Single API call with array
    BatchPayload := BuildBatchJson(SendContext.GetTempBlob(), DocumentIds);
    HttpClient.Post(ServiceUrl + '/batch', BatchPayload, HttpResponse);

    // Parse batch response, update each EDocument."Document ID"
    ParseBatchResponse(HttpResponse, EDocument);
end;
```

**Option B: Iterate recordset**
```al
procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
begin
    if EDocument.FindSet() then
        repeat
            // Extract this document's content from shared blob (format-specific)
            ExtractDocumentFromBlob(EDocument."Index In Batch", SendContext.GetTempBlob(), SingleDocBlob);

            // Send individually
            HttpClient.Post(ServiceUrl + '/submit', SingleDocBlob, HttpResponse);

            // Update tracking ID
            EDocument."Document ID" := ExtractTrackingId(HttpResponse);
            EDocument.Modify();
        until EDocument.Next() = 0;
end;
```

## Error handling patterns

**Runtime errors:**

Caught by Commit+Run pattern in Integration Management:
```al
Commit(); // Isolate transaction
SendRunner.SetDocumentAndService(EDocument, EDocumentService);
SendRunner.SetContext(SendContext);
if not SendRunner.Run() then
    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, GetLastErrorText());
```

If service implementation throws Error(), Integration Management:
- Logs error message to E-Document error list
- Sets E-Document Service Status to Sending Error
- E-Document status becomes Error
- User sees error in error list and factbox

**Business errors:**

Service implementation logs explicitly:
```al
if not HttpResponse.IsSuccessStatusCode() then begin
    HttpResponse.Content().ReadAs(ErrorText);
    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Service error: ' + ErrorText);
    exit; // Don't throw -- Integration Management checks error count
end;
```

Integration Management detects error by comparing counts:
```al
ErrorCount := EDocumentErrorHelper.ErrorMessageCount(EDocument);
RunSend(EDocumentService, EDocument, SendContext, IsAsync);
Success := EDocumentErrorHelper.ErrorMessageCount(EDocument) = ErrorCount;
```

If count increased: Success = false, status becomes Sending Error.

**HTTP logging:**

Automatic if service sets SendContext.Http():
```al
SendContext.Http().SetHttpRequestMessage(HttpRequest);
SendContext.Http().SetHttpResponseMessage(HttpResponse);
```

Integration Management reads these after interface returns:
```al
EDocumentLog.InsertIntegrationLog(EDocument, EDocumentService,
    SendContext.Http().GetHttpRequestMessage(),
    SendContext.Http().GetHttpResponseMessage());
```

Creates E-Document Integration Log entry with:
- Request method, URL, headers, body
- Response status code, headers, body
- Timestamp and document reference

Visible in E-Document Card communication logs.

**Retry behavior:**

- Documents in Sending Error status can be resent via "Resend" action
- Resend resets status to Exported, triggers send again
- Documents in Pending Response poll automatically until ready or manual intervention
- No automatic retry on network errors (user must manually resend)

## Status transitions

**Send operation status flow:**

```
Exported → [Send] → Sent (sync success)
Exported → [Send] → Pending Response (async)
Exported → [Send] → Sending Error (error)
Sending Error → [Resend] → Exported → [Send] → ...
```

**Async response status flow:**

```
Pending Response → [GetResponse] → Sent (ready)
Pending Response → [GetResponse] → Approved (ready + approval)
Pending Response → [GetResponse] → Rejected (ready + rejection)
Pending Response → [GetResponse] → Pending Response (not ready, continue polling)
Pending Response → [GetResponse] → Sending Error (error during poll)
```

**Batch send status flow:**

```
[Multiple documents] → Pending Batch
Pending Batch → [Export batch] → Exported (per document)
Exported → [Send batch] → Sent / Pending Response / Sending Error (per document)
```

Each document in batch has independent status even though send operation is shared.
