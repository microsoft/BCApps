# Logging

Audit trail infrastructure for E-Document lifecycle events. Tracks status transitions, HTTP requests/responses, and data transformations via three log tables: E-Document Log (status history), E-Document Integration Log (HTTP audit), and E-Doc. Data Storage (blob archive). Provides drill-down navigation from documents to logs to stored payloads.

## Quick reference

- **Parent:** [`src/`](../../CLAUDE.md)
- **Files:** 7 .al files
- **Key objects:** E-Document Log (codeunit + table + page), E-Document Integration Log (table + page), E-Doc. Data Storage (table)
- **Entry points:** E-Document Log codeunit (6132) for programmatic logging, pages 6125/6126 for UI drill-down

## How it works

The logging system uses a builder pattern via E-Document Log codeunit. Callers first call SetFields(EDocument, Service) to populate core fields (Entry No, Service Code, Document Type, etc.), then optionally call SetBlob() to attach payload data (XML, JSON, PDF), then call InsertLog(status) to commit the log entry. The SetBlob() call stages data in a temporary E-Doc. Data Storage record, which InsertLog() persists and links via "E-Doc. Data Storage Entry No." foreign key.

HTTP integration logging happens automatically when EDocIntMgt.Send() executes—after HttpClient.Send(), the system calls InsertIntegrationLog(EDocument, Service, HttpRequest, HttpResponse), which extracts request/response content and stores it in E-Document Integration Log with method, URL, status code, and request/response blobs.

E-Document Log records form an append-only audit trail. Each status transition (Processing → Exported → Sent → Approved) creates a new log entry rather than updating an existing record. The GetDocumentBlobFromLog() method retrieves the most recent blob for a given status by filtering on E-Doc Entry No + Service Code + Status and calling FindLast().

Data Storage entries are shared across log entries when multiple documents are batched—InsertDataStorage(TempBlob) returns an Entry No that can be linked to multiple E-Document Log records via ModifyDataStorageEntryNo(). This avoids duplicating large XML payloads when 50 invoices are exported in a single batch.

Processing Status enum tracks inbound import progress (Unprocessed → Processing → Processed) separately from Service Status enum (Imported → Imported Document Created). The "Step Undone" flag marks log entries created when users click "Undo" actions, reverting import steps.

## Key files

- **EDocumentLog.Codeunit.al** -- Builder pattern API: SetFields(), SetBlob(), ConfigureLogToInsert(), InsertLog(), InsertDataStorage(), InsertIntegrationLog()
- **EDocumentLog.Table.al** -- Log entry record with Status, Processing Status, Step Undone, FK to Data Storage
- **EDocumentLogs.Page.al** -- List page with ExportDataStorage action, drill-down to mapping logs
- **EDocumentIntegrationLog.Table.al** -- HTTP request/response audit with URL, method, status code, request/response blobs
- **EDocumentIntegrationLogs.Page.al** -- HTTP log viewer with blob content display
- **EDocDataStorage.Table.al** -- Blob storage with Name, File Format enum (XML, JSON, PDF), Data Storage Size
- **EDocFileFormat.Enum.al** -- File format classification (XML, JSON, PDF, TXT)

## Things to know

- **InsertLog() resets Entry No + Data Storage Entry No** -- After inserting, caller can reuse codeunit instance for next log by calling SetFields() again (builder pattern allows chaining)
- **ConfigureLogToInsert() enables parameterless InsertLog()** -- Stores status + processing status + undo flag in codeunit state, next InsertLog() call uses stored values (useful when logging from event subscribers)
- **GetDocumentBlobFromLog() returns log record as out param** -- Enables caller to inspect Status, Processing Status, timestamp after retrieving blob
- **ModifyDataStorageEntryNo() errors if already set** -- EDocDataStorageAlreadySetErr prevents overwriting existing blob link (ensures audit trail immutability)
- **OnDelete trigger cascades to Data Storage** -- Deleting log entry calls DeleteRelatedDataStorage(EntryNo), removes orphaned blob (but only if no other logs reference it)
- **InsertIntegrationLog() skips if no URL** -- If HttpRequest.GetRequestUri() = '', exits early (prevents empty log spam during local processing)
- **InsertIntegrationLog() checks Service Integration enum** -- If service = "No Integration", skips HTTP logging (no external calls made)
- **InsertMappingLog() transfers temp mapping changes** -- Copies E-Doc. Mapping records from temp buffer to permanent E-Doc. Mapping Log with FK to log entry
- **GetLastServiceFromLog() returns most recent service** -- FindLast() on logs ordered by Entry No, returns service code (used during import to resume processing)
- **CanHaveMappingLogs()** -- Returns true only if Status = Exported or Imported (mapping transformations only happen during export/import, not send/receive)

## Integration points

- **OnBeforeExportDataStorage(log, filename)** -- Allows external code to modify filename before DownloadFromStream() (e.g., append timestamp, sanitize illegal characters)
- **TempBlob.ToRecordRef() integration** -- InsertDataStorage() uses ToRecordRef(RecRef, FieldNo) to copy blob from TempBlob to Data Storage without loading into memory twice
- **Error Message framework** -- E-Document Error Helper wraps Error Message table, storing validation errors with context Record ID = E-Document.RecordId()

## Error handling

- **EDocDataStorageAlreadySetErr** -- Raised if ModifyDataStorageEntryNo() called on log with non-zero Data Storage Entry No (prevents overwrite)
- **NonEmptyTempBlobErr** -- Raised if GetDataStorage() called with TempBlob already containing data (prevents accidental merge)
- **EDocLogEntryNoExportMsg** -- Raised if ExportDataStorage() called on log with Data Storage Entry No = 0 (no blob to export)
- **Developer error if InsertLog() without config** -- If InsertLog() called without SetFields() or ConfigureLogToInsert(), raises locked label error

## Performance notes

- **Data Storage shared across batch entries** -- InsertDataStorage(TempBlob) returns Entry No referenced by N log entries, avoiding blob duplication
- **SetAutoCalcFields("Data Storage")** -- GetDocumentBlobFromLog() explicitly loads blob field only when needed (not on list page display)
- **SetLoadFields("E-Doc. Entry No", Status)** -- Filters log queries with minimal field loading for performance (only loads PK + Status)
- **Key2 includes Status in IncludedFields** -- Indexed covering index for filtering + sorting by status without table lookups
- **InsertIntegrationLog uses RecordRef** -- Avoids loading entire EDocumentIntegrationLog record into memory when writing blobs (writes directly to blob field via FieldRef)
