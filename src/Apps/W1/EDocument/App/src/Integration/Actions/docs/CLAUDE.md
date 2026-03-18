# Actions

The extensible action framework for post-send operations on e-documents. Actions are operations that happen after a document has been sent -- checking approval status, requesting cancellation, or performing custom connector-specific operations. The framework uses the `Integration Action Type` enum as a dispatch table, with each enum value mapping to an `IDocumentAction` implementation.

## How it works

`E-Doc. Integration Management.InvokeAction` is the entry point. It receives an `ActionContext` and an `Integration Action Type`, then delegates to `E-Document Action Runner`. The runner resolves the `IDocumentAction` interface from the enum value and calls `InvokeAction`. The action returns a Boolean indicating whether the E-Document's service status should be updated -- some actions are purely informational polls that should not change state.

Two built-in action types exist: "Sent Document Approval" and "Sent Document Cancellation". Their implementations (`SentDocumentApproval.Codeunit.al`, `SentDocumentCancellation.Codeunit.al`) follow an identical pattern: set default success and error statuses on the `ActionContext`, resolve `IDocumentSender` from the service enum, check `if IDocumentSender is ISentDocumentActions`, then delegate to the connector's `GetApprovalStatus` or `GetCancellationStatus`.

`ActionContext` (`ActionContext.Codeunit.al`) provides HTTP state via `Http()` and status management via `Status()`. The status object (`IntegrationActionStatus`) carries both a success status and an error status. The built-in approval action pre-sets success to Approved and error to "Approval Error"; the cancellation action pre-sets success to Canceled and error to "Cancel Error". Connectors can override these via `ActionContext.Status().SetStatus(...)`.

`HttpMessageState` (`HttpMessageState.Codeunit.al`) is the shared HTTP request/response container used by both `SendContext` and `ActionContext`. It is the same codeunit in both contexts -- a simple getter/setter pair for `HttpRequestMessage` and `HttpResponseMessage`.

## Things to know

- The `Integration Action Type` enum is extensible. Connector apps can add custom action types that implement `IDocumentAction` and invoke them through the standard `InvokeAction` path.

- The `IDocumentAction.InvokeAction` return value is critical: `true` means "update the service status to whatever is in `ActionContext.Status().GetStatus()`"; `false` means "do not touch the status." The framework always logs HTTP communication regardless of the return value.

- The built-in approval/cancellation actions cast from `IDocumentSender` to `ISentDocumentActions` using `is`/`as`. This means your connector's sender codeunit must also implement `ISentDocumentActions` for these actions to work -- it is not a separate registration.

- `E-Document Action Runner` uses the "if codeunit.Run()" pattern. If the action throws a runtime error, the framework catches it, logs the error, and sets the service status to the error status from `ActionContext.Status().GetErrorStatus()`.

- The `"No Action"` enum value maps to `Empty Integration Action`, which is the null-object implementation.
