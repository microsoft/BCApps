# Processing engine

The Processing engine orchestrates both outbound export (sales documents to e-invoice format) and inbound import (received documents to purchase drafts). It provides the top-level coordination codeunits (EDocExport, EDocImport) that delegate to specialized subsystems for formatting, sending, structuring, and matching.

## How it works

The outbound flow starts when a sales document is posted with a Document Sending Profile configured for e-document. EDocExport.CreateEDocument creates an E-Document record with "In Progress" status, then for each configured service calls EDocExport.ExportEDocument to format via IEDocFileFormat interfaces and send via IDocumentSender interfaces. Services can use batch processing (accumulate documents) or immediate processing (send on posting). The system creates E-Document Service Status records tracking each service's result independently.

The inbound flow is managed by EDocImport.ProcessIncomingEDocument, which drives a 4-step state machine: Structure (parse blob into structured format), Read (extract data into temp purchase records), Prepare (match to existing purchase orders), and Finish (create final purchase drafts). Each step is executed by ImportEDocumentProcess codeunit, which tracks completion flags on the E-Document record. Users can undo steps to re-run with different parameters, with undo operations cascading to subsequent steps.

Background job support enables scheduled processing. EDocumentBackgroundJobs queues batch export/import operations, processing multiple documents per service in a single job run. This reduces API rate limit pressure and enables off-hours processing for high-volume scenarios.

API endpoints expose E-Documents, Service Status, and file content via OData, enabling external systems to trigger processing, monitor status, and download formatted documents. Business events fire on key transitions (document created, exported, imported, processed) for workflow integration.

## Things to know

- **Dual entry points** -- EDocExport is called from Document Sending Profile posting integration (automatic), while EDocImport can be triggered automatically via ReceiveAndProcessAutomatically or manually per document.
- **Service Status is authoritative** -- The E-Document header status is calculated from child Service Status records, not stored. One document can have multiple statuses (one per service).
- **Batch vs immediate** -- Services with "Use Batch Processing" enabled skip immediate export and are processed later by EDocumentBackgroundJobs codeunit.
- **Import process version** -- Services can specify "Version 1.0" (legacy synchronous processing) or default version (4-step state machine). Version 1.0 bypasses the step-by-step workflow.
- **Undo cascading** -- Undoing "Structure" resets all subsequent flags (Read Done, Prepare Done, Finish Done). Undoing "Prepare" resets Prepare Done and Finish Done but preserves Structure Done and Read Done.
- **Background job isolation** -- Each service has independent job queue entries. Failures in one service's batch do not affect other services.
- **API authentication** -- OData endpoints require standard Business Central OAuth/service-to-service authentication. No separate API keys for e-document operations.
