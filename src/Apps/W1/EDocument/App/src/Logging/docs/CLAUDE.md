# Logging

The Logging module provides the audit trail and binary content storage for the E-Document framework. It consists of three tables -- `E-Document Log` for state change history, `E-Document Integration Log` for HTTP request/response capture, and `E-Doc. Data Storage` for binary content -- plus the `E-Document Log` codeunit that orchestrates their creation and linkage.

## How it works

Every significant state transition in the E-Document lifecycle produces an `E-Document Log` entry (table 6124, `EDocumentLog.Table.al`). The log records the E-Document entry number, the service code, the service status at the time of the event, document format, integration type, and optionally a reference to a `E-Doc. Data Storage` entry containing the document content at that point. Log entries use AutoIncrement for their primary key, creating a strictly chronological sequence.

When the framework communicates with an external service, it creates an `E-Document Integration Log` entry (table 6127, `EDocumentIntegrationLog.Table.al`). This captures the HTTP method, request URL (up to 2048 characters), request body, response body, and response status code. The request and response bodies are stored as BLOB fields directly on the log record, not in the shared Data Storage table. The `InsertIntegrationLog` procedure in the codeunit populates these by reading from `HttpRequestMessage` and `HttpResponseMessage` objects, skipping the entry entirely if the request URI is empty or the service has no integration configured.

The `E-Doc. Data Storage` table (table 6125, `EDocDataStorage.Table.al`) is a shared binary store. Each entry holds a BLOB field, a size integer, a name, and a file format enum (`E-Doc. File Format`). The E-Document table itself points to two Data Storage entries -- one for structured content (e.g., XML) and one for unstructured content (e.g., PDF). Log entries point to a single Data Storage entry representing the document content at that processing stage.

The `E-Document Log` codeunit (codeunit 6132, `EDocumentLog.Codeunit.al`) is the central orchestrator with 30+ procedures. It manages a two-phase pattern for log creation: first call `SetFields` to configure the log template with E-Document and service context, optionally call `SetBlob` to stage binary content in a temporary Data Storage record, then call `InsertLog` to persist both the Data Storage entry and the log entry in one operation. This avoids orphaned Data Storage records if the log insert fails.

## Things to know

- The blob lifecycle follows a specific pattern: processing code works with `TempBlob` (in-memory codeunit), the log codeunit's `InsertDataStorage` persists it to a `E-Doc. Data Storage` record, and the resulting entry number is stamped on the log entry. The `SetBlob` overloads accept Text, TempBlob, or InStream, converting all to the same storage format.

- Deleting an `E-Document Log` entry cascades to its referenced Data Storage entry via the `OnDelete` trigger. Deleting the parent E-Document cascades to all its log entries, integration log entries, and related records via `CleanupDocument`.

- The `GetDocumentBlobFromLog` procedure finds the latest log entry matching specific criteria (E-Document, service, integration, format, status) and extracts its Data Storage content. It filters to `Processing Status = Unprocessed` to avoid retrieving content from already-processed stages. If no matching log is found, it emits a telemetry error ('0000LCE').

- Integration log entries are only created when the service has a non-"No Integration" integration configured -- the codeunit explicitly checks this and exits early otherwise.

- The `InsertMappingLog` procedure on this codeunit writes mapping audit records (from the Mapping module) by iterating a temporary record set of applied mappings and inserting `E-Doc. Mapping Log` entries linked to both the document log entry and the E-Document.

- The `E-Document Log` table's `GetDataStorage` procedure enforces that the caller passes an empty TempBlob (errors on non-empty), preventing accidental data overwrites during content retrieval.

- The `Step Undone` boolean on log entries marks entries created as part of an undo/rollback operation, distinguishing forward progress from corrections in the audit trail.
