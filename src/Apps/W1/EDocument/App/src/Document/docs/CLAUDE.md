# Document

This area defines the core E-Document entity (table 6121), its status model, direction routing, type classification, and notification system. Everything else in E-Document Core ultimately references back to this table.

## How it works

An E-Document record represents one electronic document, either outgoing (created from a posted sales/service doc) or incoming (received from an external service). The `Direction` enum (`EDocumentDirection.Enum.al`) has two values -- Outgoing and Incoming -- and controls which UI pages, processing pipelines, and validation logic apply. `Document Record ID` is a RecordId pointing to the source/target BC document (e.g. Posted Sales Invoice, Purchase Header); it can be empty for newly imported incoming documents that haven't been linked to a BC record yet.

The status model has two layers. `E-Document Status` (enum 6108) is the top-level aggregate with three values: In Progress, Processed, Error. `E-Document Service Status` (enum 6106) is the granular per-service status with ~24 values (Created, Exported, Sent, Imported, Order Linked, Sending Error, etc.). Each service status value declares which `IEDocumentStatus` implementation it uses -- for example, "Exported" and "Sent" map to `EDocProcessedStatus`, "Sending Error" and "Export Error" map to `EDocErrorStatus`, and most others default to `EDocInProgressStatus`. This interface-based mapping means the top-level status is derived from the service status, not set independently.

The `E-Document Type` enum (enum 6121) has 22 values covering sales, purchase, service, finance charge, reminder, journal, and transfer document types. It implements `IEDocumentFinishDraft` -- only Purchase Invoice has a concrete implementation (`E-Doc. Create Purchase Invoice`); all others use the default unspecified implementation. This reflects the fact that inbound document creation is currently purchase-focused.

Duplicate detection uses a secondary key on `(Incoming E-Document No., Bill-to/Pay-to No., Document Date)` via the `IsDuplicate` method. When a duplicate is found, telemetry is logged and the user is warned.

## Things to know

- Deletion is restricted: you cannot delete a Processed E-Document or one with a non-empty `Document Record ID` (linked to a BC document). Deleting a non-duplicate requires UI confirmation
- Validating `Document Record ID` triggers `EDocAttachmentProcessor.MoveAttachmentsAndDelete`, which moves Document Attachment records from the E-Document to the newly linked BC document
- `CleanupDocument` cascades deletion to logs, service statuses, attachments, imported lines, mapping logs, and Purchase Header E-Document Links -- it also calls `IProcessStructuredData.CleanUpDraft` for version 2 processing cleanup
- The `Structured Data Entry No.` and `Unstructured Data Entry No.` fields point to `E-Doc. Data Storage` records (e.g. XML and PDF respectively) -- structured means machine-parseable, unstructured means human-readable
- The notification table (`EDocumentNotification.Table.al`) is keyed by (E-Document Entry No., ID, User Id) -- notifications are per-user per-document, currently used for vendor matching warnings
- `Service` field on E-Document references an `E-Document Service` record and is set at creation time along with `Service Integration` -- this determines which integration and format implementation processes the document
- The `Import Processing Status` is a FlowField that reads from `E-Document Service Status`, not stored directly on the E-Document
