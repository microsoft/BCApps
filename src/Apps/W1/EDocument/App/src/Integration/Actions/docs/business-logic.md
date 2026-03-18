# Actions business logic

## Action dispatch flow

```mermaid
flowchart TD
    A[InvokeAction called] --> B[Verify Service Integration V2 is set]
    B --> C[Run E-Document Action Runner via if codeunit.Run]
    C --> D{Runner succeeded without errors?}
    D -->|No| E[Set status to ActionContext error status]
    D -->|Yes| F{Action returned true -- update status?}
    F -->|Yes| G[Set status to ActionContext success status]
    F -->|No| H[Skip status update]
    E --> I[Log HTTP communication]
    G --> I
    H --> I
```

## Built-in approval action flow

The "Sent Document Approval" action follows a delegation pattern -- the framework sets default statuses, then hands off to the connector.

```mermaid
flowchart TD
    A[Sent Document Approval invoked] --> B[Set error status = Approval Error]
    B --> C[Set success status = Approved]
    C --> D[Resolve IDocumentSender from enum]
    D --> E{Sender implements ISentDocumentActions?}
    E -->|No| F[Return false -- no status update]
    E -->|Yes| G[Cast to ISentDocumentActions]
    G --> H[Call GetApprovalStatus]
    H --> I{Connector returns true?}
    I -->|Yes| J[Framework sets status to Approved]
    I -->|No| K[Framework leaves status unchanged]
```

## Built-in cancellation action flow

Identical to approval, with Canceled/Cancel Error as the default statuses and `GetCancellationStatus` as the connector method.

## Action context status management

The `IntegrationActionStatus` codeunit holds two status values: a success status and an error status. This dual-status design exists because the framework needs to know which status to apply in both the success and error paths without requiring the action implementation to handle error-status logic.

The built-in actions pre-set both values before calling the connector:

- Approval: success = Approved, error = Approval Error
- Cancellation: success = Canceled, error = Cancel Error

Connectors can override the success status via `ActionContext.Status().SetStatus(...)` if their API returns a different terminal state. The error status is typically left at the default.
