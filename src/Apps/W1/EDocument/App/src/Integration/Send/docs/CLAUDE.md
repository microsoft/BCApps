# Integration Send

The Send subdirectory implements the outbound document transmission pipeline, handling both synchronous HTTP sends and asynchronous polling for responses. It provides the infrastructure for single-document sends, batch sends, and background jobs that check pending responses. This layer sits between E-Doc. Integration Management (which orchestrates operations) and service implementations (which communicate with APIs), managing context state, interface dispatch, and async workflow scheduling.

## Quick reference

- **Files:** 5 codeunits (runners, context, batch processing)
- **Key operations:** Send, SendBatch, GetResponse, RecurrentBatchSend
- **Async support:** IDocumentResponseHandler detection and polling
- **Context:** SendContext codeunit carries TempBlob, HTTP state, status

## What it does

Send Runner is the interface dispatcher for IDocumentSender and IDocumentResponseHandler. Integration Management calls SendRunner.Run() within a Commit+Run error boundary, which selects V1 or V2 interface based on service configuration, invokes the Send method, and detects async behavior by checking if the sender implements IDocumentResponseHandler. The IsAsync flag returned to Integration Management controls whether the document transitions to Sent or Pending Response.

SendContext is the state carrier for send operations. It holds three pieces of state: the formatted document content (TempBlob), the HTTP communication (HttpRequestMessage and HttpResponseMessage), and the target status (default: Sent). Service implementations read from context (get TempBlob, get service config) and write to context (set HTTP messages for logging, override status if needed). Integration Management reads context after the interface call completes to determine what to log and which status to apply.

E-Document Get Response is the background job that polls async services for send responses. It runs every 5 minutes (configurable), queries all documents in Pending Response status, calls GetResponse on each via Get Response Runner, and updates status based on results. If GetResponse returns true, the document transitions to Sent/Approved/Rejected based on context status. If false, it remains Pending Response for next poll. If any documents remain pending after the job runs, it reschedules itself for the next interval.

E-Doc. Recurrent Batch Send is a separate background job for batched document sending. It processes documents in Pending Batch status, groups by Document Type, exports each group to a shared TempBlob, calls SendBatch on the service interface, and updates statuses individually. This allows services to optimize transmission by sending multiple documents in a single HTTP request while maintaining per-document status tracking.

Get Response Runner handles the interface dispatch for IDocumentResponseHandler, including legacy V1 fallback. It checks if the service uses V2 integration (Service Integration V2 field), casts to IDocumentResponseHandler, and calls GetResponse with SendContext. For V1 services, it falls back to the obsolete E-Document Integration interface. The result Boolean indicates whether the response is ready (true) or still pending (false).

## Key files

**SendRunner.Codeunit.al** (4KB, 107 lines) -- Interface dispatcher for Send operation. OnRun trigger checks service configuration: if V2, casts to IDocumentSender and calls Send; if V1, uses legacy E-Document Integration interface. After Send completes, checks if sender implements IDocumentResponseHandler via interface cast and sets IsAsyncValue flag. GetIsAsync method returns this flag to Integration Management for status determination. Handles both single and batch send paths based on service configuration.

**SendContext.Codeunit.al** (2KB, 55 lines) -- Public API for send operation state. Provides GetTempBlob/SetTempBlob for document content, Http() accessor for HttpMessageState codeunit, Status() accessor for IntegrationActionStatus codeunit. Context is initialized by Integration Management before calling SendRunner, passed to service interface implementation, and read by Integration Management after completion. Service implementations never create SendContext instances directly.

**EDocRecurrentBatchSend.Codeunit.al** (6KB, 109 lines) -- Job queue codeunit for batch sending. Queries E-Document Service Status for Pending Batch status, groups documents by Document Type, calls E-Doc Export to generate formatted blobs for each group, invokes Integration Management.SendBatch with document recordset, updates statuses individually (Exported → Sent or Sending Error). If send is async, schedules Get Response job. Stores shared blob in E-Document Data Storage with single entry number referenced by all documents in batch.

**EDocumentGetResponse.Codeunit.al** (7KB, 135 lines) -- Job queue codeunit for async response polling. TableNo is "Job Queue Entry" for background execution. OnRun trigger checks if any documents are Pending Response; if not, exits. Otherwise, calls ProcessPendingResponseDocuments which iterates all Pending Response statuses, calls HandleResponse for each, and triggers workflow events after status update. If documents remain pending after processing, reschedules itself via E-Document Background Jobs. HandleResponse invokes Get Response Runner, interprets Boolean result, and determines final status via GetServiceStatusFromResponse.

**GetResponseRunner.Codeunit.al** (3KB, 82 lines) -- Interface dispatcher for GetResponse operation. OnRun trigger checks if service uses V2 integration; if yes, casts IDocumentSender to IDocumentResponseHandler (will be null if not implemented), calls GetResponse with SendContext. If V1, uses legacy E-Document Integration.GetResponse with HttpRequestMessage/HttpResponseMessage directly. Result Boolean stored in local variable, returned via GetResponseResult accessor. SetContext and SetDocumentAndService methods populate instance variables before Run is called.

## Send operation flow

1. Integration Management creates SendContext, sets TempBlob from E-Document Log, sets default status to Sent
2. Integration Management calls SendRunner.Run() within Commit boundary
3. SendRunner.OnRun checks EDocumentService."Service Integration V2" field
4. If V2: casts to IDocumentSender, calls Send(EDocument, EDocumentService, SendContext)
5. Service implementation reads SendContext.GetTempBlob(), builds HTTP request, sends to API
6. Service sets SendContext.Http() request/response for logging, optionally overrides SendContext.Status()
7. SendRunner checks if IDocumentSender is also IDocumentResponseHandler (interface cast)
8. SendRunner.GetIsAsync returns true if ResponseHandler implemented, false otherwise
9. Integration Management reads IsAsync flag and SendContext.Status()
10. If IsAsync, transitions to Pending Response and schedules Get Response job
11. If not async, transitions to SendContext.Status() (default: Sent)

## Async response polling flow

1. E-Document Background Jobs schedules "E-Document Get Response" job queue entry
2. Job runs every 5 minutes (default interval)
3. EDocumentGetResponse.OnRun queries E-Document Service Status for Pending Response
4. For each status, calls HandleResponse(EDocument, EDocumentService, ServiceStatus)
5. HandleResponse creates new SendContext, sets default status to Sent
6. HandleResponse calls RunGetResponse which invokes Get Response Runner within Commit+Run boundary
7. Get Response Runner casts to IDocumentResponseHandler, calls GetResponse(EDocument, EDocumentService, SendContext)
8. Service implementation queries API for response status using EDocument."Document ID"
9. If ready: service sets SendContext.Status() to Sent/Approved/Rejected, returns true
10. If not ready: service returns false without changing status
11. HandleResponse interprets result via GetServiceStatusFromResponse:
    - If error count increased: Sending Error
    - If GetResponse returned true: use SendContext.Status()
    - If GetResponse returned false: remain Pending Response
12. Integration Management updates E-Document Service Status and E-Document status
13. If any documents still Pending Response after job completes, job reschedules itself

## Batch send flow

1. User posts multiple sales documents with same service configured
2. E-Document Workflow Processing transitions documents to Pending Batch status
3. E-Document Background Jobs schedules "E-Doc. Recurrent Batch Send" job for the service
4. Job runs, queries all Pending Batch documents for the service
5. Groups documents by Document Type (Sales Invoice, Sales Credit Memo, etc.)
6. For each group:
   - Calls E-Doc Export.ExportEDocumentBatch with filtered recordset
   - Export generates single TempBlob with all documents (format-specific concatenation)
   - Calls Integration Management.SendBatch with recordset and TempBlob
   - SendBatch invokes SendRunner with batch context (recordset has multiple records)
   - Service implementation iterates recordset or sends as batch API call
   - SendBatch updates each document status individually based on error counts
7. If send is async, schedules Get Response job for polling
8. If send is sync, documents transition directly to Sent or Sending Error

## How it connects

Integration Management is the primary caller. It invokes SendRunner for individual sends and Get Response Runner for async polls. Both runners are Internal access, never called directly by UI or workflow code.

SendContext and ActionContext (in Actions directory) share the same structure: both provide Http() and Status() accessors. SendContext adds GetTempBlob/SetTempBlob for document content. This consistency allows service implementations to use similar patterns for Send and Action operations.

E-Document Background Jobs (in Processing directory) schedules the batch send and get response jobs. Recurrent Batch Send is triggered when documents reach Pending Batch status. Get Response is triggered after async sends and reschedules itself if documents remain pending.

E-Doc Export (in Processing directory) generates the formatted TempBlob that SendContext carries. Export reads E-Document Service configuration to select format interface, invokes format creation, and writes output to TempBlob. SendRunner receives the TempBlob via SendContext and passes it to service implementation.

## Things to know

- **SendContext is created once per operation** -- Integration Management creates SendContext before calling SendRunner. Service implementations receive the same instance. Context is not reused across operations.
- **TempBlob default is Exported blob** -- Integration Management sets SendContext.GetTempBlob() from the most recent Exported log entry. Service implementations never need to query E-Document Log directly.
- **Status default is Sent** -- SendContext.Status() starts as Sent. Service implementations only set status if result is different (Approved, custom status). If service doesn't set status, Integration Management uses Sent.
- **IsAsync detection is interface-based** -- SendRunner checks if IDocumentSender implements IDocumentResponseHandler via AL interface casting. No configuration field controls this; implementation determines behavior.
- **GetResponse polling has no timeout** -- A document can remain Pending Response indefinitely. User must manually intervene (resend, cancel) if service never returns response.
- **Batch blob is shared storage** -- RecurrentBatchSend creates one Data Storage entry for all documents in batch. Each E-Document Log references the same Data Storage Entry No. This avoids duplicating large blobs.
- **V1 fallback is conditional compilation** -- Code contains #if not CLEAN26 blocks for legacy E-Document Integration interface support. These paths will be removed when all services migrate to V2.
- **HTTP logging is automatic** -- If SendContext.Http() contains request/response, Integration Management logs them to E-Document Integration Log. Service implementations never call log methods directly.

## Extensibility

Service implementations extend SendContext usage via status overrides:

**Custom success status:**
```al
procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
begin
    // Send to API
    HttpClient.Send(HttpRequest, HttpResponse);

    // If service immediately approves document
    if ResponseIndicatesApproval(HttpResponse) then
        SendContext.Status().SetStatus("E-Document Service Status"::Approved);
    // Otherwise, defaults to Sent
end;
```

**Async send with custom tracking:**
```al
codeunit 50100 "My Async Sender" implements IDocumentSender, IDocumentResponseHandler
{
    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    begin
        // Submit document, get tracking ID
        HttpClient.Post(SendContext.Http().GetHttpRequestMessage(), SendContext.Http().GetHttpResponseMessage());
        EDocument."Document ID" := ExtractTrackingId(SendContext.Http().GetHttpResponseMessage());
        EDocument.Modify();

        // Don't set status -- Integration Management will override to Pending Response
    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean
    begin
        // Poll status using EDocument."Document ID"
        HttpClient.Get(ServiceUrl + '/status/' + EDocument."Document ID", SendContext.Http().GetHttpResponseMessage());

        if ResponseIsReady(SendContext.Http().GetHttpResponseMessage()) then begin
            SendContext.Status().SetStatus("E-Document Service Status"::Sent);
            exit(true);
        end;

        exit(false); // Still processing
    end;
}
```

No events are defined at this layer. Extensibility is via interface implementation and SendContext state manipulation. See Integration extensibility.md for complete interface documentation.
