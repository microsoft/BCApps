# Logging

Three-tier logging infrastructure for E-Documents: document state transitions, HTTP integration traces, and binary data storage. This module owns the audit trail and is used by nearly every other module in the app.

## How it works

`E-Document Log` (`EDocumentLog.Table.al`) records one entry per state transition per service. Each entry captures the service code, status enum, document format, integration version, and an optional reference to `E-Doc. Data Storage` for the document payload. The `E-Document Log` codeunit (`EDocumentLog.Codeunit.al`) provides the insert API and manages the relationship between logs, data storage, and integration logs.

`E-Document Integration Log` (`EDocumentIntegrationLog.Table.al`) stores raw HTTP request/response data as BLOB fields, plus the URL, method, and response status code. One E-Document can have many integration log entries (one per HTTP call). The log codeunit's `InsertIntegrationLog` skips logging when there is no integration configured or when the request URI is empty.

`E-Doc. Data Storage` (`EDocDataStorage.Table.al`) holds binary payloads (XML, JSON, PDF) in a BLOB field with a cached `Data Storage Size` integer and a `File Format` enum implementing `IEDocFileFormat`. Multiple log entries can reference the same Data Storage record -- this is intentional for batch scenarios where one exported blob covers multiple documents. The OnDelete trigger on E-Document Log cleans up the referenced Data Storage only if it exists.

## Things to know

- Document Log entries are immutable by design -- there is no update API, only insert. Each state change creates a new entry.
- The `E-Doc. File Format` enum (`EDocFileFormat.Enum.al`) has four values: Unspecified, PDF, XML, JSON. Each implements `IEDocFileFormat` for format-specific handling during import processing.
- `GetDocumentBlobFromLog` filters by service, integration version, format, and processing status to find the correct log entry. If it fails, it logs telemetry rather than throwing an error.
- `ModifyDataStorageEntryNo` errors if the log entry already has a Data Storage reference -- this prevents accidental overwrites of the blob link.
- Integration log entries store request and response bodies as BLOBs via `TempBlob.ToRecordRef`, not direct BLOB field writes.
- The `InsertDataStorage` method returns 0 (not an error) if the TempBlob has no value, so callers must handle the zero-entry-no case.
- Mapping logs are also written through this codeunit's `InsertMappingLog` method, tying field-level change tracking to specific E-Document Log entries.
