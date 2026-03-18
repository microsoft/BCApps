# E-Document Core

E-Document Core is Business Central's foundation framework for electronic document exchange. It sits between BC's posting engine and external e-invoicing networks (PEPPOL, country clearance systems, etc.), providing the plumbing so that connector and format apps don't have to reinvent lifecycle tracking, error handling, or status management. Think of it as the "middleware" that turns a posted sales invoice into a tracked, auditable electronic document that flows through configurable services.

## Quick reference

- **ID range**: 6100-6199, 6208-6209, 6231-6232, 6234
- **Dependencies**: None -- this is the base layer. Everything else depends on it.
- **Namespace**: `Microsoft.eServices.EDocument`

## How it works

The app is organized in three conceptual layers. The **Core** layer owns the E-Document record, its lifecycle states, logging, and workflow orchestration. The **Document Format** layer (plugged in via the `E-Document` interface and the `E-Document Format` enum) handles serialization -- turning a BC document into XML/JSON and vice versa. The **Service Integration** layer (plugged in via `IDocumentSender`, `IDocumentReceiver`, and friends on the `Service Integration` enum) handles the actual HTTP communication with external networks.

Documents flow bidirectionally. **Outbound**: when a sales invoice is posted, `EDocumentSubscribers` fires, creating an E-Document record, exporting it through the configured format, then routing it through a BC Workflow (`EDOC` category) that determines which service(s) send it. Sending can be synchronous or asynchronous -- if the connector implements `IDocumentResponseHandler`, the framework polls for responses via `GetResponse`. **Inbound**: a service's `IDocumentReceiver` fetches documents from an API, then each document flows through a multi-stage pipeline: Structure (convert PDF to XML via ADI or similar) -> Read into Draft (parse into `E-Document Purchase Header/Line`) -> Prepare Draft (resolve vendor, items, GL accounts) -> Finish Draft (create the actual BC purchase invoice).

There are two import processing versions. **V1** (legacy, behind `#if not CLEAN27` guards) is a monolithic path where `GetCompleteInfoFromReceivedDocument` on the format interface does everything at once -- parse, resolve, and create the BC document in a single call. **V2** breaks this into four discrete steps with undo capability, each driven by a separate interface (`IStructureReceivedEDocument`, `IStructuredFormatReader`, `IProcessStructuredData`, `IEDocumentFinishDraft`). V2 is the active development path; V1 exists only for backward compatibility.

Batch processing supports two modes: **Threshold** (accumulate N documents, then send as one blob) and **Recurrent** (job queue fires on a schedule, sends whatever is pending). Each mode creates a single export blob from multiple E-Documents via `CreateBatch` on the format interface.

## Structure

- `src/Document/` -- The E-Document table itself, status enums, direction/type enums, and the inbound/outbound list pages
- `src/Service/` -- E-Document Service configuration, supported document types, and service participants
- `src/Integration/` -- The V2 integration interfaces (`IDocumentSender`, `IDocumentReceiver`, etc.), context codeunits (`SendContext`, `ReceiveContext`, `ActionContext`), and the send/receive runners
- `src/Processing/` -- The heavy lifting: export (`EDocExport`), import pipeline (`ImportEDocumentProcess`), AI-powered matching (Copilot tools), order matching, and all the V2 import interfaces
- `src/Processing/Import/Purchase/` -- Draft purchase document tables and history tables used by V2 import
- `src/Logging/` -- E-Document Log, Integration Log (HTTP request/response), and Data Storage (blob table)
- `src/Mapping/` -- Field-level value mapping (find/replace on RecordRef fields during export/import)
- `src/Workflow/` -- BC Workflow integration: EDOC category setup, flow processing, step arguments
- `src/Helpers/` -- Error helper, JSON helper, import helper, log helper
- `src/Format/` -- PEPPOL BIS 3.0 import handler
- `src/DataExchange/` -- Data Exchange Definition integration for PEPPOL
- `src/ClearanceModel/` -- QR code handling for clearance-model countries (posted invoice extensions with QR viewer)
- `src/Extensions/` -- Page/table extensions that embed E-Document functionality into standard BC pages

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)

## Things to know

- The E-Document table's `Status` field (3 values: In Progress / Processed / Error) is an **aggregate** derived from the per-service `E-Document Service Status` (24+ granular values). Each service status value implements `IEDocumentStatus` to declare which aggregate it maps to. Don't set E-Document.Status directly -- modify the service status and call `ModifyEDocumentStatus`.

- The `E-Document Service Status` enum is `Extensible = true` with `DefaultImplementation = IEDocumentStatus = "E-Doc In Progress Status"`. This means any new enum value added by an extension defaults to "In Progress" unless it explicitly declares a different implementation.

- E-Documents link to their source BC document via `Document Record ID` (a RecordId field). This is fragile across company renames and data migrations. The `Table ID` field exists separately for FlowField lookups.

- The V2 import pipeline stores state across steps using enum fields on the E-Document record itself (`Structure Data Impl.`, `Read into Draft Impl.`, `Process Draft Impl.`). Each step's output determines which implementation the next step uses. This is a form of runtime dispatch chain.

- `Commit()` is called deliberately before `Codeunit.Run()` in export and send paths. This is the error isolation pattern -- if the format/connector implementation throws a runtime error, the E-Document record survives and the error is logged rather than rolling back everything.

- Duplicate detection uses the combination of `Incoming E-Document No.` + `Bill-to/Pay-to No.` + `Document Date`. The `IsDuplicate` method checks this and logs telemetry. Deleting non-duplicate E-Documents requires user confirmation.

- The `E-Doc. Data Storage` table is a blob store. E-Documents reference it twice: `Unstructured Data Entry No.` (the original received file, e.g. PDF) and `Structured Data Entry No.` (the parsed structured version, e.g. XML). The structuring step may produce a new Data Storage entry, or reuse the original if the document was already structured.

- Mapping (`E-Doc. Mapping` table) works at the RecordRef/FieldRef level. It applies find/replace transformations on field values during export or import, per service. The `For Import` flag distinguishes export mappings from import mappings.

- The `Service Participant` table maps Customer/Vendor codes to external identifiers (PEPPOL participant IDs, etc.) per service. This is how the framework resolves "who does this document go to on the external network."

- V1 integration code is wrapped in `#if not CLEAN26` / `#if not CLEAN27` guards and is being actively removed. The `Service Integration` field (old enum) is obsolete; use `Service Integration V2` instead.
