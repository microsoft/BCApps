# Integration extensibility

The Integration module exposes 7 interfaces (in `Interfaces/`) that define how connector extensions communicate with external e-document services. All are in the `Microsoft.eServices.EDocument.Integration.Interfaces` namespace. Implementations are registered via the `Service Integration` enum on the E-Document Service record.

## How to build a send connector

Implement **IDocumentSender** to send e-documents to an external service. The framework calls `Send` with the E-Document, service configuration, and a `SendContext` that carries the exported blob and HTTP state.

```al
interface IDocumentSender
{
    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext);
}
```

The `SendContext` provides:

- `GetTempBlob()` / `SetTempBlob()` -- the exported document content
- `Http()` -- returns `HttpMessageState` where you set your `HttpRequestMessage` and `HttpResponseMessage`. If populated, the framework automatically logs them to communication logs.
- `Status()` -- returns `IntegrationActionStatus` for setting the resulting service status

For batch sending, the framework sets filters on the `EDocument` record so it contains multiple records. Your implementation iterates them.

For **synchronous** sending, just implement `IDocumentSender`. The framework sets the status to Sent after a successful call.

For **asynchronous** sending, implement `IDocumentSender` **and** `IDocumentResponseHandler` on the same codeunit. The framework detects this via an `is` check (`IDocumentSender is IDocumentResponseHandler`) and automatically queues a background job to poll for the response.

## How to handle async responses

Implement **IDocumentResponseHandler** on the same codeunit as your `IDocumentSender`. The framework calls `GetResponse` on a recurring schedule until it returns `true` or an error is logged.

```al
interface IDocumentResponseHandler
{
    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean;
}
```

Return `true` when the service confirms the document was received -- the status moves to Sent. Return `false` when the service hasn't finished processing -- the status stays at Pending Response and the job retries. If a runtime error occurs or you log an error via the error helper, the status moves to Sending Error and polling stops.

## How to build a receive connector

Implement **IDocumentReceiver** to fetch documents from an external service. Receiving is a two-phase process:

```al
interface IDocumentReceiver
{
    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext);
    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext);
}
```

**Phase 1 -- `ReceiveDocuments`**: Query the service for available documents and add one `Temp Blob` per document to the `DocumentsMetadata` list. Each blob typically contains a document ID or metadata JSON. The count of blobs determines how many E-Documents will be created.

**Phase 2 -- `DownloadDocument`**: Called once per document. Read the metadata blob to get the document ID, then fetch the actual content (XML, PDF, etc.) and write it into `ReceiveContext.GetTempBlob()`. Set the file format via `ReceiveContext.SetFileFormat()` and the name via `ReceiveContext.SetName()`.

The `ReceiveContext` provides the same `Http()` and `Status()` accessors as `SendContext`, plus file format and name setters.

Optionally implement **IReceivedDocumentMarker** to tell the service a document has been successfully fetched (prevents duplicate downloads):

```al
interface IReceivedDocumentMarker
{
    procedure MarkFetched(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var DocumentBlob: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext);
}
```

This is called after the document is successfully created in BC. If `MarkFetched` errors, the document creation is rolled back.

## How to add custom actions

The action framework handles post-send lifecycle events. There are two levels:

**ISentDocumentActions** -- provides the two built-in action types: approval and cancellation. Implement this for services that support checking whether a sent document was approved or requesting cancellation.

```al
interface ISentDocumentActions
{
    procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean;
    procedure GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean;
}
```

Both return `true` if the action should update the E-Document service status, `false` otherwise. The built-in implementations (`SentDocumentApproval`, `SentDocumentCancellation`) delegate to this interface via the `Integration Action Type` enum.

**IDocumentAction** -- the generic action interface for custom action types beyond approval/cancellation. Each action type is registered in the `Integration Action Type` enum and resolved to an `IDocumentAction` implementation.

```al
interface IDocumentAction
{
    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean;
}
```

The `ActionContext` provides `Http()` for HTTP state and `Status()` where your implementation sets the target service status via `SetStatus()`. The `EDocumentActionRunner` calls `InvokeAction` and uses the boolean return to decide whether to persist the status change.

## How to manage consent

Implement **IConsentManager** to customize the privacy consent flow shown before service operations.

```al
interface IConsentManager
{
    procedure ObtainPrivacyConsent(): Boolean;
}
```

Return `true` if the user granted consent, `false` to block the operation. The default implementation uses the standard BC `Customer Consent Mgt.` codeunit, but you can replace it with a custom consent message or external consent flow.
