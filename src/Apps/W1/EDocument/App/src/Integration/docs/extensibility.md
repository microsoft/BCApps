# Integration Extensibility

This document describes the service integration interface contracts defined in the Integration/Interfaces subdirectory. These interfaces enable partners to implement custom e-invoice services, government portals, and clearance systems without modifying core E-Document code.

## Interface overview

The V2 integration architecture defines seven interfaces organized by operation type:

**Document transmission:**
- **IDocumentSender** -- Sends formatted document to external service (required for outbound)
- **IDocumentResponseHandler** -- Retrieves async response after send (optional, triggers async flow)

**Document reception:**
- **IDocumentReceiver** -- Polls service for inbound documents and downloads content (required for inbound)
- **IReceivedDocumentMarker** -- Marks document as fetched on service side (optional, prevents re-download)

**Post-send actions:**
- **ISentDocumentActions** -- Default actions: GetApprovalStatus, GetCancellationStatus
- **IDocumentAction** -- Custom extensible actions defined by enum extensions

**Privacy consent:**
- **IConsentManager** -- Handles OAuth consent flows and privacy notices

All interfaces are registered via Service Integration enum implementations. See app-level extensibility.md sections "Add a new e-invoice service" and "Add custom actions" for detailed implementation examples.

## IDocumentSender

**Purpose:** Send formatted E-Document to external service endpoint.

**Method:** `Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)`

**Context parameters:**
- `SendContext.GetTempBlob()` -- Formatted document content from export step
- `SendContext.Http()` -- HTTP request/response message state
- `SendContext.Status()` -- Target service status (default: Sent)

**Implementation responsibilities:**
1. Read formatted document from SendContext.GetTempBlob()
2. Build HTTP request with service authentication headers
3. Call HttpClient.Send() or equivalent API
4. Set HttpRequestMessage and HttpResponseMessage on SendContext.Http() for automatic logging
5. On success, optionally modify SendContext.Status() (default is Sent)
6. On error, call E-Document Error Helper to log error message

**Async handling:** If sender also implements IDocumentResponseHandler, the document transitions to Pending Response after Send completes. A background job polls GetResponse until success or error. If sender does not implement IDocumentResponseHandler, Send is treated as synchronous and must return final status.

**Batch support:** SendContext may contain multiple E-Document records (filtered recordset). Implementation can choose to process them individually or as a true batch API call. E-Document Service."Use Batch Processing" controls whether Integration Management calls Send once per document or once for all documents.

**Error handling:** Runtime errors inside Send are caught by Integration Management. Call E-Document Error Helper explicitly to log business errors (invalid credentials, service unavailable). HTTP communication is logged automatically if HttpRequestMessage/HttpResponseMessage are set.

## IDocumentResponseHandler

**Purpose:** Poll async service for send response after initial submission returned pending status.

**Method:** `GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean`

**Return value:**
- `true` -- Response is ready, transition to SendContext.Status() (typically Sent or Approved)
- `false` -- Response not ready yet, remain in Pending Response status for next poll

**Implementation pattern:**
1. Query service API using EDocument."Document ID" or custom tracking field
2. If response ready: set SendContext.Status() to final state, return true
3. If still processing: return false (Integration Management keeps Pending Response status)
4. On permanent error: log error via E-Document Error Helper, return false (status becomes Sending Error)

**Polling schedule:** E-Document Background Jobs schedules GetResponse job after each async send. Job runs every 5 minutes by default. Job reschedules itself if any documents remain in Pending Response after processing.

**Timeout:** No built-in timeout. If a document remains in Pending Response indefinitely, user can manually retry via "Resend" action which resets to Exported status.

## IDocumentReceiver

**Purpose:** Poll service for new inbound documents and download content.

**Method 1:** `ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)`

Queries service API for list of available documents. For each document, create a TempBlob with metadata (document ID, date, etc.) and add to DocumentsMetadata list. Integration Management will create an E-Document record for each blob and call DownloadDocument for each.

**Method 2:** `DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)`

Downloads the actual document content (XML, JSON, PDF) for a single E-Document. Read document ID from DocumentMetadata, call service download API, write result to ReceiveContext.GetTempBlob(). Set ReceiveContext.Status() to Imported (default). Optionally set filename via ReceiveContext helper methods.

**Mark-fetched flow:** If receiver also implements IReceivedDocumentMarker, Integration Management calls MarkFetched after successful download. This notifies the service that the document was retrieved, preventing re-download on next poll. If MarkFetched fails, the document is still imported but may be downloaded again next time.

**Scheduling:** E-Document Background Jobs schedules ReceiveDocuments job based on service configuration polling interval (default: hourly).

## IReceivedDocumentMarker

**Purpose:** Notify service that document was successfully downloaded, preventing re-download.

**Method:** `MarkFetched(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var DocumentBlob: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)`

Called automatically after DownloadDocument succeeds. Send HTTP request to service API marking document as retrieved. If call fails, throw error -- Integration Management will not create E-Document record.

**Optional interface:** Services that don't support mark-fetched tracking should not implement this interface. Integration Management checks via interface cast before calling.

## ISentDocumentActions

**Purpose:** Provide default post-send actions for approval and cancellation status checks.

**Method 1:** `GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean`

Query service API to check if sent document was approved by recipient or clearance authority. Return true if action should update status (ActionContext.Status() set to Approved or Rejected). Return false if status is unchanged (still pending approval).

**Method 2:** `GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean`

Query service API to check if cancellation request succeeded. Return true if status should update to Cancelled or Cancel Error. Return false if cancellation still pending.

**User trigger:** These actions are invoked manually via E-Document Card page actions or automatically via workflow steps. Not polled on schedule.

**Integration Action Type enum:** Maps to enum values "Sent Document Approval" and "Sent Document Cancellation". E-Document Action Runner dispatches to ISentDocumentActions methods.

## IDocumentAction

**Purpose:** Define custom service-specific actions (e.g., download receipt, update invoice, request credit note).

**Method:** `InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean`

Generic action dispatcher. Implementation reads action type from context (or uses fixed action), calls service API, updates ActionContext.Status() if needed. Return true if status should update, false otherwise.

**Extensibility:** Extend Integration Action Type enum with custom values and Implementation assignments:

```al
enumextension 50200 "Custom Actions" extends "Integration Action Type"
{
    value(50200; "Download Receipt")
    {
        Implementation = IDocumentAction = "My Receipt Downloader";
    }
}
```

Then implement the assigned codeunit with InvokeAction logic.

## IConsentManager

**Purpose:** Handle OAuth consent flows and privacy notices for authenticated services.

**Method:** `ObtainPrivacyConsent(): Boolean`

Display privacy notice to user and capture consent. Return true if user consents, false if declined. Called once when service is first configured. Consent is stored in E-Document Service setup.

**Default implementation:** Consent Manager Default Impl. displays standard privacy notice and stores approval in user settings. Custom services can override to show service-specific consent text or trigger OAuth flows.

## Context codeunits

**SendContext** -- Carries send operation state:
- `GetTempBlob()` / `SetTempBlob()` -- Document content
- `Http()` -- HTTP request/response state
- `Status()` -- Target service status

**ReceiveContext** -- Carries receive operation state:
- `GetTempBlob()` / `SetTempBlob()` -- Downloaded document content
- `Http()` -- HTTP request/response state
- `Status()` -- Import status (default: Imported)
- `GetName()` / `SetName()` -- Document filename
- `GetFileFormat()` / `SetFileFormat()` -- E-Document file format enum

**ActionContext** -- Carries action execution state:
- `Http()` -- HTTP request/response state
- `Status()` -- Result status and error status

**HttpMessageState** -- Wraps HttpRequestMessage and HttpResponseMessage:
- `GetHttpRequestMessage()` / `SetHttpRequestMessage()`
- `GetHttpResponseMessage()` / `SetHttpResponseMessage()`

Integration Management logs HTTP messages automatically if they are set in context codeunits.

## Implementation checklist

To implement a custom service integration:

1. Create enum extension for Service Integration with Implementation assignments
2. Implement IDocumentSender (outbound) and/or IDocumentReceiver (inbound)
3. Optionally implement IDocumentResponseHandler for async send
4. Optionally implement IReceivedDocumentMarker for mark-fetched
5. Optionally implement ISentDocumentActions for approval/cancellation
6. Optionally implement IConsentManager for custom privacy consent
7. Create service setup table extension with service-specific fields (API key, endpoint URL)
8. Subscribe to OnBeforeOpenServiceIntegrationSetupPage event to open custom setup page
9. Test with E-Document Service setup: assign enum value, configure service, enable workflows

Integration Management handles all interface dispatch, error isolation, status updates, and HTTP logging automatically. Service implementations focus only on API communication logic.
