# Status

Status tracking for e-documents operates at two levels: a document-level status and a per-service status. This directory contains the enums and interface implementations that make the status state machine work. The `IEDocumentStatus` interface bridges between the fine-grained service statuses and the coarse document-level status.

## How it works

The `E-Document Service Status` enum (`EDocumentServiceStatus.Enum.al`) has roughly 20 values covering the full outbound and inbound lifecycle -- Created, Exported, Sent, Pending Response, Approved, Rejected, Canceled, Imported, Order Linked, and so on. Each enum value carries a `DefaultImplementation` of `IEDocumentStatus` that maps it to one of three document-level states. The mapping is baked into the enum declaration itself: each value specifies which codeunit implements `IEDocumentStatus`.

Three trivial codeunits implement the interface -- `EDocErrorStatus` (returns Error), `EDocInProgressStatus` (returns In Progress), and `EDocProcessedStatus` (returns Processed). The default for any value without an explicit implementation is `EDocInProgressStatus`. This is the entire status aggregation logic: the processing layer calls `GetEDocumentStatus()` on a service status enum value and gets back the document-level status.

The document-level `E-Document Status` enum has only three values: In Progress (0), Processed (1), and Error (2). The aggregation is pessimistic -- if any service associated with a document is in an error state, the document status becomes Error. If any is in-progress, the document is In Progress. Only when all services reach a "processed" terminal state does the document become Processed.

## Things to know

- The enum-implements-interface pattern means you cannot look at the three codeunits in isolation and understand the status mapping. You must read the `E-Document Service Status` enum declaration to see which service statuses map to which document statuses.

- Service statuses that lack an explicit `Implementation` line default to `EDocInProgressStatus` via `DefaultImplementation` on the enum. This means any new enum value is automatically treated as "in progress" unless you explicitly wire it to Error or Processed.

- Error statuses: Sending Error, Cancel Error, Export Error, Imported Document Processing Error, and Approval Error. All map to `EDocErrorStatus`.

- Processed statuses: Exported, Canceled, Imported Document Created, Journal Line Created, Sent, Approved, Rejected, and Cleared. Note that Rejected is treated as Processed (terminal), not Error.

- The clearance model statuses (Not Cleared = 30, Cleared = 31) live in a reserved range (30-40) and follow the same pattern.

- Status transition is not enforced by these objects. The enum values define the mapping; the actual state machine transitions happen in `E-Document Processing` and `E-Doc. Integration Management`.
