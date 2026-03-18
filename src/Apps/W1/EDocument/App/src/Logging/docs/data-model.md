# Logging — Data Model

Audit trail storage for E-Document lifecycle events, HTTP communications, and data transformations. Three-table design separates status history (E-Document Log), HTTP audit (Integration Log), and payload storage (Data Storage) with shared blob references.

## Core entities

### E-Document Log (table 6124)

Append-only audit trail of status transitions and processing steps.

**Key fields:**
- `Entry No.` (PK, AutoIncrement) -- Unique log entry identifier
- `E-Doc. Entry No` (int) -- FK to E-Document parent
- `Service Code` (Code[20]) -- FK to E-Document Service used for this operation
- `E-Doc. Data Storage Entry No.` (int) -- FK to E-Doc. Data Storage (optional, links to payload blob)
- `E-Doc. Data Storage Size` (FlowField) -- Lookup to Data Storage."Data Storage Size" (for UI display)
- `Status` (enum) -- E-Document Service Status (Processing, Exported, Sent, Pending Response, Approved, Rejected, etc.)
- `Service Integration V2` (enum) -- Copy of service's integration type at log time (audit trail)
- `Document Format` (enum) -- Copy of service's format (PEPPOL, Data Exchange, etc.)
- `Document Type` (enum) -- E-Document Type (Sales Invoice, Purchase Invoice, etc.)
- `Document No.` (Code[20]) -- Document number for filtering
- `Processing Status` (enum) -- Import processing state (Unprocessed, Processing, Processed)
- `Step Undone` (bool) -- True if this log entry records an undo action (reverting import step)

**Keys:**
- Primary: `Entry No.` (clustered, AutoIncrement)
- Secondary: `E-Doc. Entry No` (includes Status in IncludedFields for fast filtering)
- Secondary: `Status` + `Service Code` + `Document Format` + `Service Integration V2` (for batch job queries)

**Relationships:**
- N:1 → E-Document (parent document)
- N:1 → E-Document Service (service configuration)
- N:1 → E-Doc. Data Storage (optional payload reference, shared across logs)
- 1:N ← E-Doc. Mapping Log (data transformation audit)

**Triggers:**
- `OnDelete` -- Calls DeleteRelatedDataStorage(EntryNo) to cascade delete Data Storage if no other logs reference it

**Calculated methods:**
- `ExportDataStorage()` -- Downloads blob as file via DownloadFromStream()
- `GetDataStorage(out TempBlob)` -- Retrieves blob from Data Storage into TempBlob
- `CanHaveMappingLogs()` -- Returns true if Status = Exported or Imported (only these statuses perform mapping transformations)

### E-Document Integration Log (table 6126)

HTTP request/response audit trail for external service calls.

**Key fields:**
- `Entry No.` (PK, AutoIncrement) -- Unique integration log entry
- `E-Doc. Entry No` (int) -- FK to E-Document
- `Service Code` (Code[20]) -- FK to E-Document Service
- `Response Status` (int) -- HTTP status code (200, 401, 500, etc.)
- `Request URL` (Text[2048]) -- Full HTTP endpoint URL
- `Method` (Text[50]) -- HTTP verb (GET, POST, PUT, etc.)
- `Request Blob` (Blob) -- HTTP request body (JSON, XML, form data)
- `Response Blob` (Blob) -- HTTP response body

**Keys:**
- Primary: `Entry No.` (clustered, AutoIncrement)
- Secondary: `Service Code` + `E-Doc. Entry No` (for drill-down from E-Document Service Status)

**Relationships:**
- N:1 → E-Document
- N:1 → E-Document Service

**Usage:**
- Logged automatically by E-Document Log codeunit after HttpClient.Send() completes
- Only logged if Service Integration ≠ "No Integration" and Request URL not blank
- Request/response blobs written via RecordRef to avoid memory overhead

### E-Doc. Data Storage (table 6136)

Blob storage for E-Document payloads (XML, JSON, PDF attachments).

**Key fields:**
- `Entry No.` (PK, AutoIncrement) -- Unique storage entry
- `Name` (Text[256]) -- Filename or description (e.g., "E-Document_Export_12345.xml")
- `Data Storage` (Blob) -- Payload content
- `Data Storage Size` (int) -- Blob length in bytes
- `File Format` (enum) -- E-Doc. File Format (XML, JSON, PDF, TXT)

**Keys:**
- Primary: `Entry No.` (clustered, AutoIncrement)

**Relationships:**
- 1:N ← E-Document Log (Data Storage Entry No FK, many logs can share one blob)

**Usage:**
- Shared blob references for batch exports (N invoices → 1 XML payload → 1 Data Storage entry → N log entries)
- Cascade delete via OnDelete trigger in E-Document Log (only if no other logs reference this Entry No)

### E-Doc. Mapping Log (table 6137)

Data transformation audit recording field mappings applied during export/import.

**Key fields:**
- `Entry No.` (PK, AutoIncrement) -- Unique mapping log entry
- `E-Doc Log Entry No.` (int) -- FK to E-Document Log parent
- `E-Doc Entry No.` (int) -- FK to E-Document (denormalized for filtering)
- `Table ID` (int) -- Target table modified (e.g., 38 = Purchase Header)
- `Field ID` (int) -- Target field modified (e.g., 79 = "Buy-from Vendor No.")
- `Find Value` (Text[250]) -- Original value before mapping
- `Replace Value` (Text[250]) -- Transformed value after mapping

**Keys:**
- Primary: `Entry No.` (clustered, AutoIncrement)
- Secondary: `E-Doc Log Entry No.` (for drill-down from log entry)
- Secondary: `E-Doc Entry No.` (for aggregate view across all logs)

**Relationships:**
- N:1 → E-Document Log (parent log entry)
- N:1 → E-Document (denormalized for filtering)

**Usage:**
- Inserted via E-Document Log.InsertMappingLog(LogEntry, TempMappingRecords)
- Transfers temp E-Doc. Mapping records to permanent Mapping Log table
- Only created for logs with Status = Exported or Imported (CanHaveMappingLogs() check)

### E-Doc. File Format (enum 6136)

File format classification for Data Storage blobs.

**Values:**
- `XML` (0) -- XML documents (PEPPOL, UBL, custom schemas)
- `JSON` (1) -- JSON payloads
- `PDF` (2) -- PDF attachments (embedded in export or received separately)
- `TXT` (3) -- Plain text files

**Usage:**
- Stored in Data Storage.File Format for UI display and MIME type determination
- Influences download filename extension in ExportDataStorage()

## Relationships

```
E-Document (1) ───────┬────── (N) E-Document Log
                       │              ├─ Status (enum): Processing → Exported → Sent → Approved
                       │              ├─ Processing Status (enum): Unprocessed → Processing → Processed
                       │              ├─ Step Undone (bool): marks undo actions
                       │              │
                       │              ├───── (N:1) E-Doc. Data Storage (shared blob reference)
                       │              │              └─ File Format (enum): XML, JSON, PDF, TXT
                       │              │
                       │              └───── (1:N) E-Doc. Mapping Log
                       │                            ├─ Table ID, Field ID
                       │                            └─ Find Value → Replace Value
                       │
                       └────── (N) E-Document Integration Log
                                      ├─ Request URL, Method
                                      ├─ Response Status (HTTP code)
                                      ├─ Request Blob
                                      └─ Response Blob
```

## Field usage patterns

### Log entry creation lifecycle

1. **SetFields(EDocument, Service)** -- Populates Entry No, Service Code, Document Type, Document No., Service Integration V2, Document Format
2. **SetBlob(name, format, content)** -- Stages TempDataStorageEntry with Name, File Format, Data Storage Size, blob content
3. **ConfigureLogToInsert(status, procStatus, undoStep)** -- Stores Status, Processing Status, Step Undone in codeunit state (optional, alternative to explicit params)
4. **InsertLog(status, procStatus, undoStep)** -- Calls InsertDataStorage(TempDataStorageEntry) if blob staged, returns Entry No, inserts E-Document Log record
5. **InsertMappingLog(log, tempMappings)** -- Copies temp E-Doc. Mapping records to E-Doc. Mapping Log with FK to log Entry No

### Integration log creation lifecycle

1. **EDocIntMgt.Send() executes** -- HttpClient.Send(request, response)
2. **InsertIntegrationLog(EDocument, Service, request, response)** -- Extracts URL, method, status code
3. **Check Service Integration** -- If "No Integration", exit early (no HTTP call made)
4. **Insert record** -- E-Doc. Entry No, Service Code, Response Status, Request URL, Method
5. **Write request blob** -- InsertIntegrationBlob(RecRef, requestText, FieldNo(Request Blob))
6. **Write response blob** -- InsertIntegrationBlob(RecRef, responseText, FieldNo(Response Blob))
7. **Modify record** -- RecRef.Modify() commits both blobs

### Data Storage sharing pattern

1. **Batch export** -- EDocExport.ExportEDocumentBatch() exports 50 invoices into single XML TempBlob
2. **InsertDataStorage(TempBlob)** -- Returns Entry No = 1001
3. **Loop 50 documents** -- For each EDocument, InsertLog() calls ModifyDataStorageEntryNo(log, 1001)
4. **Result** -- 50 E-Document Log entries, all with Data Storage Entry No = 1001, referencing same XML blob
5. **Cascade delete** -- Deleting any log entry checks if other logs reference 1001; only deletes blob if last reference removed

## Composite key patterns

**E-Document Log enables fast filtering:**
- Key2 (E-Doc. Entry No) with IncludedFields = Status -- O(1) drill-down from E-Document to logs, filter by status without table scans
- Key4 (Status, Service Code, Document Format, Service Integration V2) -- Enables batch job queries like "all logs with Status = 'Pending Batch' for Service Code = 'PEPPOL'"

**E-Document Integration Log clusters by service:**
- Key2 (Service Code, E-Doc. Entry No) -- Fast drill-down from E-Document Service Status to HTTP logs

**E-Doc. Mapping Log dual indexing:**
- Key2 (E-Doc Log Entry No.) -- Drill-down from log entry to transformations
- Key3 (E-Doc Entry No.) -- Aggregate view of all mappings applied to document across all logs

## Performance notes

- **AutoIncrement primary keys** -- All log tables use identity columns for fast inserts without contention
- **Blob fields not autoloaded** -- CalcFields("Data Storage") required to load blob content (list pages don't load blobs)
- **SetLoadFields() minimizes data transfer** -- GetDocumentBlobFromLog() uses SetLoadFields("E-Doc. Entry No", Status) to fetch only PK + filter fields
- **RecordRef blob writes avoid memory copies** -- InsertIntegrationLog() uses RecordRef.GetTable() + TempBlob.ToRecordRef() to write blobs without loading entire record
- **Data Storage shared references reduce storage** -- Batch export of 100 invoices stores 1 XML blob instead of 100 duplicate copies
- **Cascade delete checks reference count** -- OnDelete in E-Document Log queries if other logs reference Data Storage Entry No before deleting blob (prevents orphans but allows sharing)
