# E-Document Core

E-Document Core is the foundation framework for electronic invoicing in Business Central. It manages the full lifecycle of e-documents -- creating them from posted BC documents (outbound) and receiving them from external services to create purchase documents (inbound). The app itself ships no country-specific formats or service connectors; those are added by localization extensions that plug into its interface-driven architecture.

## Quick reference

- **ID range**: 6100-6199, 6208-6209, 6231-6232, 6234

## How it works

The framework operates in two directions. **Outbound**: when a sales or service document is posted, the Document Sending Profile triggers a workflow that creates an E-Document record, exports it via a format interface (`E-Document Format` enum implementing the `E-Document` interface), optionally applies field mappings, and sends it through a service integration (`Service Integration` enum implementing `IDocumentSender`). **Inbound**: a service integration (`IDocumentReceiver`) fetches documents from an external API, each one becomes an E-Document record, and the V2 import pipeline walks it through structuring, reading into draft, preparing the draft, and finishing the draft to create a real BC purchase document.

The architecture is **interface-driven and polymorphic**. Document formats are plugged in by extending the `E-Document Format` enum (see `src/Document/EDocumentFormat.Enum.al`). Service integrations are plugged in by extending the `Service Integration` enum (see `src/Integration/ServiceIntegration.Enum.al`), which implements `IDocumentSender`, `IDocumentReceiver`, and `IConsentManager`. The V2 import pipeline adds further plug points: `IStructureReceivedEDocument` converts unstructured data (e.g. PDF via Azure Document Intelligence) into structured XML/JSON, `IStructuredFormatReader` reads structured data into draft purchase tables, and provider interfaces (`IItemProvider`, `IVendorProvider`, `IUnitOfMeasureProvider`, etc.) resolve BC entities from raw e-document data.

The **V2 import pipeline** (introduced with `Import Process` = "Version 2.0" on the service) processes inbound documents through five states: Unprocessed, Readable, Ready for draft, Draft Ready, Processed. Each transition corresponds to a step: structure received data, read into draft, prepare draft, finish draft. The pipeline supports undo -- each step can be reverted, moving the document back one state. This is managed in `ImportEDocumentProcess.Codeunit.al`. The draft tables (`E-Document Purchase Header`, `E-Document Purchase Line`) stage data before it becomes a real Purchase Invoice or Credit Memo.

What this app does NOT do: it does not define any concrete e-invoicing format (PEPPOL, FatturaPA, etc.) or any concrete service connector (Pagero, Avalara, etc.). Those are implemented by separate localization or connector extensions that depend on E-Document Core and extend its enums and interfaces. The built-in `E-Document Format` enum ships only "Data Exchange" and "PEPPOL BIS 3.0" as baseline options.

## Structure

- `src/Document/` -- E-Document table, status enums, direction/type enums, the `E-Document` format interface, status strategy codeunits
- `src/Service/` -- E-Document Service configuration table, service status table, supported document types, service participants
- `src/Integration/` -- Service Integration V2 enum, all V2 interfaces (`IDocumentSender`, `IDocumentReceiver`, `IDocumentResponseHandler`, `ISentDocumentActions`, `IDocumentAction`, `IConsentManager`, `IReceivedDocumentMarker`), context objects (`SendContext`, `ReceiveContext`, `ActionContext`), runner codeunits, receive/send orchestration
- `src/Processing/` -- Export, import, document creation, error handling, business events, API endpoints, order matching (V1), Copilot AI matching
- `src/Processing/Import/` -- V2 import pipeline: step/status enums, import process orchestrator, draft tables, header/line mapping, provider codeunits, purchase order matching, history tables, additional field configuration
- `src/Processing/Interfaces/` -- All provider interfaces (`IItemProvider`, `IVendorProvider`, `IUnitOfMeasureProvider`, `IPurchaseOrderProvider`, `IPurchaseLineProvider`), draft lifecycle interfaces (`IPrepareDraft`, `IProcessStructuredData`, `IEDocumentFinishDraft`, `IStructuredFormatReader`, `IStructureReceivedEDocument`), `IExportEligibilityEvaluator`
- `src/Logging/` -- E-Document Log, Integration Log (HTTP request/response), Data Storage (blob), file format enum
- `src/Mapping/` -- Per-service field transformation rules and their execution logs
- `src/Helpers/` -- Error message framework, JSON helper, import helper, log helper
- `src/Extensions/` -- Page extensions on sales, purchase, service, and reminder documents to surface E-Document status; table extensions on Purchase Header, Vendor, Location
- `src/Workflow/` -- Workflow event and response integration for multi-service flows
- `src/ClearanceModel/` -- QR code handling for clearance-model countries
- `src/DataExchange/` -- Data Exchange Definition based format implementation with PEPPOL pre-mapping

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)
- [README.md](README.md) -- Developer guide for building localization extensions (code examples)

## Things to know

- The `E-Document` table uses a **polymorphic `Document Record ID` (RecordId)** field to link to any BC source document -- sales invoice, purchase order, service credit memo, etc. The `Table ID` field stores the table number for display purposes.
- **Three layers of status** exist: document-level (`E-Document Status`: In Progress / Processed / Error), service-level (`E-Document Service Status`: Created, Exported, Sent, Approved, etc.), and import processing status (`Import E-Doc. Proc. Status`: Unprocessed through Processed). The document-level status is derived from service statuses using the `IEDocumentStatus` interface -- each service status enum value maps to an `E-Document Status` via its interface implementation.
- The `E-Document Service Status` enum implements `IEDocumentStatus` on each value, creating a **strategy pattern** where each service status knows its corresponding document status (e.g. "Sending Error" maps to "Error", "Exported" maps to "Processed").
- **Commit-before-interface-call** is a deliberate pattern throughout the codebase. Every `RunSend`, `RunReceiveDocuments`, `RunDownloadDocument`, etc. does `Commit()` before `if not Runner.Run()` so that errors in the external call are caught without rolling back prior database changes. This is the `if Codeunit.Run()` error-trapping pattern in AL.
- The V1 integration interface (`E-Document Integration`) is **obsolete since 26.0**. It used raw `HttpRequestMessage`/`HttpResponseMessage` parameters. V2 uses context objects (`SendContext`, `ReceiveContext`, `ActionContext`) that encapsulate HTTP state and status management.
- **Batch processing** is controlled per-service via `Use Batch Processing` on `E-Document Service`. When enabled, the framework collects multiple E-Documents and calls `CreateBatch` on the format interface and `Send` with a filtered record set containing all documents.
- The `E-Doc. Data Storage` table is the **blob store** -- it holds the actual XML, JSON, or PDF content. It is referenced by `E-Document Log` entries (via `E-Doc. Data Storage Entry No.`), and by E-Document directly (`Structured Data Entry No.`, `Unstructured Data Entry No.`). Deleting a log entry cascades to delete its data storage.
- Inbound documents carry **dual-namespace fields** on draft tables: raw vendor data from the XML/PDF (e.g. `Vendor Company Name`, `Vendor Address`) alongside validated BC fields (e.g. `[BC] Vendor No.`). This allows the user to review what the document says vs. what BC resolved.
- The `E-Doc. Record Link` table provides a **generic link between draft and real BC records** -- it links `E-Document Purchase Header` to `Purchase Header` and `E-Document Purchase Line` to `Purchase Line` using SystemId pairs. This replaces the older `E-Document Link` Guid field on Purchase Header.
- **Historical learning**: After posting a purchase invoice created from an e-document, `E-Doc. Vendor Assign. History` and `E-Doc. Purchase Line History` are written. These records allow the framework (and AI/Copilot) to suggest vendor assignments and line mappings for future documents from the same vendor.
- The `Export Eligibility Evaluator` field on `E-Document Service` implements `IExportEligibilityEvaluator`, letting services control which documents should be exported -- for example, filtering by location or customer for multi-service setups.
- **Business events** `EDocumentStatusChanged` and `EDocumentServiceStatusChanged` (in `EDocumentBusinessEvents.Codeunit.al`) fire on every status change, enabling external webhook integrations via the BC business events API.
