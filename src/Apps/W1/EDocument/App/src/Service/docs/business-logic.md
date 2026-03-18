# Service — Business Logic

Service registration orchestrates E-Document lifecycle flows by defining integration endpoints, scheduling parameters, and processing rules. This document describes how services are configured, how batch/import jobs are managed, and how service status tracking enables multi-service routing.

## Core workflows

### Service configuration

1. **Create service record** -- Admin opens E-Document Services page, clicks "New Service", assigns code + description
2. **Select format + integration** -- Choose Document Format enum (PEPPOL, Data Exchange, etc.) and Service Integration V2 enum (HTTP Send, No Integration, etc.)
3. **Configure supported types** -- Navigate to "Configure documents to export" action, add E-Doc. Service Supported Type records for each document type (Sales Invoice, Credit Memo, etc.)
4. **Set batch parameters (outbound)** -- Enable "Use Batch Processing", choose Batch Mode (Threshold or Recurrent), set threshold count or schedule (start time + interval)
5. **Set import parameters (inbound)** -- Enable "Auto Import", configure import schedule, select Import Process version (V1.0 or V2.0), choose Automatic Import Processing mode

### Batch processing lifecycle

1. **OnValidate "Use Batch Processing"** -- EDocumentBackgroundJobs.HandleRecurrentBatchJob() creates or updates job queue entry with "Batch Recurrent Job Id" GUID
2. **Recurrent mode** -- Job runs at "Batch Start Time", repeats every "Batch Minutes between runs", calls EDoc Recurrent Batch Send codeunit
3. **Threshold mode** -- Each export sets status to "Pending Batch"; when count >= "Batch Threshold" for same document type + sending profile, DoBatchSend() triggers
4. **Batch export** -- EDocExport.ExportEDocumentBatch() exports all pending documents into single TempBlob, EDocIntMgt.SendBatch() transmits
5. **OnDelete cleanup** -- EDocBackgroundJobs.RemoveJob(Rec."Batch Recurrent Job Id") cancels job queue entry

### Auto-import scheduling

1. **OnValidate "Auto Import"** -- EDocumentBackgroundJobs.HandleRecurrentImportJob() schedules job with "Import Recurrent Job Id"
2. **Import job runs** -- At "Import Start Time", repeats every "Import Minutes between runs", calls E-Document Import Job codeunit
3. **Receive + process** -- Calls IDocumentReceiver.ReceiveDocuments(), creates E-Document records, optionally triggers automatic processing based on "Automatic Import Processing" enum
4. **Processing step selection** -- GetDefaultImportParameters() returns step-to-run based on Import Process version + auto-processing flag
5. **OnDelete cleanup** -- Removes import job via RemoveJob(Rec."Import Recurrent Job Id")

### Service status tracking

1. **Create status on first service interaction** -- When E-Document is exported/imported via service, EDocumentProcessing.ModifyServiceStatus() inserts E-Document Service Status record
2. **Status transitions logged** -- Each status change (Exported → Sent → Pending Response → Approved) inserts E-Document Log entry with Status + Processing Status + timestamp
3. **Multi-service routing** -- One E-Document can have N Service Status records (one per service); header status calculated via IEDocumentStatus interface aggregating all statuses
4. **Drill-down to logs** -- Status.ShowLogs() filters E-Document Log by Entry No + Service Code; Status.ShowIntegrationLogs() filters E-Document Integration Log
5. **Cascade delete** -- Deleting Service Status does NOT delete logs (logs remain for audit trail)

## Key procedures

### E-Document Service

- **GetPDFReaderService()** -- Returns/creates singleton "MSEOCADI" service for Azure Document Intelligence PDF extraction (Import Process = V2.0, no auto-processing)
- **IsAutomaticProcessingEnabled()** -- Returns true if Automatic Import Processing = Yes; used to determine whether to auto-create purchase drafts
- **GetImportProcessVersion()** -- Returns Import Process enum (V1.0 or V2.0); controls whether to use legacy path-based extraction or new draft-based flow
- **GetDefaultImportParameters()** -- Builds E-Doc. Import Parameters record with step-to-run, desired status, and customization flags based on service settings
- **LastEDocumentLog(status)** -- Filters logs by service code + status, returns most recent entry (used to check last import/export result)
- **GetDefaultFileExtension()** -- Returns '.xml' by default; extensible via OnAfterGetDefaultFileExtension event for custom formats (e.g., JSON, CSV)

### E-Document Service Status

- **Logs()** -- Counts E-Document Log entries for this service/document pair; displayed as drillable field on status page
- **ShowLogs()** -- Opens E-Document Logs page filtered by Service Code + Entry No
- **IntegrationLogs()** -- Counts HTTP request/response logs (E-Document Integration Log) for this service/document
- **ShowIntegrationLogs()** -- Opens E-Document Integration Logs page with drill-down to request/response blobs

### E-Document Workflow Processing integration

- **IsServiceUsedInActiveWorkflow()** -- Iterates enabled workflows, checks if any WorkflowStepArgument references this service code; blocks deletion if true
- **GetServicesFromEntryPointResponseInWorkflow()** -- Returns filter of all E-Document Services referenced in workflow entry point responses (used to validate workflow setup)
- **DoesFlowHasEDocService()** -- Checks if specified workflow code contains any E-Document service references in response arguments

## Validation rules

- **Service Integration V2 consent required** -- OnValidate checks if previous value = "No Integration"; if changing to external integration, calls IConsentManager.ObtainPrivacyConsent()
- **General Journal Template Type restriction** -- Only allows General, Purchases, Payments, Sales, or Cash Receipts template types (error if Assets, Fixed Assets, etc.)
- **General Journal Batch must not be recurring** -- TestField(Recurring, false) on batch validation
- **Batch Threshold minimum value** -- MinValue = 1 (cannot batch single document)
- **Time fields not blank** -- Import Start Time, Batch Start Time use InitValue = 0T, NotBlank = true
- **Service code length** -- Max 20 characters (Code[20] type)

## Integration points

- **OnAfterGetDefaultFileExtension(service, extension)** -- Allows external code to override default '.xml' file extension (e.g., for JSON exports)
- **OnBeforeOpenServiceIntegrationSetupPage(service, isRun)** -- Allows external setup page invocation before default "no configuration" message
- **Workflow events** -- Service deletion checks active workflow usage via IsServiceUsedInActiveWorkflow(); prevents orphaned workflow step arguments

## Error handling

- **ServiceInActiveFlowErr** -- Raised OnDelete if service used in enabled workflow; user must disable workflow or remove service reference first
- **TemplateTypeErr** -- Raised if General Journal Template Type not in allowed set (General, Purchases, Payments, Sales, Cash Receipts)
- **Non-recurring batch validation** -- TestField(Recurring, false) prevents use of recurring journal batches for E-Document journal line creation

## Performance notes

- **Service Status is indexed by Status + Service Code** -- Key2 enables fast lookup of all documents in "Pending Batch" status for threshold batching
- **Logs/IntegrationLogs are counted on demand** -- Not stored as fields; calculated via Count() when displaying status page (avoids maintaining counters)
- **Background job GUID linking** -- Batch/Import job IDs stored directly on service record for O(1) cleanup on deletion (no table scan)
- **Supported Type junction table** -- Indexed by Service Code + Document Type for fast eligibility checks during document posting
