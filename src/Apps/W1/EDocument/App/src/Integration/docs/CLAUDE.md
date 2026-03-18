# Integration

The orchestration layer between the E-Document processing pipeline and external services. `EDocIntegrationManagement.Codeunit.al` is the single entry point for all send, receive, and action operations. This directory does not implement any specific connector -- it provides the framework that connector apps plug into via the interfaces defined in `Interfaces/`.

## How it works

`E-Doc. Integration Management` (codeunit 6134) orchestrates three major flows: Send, Receive, and Actions. For sending, it retrieves the exported blob from the E-Document Log, populates a `SendContext`, invokes the connector's `IDocumentSender.Send` through a `Send Runner` codeunit (using the `if codeunit.Run()` error-isolation pattern), then logs the HTTP communication and updates statuses. Batch sending follows the same pattern but iterates over filtered E-Document records.

For receiving, the flow is two-phase: first `ReceiveDocuments` gets a list of document metadata blobs from the connector, then `ReceiveSingleDocument` downloads each document individually. If the connector implements `IReceivedDocumentMarker`, the framework also calls `MarkFetched` to acknowledge receipt to the external API -- this is critical for services that won't re-serve already-fetched documents.

The action flow routes through `InvokeAction`, which delegates to `E-Document Action Runner`. The `Integration Action Type` enum maps action types to `IDocumentAction` implementations. Two built-in actions exist: "Sent Document Approval" and "Sent Document Cancellation", which in turn delegate to the connector's `ISentDocumentActions` interface.

The `Service Integration` enum (`ServiceIntegration.Enum.al`) is the V2 extensible enum that connector apps extend. It implements `IDocumentSender`, `IDocumentReceiver`, and `IConsentManager`. The obsolete `E-Document Integration` enum and interface (`EDocumentIntegration.Enum.al`, `EDocumentIntegration.Interface.al`) are the V1 equivalents being removed in CLEAN26.

## Things to know

- Every external call uses the "if codeunit.Run()" pattern -- a `Commit()` before the runner codeunit call, then `GetLastErrorText()` if the run fails. This isolates connector errors from the framework transaction.

- After every interface call, the framework re-reads both EDocument and EDocumentService from the database. Connectors are allowed to modify these records during their execution.

- `E-Document No Integration` (codeunit 6128) is the null-object implementation. It does nothing for all operations and returns `true` for consent. It is wired to the `"No Integration"` enum value.

- The `IConsentManager` interface is invoked when a user first sets a Service Integration value on an `E-Document Service` record. The default implementation shows a GDPR privacy consent dialog.

- The legacy V1 `ReceiveDocument` path (behind `#if not CLEAN26`) handles batch reception differently -- it uses `GetDocumentCountInBatch` to determine how many documents are in a single blob. The V2 path uses `Temp Blob List` where count is implicit.

- `DetermineServiceStatus` in the send flow has three outcomes: `Sending Error` if the connector errored, `Pending Response` if async, or whatever status the connector set via `SendContext.Status()` if sync.
