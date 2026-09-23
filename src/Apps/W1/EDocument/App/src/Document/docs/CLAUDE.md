# Document

The E-Document table (table 6121 in `EDocument.Table.al`) is the aggregate root of the entire framework. Every electronic document -- whether an outbound sales invoice, an inbound purchase credit memo, or a response message for an existing order -- lives or is tracked from here. This module also owns the status model, direction semantics, document type taxonomy, message factboxes, and user notification infrastructure.

## How it works

*Updated: 2026-07-29 -- Added message handling, sales order import, and refreshed incoming draft semantics.*

When a BC document is posted or an external document arrives from a service endpoint, the framework creates an E-Document record via the `Create` procedure, stamping it with a direction (Incoming/Outgoing from `EDocumentDirection.Enum.al`), a document type from the extensive `E-Document Type` enum (covering sales, purchase, service, finance charge, reminders, journals, shipments, and order responses), and the originating service code.

The E-Document carries three independent status dimensions that evolve separately. The top-level `Status` field (enum 6108: In Progress, Processed, Error, plus Canceled for explicit cancellation checks) is normally derived from the per-service `E-Document Service Status` via the strategy pattern -- each service status value implements `IEDocumentStatus` (defined in `Interfaces/IEDocumentStatus.Interface.al`), and the three codeunits in `Status/` (`EDocErrorStatus`, `EDocInProgressStatus`, `EDocProcessedStatus`) return the corresponding top-level status. Most service statuses default to "In Progress" unless explicitly mapped to Error or Processed in the enum implementation declarations. The third dimension, `Import Processing Status`, is a FlowField that reads from the `E-Document Service Status` table, tracking inbound documents through a five-step pipeline: Unprocessed, Readable, Ready for draft, Draft Ready, Processed.

The `E-Document` interface (`Interfaces/EDocument.Interface.al`) defines the format contract that document format implementations must satisfy -- `Check`, `Create`, `CreateBatch` for outbound, and `GetBasicInfoFromReceivedDocument` / `GetCompleteInfoFromReceivedDocument` for inbound. The `E-Document Format` enum now also implements `IEDocResponseProvider`; the PEPPOL implementation can classify an inbound order response as a message for an existing outbound E-Document instead of continuing through draft creation.

Order response messages are stored in `E-Document Message` records and shown on the E-Document card, the E-Documents list, and inbound pages through the messages factbox. A message can carry its own data storage entry and response type, but it does not create a BC purchase or sales document. The inbound carrier record is cleaned up after the message is attached to the outbound E-Document.

## Things to know

*Updated: 2026-07-29 -- Refreshed duplicate, deletion, cleanup, and draft metadata notes.*

- Duplicate detection uses `IsDuplicate()` which checks the composite `(Incoming E-Document No., Bill-to/Pay-to No., Document Date)` with `ReadIsolation::ReadUncommitted` -- this means it can see uncommitted records from other sessions, avoiding race conditions during batch imports. For V2 purchase imports, `PrepareDraft` copies `Document Date` and `Due Date` from `E-Document Purchase Header` back to the E-Document, so the duplicate check depends on the extracted document date rather than only on the received file identity.

- Deletion is still guarded by the table trigger: you cannot delete a Processed document or one linked to a source document (`Document Record ID`). List pages now allow users to invoke delete, but unique non-GUI deletes still block and unique GUI deletes still require confirmation. Orphaned inbound carrier records for order response messages use `DeleteOrphanedImport()` after cleanup.

- The `CleanupDocument` procedure cascades deletes to logs, integration logs, service statuses, mapping logs, imported lines, document attachments, E-Document messages, and error messages. It also invokes `IProcessStructuredData.CleanUpDraft` for version 2 processing cleanup.

- The `E-Documents Setup` table (table 6107) is marked `ObsoleteState = Pending` with tag '28.0'. It controls the "new E-Document experience" feature gate, which is activated per-tenant via AAD tenant ID allowlist, environment setting, or country code list.

- The `E-Document` interface's `CreateBatch` method receives a record set of E-Documents rather than a single record -- format implementations must handle multi-document serialization into a single blob.

- Fields 42-44 (`Structure Data Impl.`, `Read into Draft Impl.`, `Process Draft Impl.`) are enum-based strategy selectors for the import processing pipeline, allowing different implementations per document. `E-Document Type` now routes Purchase Credit Memo and Sales Order to finish-draft implementations in addition to Purchase Invoice.

- PEPPOL basic-info parsing sets `Order No.` from `OrderReference` for both purchase invoices and purchase credit memos before full draft processing. Credit memo finish draft also keeps apply-to references: `EDocCreatePurchCrMemo` copies the purchase order reference to `Vendor Order No.` and can resolve the apply-to invoice either from `Applies-to Doc. No.` or from the external invoice number.

- Inbound page actions that continue processing (`Analyze PDF`, `Prepare Draft`, and `Open draft document`) call `ThrowIfHasErrors` after running import steps, so processing errors are surfaced to the user instead of only changing status.

- Notification infrastructure (`Notification/`) currently handles a single scenario -- alerting users when an inbound vendor was matched by name but not address. Notifications are per-user, dismissable, and backed by the `My Notifications` framework.
