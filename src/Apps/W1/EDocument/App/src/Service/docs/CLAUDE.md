# Service

The E-Document Service (`EDocumentService.Table.al`) is the central configuration record that binds together a document format, an integration connector, batch settings, and import behavior for a specific e-document exchange channel. Each service defines how documents are exported, sent, received, and processed. Adjacent modules (Workflow, Logging, Format) all reference a service by its Code.

## How it works

A service record stores which format implementation to use (`Document Format` enum), which connector to use (`Service Integration V2` enum), and a rich set of import-processing flags (resolve UoM, lookup item reference, lookup GTIN, validate line discount, etc.). The `Import Process` field selects between V1 and V2 processing architectures -- V1 uses the legacy `IEDocument` interface flow while V2 uses the newer structured-data pipeline with draft documents. This choice fundamentally changes which codeunits handle inbound documents.

`E-Doc. Service Supported Type` is a simple N:M junction table that links services to document types (Sales Invoice, Credit Memo, etc.). `E-Document Service Status` tracks per-service progress for each E-Document with a rich enum of ~24 states, compared to the 3-state status on the E-Document header itself. The `Service Participant` table (`Participant\ServiceParticipant.Table.al`) associates customers or vendors with a service using a service-specific identifier (e.g., a PEPPOL endpoint ID), enabling participant resolution during import.

## Things to know

- Toggling `Use Batch Processing` or `Auto Import` immediately creates or removes Job Queue entries via `EDocumentBackgroundJobs` -- this is not deferred.
- Changing `Service Integration V2` away from "No Integration" triggers a privacy consent dialog; if the user declines, the change is silently reverted.
- Deleting a service that is referenced by an active workflow raises an error. The OnDelete trigger also cleans up all supported types and background jobs.
- Batch mode (`EDocumentBatchMode.Enum.al`) is extensible -- Threshold and Recurrent are built-in, but custom modes can be added and handled via the `OnBatchSendWithCustomBatchMode` event.
- `GetPDFReaderService` auto-creates a hardcoded Azure Document Intelligence service record (`MSEOCADI`) for PDF import if it does not exist.
- The old `Service Integration` enum field (V1) is obsolete since 26.0 and removed in 29.0; the `#if CLEAN26` guards manage the transition.
- Import-related fields (start time, minutes between runs) all re-schedule the recurrent job on every validate, so editing these fields has an immediate side effect.
- The `Export Eligibility Evaluator` enum field allows services to plug in custom logic for deciding whether a posted document should be exported, without modifying the core posting flow.
