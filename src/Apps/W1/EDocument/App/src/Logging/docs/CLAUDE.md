# Logging

Audit trail for the entire e-document lifecycle. Three main tables plus a
mapping log, managed through the `E-Document Log` codeunit.

## E-Document Log

The primary log table. Each entry records a status transition for a
specific e-document + service combination. Fields include document type,
document number, service code, integration type, format, and a pointer
to the `E-Doc. Data Storage` entry that holds the document content at
that point. Multiple log entries per e-document are normal -- one for
each processing step (exported, sent, imported, error, etc.).

## E-Doc. Data Storage

BLOB storage for document content (XML, PDF, JSON). Each row holds a
binary payload with a size, name, and `File Format` enum value. Log
entries reference data storage by entry number. Multiple log entries can
share the same data storage entry (e.g. in batch processing where one
exported blob covers several e-documents). Deleting a log entry cascades
to delete its data storage record, so do not delete data storage rows
directly -- let the log cleanup handle it.

## E-Document Integration Log

HTTP-level audit trail. Each entry stores the request URL, method, request
body BLOB, response body BLOB, and response status code. Only populated
when a service integration actually makes HTTP calls (skipped for
"No Integration"). Entries link to the e-document and service code. Use
the export actions to download request/response bodies for debugging.

## E-Doc. Mapping Log

Records field-level transformations applied during export or import. Each
row captures the table, field, original value, and replacement value,
linked to the parent E-Document Log entry. Only populated when mappings
are configured and actually change a value.

## E-Doc. File Format enum

Specifies the binary format of data storage content: Unspecified, PDF,
XML, or JSON. Each value implements the `IEDocFileFormat` interface, which
controls how the stored content can be viewed or processed downstream.

## Log codeunit

`E-Document Log` (codeunit 6132) centralizes all insert operations. It
manages data storage creation, log entry creation, integration log
insertion, and mapping log insertion. It also provides
`GetDocumentBlobFromLog` which retrieves the stored blob for a given
e-document + service + status combination -- used when re-processing or
viewing document content.
