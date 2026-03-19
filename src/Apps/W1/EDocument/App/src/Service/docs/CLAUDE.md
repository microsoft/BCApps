# Service

The E-Document Service module defines how documents are formatted, transmitted, and scheduled. Each service record (`EDocumentService.Table.al`, table 6103) pairs a document format implementation with an integration endpoint, then layers on batch processing, auto-import scheduling, and inbound document processing configuration.

## How it works

A service is identified by a `Code[20]` primary key and configures two pluggable dimensions: `Document Format` (an enum selecting the serialization format like PEPPOL or UBL) and `Service Integration V2` (an enum selecting the transport mechanism -- API, file exchange, etc.). When a user selects an integration that is not "No Integration", the system invokes the `IConsentManager` interface on the integration enum to obtain privacy consent before persisting the change.

For outbound documents, the service controls batch processing via `Use Batch Processing`, `Batch Mode`, `Batch Threshold`, and scheduling fields (`Batch Start Time`, `Batch Minutes between runs`). Enabling batch processing automatically creates a recurrent job queue entry (tracked by `Batch Recurrent Job Id`). For inbound documents, `Auto Import` plus `Import Start Time` and `Import Minutes between runs` configure a separate recurrent job (tracked by `Import Recurrent Job Id`). Both job queue entries are cleaned up automatically when the service is deleted.

The service also carries extensive inbound processing configuration: `Import Process` selects between Version 1.0 and 2.0 pipelines, `Automatic Import Processing` controls whether documents are fully processed on arrival or parked for manual review, and `Read into Draft Impl.` selects the strategy for converting structured content into draft purchase documents. A set of boolean flags (`Validate Receiving Company`, `Resolve Unit Of Measure`, `Lookup Item Reference`, `Lookup Item GTIN`, `Lookup Account Mapping`, `Validate Line Discount`, `Apply Invoice Discount`, `Verify Totals`, `Verify Purch. Total Amounts`) governs which validation and enrichment steps run during import.

The `E-Doc. Service Supported Type` table (`EDocServiceSupportedType.Table.al`, table 6122) bridges services to document types -- a service can handle any subset of the `E-Document Type` enum values. The `Service Participant` table (`Participant/ServiceParticipant.Table.al`, table 6104) links customers or vendors to specific services with per-participant identifiers used for electronic addressing (e.g., PEPPOL participant IDs).

## Things to know

- Deleting a service checks `IsServiceUsedInActiveWorkflow` first and blocks deletion if any active workflow references it. It then cascade-deletes all supported type records and removes both recurrent job queue entries.

- The `GetPDFReaderService` procedure auto-creates a hardcoded service with code 'MSEOCADI' for Azure Document Intelligence PDF processing -- this is an internal bootstrap, not user-configurable.

- `GetDefaultImportParameters` returns different defaults depending on the import process version. Version 1.0 always runs to "Finish draft" step; Version 2.0 respects `Automatic Import Processing` to decide whether to fully process or stop at Unprocessed.

- The service's `General Journal Template Name` and `General Journal Batch Name` fields enable routing inbound documents to specific journal batches, with validation that the template type is General, Purchases, Payments, Sales, or Cash Receipts.

- The `Export Eligibility Evaluator` enum field allows plugging in custom logic to determine whether a document qualifies for export through this service, supporting scenarios like conditional routing based on document attributes.

- The `Embed PDF in export` flag triggers automatic PDF generation from Report Selection as a background process during posting, embedding it into the export file.
