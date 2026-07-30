# E-Document Core

E-Document Core is the framework for electronic document exchange in Business Central. It converts outbound sales/service/purchase documents into structured formats (Data Exchange, PEPPOL-backed formats, or custom), transmits them through configurable service integrations, and processes inbound electronic documents into purchase invoices, credit memos, sales orders, or journal lines. The framework is interface-driven: it defines the contracts, and connector or format apps provide the actual service communication and specialized format logic.

See [README.md](README.md) for detailed interface implementation examples with code samples.

## Quick reference

- **ID range**: 6100-6199, 6208-6209, 6231-6232, 6234

## How it works

Everything starts with the **Document Sending Profile**. When a BC document is posted, `EDocumentSubscribers.Codeunit.al` catches the posting event and looks up the Document Sending Profile for the customer/vendor. If the profile specifies "Extended E-Document Service Flow", the framework follows the referenced **Workflow** to determine which E-Document Services to invoke. The workflow is a first-class citizen -- it orchestrates send, email, approval, and other steps as a sequence of workflow responses.

An **E-Document Service** (`EDocumentService.Table.al`) combines a **Document Format** (how to serialize, e.g. PEPPOL BIS 3.0) with a **Service Integration** (where to send/receive, e.g. a connector app). Both are enum-based with interface implementations, so you extend them by adding enum values that bind to your interface implementation -- classic strategy pattern via AL enums.

Outbound documents flow through: check on release -> create E-Document record on post or purchase order release -> export to blob via the "E-Document" interface -> send via IDocumentSender -> optionally poll for async response via IDocumentResponseHandler. Inbound documents use the V2.0 multi-stage pipeline by default for new services: receive document list -> download each document -> structure (convert PDF to structured data via ADI/MLLM or passthrough for XML) -> read into draft staging tables -> prepare draft (resolve vendors/customers, items, accounts) -> finish draft (create the BC purchase document or sales order). Each stage is independently reversible.

The framework does not provide any service connector itself. The `"Service Integration"` enum ships with only `"No Integration"`. Connector apps (like E-Document Connector for Pagero or Avalara) extend this enum and implement IDocumentSender, IDocumentReceiver, and other integration interfaces. The `"E-Document Format"` enum still exposes `"Data Exchange"` and `"PEPPOL BIS 3.0"`, but Core now depends on the standalone PEPPOL app for PEPPOL XML builders, validation interfaces, purchase order export, and order response payload construction.

Three status dimensions track document lifecycle: **E-Document Status** (In Progress / Processed / Error -- the overall state), **E-Document Service Status** (per-service granular status like Exported, Sent, Pending Response, Approved, etc.), and **Import Processing Status** (the V2.0 import pipeline stage: Unprocessed -> Readable -> Ready for draft -> Draft Ready -> Processed). Lifecycle messages such as PEPPOL Order Responses are stored separately from BC documents and linked back to the parent E-Document.

*Updated: 2026-07-29 -- clarified V2.0 defaults, PEPPOL app dependency, sales order import, and message handling.*

## Structure

```
src/
  ClearanceModel/     -- Tax authority QR code clearance on posted invoices/credit memos
  ControlAddIn/       -- PDF Viewer browser control add-in
  DataExchange/       -- Data Exchange Definition format impl, resource import, and v2 bridge support
  Document/           -- Core E-Document table, status model, direction/type enums, notification
  Extensions/         -- Table/page extensions hooking into BC sales, purchase, service documents
  Format/             -- Core format adapters, including PEPPOL BIS 3.0 bindings over the PEPPOL app
  Helpers/            -- Utilities: error handling, JSON helpers, logging, blob processing
  Integration/        -- Service integration framework: send/receive/action interfaces, runners, context
  Logging/            -- E-Document Log, Integration Log, Data Storage tables
  Mapping/            -- Field mapping engine for import/export transformations
  Processing/         -- Core orchestration: export, import pipeline, messages, order matching, AI, providers
  SampleInvoice/      -- Demo sample invoice generation
  Service/            -- Service configuration, participants, supported document types
  Setup/              -- Installation, upgrade, consent management
  Workflow/           -- Workflow integration: event triggers, response handlers, setup
```

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)

## Things to know

- The E-Document table (`table 6121`) is the central entity. It links to the source BC document via `"Document Record ID"` (a RecordId, not a foreign key). For inbound V1.0 documents, Purchase Header links back via `"E-Document Link"` (a Guid matching `SystemId`), but this is being removed in CLEAN27.
- Inbound documents have two data storage slots: `"Unstructured Data Entry No."` (the raw PDF/file) and `"Structured Data Entry No."` (the parsed XML/JSON). Both point to `"E-Doc. Data Storage"` records containing blobs.
- The import pipeline implementation fields live directly on the E-Document table: `"Structure Data Impl."`, `"Read into Draft Impl."`, and `"Process Draft Impl."`. These enums determine which interface implementations run at each stage.
- `"E-Document Service Status"` enum implements `IEDocumentStatus` interface -- each status value knows whether it means "in progress", "processed", or "error", via `EDocInProgressStatus`, `EDocProcessedStatus`, and `EDocErrorStatus` codeunits.
- Batch processing and single-document processing are distinct code paths. Batch mode uses recurrent background jobs configured on the service (fields 21-26 on `"E-Document Service"`).
- The V1.0 import process (`"Import Process" = "Version 1.0"`) collapses all pipeline stages into a single "Finish draft" step. V2.0 is the current architecture, and new services default to it. The import version is selectable on the service card. For V2.0 services the service-level `"Read into Draft Impl."` field ("Draft Format" on the card) selects how already-structured documents (for example PEPPOL, Data Exchange Purchase, OIOUBL, or XRechnung XML from dependent format apps) are read into a draft; it is the fallback used when neither the structuring step nor the receiving integration sets a reader, so leaving it `Unspecified` for such formats makes import fail.
- `#if not CLEAN26` and `#if not CLEAN27` blocks mark deprecated code scheduled for removal. The old `"E-Document Integration"` enum and its `"Service Integration"` field on the service table are fully replaced by `"Service Integration V2"`.
- The framework uses the "if codeunit.run" pattern extensively -- interface calls are wrapped in codeunits that run with error trapping, so a connector failure produces a logged error rather than a crash.
- `"E-Document Background Jobs"` manages Job Queue Entries for recurrent import polling and batch send processing.
- The `IExportEligibilityEvaluator` interface (field `"Export Eligibility Evaluator"` on the service) lets connector apps control which documents should be exported via their service, beyond the basic document type check.
- Purchase draft staging tables are intentionally consumable by dependent country apps; sales order staging is internal to Core and participates in sensitivity classification with the other E-Document tables.

*Updated: 2026-07-29 -- added current import format selection, PEPPOL split, and staging visibility notes.*
