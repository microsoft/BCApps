# Integration extensibility

This document describes how to extend the E-Document integration framework by implementing its interfaces. Each section covers a specific capability, the interface that enables it, and the method signatures partners must implement.

All interfaces live in `src/Integration/Interfaces/`. To activate an integration, add a value to the `Service Integration` enum (6151) and declare which interfaces it implements.

## Send documents to an external service

**Interface**: `IDocumentSender`

```al
procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext);
```

The framework calls `Send` after the document has been exported to a blob. The implementation retrieves the content from `SendContext.GetTempBlob()`, builds an HTTP request via `SendContext.Http().GetHttpRequestMessage()`, sends it, and stores the response via `SendContext.Http().SetHttpResponseMessage()`. The framework logs whatever is on the HTTP context automatically.

For **synchronous** sends, `Send` is all that is needed. The framework will set the service status to `Sent` (or whatever the implementation sets via `SendContext.Status().SetStatus()`).

For **asynchronous** sends, the implementation codeunit must also implement `IDocumentResponseHandler`. The framework detects this at runtime (`IDocumentSender is IDocumentResponseHandler`) and marks the document as `Pending Response` instead of `Sent`. There is no explicit async flag -- implementing the response handler interface is the signal.

When batch sending is enabled on the service, the `EDocument` record parameter will contain multiple records (filtered). The implementation should process all records in the set.

## Receive documents from an external service

**Interface**: `IDocumentReceiver`

```al
procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext);

procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext);
```

Receiving is two-phase:

1. **ReceiveDocuments** -- Query the external service for available documents. For each document found, create a `Temp Blob` containing metadata (e.g., a document ID as text or a JSON object) and add it to the `DocumentsMetadata` list. The count of blobs determines how many documents will be downloaded.

2. **DownloadDocument** -- Called once per blob in the metadata list. The implementation reads the metadata from `DocumentMetadata` (e.g., extracts a document ID), fetches the actual document content from the external service, and writes it to `ReceiveContext.GetTempBlob()`. Set the file name via `ReceiveContext.SetName()` and the format via `ReceiveContext.SetFileFormat()`.

If the download fails or the TempBlob is empty after the call, the framework skips that document and deletes the E-Document record.

## Mark received documents as fetched

**Interface**: `IReceivedDocumentMarker`

```al
procedure MarkFetched(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var DocumentBlob: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext);
```

This is an **optional** interface. If the `IDocumentReceiver` implementation also implements `IReceivedDocumentMarker`, the framework calls `MarkFetched` after each successful document download. This allows the integration to notify the external service that the document has been consumed (preventing re-download on the next poll).

The framework detects this via `IDocumentReceiver is IReceivedDocumentMarker` and uses an `as` cast to invoke it. If the mark-fetched call fails, the error is logged against the E-Document and the document is not imported.

## Handle async responses

**Interface**: `IDocumentResponseHandler`

```al
procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean;
```

When a sender also implements this interface, the framework schedules a Job Queue entry (`E-Document Get Response`, codeunit 6144) that periodically polls for responses. For each E-Document with `Pending Response` service status, it calls `GetResponse`.

Return values:
- `true` -- The service confirmed receipt. The framework sets the service status to the value from `SendContext.Status().GetStatus()` (defaults to `Sent`).
- `false` -- The response is not yet available. The document stays at `Pending Response` and will be polled again on the next job run.

If a runtime error occurs or an error message is logged during the call, the service status is set to `Sending Error` and no further polling occurs for that document.

## Manage sent document lifecycle

**Interface**: `ISentDocumentActions`

```al
procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean;

procedure GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean;
```

These are dispatched through the action framework. The built-in `Sent Document Approval` action codeunit pre-sets `ActionContext.Status()` to `Approved` (success) and `Approval Error` (failure), then calls `GetApprovalStatus`. The `Sent Document Cancellation` action pre-sets `Canceled` and `Cancel Error`, then calls `GetCancellationStatus`.

Return `true` to update the E-Document service status to the pre-set value. Return `false` to leave the status unchanged. Override the default status before returning by calling `ActionContext.Status().SetStatus()` with a different value.

The framework detects `ISentDocumentActions` support via `IDocumentSender is ISentDocumentActions` -- the check is done by casting from the sender interface.

## Add custom document actions

**Interface**: `IDocumentAction`

```al
procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean;
```

The `Integration Action Type` enum (6170) is extensible. To add a custom action, add a new enum value with `Implementation = IDocumentAction = "Your Codeunit"`. Call it via `E-Doc. Integration Management.InvokeAction(EDocument, EDocumentService, YourActionType, ActionContext)`.

Return `true` to tell the framework to update the service status to whatever is set on `ActionContext.Status().GetStatus()`. Return `false` to skip the status update. Regardless of the return value, communication logs (from `ActionContext.Http()`) are always saved.

Set the error fallback status via `ActionContext.Status().SetErrorStatus()` -- the framework uses this if the action fails with an error.

## Control export eligibility

**Interface**: `IExportEligibilityEvaluator` (in `src/Processing/Interfaces/`)

```al
procedure ShouldExport(EDocumentService: Record "E-Document Service"; SourceDocumentHeader: RecordRef; DocumentType: Enum "E-Document Type"): Boolean;
```

This interface is not in the Integration folder but is relevant to integrations. It determines whether a given BC source document should be exported as an E-Document for a particular service. The `ExportEligibilityEvaluator` enum (extensible) implements this interface. The default implementation allows all documents; custom implementations can filter by document type, customer/vendor attributes, or other criteria.

## Manage consent

**Interface**: `IConsentManager`

```al
procedure ObtainPrivacyConsent(): Boolean;
```

Required on the `Service Integration` enum. Called before the service is activated to obtain customer privacy consent. The default implementation (`Consent Manager Default Impl.`) uses the standard BC `Customer Consent Mgt.` framework. Return `true` if consent was granted, `false` to block activation.

Custom implementations can display service-specific consent messages or integrate with external consent management systems.

## Summary of interface detection

| Interface | Required on enum | Detection method |
|---|---|---|
| `IDocumentSender` | Yes | Direct dispatch from enum |
| `IDocumentReceiver` | Yes | Direct dispatch from enum |
| `IConsentManager` | Yes | Direct dispatch from enum (has default impl) |
| `IDocumentResponseHandler` | No | `IDocumentSender is IDocumentResponseHandler` |
| `ISentDocumentActions` | No | `IDocumentSender is ISentDocumentActions` |
| `IReceivedDocumentMarker` | No | `IDocumentReceiver is IReceivedDocumentMarker` |
| `IDocumentAction` | No | Dispatch via `Integration Action Type` enum |
| `IExportEligibilityEvaluator` | No | Dispatch via `ExportEligibilityEvaluator` enum |
