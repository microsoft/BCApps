# E-Document Core

The E-Document Core app is a plugin framework for electronic document exchange in Business Central. Think of it as a three-layer sandwich: format (how to serialize a BC document into XML/JSON), service (where to send/receive it), and processing (what to do with incoming data). The framework itself ships with PEPPOL BIS 3.0 as a built-in format but does not ship any service connectors -- those come from country-specific extensions and third-party ISVs.

## Quick reference

- ID ranges: 6100-6199, 6208-6209, 6231-6232, 6234
- No external dependencies (foundation layer)
- InternalsVisibleTo: E-Document Core Tests, E-Document AI Tests, E-Document Core Demo Data, Payables Agent, Payables Agent Tests

## How it works

The `E-Document` table (6121) is the central entity that links a Business Central document (via Document Record ID) to its electronic representation. Each e-document flows through a state machine tracked at two levels: the document-level Status and the per-service E-Document Service Status. For outbound, posting a sales/service document triggers e-document creation, the format interface serializes it to a blob, mapping rules apply transformations, and then the service integration sends it over HTTP. For inbound, a service connector polls an external API, downloads documents, and feeds them into an import pipeline.

The inbound import pipeline exists in two versions. V1 (legacy) is a single-step process that directly creates a purchase document. V2 is a four-stage pipeline: Structure (convert PDF to JSON via ADI/MLLM or pass through already-structured XML), Read into Draft (populate staging tables), Prepare Draft (resolve vendors, match items, apply AI), and Finish Draft (create the actual BC document). Each stage is a separate interface implementation that can be swapped per document -- the implementation selectors live as enum fields directly on the E-Document record.

The framework also supports a clearance model (tax authority pre-approval) used by countries like Spain and Italy, batch processing for both send and receive, async response polling, and Copilot-powered order line matching. It does NOT implement any specific country localizations, service connectors, or tax authority integrations -- those are all extension points.

## Structure

- `src/Document/` -- the E-Document table, direction/type enums, status state machines, and the format interface definition
- `src/Service/` -- service configuration, supported document types, service participants (customer/vendor enrollment)
- `src/Integration/` -- IDocumentSender, IDocumentReceiver, context objects (SendContext, ReceiveContext, ActionContext), and the V1 legacy integration interface
- `src/Processing/` -- the core orchestration: export, import pipeline (V1 + V2), order matching, Copilot AI tools, API endpoints, and all processing interfaces
- `src/Processing/Import/` -- V2 import pipeline: structuring, draft read, draft preparation, finish draft, purchase staging tables, PO matching
- `src/Processing/OrderMatching/` -- imported line normalization, match proposals, Copilot matching
- `src/Logging/` -- E-Document Log (state transitions), Integration Log (HTTP pairs), Data Storage (blob storage)
- `src/Mapping/` -- user-defined field mappings with find/replace and transformation rules
- `src/Format/` -- PEPPOL BIS 3.0 export/import implementations, structured format enum
- `src/ClearanceModel/` -- QR code handling for clearance-model countries
- `src/Extensions/` -- table and page extensions to purchase headers, vendors, posted documents, sending profiles, role centers
- `src/Helpers/` -- error helper, import helper, JSON helper, log helper
- `src/DataExchange/` -- data exchange definition integration (alternative to code-based format)

## Documentation

- [docs/data-model.md](docs/data-model.md) -- tables, relationships, and the dual status pattern
- [docs/business-logic.md](docs/business-logic.md) -- outbound/inbound flows, import pipeline, error handling
- [docs/extensibility.md](docs/extensibility.md) -- how to implement formats, connectors, and import processors
- [docs/patterns.md](docs/patterns.md) -- non-obvious architectural patterns and legacy patterns

## Things to know

- The E-Document table is the god object. It has fields for both outbound and inbound, implementation selector enums for all four import stages, clearance model timestamps, and blob storage pointers. Everything hangs off its Entry No.
- There are three parallel state machines: `E-Document.Status` (document-level), `E-Document Service Status.Status` (per-service), and `E-Document Service Status."Import Processing Status"` (import pipeline stage). The import processing status auto-cascades to service status via OnValidate.
- Blob storage is indirect. The E-Document has `Unstructured Data Entry No.` (PDF/binary) and `Structured Data Entry No.` (XML/JSON), both pointing to `E-Doc. Data Storage`. Logs also reference data storage entries. This separation lets blobs have independent lifecycles from log entries.
- V1 and V2 import processes coexist. The `E-Document Service."Import Process"` field determines which path runs. V1 uses the legacy `E-Document Integration` interface. V2 uses the four-stage pipeline with IStructureReceivedEDocument, IStructuredFormatReader, IProcessStructuredData, and IEDocumentFinishDraft.
- Implementation selectors cascade. During Structure, the output can override Read into Draft implementation. During Read into Draft, the output can set the Process Draft implementation. This means the actual code path for an import is determined dynamically, not just by service configuration.
- Draft tables are ephemeral. `E-Document Purchase Header` and `E-Document Purchase Line` are staging areas deleted after Finish Draft creates the real BC document. They have parallel field structures: external fields (raw from sender) and BC-resolved fields (prefixed with `[BC]`).
- SystemId-based linking. The `E-Doc. Record Link` table uses SystemIds (not primary keys) to link draft records to BC records. This survives record renaming but not table recreation.
- The Commit-Run-Log pattern is everywhere. The framework calls Commit() before running interface implementations via Codeunit.Run(), catches failures, and logs errors per document. This allows batch processing to continue when individual documents fail.
- Context objects (SendContext, ReceiveContext, ActionContext) carry HTTP message state, temp blobs, and status. They are the primary data exchange mechanism between framework and connector implementations.
- Historical learning tables (`E-Doc. Purchase Line History`, `E-Doc. Vendor Assign. History`) record past resolutions so future imports can auto-match vendors and line items based on prior decisions.
