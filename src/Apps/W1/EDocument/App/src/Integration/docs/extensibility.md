# Extensibility

## Overview

The Integration module exposes two independent extension axes: the **service integration enum** (for send/receive implementations) and the **action type enum** (for post-send operations). Both are extensible AL enums that bind interface implementations at runtime. A third-party app extends the enum, provides the implementation codeunit, and the framework calls it automatically when the service is configured.

All V2 interfaces receive a context codeunit rather than raw HTTP types. This means the framework handles HTTP logging, status tracking, and error isolation -- the implementation just needs to populate the context's `Http()` and `TempBlob`.

## Send documents to a new service

Implement `IDocumentSender` (in `Interfaces/IDocumentSender.Interface.al`). This is the only required interface for outbound documents.

```al
codeunit 50100 "My Service Sender" implements IDocumentSender
{
    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        Request: HttpRequestMessage;
        Client: HttpClient;
    begin
        Request := SendContext.Http().GetHttpRequestMessage();
        // Build and send request using SendContext.GetTempBlob() for content
        Client.Send(Request, SendContext.Http().GetHttpResponseMessage());
    end;
}
```

Register by extending the `"Service Integration"` enum (`ServiceIntegration.Enum.al`):

```al
enumextension 50100 "My Integration" extends "Service Integration"
{
    value(50100; "My Service")
    {
        Implementation = IDocumentSender = "My Service Sender",
                         IDocumentReceiver = "E-Document No Integration";
    }
}
```

When batch mode is enabled on the service, the framework passes an `EDocument` record with multiple entries (set by filters). The `Send()` method receives all of them at once.

## Support async sending

Implement `IDocumentResponseHandler` (in `Interfaces/IDocumentResponseHandler.Interface.al`) on the **same codeunit** that implements `IDocumentSender`. The framework detects this at runtime via `IDocumentSender is IDocumentResponseHandler` -- no additional registration needed.

```al
codeunit 50100 "My Service Sender" implements IDocumentSender, IDocumentResponseHandler
{
    // ... Send() as above ...

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean
    begin
        // Return true when the external service confirms receipt; false to keep polling.
        // Set SendContext.Status().SetStatus() to control the final service status.
    end;
}
```

A background job (`"E-Document Get Response"`) polls every 5 minutes. Returning `true` advances to the status set on `SendContext.Status()`; returning `false` leaves the document at `"Pending Response"`. A runtime error or logged error message sets `"Sending Error"` and stops polling.

## Receive documents from a service

Implement `IDocumentReceiver` (in `Interfaces/IDocumentReceiver.Interface.al`). The receive flow is two-phase:

1. `ReceiveDocuments()` -- query the API for available documents; add one `"Temp Blob"` per document to the `DocumentsMetadata` list (contents are opaque metadata, not the document itself).
2. `DownloadDocument()` -- called once per metadata blob; fetch the actual document content and store it in `ReceiveContext.GetTempBlob()`. Set filename via `ReceiveContext.SetName()` and format via `ReceiveContext.SetFileFormat()`.

This two-phase design lets the framework create E-Document records between the calls, so `DownloadDocument()` receives a fully initialized `EDocument` record.

## Mark received documents as fetched

Optionally implement `IReceivedDocumentMarker` (in `Interfaces/IReceivedDocumentMarker.Interface.al`) on the same codeunit as `IDocumentReceiver`. The framework checks `IDocumentReceiver is IReceivedDocumentMarker` after downloading each document. If present, it calls `MarkFetched()` to acknowledge the download on the external service. If `MarkFetched()` fails, the document is not imported.

## Check approval and cancellation status

Implement `ISentDocumentActions` (in `Interfaces/ISentDocumentActions.Interface.al`) on the same codeunit as `IDocumentSender`. The framework casts to this interface when the `"Sent Document Approval"` or `"Sent Document Cancellation"` action runs.

- `GetApprovalStatus()` -- return `true` to update the document to `Approved`; `false` to leave it unchanged.
- `GetCancellationStatus()` -- return `true` to update to `Canceled`; `false` to leave it unchanged.

Use `ActionContext.Status().SetStatus()` to override the default target status if needed.

## Add custom post-send actions

Extend the `"Integration Action Type"` enum (`IntegrationActionType.Enum.al`) and implement `IDocumentAction` (in `Interfaces/IDocumentAction.Interface.al`):

```al
enumextension 50100 "My Actions" extends "Integration Action Type"
{
    value(50100; "My Custom Action")
    {
        Implementation = IDocumentAction = "My Custom Action Impl";
    }
}
```

The `InvokeAction()` method returns `true` if the framework should update the E-Document service status to whatever is set on `ActionContext.Status()`, or `false` to leave the status unchanged.

## Gate service activation behind privacy consent

Implement `IConsentManager` (in `Interfaces/IConsentManager.Interface.al`) alongside the service integration enum. The default implementation delegates to `"Consent Manager Default Impl."`, which shows BC's standard privacy notice. Override to show a custom consent dialog or enforce region-specific requirements.

## Filter which documents get exported

This interface lives in `Processing/Interfaces/`, not here, but is relevant to integration developers. Extend the `"Export Eligibility Evaluator"` enum and implement `IExportEligibilityEvaluator` to control which source documents are eligible for export through a given service. The default implementation (`DefaultExportEligibility.Codeunit.al`) allows all documents.

## V1 to V2 migration

The V1 interface `"E-Document Integration"` (8 methods including `GetIntegrationSetup`) is deprecated at version 26.0. Key differences:

| V1 | V2 |
|---|---|
| Single monolithic interface (6+ methods) | Granular interfaces -- implement only what you need |
| Raw `HttpRequestMessage` / `HttpResponseMessage` parameters | Context codeunits (`SendContext`, `ReceiveContext`, `ActionContext`) |
| Separate `Send()` and `SendBatch()` methods | Single `Send()` -- batch mode uses record filters |
| `GetDocumentCountInBatch()` for receive | `"Temp Blob List"` count determines document count |
| `GetIntegrationSetup()` for setup page | Replaced by `OnBeforeOpenServiceIntegrationSetupPage` event |
| `"E-Document Integration"` enum | `"Service Integration"` enum (field `"Service Integration V2"`) |

To migrate: move your implementation from `"E-Document Integration"` to the new interfaces, extend `"Service Integration"` instead, and remove the V1 enum extension. The `#if not CLEAN26` blocks in the framework handle dual-mode dispatch during the transition period.
