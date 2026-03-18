# Integration interfaces

The contracts that connector apps implement to integrate with the E-Document framework. These seven interfaces define the full surface area for sending, receiving, acknowledging, polling async responses, checking approval/cancellation, executing custom actions, and managing privacy consent.

## How it works

A connector app extends the `Service Integration` enum with a new value and provides implementations for the interfaces it supports. At minimum, a connector must implement `IDocumentSender` or `IDocumentReceiver` (or both). The framework discovers capabilities at runtime using `is` checks -- for example, `SendRunner` checks `if IDocumentSender is IDocumentResponseHandler` to determine whether sending is async.

The interfaces are organized by operation:

- **Sending**: `IDocumentSender` -- the core send method. A single `Send` procedure handles both individual and batch sends (batch is indicated by a filtered EDocument recordset).
- **Async response**: `IDocumentResponseHandler` -- polled by a background job when the sender supports async. Returns `true` when the external service has accepted the document, `false` if still pending.
- **Receiving**: `IDocumentReceiver` -- two-phase: `ReceiveDocuments` gets a list of available document metadata, `DownloadDocument` fetches the actual content for each.
- **Acknowledge receipt**: `IReceivedDocumentMarker` -- optional. Tells the external API that a document has been fetched so it is not served again.
- **Post-send actions**: `ISentDocumentActions` -- approval and cancellation status checks for sent documents.
- **Custom actions**: `IDocumentAction` -- extensible action dispatch via the `Integration Action Type` enum.
- **Consent**: `IConsentManager` -- GDPR privacy consent. Called once when a service integration is first configured.

## Things to know

- `IDocumentSender` is the only send interface. Batch vs. single is not a separate method in V2 -- the framework sets filters on the EDocument record. Connectors check `EDocument.Count()` if they need to branch.

- `IDocumentResponseHandler` is discovered via `is` check, not via a separate enum registration. If your codeunit that implements `IDocumentSender` also implements `IDocumentResponseHandler`, sending is automatically treated as async.

- `IReceivedDocumentMarker` is also discovered via `is` check on the `IDocumentReceiver` implementor. This is the "tell the API we got it" step -- if your connector does not implement it, the framework skips the acknowledgment.

- `IDocumentAction.InvokeAction` returns a Boolean indicating whether the framework should update the E-Document's service status. Returning `false` is valid -- some actions are polling checks that should not change status if the external state has not changed.

- All interfaces receive context codeunits (`SendContext`, `ReceiveContext`, `ActionContext`) rather than raw HTTP objects. The context encapsulates temp blobs, HTTP request/response, and status. Connectors must use `Context.Http().GetHttpRequestMessage()` and `Context.Http().GetHttpResponseMessage()` -- the framework auto-logs whatever is in these objects after the call.

- `ISentDocumentActions` is cast from `IDocumentSender` using `as`. The concrete pattern in `SentDocumentApproval.Codeunit.al` is: get the `IDocumentSender` from the enum, check `if IDocumentSender is ISentDocumentActions`, then cast and call.
