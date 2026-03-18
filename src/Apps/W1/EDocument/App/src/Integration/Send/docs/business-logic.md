# Send business logic

## Single document send flow

```mermaid
flowchart TD
    A[Send called] --> B{Service integration configured?}
    B -->|No| Z[Exit -- no integration]
    B -->|Yes| C{Document in valid state?}
    C -->|No| Z2[Show message and exit]
    C -->|Yes| D[Get exported blob from E-Document Log]
    D --> E{Blob found?}
    E -->|No| F[Log error, set Sending Error]
    E -->|Yes| G[Create SendContext with blob]
    G --> H[Set default status = Sent]
    H --> I[Run Send Runner via if codeunit.Run]
    I --> J{Runner succeeded?}
    J -->|No| K[Log error from GetLastErrorText]
    J -->|Yes| L{Is sender also IDocumentResponseHandler?}
    L -->|Yes| M[IsAsync = true]
    L -->|No| N[IsAsync = false]
    M --> O[Status = Pending Response]
    N --> P[Status = SendContext.Status]
    K --> Q[Status = Sending Error]
    O --> R[Insert log, update service status, log HTTP]
    P --> R
    Q --> R
    R --> S{IsAsync?}
    S -->|Yes| T[Schedule GetResponse background job]
    S -->|No| U[Done]
```

## Async response polling flow

The `E-Document Get Response` codeunit runs as a job queue entry. It processes all documents in "Pending Response" state.

```mermaid
flowchart TD
    A[Job queue fires] --> B{Any documents Pending Response?}
    B -->|No| Z[Exit]
    B -->|Yes| C[For each Pending Response document]
    C --> D[Run GetResponse Runner]
    D --> E{Runner succeeded without errors?}
    E -->|No| F[Status = Sending Error]
    E -->|Yes| G{GetResponse returned true?}
    G -->|Yes| H[Status = SendContext.Status -- default Sent]
    G -->|No| I[Status = Pending Response -- unchanged]
    F --> J[Insert log and update status]
    H --> J
    I --> J
    J --> K[Next document]
    K --> L{Still documents in Pending Response?}
    L -->|Yes| M[Reschedule job]
    L -->|No| N[Done]
```

## Batch send flow

Recurrent batch send is triggered by a scheduled job queue entry tied to a specific E-Document Service.

```mermaid
flowchart TD
    A[Job fires for service] --> B[Find all Pending Batch service statuses]
    B --> C{Any found?}
    C -->|No| Z[Exit]
    C -->|Yes| D[Group documents by Document Type]
    D --> E[For each document type group]
    E --> F[Export batch to single blob]
    F --> G[For each document: check export errors]
    G --> H{Export error?}
    H -->|Yes| I[Status = Export Error]
    H -->|No| J[Status = Exported]
    J --> K[Collect exported entry numbers]
    I --> L[Log and update per-document status]
    K --> L
    L --> M[Store shared data blob]
    M --> N[Call SendBatch on integration management]
    N --> O{Async?}
    O -->|Yes| P[Schedule GetResponse job]
    O -->|No| Q[Handle workflow events]
```

## State guard for sending

`IsEDocumentInStateToSend` prevents sending from invalid states. Only documents with service status `Exported` or `Sending Error` are eligible. This enables retry-from-error without requiring manual status reset, while preventing duplicate sends from other states like "Sent" or "Pending Response".
