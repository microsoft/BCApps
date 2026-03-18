# Integration Interfaces

The Interfaces subdirectory defines seven service integration contracts that enable external e-invoice services, government portals, and clearance systems to connect with E-Document Core. These interfaces represent the V2 architecture introduced in version 24.0, replacing the monolithic V1 interface with granular, purpose-specific contracts. Each interface focuses on a single responsibility: sending documents, receiving documents, handling async responses, marking documents fetched, executing post-send actions, custom actions, or managing privacy consent.

## Quick reference

- **Files:** 7 interface definitions
- **Purpose:** Service integration contracts (send, receive, actions, consent)
- **Extensibility:** All interfaces are implemented by service-specific codeunits
- **Registration:** Via Service Integration enum Implementation assignments

## What it does

These interfaces define the contract between E-Document Core and external service implementations. Core code never calls service APIs directly -- it invokes interface methods that service extensions implement. This inversion of control allows partners to add new services without modifying foundation code.

The interfaces are grouped by operation type. IDocumentSender and IDocumentResponseHandler handle outbound document transmission (synchronous and asynchronous). IDocumentReceiver and IReceivedDocumentMarker handle inbound document polling and download. ISentDocumentActions and IDocumentAction provide post-send operations like approval status checks and cancellation requests. IConsentManager handles OAuth flows and privacy notices.

Each interface receives context codeunits (SendContext, ReceiveContext, ActionContext) that carry operation state. Context provides access to document content (TempBlob), HTTP message state (request/response), and status targets. Implementations populate these contexts, and Integration Management reads them to update E-Document Service Status and log HTTP communication.

Interface methods never modify E-Document records directly (except fields explicitly passed as var parameters). They communicate results via context status fields and error logging. Integration Management handles all status transitions, log insertions, and workflow triggers after the interface call completes.

## Key files

**IDocumentSender.Interface.al** (3KB, 55 lines) -- Defines Send method for transmitting formatted documents to service endpoints. Method receives EDocument, EDocumentService, and SendContext. Implementation reads content from SendContext.GetTempBlob(), builds HTTP request, sends to service API, sets response on SendContext.Http() for logging. If sender also implements IDocumentResponseHandler, Integration Management treats send as async and schedules GetResponse polling.

**IDocumentReceiver.Interface.al** (6KB, 113 lines) -- Defines ReceiveDocuments and DownloadDocument methods for inbound document polling. ReceiveDocuments queries service API for available documents, creates metadata blobs for each, adds to DocumentsMetadata list. DownloadDocument retrieves actual content for one document, writes to ReceiveContext.GetTempBlob(). If receiver also implements IReceivedDocumentMarker, Integration Management calls MarkFetched after successful download.

**IDocumentResponseHandler.Interface.al** (4KB, 65 lines) -- Defines GetResponse method for polling async send results. Called by E-Document Background Jobs when documents are in Pending Response status. Returns true if response ready (transition to Sent/Approved), false if still processing (remain in Pending Response). Errors log via E-Document Error Helper and transition to Sending Error.

**ISentDocumentActions.Interface.al** (5KB, 90 lines) -- Defines GetApprovalStatus and GetCancellationStatus methods for post-send status checks. GetApprovalStatus queries if document was approved by recipient or clearance authority, returns true if status should update to Approved/Rejected. GetCancellationStatus checks if cancellation request succeeded, returns true if status should update to Cancelled/Cancel Error. Both methods invoked manually via UI actions or workflow steps.

**IDocumentAction.Interface.al** (3KB, 48 lines) -- Generic action interface for custom service-specific operations (download receipt, update invoice, request credit note). Single method InvokeAction receives EDocument, EDocumentService, ActionContext. Implementation executes service API call, updates ActionContext.Status() if needed, returns true if status should update. Extensible via Integration Action Type enum extensions.

**IReceivedDocumentMarker.Interface.al** (3KB, 54 lines) -- Defines MarkFetched method for notifying service that document was downloaded. Called automatically after DownloadDocument succeeds if receiver implements this interface. Sends HTTP request to mark document as retrieved, preventing re-download on next poll. If MarkFetched fails, document import is aborted (error prevents duplicate imports).

**IConsentManager.Interface.al** (2KB, 46 lines) -- Defines ObtainPrivacyConsent method for handling OAuth flows and privacy notices. Called once when service is first configured. Returns true if user grants consent, false if declined. Default implementation (Consent Manager Default Impl.) shows standard privacy notice and stores approval. Custom services override to show service-specific consent or trigger OAuth.

## Interface implementation patterns

**Synchronous send:**
```al
procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
var
    Client: HttpClient;
begin
    SendContext.Http().GetHttpRequestMessage().SetRequestUri(EDocumentService."Service URL");
    SendContext.Http().GetHttpRequestMessage().Method := 'POST';
    // Add headers, content
    Client.Send(SendContext.Http().GetHttpRequestMessage(), SendContext.Http().GetHttpResponseMessage());
    // SendContext.Status() defaults to Sent, no need to set
end;
```

**Asynchronous send:**
```al
codeunit 50100 "My Async Sender" implements IDocumentSender, IDocumentResponseHandler
{
    procedure Send(...)
    begin
        // Submit to service, get tracking ID
        EDocument."Document ID" := TrackingId;
        EDocument.Modify();
        // Don't set SendContext.Status() -- defaults to Sent, but Integration Management overrides to Pending Response
    end;

    procedure GetResponse(...): Boolean
    begin
        // Poll service with EDocument."Document ID"
        if ResponseReady then begin
            SendContext.Status().SetStatus("E-Document Service Status"::Sent);
            exit(true);
        end;
        exit(false); // Still processing
    end;
}
```

**Inbound with mark-fetched:**
```al
codeunit 50110 "My Receiver" implements IDocumentReceiver, IReceivedDocumentMarker
{
    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    var
        DocumentBlob: Codeunit "Temp Blob";
        JsonArray: JsonArray;
        JsonToken: JsonToken;
    begin
        // Query API for document list
        JsonArray.ReadFrom(ApiResponse);
        foreach JsonToken in JsonArray do begin
            DocumentBlob.CreateOutStream(OutStr);
            JsonToken.WriteTo(OutStr); // Store metadata
            DocumentsMetadata.Add(DocumentBlob);
        end;
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    var
        DocumentId: Text;
    begin
        // Read DocumentId from DocumentMetadata blob
        DocumentMetadata.CreateInStream(InStr);
        InStr.ReadText(DocumentId);

        // Download actual document content
        Client.Get(ServiceUrl + '/download/' + DocumentId, ReceiveContext.Http().GetHttpResponseMessage());

        // Write to ReceiveContext.GetTempBlob()
        ReceiveContext.GetTempBlob().CreateOutStream(OutStr);
        ReceiveContext.Http().GetHttpResponseMessage().Content().ReadAs(OutStr);
    end;

    procedure MarkFetched(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var DocumentBlob: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    begin
        // POST to service API to mark as fetched
        Client.Post(ServiceUrl + '/mark-fetched/' + EDocument."Document ID", ...);
        if not HttpResponse.IsSuccessStatusCode() then
            Error('Failed to mark document as fetched');
    end;
}
```

**Custom action:**
```al
enumextension 50200 "Custom Actions" extends "Integration Action Type"
{
    value(50200; "Download Receipt")
    {
        Implementation = IDocumentAction = "Download Receipt Action";
    }
}

codeunit 50200 "Download Receipt Action" implements IDocumentAction
{
    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    begin
        // Download PDF receipt from service
        Client.Get(ServiceUrl + '/receipt/' + EDocument."Document ID", ActionContext.Http().GetHttpResponseMessage());

        // Store in E-Document Data Storage
        TempBlob.CreateOutStream(OutStr);
        ActionContext.Http().GetHttpResponseMessage().Content().ReadAs(OutStr);
        EDocLog.InsertDataStorage(TempBlob);

        // Don't change status
        exit(false);
    end;
}
```

## How it connects

Integration Management (parent directory) invokes these interfaces via dynamic dispatch. When a Send operation is requested, Integration Management reads EDocumentService."Service Integration V2" enum value, casts to IDocumentSender interface, and calls Send method. Context codeunits (SendContext, ReceiveContext, ActionContext) defined in parent and Actions directories flow through the interface boundary, carrying state in both directions.

Service implementations live in separate apps (localization extensions, partner apps). They extend Service Integration enum, implement required interfaces, and register via enum Implementation clause. At runtime, AL platform binds enum value to implementation codeunit.

E-Document Background Jobs schedules GetResponse polling for IDocumentResponseHandler and ReceiveDocuments polling for IDocumentReceiver. E-Document Processing invokes ISentDocumentActions methods when user clicks approval/cancellation actions. E-Document Action Runner dispatches IDocumentAction implementations based on Integration Action Type enum.

## Things to know

- **Interface casting determines behavior** -- Integration Management checks if sender implements IDocumentResponseHandler via interface cast. If true, send becomes async. If false, send is synchronous. This allows same enum value to support both patterns based on implementation.
- **Context is bidirectional** -- Implementations read inputs from context (TempBlob, service config) and write outputs to context (HTTP messages, status). Integration Management reads context after interface returns to determine next action.
- **HTTP logging is automatic** -- If HttpRequestMessage and HttpResponseMessage are set in context, Integration Management logs them to E-Document Integration Log. Implementations don't need explicit logging calls.
- **Error handling is split** -- Runtime errors (exceptions) are caught by Integration Management via if/Run() pattern. Business errors (invalid response, auth failure) are logged by implementation via E-Document Error Helper. Both result in Sending Error / Import Error status.
- **Mark-fetched is optional and separate** -- Services that don't support fetch tracking should not implement IReceivedDocumentMarker. Integration Management checks interface support via casting before calling. If not implemented, documents may be downloaded multiple times (service returns same list on each poll).
- **Action return value controls status update** -- InvokeAction returns Boolean. True means ActionContext.Status() should be written to E-Document Service Status. False means action was informational only (e.g., viewing status), no status update. Integration Management respects this flag.
- **Consent is called once** -- IConsentManager.ObtainPrivacyConsent is called when service is first added to E-Document Service setup or when user triggers consent re-validation. Consent approval is cached in setup; interface doesn't run on every document operation.

## Extensibility

These interfaces are the primary extensibility mechanism for E-Document Core. To add a custom service:

1. Create enum extension for Service Integration:
```al
enumextension 50100 "My Service" extends "Service Integration"
{
    value(50100; "My Service")
    {
        Implementation = IDocumentSender = "My Sender Codeunit",
                        IDocumentReceiver = "My Receiver Codeunit",
                        IConsentManager = "Consent Manager Default Impl.";
    }
}
```

2. Implement required interfaces in separate codeunits (one codeunit per interface or combined).

3. Optionally implement IDocumentResponseHandler (async send), IReceivedDocumentMarker (mark-fetched), ISentDocumentActions (approval/cancellation).

4. Create service setup table extension and page for service-specific configuration (API keys, endpoints).

5. Subscribe to OnBeforeOpenServiceIntegrationSetupPage event to open custom setup when user clicks Setup action.

No other code changes required -- Integration Management discovers and invokes implementations automatically via interface dispatch.

See parent directory extensibility.md for complete implementation examples with code samples.
