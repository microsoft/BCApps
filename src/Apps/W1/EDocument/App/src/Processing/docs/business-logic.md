# Processing business logic

## Export pipeline

The export path runs synchronously during posting unless batch processing is enabled. `EDocExport.CreateEDocument` is the public entry point called from workflow subscribers.

```mermaid
flowchart TD
    A[Posted document triggers workflow] --> B{Document Sending Profile has E-Doc flow?}
    B -- No --> Z[Exit]
    B -- Yes --> C[Filter services that support this doc type]
    C --> D{Any supported services?}
    D -- No --> Z
    D -- Yes --> E[Insert E-Document record]
    E --> F[PopulateEDocument from RecordRef]
    F --> G[Insert Service Status per service]
    G --> H{Batch processing?}
    H -- Yes --> I[Skip export -- batch job handles it]
    H -- No --> J[ExportEDocument per service]
    J --> K[Map fields via E-Doc. Mapping]
    K --> L[Call IEDocument.Create on format interface]
    L --> M{Errors?}
    M -- Yes --> N[Log Export Error status]
    M -- No --> O[Log Exported status + blob]
    O --> P[Start E-Document Created Flow background job]
```

The `CheckEDocument` path runs during release/pre-posting validation. It calls `IEDocument.Check` on the format interface -- this lets format implementations validate required fields before the document actually posts.

## Import pipeline -- V2

The V2 pipeline is a state machine. `EDocImport.GetEDocumentToDesiredStatus` computes the steps needed to reach a target status from the current status, undoing steps if the target is earlier than current (for reprocessing).

```mermaid
flowchart TD
    A[Unprocessed] -->|Structure received data| B[Readable]
    B -->|Read into Draft| C[Ready for draft]
    C -->|Prepare draft| D[Draft ready]
    D -->|Finish draft| E[Processed]
    E -.->|Undo finish draft| D
    D -.->|Undo prepare draft| C
    C -.->|Undo read into draft| B
    B -.->|Undo structure| A
```

Each step is executed inside `Codeunit.Run` with a commit barrier, so failures are caught and logged as `Imported Document Processing Error` without corrupting the transaction.

## Import pipeline -- V1

V1 is the legacy monolithic path. It processes everything in `V1_ProcessImportedDocument`: get basic info, parse document lines, resolve vendor, then branch on vendor settings.

```mermaid
flowchart TD
    A[V1_ProcessEDocument] --> B[GetDocumentBasicInfo via IEDocument]
    B --> C{Errors?}
    C -- Yes --> ERR[Log error, exit]
    C -- No --> D[ParseDocumentLines via IEDocument]
    D --> E{Vendor found?}
    E -- No --> ERR
    E -- Yes --> F{Self-billing vendor?}
    F -- Yes --> ERR
    F -- No --> G{Vendor.Receive E-Document To = Purchase Order?}
    G -- Yes --> H{Order exists?}
    H -- Yes --> I[ProcessExistingOrder -- link to PO]
    H -- No --> J{GUI available?}
    J -- Yes --> K[User selects PO or creates new]
    J -- No --> L[Set status Pending]
    G -- No --> M[Create purchase invoice/credit memo]
```

V1 documents only respond to the "Finish draft" step in the V2 state machine -- all other steps are no-ops.

## Status management

`EDocumentProcessing.ModifyEDocumentStatus` aggregates per-service statuses into a single E-Document status using short-circuit logic: the first error found sets the document to Error and returns. Otherwise, any in-progress service means the document is in-progress. Only if all services are done does it become Processed.

The `Import Processing Status` is a separate dimension tracked on `E-Document Service Status` and only applies to incoming documents. It represents position in the V2 pipeline and is independent of the overall service status.
