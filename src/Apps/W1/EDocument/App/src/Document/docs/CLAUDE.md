# Document

The E-Document table (table 6121 in `EDocument.Table.al`) is the aggregate root of the entire framework. Every electronic document -- whether an outbound sales invoice or an inbound purchase credit memo -- lives as a single row here. This module also owns the status model, direction semantics, document type taxonomy, and user notification infrastructure.

## How it works

When a BC document is posted or an external document arrives from a service endpoint, the framework creates an E-Document record via the `Create` procedure, stamping it with a direction (Incoming/Outgoing from `EDocumentDirection.Enum.al`), a document type from the extensive `E-Document Type` enum (22 values covering sales, purchase, service, finance charge, reminders, journals, and shipments), and the originating service code.

The E-Document carries three independent status dimensions that evolve separately. The top-level `Status` field (enum 6108: In Progress, Processed, Error) is derived automatically from the per-service `E-Document Service Status` via the strategy pattern -- each service status value implements `IEDocumentStatus` (defined in `Interfaces/IEDocumentStatus.Interface.al`), and the three codeunits in `Status/` (`EDocErrorStatus`, `EDocInProgressStatus`, `EDocProcessedStatus`) return the corresponding top-level status. Most service statuses default to "In Progress" unless explicitly mapped to Error or Processed in the enum implementation declarations. The third dimension, `Import Processing Status`, is a FlowField that reads from the `E-Document Service Status` table, tracking inbound documents through a five-step pipeline: Unprocessed, Readable, Ready for draft, Draft Ready, Processed.

The `E-Document` interface (`Interfaces/EDocument.Interface.al`) defines the format contract that document format implementations must satisfy -- `Check`, `Create`, `CreateBatch` for outbound, and `GetBasicInfoFromReceivedDocument` / `GetCompleteInfoFromReceivedDocument` for inbound.

## Things to know

- Duplicate detection uses `IsDuplicate()` which checks the composite `(Incoming E-Document No., Bill-to/Pay-to No., Document Date)` with `ReadIsolation::ReadUncommitted` -- this means it can see uncommitted records from other sessions, avoiding race conditions during batch imports.

- Deletion is heavily guarded: you cannot delete a Processed document or one linked to a source document (`Document Record ID`). Non-duplicate documents require explicit user confirmation, and non-GUI contexts block outright.

- The `CleanupDocument` procedure cascades deletes to logs, integration logs, service statuses, mapping logs, imported lines, and document attachments. It also invokes `IProcessStructuredData.CleanUpDraft` for version 2 processing cleanup.

- The `E-Documents Setup` table (table 6107) is marked `ObsoleteState = Pending` with tag '28.0'. It controls the "new E-Document experience" feature gate, which is activated per-tenant via AAD tenant ID allowlist, environment setting, or country code list.

- The `E-Document` interface's `CreateBatch` method receives a record set of E-Documents rather than a single record -- format implementations must handle multi-document serialization into a single blob.

- Fields 42-44 (`Structure Data Impl.`, `Read into Draft Impl.`, `Process Draft Impl.`) are enum-based strategy selectors for the import processing pipeline, allowing different implementations per document.

- Notification infrastructure (`Notification/`) currently handles a single scenario -- alerting users when an inbound vendor was matched by name but not address. Notifications are per-user, dismissable, and backed by the `My Notifications` framework.
