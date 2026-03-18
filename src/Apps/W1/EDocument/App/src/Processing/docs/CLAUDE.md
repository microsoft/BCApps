# Processing

The orchestration layer for the E-Document app. Every outbound document export, inbound document import, status transition, and background job flows through codeunits in this directory. It sits between the E-Document data model (tables, logs, services) and the format-specific or integration-specific code, acting as the central coordinator.

## How it works

Outbound flow: when a BC document is posted and has an electronic document sending profile, `EDocExport` creates an `E-Document` record, populates it from the source RecordRef (sales invoice, purchase credit memo, etc.), runs field mappings, invokes the `IEDocument` format interface to produce a blob, logs the result, and kicks off a workflow via `EDocumentBackgroundJobs`. Batch processing is supported -- multiple documents can be exported in a single call.

Inbound flow: `EDocImport` is the entry point. It delegates to `ImportEDocumentProcess` which runs a configurable step-based pipeline (V2) or falls back to the monolithic V1 path. The V2 pipeline walks through statuses -- Unprocessed, Readable, Ready for draft, Draft ready, Processed -- executing or undoing steps as needed. V1 does everything in one shot: parse XML, resolve vendors/items, create purchase documents.

`EDocumentProcessing` is the shared utility. It manages service status records, derives document types from RecordRefs, computes the aggregate E-Document status from per-service statuses ("any error = error, any in-progress = in-progress, else processed"), and provides telemetry dimensions.

## Things to know

- The V1 vs V2 split is driven by `EDocumentService.GetImportProcessVersion()`. V1 code lives in procedures prefixed with `V1_` in `EDocImport`. V2 delegates to `ImportEDocumentProcess` which is in the `Import/` subfolder.

- `EDocRecordLink.Table.al` is a generic SystemId-to-SystemId linking table used by the purchase draft historical mapping. It links draft purchase headers/lines to real Purchase Header/Line records and is cleaned up when the invoice posts.

- `EDocumentBackgroundJobs` schedules via Job Queue. The get-response job runs every 5 minutes. Import and batch export jobs are recurrent and configured per-service with start times and intervals.

- `EDocExport.IsDocumentSupported` checks two things: the document type is in the service's supported type list, AND the `IExportEligibilityEvaluator` interface says it should export. The default evaluator always returns true.

- The `EDocumentCreate` codeunit is a `Codeunit.Run` wrapper -- it exists so that format interface calls can be isolated inside try-function semantics (commit + run + catch last error).

- `EDocumentProcessing.ModifyEDocumentStatus` uses priority: error beats in-progress beats processed. If any service has an error, the whole E-Document is error.

- The `EDocumentSubscribers` codeunit wires into BC posting events (sales, purchase, service documents) to trigger e-document creation automatically.
