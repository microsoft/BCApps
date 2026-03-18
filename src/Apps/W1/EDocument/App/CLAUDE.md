# E-Document Core

E-Document Core is Business Central's foundation layer for electronic document exchange. It provides the framework for sending outbound e-invoices (sales invoices, credit memos, reminders, shipments, transfer documents) and receiving inbound e-invoices (purchase invoices, purchase orders), with pluggable format and integration layers so that country-specific apps only need to implement the "how to serialize" and "how to transmit" parts. The app has zero dependencies -- every other e-document app depends on it.

## Quick reference

- **ID range**: 6100-6199, 6208-6209, 6231-6232, 6234
- **Dependencies**: None (self-contained foundation layer)

## How it works

The core design is a two-layer plugin model: **Format** (how to transform a BC document into XML/JSON and back) and **Integration** (how to transmit that blob to/from an external service). Both are stored as enum values on the `E-Document Service` table, resolved at runtime to interface implementations. This means a PEPPOL format can be paired with any integration connector, and vice versa.

Outbound flow starts when a sales document is posted. `EDocumentSubscribers` catches the posting event, `EDocExport` transforms the document using the format interface, and `EDocIntegrationManagement` sends it using the integration interface. The workflow engine (`EDocumentWorkFlowProcessing`) orchestrates multi-step flows like export-then-send or export-then-email. Batch sending supports three modes: threshold-based accumulation, recurrent job queue, and custom extension events.

Inbound flow has two distinct paths. The legacy V1 path calls `GetBasicInfo` then `GetCompleteInfo` on the format interface to directly populate a purchase document in a single step. The V2 path is a four-stage pipeline: Structure (convert PDF to XML via ADI/MLLM/PEPPOL), Read (parse into draft tables), Prepare (resolve vendor/items via provider interfaces), and Finish (create the actual BC purchase document). Each stage is independently undoable. The V2 path stores intermediate state in `E-Document Purchase Header/Line` tables with raw external data alongside `[BC]`-prefixed validated fields.

Status is a three-tier state machine. The top-level `E-Document.Status` (Error, In Progress, Processed) is derived by scanning all `E-Document Service Status` records -- any error wins, then any in-progress, otherwise processed. For imports, the service status also carries an `Import Processing Status` (Unprocessed, Readable, Ready for draft, Draft ready, Processed) that drives the V2 pipeline progression.

## Structure

- `src/Document/` -- The `E-Document` table, status enums, inbound/outbound list pages, and the `E-Document` format interface
- `src/Service/` -- `E-Document Service` configuration, service status tracking, supported document types, and service participants
- `src/Integration/` -- Send/receive context objects, interface definitions for `IDocumentSender`/`IDocumentReceiver`/`IDocumentResponseHandler`, and action runners for approval/cancellation
- `src/Processing/` -- The export pipeline (`EDocExport`), subscribers that hook into BC posting events, and the import subsystem under `Import/` with its four-stage pipeline, provider interfaces, and purchase order matching
- `src/Processing/AI/` -- Copilot-powered line matching tools (historical matching, GL account matching, deferral matching)
- `src/Processing/OrderMatching/` -- Purchase order line matching with Copilot proposal support
- `src/Format/` -- PEPPOL BIS 3.0 export/import codeunits and shipment XML generation
- `src/Logging/` -- `E-Doc. Data Storage` (binary blob store), `E-Document Log`, and `E-Document Integration Log` tables
- `src/Mapping/` -- Find/replace transformation rules applied during export/import
- `src/Workflow/` -- BC Workflow integration for multi-step document processing flows
- `src/Extensions/` -- Table/page extensions to Purchase Header, Vendor, Document Sending Profile, role centers, etc.
- `src/ClearanceModel/` -- QR code generation for clearance-model countries (Spain, India, Mexico, Italy)
- `src/DataExchange/` -- PEPPOL Data Exchange Definition integration for legacy import paths
- `src/Helpers/` -- Error handling, JSON utilities, import helpers

## Documentation

- [docs/data-model.md](docs/data-model.md) -- Tables, relationships, and storage design
- [docs/business-logic.md](docs/business-logic.md) -- Outbound and inbound processing flows
- [docs/extensibility.md](docs/extensibility.md) -- Interfaces, events, and how to build connectors
- [docs/patterns.md](docs/patterns.md) -- Recurring design patterns and legacy conventions

## Things to know

- The `E-Document` table links to its source BC document via `Document Record ID` (a RecordId field), not a foreign key. This means it can point at any posted document type without schema coupling.
- V1 import and V2 import coexist. The `E-Document Import Process` enum on the service determines which path runs. V1 skips straight to "Finish draft" and calls the old `GetCompleteInfo` interface. V2 runs all four stages.
- `E-Doc. Data Storage` is a shared blob store. Multiple log entries can reference the same storage entry. The unstructured blob (PDF) and structured blob (XML) are stored separately and linked via `Unstructured Data Entry No.` and `Structured Data Entry No.` on the E-Document.
- The `[BC]` prefix convention on `E-Document Purchase Header/Line` fields distinguishes validated Business Central values from raw external data. When you see `Vendor Name` vs `[BC] Vendor No.`, the first is what the sender wrote and the second is what the system resolved.
- Duplicate detection for incoming documents uses a composite key of (Incoming E-Document No., Bill-to/Pay-to No., Document Date).
- Error handling uses the try-commit-run pattern: commit before calling interface implementations via `Codeunit.Run()`, then catch failures with `GetLastErrorText()` and log them. This prevents partial state corruption from rolling back the caller's transaction.
- The `Service Integration V2` enum replaces the obsolete `Service Integration` enum. Code gated by `#if not CLEAN26` handles the transition. The old `E-Document Integration` interface is replaced by the split `IDocumentSender`/`IDocumentReceiver`/`IDocumentResponseHandler` interfaces.
- Workflow is not optional for outbound -- the Document Sending Profile must reference an enabled Workflow with an "Extended E-Document Service Flow" entry. The workflow steps determine which services process the document and in what order.
- The `InternalsVisibleTo` list includes Payables Agent, meaning the AI agent can directly access internal procedures for automated invoice processing.
- Historical matching (`EDocPurchaseLineHistory`, `EDocVendorAssignHistory`) is vendor-scoped and learns from posted purchase invoices to improve future automatic matching.
