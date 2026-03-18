# Integration extensibility

This guide covers the six main extension points in the integration layer, grouped by what you are trying to accomplish.

## 1. Build a service connector

This is the minimum viable integration. You need to extend the `Service Integration` enum and implement `IDocumentSender` (and optionally `IDocumentReceiver`).

The `Service Integration` enum in `ServiceIntegration.Enum.al` implements three interfaces simultaneously: `IDocumentSender`, `IDocumentReceiver`, and `IConsentManager`. When you add a new enum value, the compiler requires implementations for all three. Use `"E-Document No Integration"` as the `IDocumentReceiver` implementation if your connector is send-only.

`IDocumentSender` has a single method:

- `Send(var EDocument, var EDocumentService, SendContext)` -- read the document blob from `SendContext.GetTempBlob()`, transmit it, and populate `SendContext.Http()` with the request/response for automatic logging. Set `SendContext.Status().SetStatus()` if you need a status other than the default "Sent".

For receiving, implement `IDocumentReceiver` with two methods:

- `ReceiveDocuments(var EDocumentService, DocumentsMetadata, ReceiveContext)` -- call the external API to discover available documents and add one `Temp Blob` per document to the `DocumentsMetadata` list. Each blob carries whatever metadata your connector needs to identify the document later (e.g., a JSON object with a document ID).
- `DownloadDocument(var EDocument, var EDocumentService, DocumentMetadata, ReceiveContext)` -- given the metadata blob from the previous step, download the actual document content and store it in `ReceiveContext.GetTempBlob()`. Set `ReceiveContext.SetName()` and `ReceiveContext.SetFileFormat()` to control how the file is stored.

Example enum extension:

```al
enumextension 50100 "My Service Integration" extends "Service Integration"
{
    value(50100; "My Service")
    {
        Implementation =
            IDocumentSender = "My Service Impl.",
            IDocumentReceiver = "My Service Impl.",
            IConsentManager = "My Service Impl.";
    }
}
```

## 2. Handle async responses

If the external service does not confirm delivery synchronously, your `IDocumentSender` implementation should also implement `IDocumentResponseHandler` (in `Interfaces/IDocumentResponseHandler.Interface.al`). The framework detects this through a runtime type check -- `IDocumentSender is IDocumentResponseHandler` -- and automatically sets the service status to "Pending Response" instead of "Sent".

`IDocumentResponseHandler` has one method:

- `GetResponse(var EDocument, var EDocumentService, SendContext): Boolean` -- return `true` when the service confirms the document was received, `false` if still pending. If you log an error message against the E-Document, the framework treats it as a terminal failure and stops polling.

A background job (`EDocumentGetResponse`) polls all documents in "Pending Response" status. It calls `GetResponse` for each, updates the status, and reschedules itself if any documents remain pending.

## 3. Support post-send actions (approval and cancellation)

After a document is sent, users may need to check approval status or request cancellation. Implement `ISentDocumentActions` on your sender codeunit (the same codeunit that implements `IDocumentSender`).

`ISentDocumentActions` in `Interfaces/ISentDocumentActions.Interface.al` has two methods:

- `GetApprovalStatus(var EDocument, var EDocumentService, ActionContext): Boolean` -- check with the service whether the document is approved. Return `true` to update the E-Document status (defaults to "Approved"), `false` to leave it unchanged. Use `ActionContext.Status().SetStatus()` to override the resulting status.
- `GetCancellationStatus(var EDocument, var EDocumentService, ActionContext): Boolean` -- same pattern for cancellation. Default success status is "Canceled".

The framework discovers this through a type check in `SentDocumentApproval.Codeunit.al`: it resolves the sender from the service's `Service Integration V2` enum, checks `IDocumentSender is ISentDocumentActions`, and delegates if the check passes. No registration step is needed -- just implement the interface on your sender.

## 4. Add custom actions

For actions beyond the built-in approval and cancellation, implement `IDocumentAction` and extend the `Integration Action Type` enum.

`IDocumentAction` in `Interfaces/IDocumentAction.Interface.al` has one method:

- `InvokeAction(var EDocument, var EDocumentService, ActionContext): Boolean` -- perform the action and return `true` if the E-Document status should be updated. Use `ActionContext.Status().SetStatus()` to control the success status and `ActionContext.Status().SetErrorStatus()` to control the error status.

Example enum extension:

```al
enumextension 50101 "My Action Types" extends "Integration Action Type"
{
    value(50100; "My Custom Action")
    {
        Implementation = IDocumentAction = "My Custom Action Impl.";
    }
}
```

Call your custom action through `EDocIntegrationManagement.InvokeAction()` with the corresponding enum value.

## 5. Mark received documents as fetched

Some services require you to acknowledge that documents were downloaded. Implement `IReceivedDocumentMarker` on the same codeunit that implements `IDocumentReceiver`.

`IReceivedDocumentMarker` in `Interfaces/IReceivedDocumentMarker.Interface.al` has one method:

- `MarkFetched(var EDocument, var EDocumentService, var DocumentBlob, ReceiveContext)` -- call the service API to acknowledge receipt. If this fails (throws an error), the document is not created in Business Central.

The framework checks `IDocumentReceiver is IReceivedDocumentMarker` after downloading each document. If the type test passes, `MarkFetched` runs before the document is committed to the log. This is intentional -- if you cannot confirm receipt with the service, the document should not appear as imported.

## 6. Manage consent

Every `Service Integration` enum value must implement `IConsentManager`. The framework calls `ObtainPrivacyConsent()` when a user first selects your integration on the E-Document Service card.

`IConsentManager` in `Interfaces/IConsentManager.Interface.al` has one method:

- `ObtainPrivacyConsent(): Boolean` -- display a privacy consent dialog and return whether the user agreed. If you have no special consent requirements, delegate to `"Consent Manager Default Impl."` which ships with the framework.

The default implementation is already wired as `DefaultImplementation` on the `Service Integration` enum, so if you do not specify an `IConsentManager` implementation on your enum value, the default kicks in automatically.
