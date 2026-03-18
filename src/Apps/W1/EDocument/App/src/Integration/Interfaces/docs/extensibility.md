# Interfaces Extensibility

This document provides detailed implementation guidance for each service integration interface, including method signatures, parameter usage, error handling patterns, and complete code examples.

## Interface reference

### IDocumentSender

**Contract:** Send formatted E-Document to external service.

**Method signature:**
```al
procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
```

**Parameters:**
- `EDocument` (var) -- The document being sent. Can be single record or filtered recordset for batch operations. Modify to update fields like "Document ID" or custom tracking fields.
- `EDocumentService` (var) -- Service configuration containing endpoint URL, authentication settings, custom options. Modify if service returns updated config (e.g., refreshed OAuth token).
- `SendContext` (in/out) -- Carries document content, HTTP state, and status target. Read TempBlob for document content, write HTTP messages for logging, set status if different from default Sent.

**Implementation requirements:**

1. **Read document content:**
```al
var
    DocumentBlob: Codeunit "Temp Blob";
    InStream: InStream;
    DocumentText: Text;
begin
    DocumentBlob := SendContext.GetTempBlob();
    DocumentBlob.CreateInStream(InStream, TextEncoding::UTF8);
    InStream.ReadText(DocumentText);
end;
```

2. **Build HTTP request:**
```al
var
    HttpRequest: HttpRequestMessage;
    HttpContent: HttpContent;
begin
    HttpRequest := SendContext.Http().GetHttpRequestMessage();
    HttpRequest.Method := 'POST';
    HttpRequest.SetRequestUri(EDocumentService."Service URL" + '/submit');

    HttpContent.WriteFrom(DocumentText);
    HttpContent.GetHeaders().Clear();
    HttpContent.GetHeaders().Add('Content-Type', 'application/xml');
    HttpRequest.Content := HttpContent;

    HttpRequest.GetHeaders().Add('Authorization', 'Bearer ' + GetAccessToken(EDocumentService));
    HttpRequest.GetHeaders().Add('X-Company-ID', CompanyName());
end;
```

3. **Send and capture response:**
```al
var
    HttpClient: HttpClient;
    HttpResponse: HttpResponseMessage;
    ResponseText: Text;
begin
    if not HttpClient.Send(HttpRequest, HttpResponse) then
        Error('HTTP send failed');

    SendContext.Http().SetHttpResponseMessage(HttpResponse);

    if not HttpResponse.IsSuccessStatusCode() then begin
        HttpResponse.Content().ReadAs(ResponseText);
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Service error: ' + ResponseText);
        exit;
    end;

    // Parse response for tracking ID
    HttpResponse.Content().ReadAs(ResponseText);
    EDocument."Document ID" := CopyStr(ExtractTrackingId(ResponseText), 1, MaxStrLen(EDocument."Document ID"));
    EDocument.Modify();
end;
```

4. **Set result status (optional):**
```al
// If service immediately approves document
if ResponseIndicatesApproval(ResponseText) then
    SendContext.Status().SetStatus("E-Document Service Status"::Approved);
// Otherwise, defaults to Sent
```

**Batch operations:**

When `EDocumentService."Use Batch Processing"` is enabled, `EDocument` parameter contains multiple records (filtered recordset). Implementation can either:

A. **Process individually** (iterate recordset, send one-by-one):
```al
if EDocument.FindSet() then
    repeat
        // Send each document with same TempBlob content
    until EDocument.Next() = 0;
```

B. **Send as batch** (single API call for all documents):
```al
var
    DocumentIds: List of [Text];
begin
    // Build batch payload
    if EDocument.FindSet() then
        repeat
            DocumentIds.Add(EDocument."Entry No");
        until EDocument.Next() = 0;

    // Send batch request
    HttpRequest.Content := BuildBatchPayload(SendContext.GetTempBlob(), DocumentIds);
    // Parse batch response, update each EDocument record
end;
```

**Error handling:**

- **Runtime errors:** Throw Error() or let exception propagate. Integration Management catches via if/Run() pattern and logs as Sending Error.
- **Business errors:** Call E-Document Error Helper explicitly for user-visible messages:
```al
if not HttpResponse.IsSuccessStatusCode() then begin
    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo('HTTP %1: %2', HttpResponse.HttpStatusCode(), ResponseText));
    exit; // Don't throw -- Integration Management checks error count
end;
```

**Async pattern:**

If implementation also provides IDocumentResponseHandler:
```al
codeunit 50100 "My Async Sender" implements IDocumentSender, IDocumentResponseHandler
{
    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    begin
        // Submit to service, get tracking ID
        HttpClient.Send(HttpRequest, HttpResponse);
        ParseTrackingId(HttpResponse, EDocument."Document ID");
        EDocument.Modify();

        // Don't set status -- Integration Management will override to Pending Response
        // because this codeunit implements IDocumentResponseHandler
    end;
}
```

Integration Management detects IDocumentResponseHandler via interface cast and transitions to Pending Response instead of Sent.

---

### IDocumentResponseHandler

**Contract:** Poll async service for send response.

**Method signature:**
```al
procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean
```

**Return value:**
- `true` -- Response is ready, use SendContext.Status() for final state (Sent, Approved, etc.)
- `false` -- Still processing, remain in Pending Response for next poll

**Implementation pattern:**
```al
procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean
var
    HttpRequest: HttpRequestMessage;
    HttpResponse: HttpResponseMessage;
    HttpClient: HttpClient;
    ResponseText: Text;
    StatusCode: Text;
begin
    // Build status query request
    HttpRequest := SendContext.Http().GetHttpRequestMessage();
    HttpRequest.Method := 'GET';
    HttpRequest.SetRequestUri(EDocumentService."Service URL" + '/status/' + EDocument."Document ID");
    HttpRequest.GetHeaders().Add('Authorization', 'Bearer ' + GetAccessToken(EDocumentService));

    // Send request
    if not HttpClient.Send(HttpRequest, HttpResponse) then begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Failed to query status');
        exit(false); // Retry next poll
    end;

    SendContext.Http().SetHttpResponseMessage(HttpResponse);

    // Parse response
    HttpResponse.Content().ReadAs(ResponseText);
    StatusCode := ExtractStatusCode(ResponseText);

    // Interpret status
    case StatusCode of
        'COMPLETED':
            begin
                SendContext.Status().SetStatus("E-Document Service Status"::Sent);
                exit(true); // Done
            end;
        'APPROVED':
            begin
                SendContext.Status().SetStatus("E-Document Service Status"::Approved);
                exit(true); // Done
            end;
        'REJECTED':
            begin
                EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Document rejected by service: ' + ExtractReason(ResponseText));
                SendContext.Status().SetStatus("E-Document Service Status"::Rejected);
                exit(true); // Done (final state)
            end;
        'PROCESSING':
            exit(false); // Still pending, check next poll
        'ERROR':
            begin
                EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Service processing error: ' + ExtractErrorMessage(ResponseText));
                exit(false); // Error logged, Integration Management sets Sending Error
            end;
        else
            begin
                EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Unknown status code: ' + StatusCode);
                exit(false);
            end;
    end;
end;
```

**Polling behavior:**

- E-Document Background Jobs calls GetResponse for all documents in Pending Response status
- Job runs every 5 minutes by default (configurable via job queue entry)
- If GetResponse returns false for any document, job reschedules itself for next interval
- If all documents return true (or error), job does not reschedule until next async send occurs

**Timeout handling:**

No built-in timeout. If document remains Pending Response indefinitely, user can:
- Manually check status via page action (triggers GetResponse manually)
- Resend document (resets to Exported, starts over)
- Cancel workflow (moves to Error state)

---

### IDocumentReceiver

**Contract:** Poll service for inbound documents and download content.

**Method 1: ReceiveDocuments**

**Signature:**
```al
procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
```

**Purpose:** Query service API for list of available documents. Create metadata blob for each document and add to list.

**Implementation:**
```al
procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
var
    HttpRequest: HttpRequestMessage;
    HttpResponse: HttpResponseMessage;
    HttpClient: HttpClient;
    ResponseText: Text;
    DocumentsArray: JsonArray;
    DocumentToken: JsonToken;
    DocumentBlob: Codeunit "Temp Blob";
    OutStream: OutStream;
begin
    // Query for document list
    HttpRequest := ReceiveContext.Http().GetHttpRequestMessage();
    HttpRequest.Method := 'GET';
    HttpRequest.SetRequestUri(EDocumentService."Service URL" + '/inbox');
    HttpRequest.GetHeaders().Add('Authorization', 'Bearer ' + GetAccessToken(EDocumentService));

    if not HttpClient.Send(HttpRequest, HttpResponse) then
        Error('Failed to receive documents');

    ReceiveContext.Http().SetHttpResponseMessage(HttpResponse);

    if not HttpResponse.IsSuccessStatusCode() then
        Error('Service returned error: %1', HttpResponse.HttpStatusCode());

    // Parse response JSON array
    HttpResponse.Content().ReadAs(ResponseText);
    DocumentsArray.ReadFrom(ResponseText);

    // Create blob for each document
    foreach DocumentToken in DocumentsArray do begin
        Clear(DocumentBlob);
        DocumentBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        DocumentToken.WriteTo(OutStream); // Store entire JSON object as metadata
        DocumentsMetadata.Add(DocumentBlob);
    end;
end;
```

Integration Management calls this once per polling interval, creates E-Document record for each blob in list, then calls DownloadDocument for each record.

**Method 2: DownloadDocument**

**Signature:**
```al
procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
```

**Purpose:** Download actual document content (XML, JSON, PDF) for one E-Document.

**Implementation:**
```al
procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
var
    HttpRequest: HttpRequestMessage;
    HttpResponse: HttpResponseMessage;
    HttpClient: HttpClient;
    DocumentJson: JsonObject;
    DocumentId: Text;
    InStream: InStream;
    OutStream: OutStream;
    ResponseText: Text;
begin
    // Parse metadata to get document ID
    DocumentMetadata.CreateInStream(InStream, TextEncoding::UTF8);
    DocumentJson.ReadFrom(InStream);
    DocumentJson.Get('id', DocumentId);

    if DocumentId = '' then begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Document ID not found in metadata');
        exit;
    end;

    // Store document ID for tracking
    EDocument."Document ID" := CopyStr(DocumentId, 1, MaxStrLen(EDocument."Document ID"));
    EDocument.Modify();

    // Download document content
    HttpRequest := ReceiveContext.Http().GetHttpRequestMessage();
    HttpRequest.Method := 'GET';
    HttpRequest.SetRequestUri(EDocumentService."Service URL" + '/download/' + DocumentId);
    HttpRequest.GetHeaders().Add('Authorization', 'Bearer ' + GetAccessToken(EDocumentService));

    if not HttpClient.Send(HttpRequest, HttpResponse) then begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Failed to download document');
        exit;
    end;

    ReceiveContext.Http().SetHttpResponseMessage(HttpResponse);

    if not HttpResponse.IsSuccessStatusCode() then begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo('Download failed: HTTP %1', HttpResponse.HttpStatusCode()));
        exit;
    end;

    // Write content to ReceiveContext
    HttpResponse.Content().ReadAs(ResponseText);
    ReceiveContext.GetTempBlob().CreateOutStream(OutStream, TextEncoding::UTF8);
    OutStream.WriteText(ResponseText);

    // Set filename and format (optional, improves logging)
    ReceiveContext.SetName(DocumentId + '.xml');
    ReceiveContext.SetFileFormat("E-Doc. File Format"::XML);

    // Status defaults to Imported, can override if needed
    // ReceiveContext.Status().SetStatus("E-Document Service Status"::"Batch Imported");
end;
```

---

### IReceivedDocumentMarker

**Contract:** Notify service that document was successfully downloaded.

**Signature:**
```al
procedure MarkFetched(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var DocumentBlob: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
```

**Purpose:** Prevent re-download of same document on next poll.

**Implementation:**
```al
procedure MarkFetched(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var DocumentBlob: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
var
    HttpRequest: HttpRequestMessage;
    HttpResponse: HttpResponseMessage;
    HttpClient: HttpClient;
begin
    // Build mark-fetched request
    HttpRequest := ReceiveContext.Http().GetHttpRequestMessage();
    HttpRequest.Method := 'POST';
    HttpRequest.SetRequestUri(EDocumentService."Service URL" + '/mark-fetched/' + EDocument."Document ID");
    HttpRequest.GetHeaders().Add('Authorization', 'Bearer ' + GetAccessToken(EDocumentService));

    // Send request
    if not HttpClient.Send(HttpRequest, HttpResponse) then
        Error('Failed to mark document as fetched');

    ReceiveContext.Http().SetHttpResponseMessage(HttpResponse);

    if not HttpResponse.IsSuccessStatusCode() then
        Error('Service returned error when marking fetched: HTTP %1', HttpResponse.HttpStatusCode());
end;
```

**Error behavior:** If MarkFetched throws error, Integration Management aborts E-Document creation. Document is not imported and will be attempted again on next poll.

**Optional interface:** Only implement if service supports mark-fetched tracking. If not implemented, documents may be downloaded multiple times (service returns same list on each poll). Consider storing last-poll timestamp in service setup and filtering by date if mark-fetched is not available.

---

### ISentDocumentActions

**Contract:** Default post-send actions for approval and cancellation.

**Method 1: GetApprovalStatus**

**Signature:**
```al
procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
```

**Return:** True if status should update, false if unchanged.

**Implementation:**
```al
procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
var
    HttpRequest: HttpRequestMessage;
    HttpResponse: HttpResponseMessage;
    HttpClient: HttpClient;
    ResponseText: Text;
    ApprovalStatus: Text;
begin
    // Query approval status
    HttpRequest := ActionContext.Http().GetHttpRequestMessage();
    HttpRequest.Method := 'GET';
    HttpRequest.SetRequestUri(EDocumentService."Service URL" + '/approval/' + EDocument."Document ID");
    HttpRequest.GetHeaders().Add('Authorization', 'Bearer ' + GetAccessToken(EDocumentService));

    if not HttpClient.Send(HttpRequest, HttpResponse) then begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Failed to query approval status');
        exit(false);
    end;

    ActionContext.Http().SetHttpResponseMessage(HttpResponse);

    if not HttpResponse.IsSuccessStatusCode() then begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo('HTTP %1', HttpResponse.HttpStatusCode()));
        exit(false);
    end;

    // Parse response
    HttpResponse.Content().ReadAs(ResponseText);
    ApprovalStatus := ExtractStatus(ResponseText);

    // Update status based on result
    case ApprovalStatus of
        'APPROVED':
            begin
                ActionContext.Status().SetStatus("E-Document Service Status"::Approved);
                exit(true); // Update status
            end;
        'REJECTED':
            begin
                ActionContext.Status().SetStatus("E-Document Service Status"::Rejected);
                EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Document rejected: ' + ExtractReason(ResponseText));
                exit(true); // Update status
            end;
        'PENDING':
            exit(false); // No status change, still pending
        else
            exit(false); // Unknown status, no change
    end;
end;
```

**Method 2: GetCancellationStatus**

**Signature:**
```al
procedure GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
```

**Implementation:** Similar to GetApprovalStatus, query cancellation endpoint, set status to Cancelled or Cancel Error.

---

### IDocumentAction

**Contract:** Custom extensible actions.

**Signature:**
```al
procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
```

**Example: Download receipt**

```al
enumextension 50200 "Custom Actions" extends "Integration Action Type"
{
    value(50200; "Download Receipt")
    {
        Caption = 'Download Receipt';
        Implementation = IDocumentAction = "Download Receipt Action";
    }
}

codeunit 50200 "Download Receipt Action" implements IDocumentAction
{
    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    var
        EDocLog: Record "E-Document Log";
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpClient: HttpClient;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Download PDF receipt
        HttpRequest := ActionContext.Http().GetHttpRequestMessage();
        HttpRequest.Method := 'GET';
        HttpRequest.SetRequestUri(EDocumentService."Service URL" + '/receipt/' + EDocument."Document ID");
        HttpRequest.GetHeaders().Add('Authorization', 'Bearer ' + GetAccessToken(EDocumentService));

        if not HttpClient.Send(HttpRequest, HttpResponse) then begin
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Failed to download receipt');
            exit(false);
        end;

        ActionContext.Http().SetHttpResponseMessage(HttpResponse);

        if not HttpResponse.IsSuccessStatusCode() then begin
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Receipt not available');
            exit(false);
        end;

        // Store PDF in data storage
        TempBlob.CreateOutStream(OutStream);
        HttpResponse.Content().ReadAs(OutStream);

        EDocLog.InsertDataStorage(TempBlob);
        Message('Receipt downloaded and stored');

        // Don't change status -- informational action only
        exit(false);
    end;
}
```

---

### IConsentManager

**Contract:** Handle privacy consent and OAuth flows.

**Signature:**
```al
procedure ObtainPrivacyConsent(): Boolean
```

**Default implementation:**
```al
codeunit 50300 "My Consent Manager" implements IConsentManager
{
    procedure ObtainPrivacyConsent(): Boolean
    var
        ConsentManagerDefaultImpl: Codeunit "Consent Manager Default Impl.";
    begin
        // Use standard consent dialog
        exit(ConsentManagerDefaultImpl.ObtainPrivacyConsent());
    end;
}
```

**Custom implementation:**
```al
procedure ObtainPrivacyConsent(): Boolean
var
    CustomConsentDialog: Page "My Consent Dialog";
    Approved: Boolean;
begin
    CustomConsentDialog.SetServiceInfo('My Service', 'https://example.com/privacy');
    CustomConsentDialog.RunModal();
    Approved := CustomConsentDialog.GetApproval();

    if Approved then
        // Store approval in service setup or user settings
        StoreConsentApproval();

    exit(Approved);
end;
```

**OAuth flow example:**
```al
procedure ObtainPrivacyConsent(): Boolean
var
    OAuth2: Codeunit OAuth2;
    AccessToken: Text;
begin
    // Trigger OAuth flow
    if not OAuth2.AcquireTokenByAuthorizationCode(
        ClientId,
        ClientSecret,
        AuthorizationEndpoint,
        TokenEndpoint,
        RedirectUri,
        AccessToken) then
        exit(false);

    // Store token in service setup
    StoreAccessToken(AccessToken);
    exit(true);
end;
```

---

## Error handling patterns

**Best practices:**

1. **Use E-Document Error Helper for user messages:**
```al
EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Failed to connect to service');
```

2. **Set error status in ActionContext for action failures:**
```al
ActionContext.Status().SetErrorStatus("E-Document Service Status"::"Sending Error");
```

3. **Throw Error() for fatal failures:**
```al
if not HttpResponse.IsSuccessStatusCode() then
    Error('HTTP %1: %2', HttpResponse.HttpStatusCode(), ErrorMessage);
```

4. **Log but don't throw for retryable failures:**
```al
if not HttpClient.Send(HttpRequest, HttpResponse) then begin
    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Network error, will retry');
    exit(false); // For IDocumentResponseHandler, return false to retry
end;
```

Integration Management handles all error propagation to status updates and UI display.
