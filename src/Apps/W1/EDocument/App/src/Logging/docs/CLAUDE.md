# Logging

Multi-level audit trail for e-document operations, separating business-level logging (what happened) from HTTP-level logging (what was sent over the wire) with a shared binary blob store underneath both.

## How it works

Every significant operation on an E-Document -- export, send, receive, status check -- creates an `E-Document Log` entry (table 6124) via the `E-Document Log` codeunit (6132). The log records which E-Document, which service, and what status resulted. When the operation produces or consumes a document blob (XML, PDF, JSON), that content goes into `E-Doc. Data Storage` (table 6125) and the log entry references it by entry number.

HTTP-level details go into `E-Document Integration Log` (table 6127). Each API call to an external service logs the request/response bodies as BLOBs, the HTTP method, URL, and response status code. This is only populated when the service has an actual integration configured (not "No Integration").

The `E-Document Log` codeunit is the central entry point. It uses a builder pattern: call `SetFields` to configure the E-Document and service context, optionally call `SetBlob` to attach content, then call `InsertLog` to persist. The codeunit also handles integration log insertion and mapping log insertion in one place.

## Things to know

- `E-Doc. Data Storage` is referenced from multiple places: `E-Document Log.E-Doc. Data Storage Entry No.`, plus `E-Document.Unstructured Data Entry No.` and `Structured Data Entry No.` from the main Document table. Deleting a log entry deletes its associated data storage record via `OnDelete`, but the same blob may be referenced from the E-Document itself.
- Integration log stores request and response as separate BLOBs on the same record, not in Data Storage. This is a different storage pattern from the business log -- integration blobs live inline on the record.
- The `E-Doc. File Format` enum (Unspecified, PDF, XML, JSON) on Data Storage describes the blob content type. It replaced an earlier integer `Data Type` field (removed in v26).
- `ExportDataStorage` on the log table creates a downloadable file named `E-Document_Log_{EntryNo}` -- useful for diagnostics. There is an `OnBeforeExportDataStorage` event if you need to customize the filename.
- The log codeunit has multiple `InsertLog` overloads. The newer builder-style (`SetFields` / `SetBlob` / `ConfigureLogToInsert` / `InsertLog()`) avoids passing many parameters. The older overloads taking all parameters inline still exist for backward compatibility.
- `GetDocumentBlobFromLog` finds the last log entry matching a specific E-Document, service, status, and format, then extracts the blob. It filters to `Processing Status = Unprocessed` to avoid picking up already-consumed entries.
