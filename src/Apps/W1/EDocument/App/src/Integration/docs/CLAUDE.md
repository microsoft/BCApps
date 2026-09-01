# Integration

The Integration module defines the contracts between the E-Document Core framework and external document exchange services. It owns every interface, context codeunit, and runner that touches an external API -- sending, receiving, polling for async responses, and post-send actions like approval and cancellation. The framework never calls a service directly; it resolves an interface implementation through the extensible `"Service Integration"` enum and delegates through a runner codeunit wrapped in the `Commit(); if not Codeunit.Run()` error-isolation pattern.

## How it works

A service integration is wired by extending the `"Service Integration"` enum (`ServiceIntegration.Enum.al`) with a new value that maps to implementations of `IDocumentSender` and `IDocumentReceiver`. At runtime, `"E-Doc. Integration Management"` reads the service record's `"Service Integration V2"` field, resolves the enum to the matching interface implementation, and delegates through a runner codeunit (`SendRunner`, `"Get Response Runner"`, `"E-Document Action Runner"`, etc.). Each runner is a separate codeunit so it can be invoked with `Codeunit.Run()` -- if it throws, the framework catches the error via `GetLastErrorText()` and logs it without crashing the caller.

Every outbound or inbound HTTP call flows through a **context codeunit** -- `SendContext`, `ReceiveContext`, or `ActionContext`. These contexts bundle an `"Http Message State"` (request + response pair), a `"Temp Blob"` for document content, and an `"Integration Action Status"` for the resulting service status. After the interface call returns, the framework reads `context.Http()` and writes the request/response to the integration log automatically. This is the key difference from the deprecated V1 interface, where the caller had to pass raw `HttpRequestMessage`/`HttpResponseMessage` parameters.

Async sending is detected automatically: after `SendRunner` calls `IDocumentSender.Send()`, it checks whether the implementation also implements `IDocumentResponseHandler` (via `IDocumentSender is IDocumentResponseHandler`). If so, `IsAsync` is set to true, the service status becomes `"Pending Response"`, and `"E-Document Background Jobs"` schedules a job queue entry running `"E-Document Get Response"` every 5 minutes. That job iterates all pending-response documents, calls `IDocumentResponseHandler.GetResponse()`, and either advances to `Sent` or stays at `"Pending Response"` for the next poll.

## Things to know

- The V1 interface `"E-Document Integration"` (7 methods, one enum) is fully deprecated at `CLEAN26`. All new integrations must use the V2 interfaces in `Interfaces/`. The `#if not CLEAN26` blocks in runners and management codeunit handle dual-mode dispatch during the transition.

- `"Service Integration"` enum implements `IDocumentSender`, `IDocumentReceiver`, and `IConsentManager`. A service only needs to implement the interfaces it uses -- the `"No Integration"` default value maps to the null object `"E-Document No Integration"`.

- Actions are a separate extensibility axis. The `"Integration Action Type"` enum implements `IDocumentAction`; built-in values are `"Sent Document Approval"` and `"Sent Document Cancellation"`. The approval action (`SentDocumentApproval.Codeunit.al`) casts the sender to `ISentDocumentActions` and calls `GetApprovalStatus()`, setting default statuses of `Approved` / `"Approval Error"`.

- Batch sending (V2) reuses the same `IDocumentSender.Send()` -- the `EDocument` record parameter contains multiple records via filters. V1 had a separate `SendBatch()` method.

- The receive flow is two-phase: `IDocumentReceiver.ReceiveDocuments()` returns a `"Temp Blob List"` of metadata (one blob per document), then `DownloadDocument()` is called per-document to fetch the actual content. If the receiver also implements `IReceivedDocumentMarker`, the framework calls `MarkFetched()` to acknowledge the download on the external service before committing the import.

- Every `Run*` method in `"E-Doc. Integration Management"` re-reads the `EDocument` and `EDocumentService` records after the interface call (`EDocument.Get(...)`). This is intentional -- the interface implementation may have modified fields during execution.

- `IConsentManager` gates service activation behind a privacy consent dialog. The default implementation delegates to `"Consent Manager Default Impl."`, but integrations can override to show a custom notice.
