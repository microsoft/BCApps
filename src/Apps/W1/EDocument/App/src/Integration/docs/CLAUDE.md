# Integration

The service integration layer is the bridge between E-Document Core and external e-invoicing services. It owns the entire lifecycle of sending documents out, receiving documents in, and executing post-send actions like approval and cancellation checks. Nothing in this layer knows about document formats -- it operates on opaque blobs that the format layer has already produced.

## How it works

Every service integration call flows through `EDocIntegrationManagement.Codeunit.al`, which orchestrates the commit-run-log pattern used throughout. The pattern works like this: commit current state, run the interface call inside a dedicated runner codeunit (so runtime errors are caught by `if not Codeunit.Run()`), then log the result and update statuses. The runner codeunits -- `SendRunner`, `GetResponseRunner`, `EDocumentActionRunner`, `ReceiveDocuments`, `DownloadDocument`, `MarkFetched` -- each wrap a single interface call and exist primarily so the framework can trap errors without losing the transaction.

Context objects (`SendContext`, `ReceiveContext`, `ActionContext`) are the connective tissue. They carry an `Http()` accessor for request/response messages and a `Status()` accessor for controlling which service status gets written. When an interface implementor populates the HTTP request and response on the context, the framework automatically writes integration log entries with the full HTTP payload -- no extra work needed by the connector.

Async sending is determined by a type check, not a flag. After calling `IDocumentSender.Send()`, the `SendRunner` checks whether the sender also implements `IDocumentResponseHandler`. If it does, the document enters "Pending Response" status and a background job (`EDocumentGetResponse`) polls `GetResponse()` until it returns true or logs an error. If the sender does not implement the response handler, the send is treated as synchronous and the status resolves immediately.

## Things to know

- Context objects (`SendContext`, `ReceiveContext`, `ActionContext`) all share the same shape: `Http()` for HTTP state and `Status()` for controlling the resulting service status. Populating `Http()` is how you get automatic communication logging.
- The runners use commit-run-log: `Commit()` before the interface call, catch errors via `if not Codeunit.Run()`, then log the error text against the E-Document. This means interface implementations run in their own transaction scope.
- Async vs sync is purely structural: if your `IDocumentSender` implementation also implements `IDocumentResponseHandler`, the framework treats the send as async. There is no configuration flag.
- `IReceivedDocumentMarker` is optional. During receive, the framework checks `IDocumentReceiver is IReceivedDocumentMarker` and only calls `MarkFetched` if the type test passes. If the external service does not need to be told that documents were fetched, skip this interface entirely.
- Receive is a two-phase process: `ReceiveDocuments` returns metadata as a `Temp Blob List` (one blob per document), then `DownloadDocument` is called individually for each entry to fetch the actual content.
- Built-in action types ("Sent Document Approval", "Sent Document Cancellation") delegate to `ISentDocumentActions` via a type check on the sender. Custom actions extend the `Integration Action Type` enum and implement `IDocumentAction` directly.
- The `Service Integration` enum (V2) implements `IDocumentSender`, `IDocumentReceiver`, and `IConsentManager` simultaneously. Connectors extend this single enum to plug into all three contracts.
