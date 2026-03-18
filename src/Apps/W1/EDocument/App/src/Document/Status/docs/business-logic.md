# Status business logic

## Status aggregation

The document-level status is derived from per-service statuses. The processing layer queries each `E-Document Service Status` record for a given E-Document, calls `IEDocumentStatus.GetEDocumentStatus()` on each, and applies pessimistic aggregation.

```mermaid
flowchart TD
    A[Service status changes] --> B{Any service in Error state?}
    B -->|Yes| C[Document Status = Error]
    B -->|No| D{Any service In Progress?}
    D -->|Yes| E[Document Status = In Progress]
    D -->|No| F[Document Status = Processed]
```

## Service status to document status mapping

Each `E-Document Service Status` enum value maps to exactly one of three document-level states via the `IEDocumentStatus` interface. The mapping is declared on the enum value itself, not in procedural code.

The default implementation is `E-Doc In Progress Status`, so any service status without an explicit `Implementation` line is treated as in-progress. This is intentional -- new statuses are safe by default because they keep the document in a non-terminal state until the developer explicitly categorizes them.

## Outbound status flow

```mermaid
flowchart TD
    Created --> Exported
    Exported --> Sent
    Exported --> PendingResponse["Pending Response"]
    Exported --> SendingError["Sending Error"]
    PendingResponse --> Sent
    PendingResponse --> SendingError
    Sent --> Approved
    Sent --> Rejected
    Sent --> ApprovalError["Approval Error"]
    Sent --> Canceled
    Sent --> CancelError["Cancel Error"]
    Exported --> PendingBatch["Pending Batch"]
    PendingBatch --> Sent
    Created --> ExportError["Export Error"]
```

## Inbound status flow

```mermaid
flowchart TD
    Imported --> Pending["Pending (document link)"]
    Imported --> OrderLinked["Order Linked"]
    Imported --> ImportedDocCreated["Imported Document Created"]
    Imported --> JournalLineCreated["Journal Line Created"]
    Imported --> ImportedDocProcError["Imported Document Processing Error"]
    BatchImported --> Imported
    Pending --> OrderLinked
    OrderLinked --> ImportedDocCreated
```

## Error recovery

Error statuses are non-terminal in practice -- the UI allows reprocessing from error states. For outbound, `Sending Error` and `Export Error` allow resending. For inbound, `Imported Document Processing Error` allows reprocessing. The status codeunits themselves do not enforce transitions; they only provide the mapping. Actual transition guards live in `E-Doc. Integration Management` (e.g., `IsEDocumentInStateToSend` checks that service status is Exported or Sending Error before allowing a send).
