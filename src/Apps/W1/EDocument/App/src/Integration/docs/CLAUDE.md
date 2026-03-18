# Integration

Integration defines how e-documents are transmitted to and received from external services. It provides the V2 interface contracts (send, receive, actions), context objects that encapsulate HTTP and status state, and runner codeunits that orchestrate the calls. This module deliberately contains no business logic about document content -- it only cares about transport and lifecycle.

## How it works

The module is organized around three operations: **Send**, **Receive**, and **Action**. Each has an interface, a context object, and a runner codeunit.

For sending, `SendRunner` dispatches to the service's `IDocumentSender.Send()` implementation, passing a `SendContext` that carries the document blob, HTTP message state, and an integration action status. After the call, the runner checks if the sender also implements `IDocumentResponseHandler` -- if so, the send is async and a background job polls `GetResponse()` via `GetResponseRunner` until the service confirms receipt.

For receiving, `ReceiveDocuments` calls `IDocumentReceiver.ReceiveDocuments()` which populates a `Temp Blob List` with document metadata. Then `DownloadDocument` is called per document to fetch the actual content into the `ReceiveContext`. If the receiver also implements `IReceivedDocumentMarker`, the framework calls `MarkFetched` to tell the external service the document has been downloaded, preventing duplicates.

Actions (`EDocumentActionRunner`) handle post-send lifecycle events like approval checks and cancellation requests. The `ISentDocumentActions` interface provides `GetApprovalStatus` and `GetCancellationStatus`. For custom actions, `IDocumentAction.InvokeAction` is the generic entry point. All action calls receive an `ActionContext` with HTTP state and a status object that the implementation sets to control whether the e-document status should be updated.

## Things to know

- Async sending is determined by interface implementation, not configuration -- if your `IDocumentSender` implementation also implements `IDocumentResponseHandler`, the framework treats the send as async automatically.
- Context objects (`SendContext`, `ReceiveContext`, `ActionContext`) all expose `.Http()` for HTTP request/response state and `.Status()` for the integration action status. If you populate the HTTP objects, request/response content is automatically logged to communication logs.
- The V1 interface (`E-Document Integration`, guarded by `#if not CLEAN26`) combined send, receive, batch, response, approval, and cancellation into a single interface with raw `HttpRequestMessage`/`HttpResponseMessage` parameters. V2 splits this into focused interfaces with context objects. V1 is deprecated in 26.0 and will be removed at CLEAN26.
- `SendRunner` and `GetResponseRunner` still contain V1 fallback paths that extract HTTP messages from legacy interface calls and inject them back into the context objects for unified logging.
- `IConsentManager` is called before service operations to obtain privacy consent. The implementation decides how to prompt the user and stores the consent state.
- Batch sending in V2 is handled by setting filters on the EDocument record passed to `IDocumentSender.Send()` -- the record contains multiple documents. This replaces the V1 `SendBatch` method.
