# Send

The outbound sending infrastructure. This directory contains the context codeunit that connectors interact with, the runner codeunits that isolate connector execution, and the background job machinery for async response polling and recurrent batch sends.

## How it works

The send flow starts in `E-Doc. Integration Management.Send`, which populates a `SendContext` with the exported document blob and default status (Sent), then delegates to `Send Runner`. The runner resolves the `IDocumentSender` from the service's `Service Integration V2` enum and calls `Send`. After the call returns, the runner checks `if IDocumentSender is IDocumentResponseHandler` to determine if the send was async -- there is no explicit `IsAsync` parameter in V2.

`SendContext` (`SendContext.Codeunit.al`) is the public-facing context object. It encapsulates three things: the document blob (`GetTempBlob`/`SetTempBlob`), HTTP state (`Http()` returns an `HttpMessageState` codeunit for request/response), and status (`Status()` returns an `IntegrationActionStatus` codeunit). Connectors read the blob, populate the HTTP objects, and optionally override the default status.

For async sends, `E-Document Get Response` (`EDocumentGetResponse.Codeunit.al`) runs as a job queue entry. It finds all E-Document Service Status records in "Pending Response" state and calls `Get Response Runner` for each. The runner resolves the `IDocumentResponseHandler` interface and calls `GetResponse`. If the result is `true`, the service status advances to whatever the connector set via `SendContext.Status()` (default: Sent). If `false`, it stays at "Pending Response" and the job reschedules itself.

`E-Doc. Recurrent Batch Send` (`EDocRecurrentBatchSend.Codeunit.al`) handles the scheduled batch sending flow. It finds all E-Documents in "Pending Batch" status for a given service, groups them by document type, exports each group, then calls `SendBatch` on the integration management layer.

## Things to know

- `Send Runner` uses the "if codeunit.Run()" pattern -- it is executed via `SendRunner.Run()`, and failures are caught by the caller. A `Commit()` happens before the run. This means connector errors do not roll back framework state.

- The V1 path (behind `#if not CLEAN26`) still exists in `Send Runner`. It routes through the obsolete `E-Document Integration` interface and passes raw `HttpRequestMessage`/`HttpResponseMessage` instead of `SendContext`. After V1 calls, the runner retroactively populates `SendContext.Http()` so the caller sees a uniform interface.

- `GetResponseRunner` also discovers async capability via `is` check: `if IDocumentSender is IDocumentResponseHandler`. If the connector's sender does not implement the response handler, `GetResponse` silently does nothing.

- The response polling job re-schedules itself if any documents remain in "Pending Response" state. There is no exponential backoff -- it relies on the job queue's configured interval.

- Batch send groups documents by `Document Type` before exporting and sending. Different document types in the same batch period produce separate API calls.
