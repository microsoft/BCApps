# E-Document Core

E-Document Core provides a bidirectional foundation for electronic invoice exchange in Business Central. It handles both outbound sales documents (export, format, send) and inbound purchase documents (receive, extract, match, create drafts). The architecture is interface-driven with 25+ extensibility points, allowing partners to add new file formats, e-invoice services, and AI-powered matching.

## Quick reference

- **ID range:** 6100-6199 (core), 6360-6385 (PEPPOL), scattered extensions
- **Dependencies:** None (foundation layer)
- **Extension model:** Interface-driven processing, enum registration
- **Country scope:** W1 (worldwide), localization via service implementations

## How it works

E-Document Core implements a bidirectional pipeline. The outbound flow starts when a sales document is posted: the system creates an E-Document record, validates export eligibility, formats the content via IEDocFileFormat interfaces, and sends via IDocumentSender interfaces. Service Status records track each service's processing state independently, allowing one document to be sent to multiple services simultaneously.

The inbound flow is a 4-step state machine: Receive → Structure → Read → Prepare → Finish. When a document arrives via IDocumentReceiver, the system first structures it using IStructureReceivedEDocument, then extracts data using either MLLM (AI-powered extraction via AOAI Function) or ADI (legacy XML path extraction) as fallback. During the Prepare step, Copilot can suggest order matches based on line descriptions. The Finish step creates draft purchase documents that users can review before posting.

Service configuration is decoupled from document lifecycle. An E-Document Service defines connection settings and supported document types, while E-Document Service Status records track processing state per service per document. This 1:N composite pattern means a single E-Document can have multiple status records, one for each service it's processed through.

The generic mapping engine uses RecordRef to transform data between external formats and Business Central records without hardcoded field references. A 3-pass algorithm handles field mappings, formula evaluation, and transformation rules. Order matching combines manual line selection with Copilot-powered suggestions that analyze item descriptions and quantities.

## Structure

- `src/` -- 317 .al files organized by functional area
- `src/Processing/` -- Outbound export and inbound import codeunits
- `src/Copilot/` -- AOAI Function implementation for data extraction and matching
- `src/Service Integration/` -- Interface definitions for sender, receiver, handlers
- `src/OrderMatch/` -- Manual and AI-powered purchase order matching
- `src/Mapping/` -- Generic RecordRef transformation engine
- `src/Extensions/` -- 38 table/page extensions to Customer, Vendor, Sales, Purchase

## Documentation

- [Data model](docs/data-model.md) -- 7 conceptual areas, entity relationships
- [Business logic](docs/business-logic.md) -- Outbound, inbound, matching, mapping flows
- [Extensibility](docs/extensibility.md) -- Interfaces, events, customization patterns
- [Patterns](docs/patterns.md) -- Interface pipeline, state machine, AOAI Function, RecordRef mapping

## Things to know

- **Service Status is composite 1:N** -- One E-Document can have multiple Service Status records (one per service). The header status is calculated from all statuses, not stored.
- **Immutable document records** -- E-Document and Service Status records are append-only; status transitions create new log entries rather than updating fields.
- **SystemId linking** -- E-Document stores SystemId references to source documents (Customer, Sales Header) rather than surrogate keys, enabling cross-table lookups.
- **MLLM→ADI fallback** -- Inbound extraction tries AOAI Function first (IEDocAISystem), falls back to ADI path-based extraction if AI fails or is disabled.
- **4-step import state machine** -- Inbound processing tracks completion: Structure Done → Read Done → Prepare Done → Finish Done. Each step can be undone, resetting subsequent steps.
- **QR clearance via status enum** -- E-Document Service Status includes an "E-Document Clearance Status" enum (Not Verified, Verified, Failed, In Process) for real-time clearance validation.
- **Cascading deletes** -- Deleting an E-Document cascades to Service Status, Logs, Data Storage, and Order Match records via OnDelete triggers.
- **Bill-to/Pay-to Name is snapshot** -- E-Document stores participant names at creation time rather than live references, preserving history even if customer/vendor records change.
- **Temp record staging** -- Inbound drafts populate temporary E-Document Purchase Header/Line records first, allowing multi-step transformation before creating real Purchase Header/Line records.
- **Activity log session accumulation** -- AOAI Function calls append to a single "E-Document Activity Log" session across all processing steps, creating a conversation history for LLM context.
