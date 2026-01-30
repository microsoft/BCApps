# E-Document Batch Export Analysis

## Overview

This document provides a comprehensive analysis of how batch exporting works in e-documents when posting sales documents in Business Central. The e-document functionality enables automatic creation and electronic transmission of documents (invoices, credit memos, shipments) to external systems or regulatory bodies.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Sales Document Posting Flow](#sales-document-posting-flow)
3. [E-Document Creation Process](#e-document-creation-process)
4. [Batch Processing Configuration](#batch-processing-configuration)
5. [Batch Export Execution](#batch-export-execution)
6. [Key Components](#key-components)
7. [Status Workflow](#status-workflow)
8. [Data Flow Diagram](#data-flow-diagram)
9. [Integration Points](#integration-points)
10. [Error Handling](#error-handling)

---

## Architecture Overview

The e-document batch export system consists of several interconnected components:

| Component | Purpose |
|-----------|---------|
| **E-Document Subscribers** | Event handlers that trigger e-document creation after posting |
| **E-Doc. Export** | Core export logic for single and batch document processing |
| **E-Document Background Jobs** | Job queue management for async operations |
| **E-Doc. Recurrent Batch Send** | Scheduled batch processing job |
| **E-Doc. Integration Management** | External integration coordination |
| **E-Document Service** | Configuration for document format and delivery |

### File Locations

```
src/Apps/W1/EDocument/App/src/
├── Processing/
│   ├── EDocExport.Codeunit.al                    # Core export logic
│   ├── EDocumentSubscribers.Codeunit.al          # Event subscribers
│   ├── EDocumentProcessing.Codeunit.al           # Processing utilities
│   └── EDocumentBackgroundJobs.Codeunit.al       # Job scheduling
├── Integration/
│   ├── EDocIntegrationManagement.Codeunit.al     # Integration coordination
│   └── Send/
│       ├── EDocRecurrentBatchSend.Codeunit.al    # Batch sending job
│       ├── SendRunner.Codeunit.al                # Send execution
│       └── SendContext.Codeunit.al               # Send context
├── Service/
│   ├── EDocumentService.Table.al                 # Service configuration
│   ├── EDocumentServiceStatus.Table.al           # Status tracking
│   └── EDocumentBatchMode.Enum.al                # Batch mode options
└── Workflow/
    └── EDocumentWorkFlowProcessing.Codeunit.al   # Workflow integration
```

---

## Sales Document Posting Flow

When a sales document is posted, the following sequence occurs:

### Step 1: Document Posting
The standard Business Central posting process (`Sales-Post` codeunit) handles the sales document posting.

### Step 2: Pre-Posting Validation
**File:** `EDocumentSubscribers.Codeunit.al` (Lines 188-192)

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterCheckAndUpdate', '', false, false)]
local procedure OnAfterCheckAndUpdateSales(var SalesHeader: Record "Sales Header"; ...)
begin
    EDocumentProcessing.RunEDocumentCheck(SalesHeader, EDocumentProcessingPhase::Post);
end;
```

This validates:
- Document Sending Profile configuration
- Workflow enablement
- E-Document Service compatibility

### Step 3: Post-Posting E-Document Creation
**File:** `EDocumentSubscribers.Codeunit.al` (Lines 220-243)

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterPostSalesDoc, '', false, false)]
local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; 
    SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; SalesShptHdrNo: Code[20]; ...)
var
    DocumentSendingProfile: Record "Document Sending Profile";
begin
    // Get customer's Document Sending Profile
    // If no profile is configured for the customer, exit without creating e-document
    if not EDocumentProcessing.GetDocSendingProfileForCust(
        SalesHeader."Bill-to Customer No.", DocumentSendingProfile) then
        exit;  // No e-document flow configured for this customer

    // Create E-Document for posted invoice
    if SalesInvHdrNo <> '' then
        if SalesInvHeader.Get(SalesInvHdrNo) then
            CreateEDocumentFromPostedDocument(SalesInvHeader, DocumentSendingProfile, 
                Enum::"E-Document Type"::"Sales Invoice");
    
    // Similar for Credit Memos and Shipments...
end;
```

**Supported Document Types:**
- Sales Invoice (`"Sales Invoice"`)
- Sales Credit Memo (`"Sales Credit Memo"`)
- Sales Shipment (`"Sales Shipment"`)

---

## E-Document Creation Process

**File:** `EDocExport.Codeunit.al` (Lines 60-98)

### CreateEDocument Procedure Flow

```al
procedure CreateEDocument(DocumentHeader: RecordRef; 
    DocumentSendingProfile: Record "Document Sending Profile"; 
    EDocumentType: Enum "E-Document Type")
```

1. **Workflow Validation**
   - Verifies the workflow exists and is enabled
   - Retrieves associated E-Document Services

2. **E-Document Record Creation**
   - Creates new E-Document record
   - Populates fields from source document
   - Sets status to "In Progress"

3. **Service Status Initialization**
   - For each service supporting the document type:
     - Creates `E-Document Service Status` record with status `Created`

4. **Export Decision (Batch vs Immediate)**
   ```al
   EDocumentServiceStatus.SetRange(Status, EDocumentServiceStatus.Status::Created);
   if EDocumentServiceStatus.FindSet() then
       repeat
           EDocumentService.Get(EDocumentServiceStatus."E-Document Service Code");
           if EDocumentService."Use Batch Processing" then
               continue;  // Skip - will be processed in batch later
           
           ExportEDocument(EDocument, EDocumentService);  // Immediate export
       until EDocumentServiceStatus.Next() = 0;
   ```

5. **Workflow Initiation**
   ```al
   EDocumentBackgroundJobs.StartEDocumentCreatedFlow(EDocument);
   ```

---

## Batch Processing Configuration

### E-Document Service Configuration

**Table:** `E-Document Service` (Table 6103)

Key fields for batch processing:

| Field | Purpose |
|-------|---------|
| `Use Batch Processing` (Boolean) | Enables batch mode for the service |
| `Batch Mode` (Enum) | `Threshold` or `Recurrent` |
| `Batch Start Time` (Time) | Start time for recurrent batch jobs |
| `Batch Minutes between runs` (Integer) | Interval between batch job runs |
| `Batch Recurrent Job Id` (GUID) | ID of the scheduled job queue entry |

### Batch Mode Options

**Enum:** `E-Document Batch Mode` (Enum 6133)

```al
enum 6133 "E-Document Batch Mode"
{
    value(1; Threshold) { }   // Reserved for future threshold-based batching
    value(2; Recurrent) { }   // Batch at scheduled intervals via job queue
}
```

> **Note:** The `Recurrent` mode is the primary batch mode used in the current implementation. Documents are collected and processed based on the configured schedule (start time and interval). The `Threshold` mode is defined in the enum for extensibility but the recurrent scheduling mechanism is the main approach used.

### Configuration Trigger

When `Use Batch Processing` is enabled:

```al
field(5; "Use Batch Processing"; Boolean)
{
    trigger OnValidate()
    begin
        EDocumentBackgroundJobs.HandleRecurrentBatchJob(Rec);
    end;
}
```

This schedules or updates the recurrent job queue entry.

---

## Batch Export Execution

### Job Queue Scheduling

**File:** `EDocumentBackgroundJobs.Codeunit.al` (Lines 40-70)

```al
procedure ScheduleRecurrentBatchJob(var EDocumentService: Record "E-Document Service")
var
    JobQueueEntry: Record "Job Queue Entry";
begin
    JobQueueEntry.ScheduleRecurrentJobQueueEntryWithFrequency(
        JobQueueEntry."Object Type to Run"::Codeunit, 
        Codeunit::"E-Doc. Recurrent Batch Send",           // Codeunit 6142
        EDocumentService.RecordId, 
        EDocumentService."Batch Minutes between runs", 
        EDocumentService."Batch Start Time"
    );
    EDocumentService."Batch Recurrent Job Id" := JobQueueEntry.ID;
    EDocumentService.Modify();
end;
```

### Batch Processing Job

**File:** `EDocRecurrentBatchSend.Codeunit.al` (Codeunit 6142)

The recurrent batch job runs the following process. The code below is simplified pseudo-code to illustrate the flow; refer to the actual source file for complete implementation details:

```al
// PSEUDO-CODE - Simplified for documentation purposes
trigger OnRun()
var
    EDocumentServiceStatus: Record "E-Document Service Status";
    EDocuments: Record "E-Document";
    EntryNumbers: List of [Integer];  // Tracks successfully exported document log entries
    EDocServiceStatus: Enum "E-Document Service Status";
    BeforeExportEDocumentsErrorCount: Dictionary of [Integer, Integer];
    EDocumentListFilter: Text;
    ErrorCount: Integer;
begin
    // 1. Get the E-Document Service from job queue
    EDocumentService.Get(Rec."Record ID to Process");

    // 2. Find all documents with "Pending Batch" status
    EDocumentServiceStatus.SetRange(Status, EDocumentServiceStatus.Status::"Pending Batch");
    EDocumentServiceStatus.SetRange("E-Document Service Code", EDocumentService.Code);
    
    // 3. Build filter for E-Documents using helper procedure
    //    EDocumentWorkFlowProcessing.AddFilter() builds a pipe-separated filter string
    EDocumentServiceStatus.FindSet();
    repeat
        EDocumentWorkFlowProcessing.AddFilter(EDocumentListFilter, 
            Format(EDocumentServiceStatus."E-Document Entry No"));
    until EDocumentServiceStatus.Next() = 0;

    // 4. Process by document type (to group similar documents)
    //    Uses enum ordinals to iterate through all possible document types
    foreach DocumentType in Enum::"E-Document Type".Ordinals() do begin
        EDocuments.SetFilter("Entry No", EDocumentListFilter);
        EDocuments.SetRange("Document Type", DocumentType);
        
        if EDocuments.FindSet() then begin
            // 5. Export batch - creates combined document in TempBlob
            EDocExport.ExportEDocumentBatch(EDocuments, EDocumentService, 
                TempEDocMappingLogs, TempBlob, BeforeExportEDocumentsErrorCount);
            
            // 6. Update status for each document
            EDocuments.FindSet();
            repeat
                // Check if new errors were added during export
                BeforeExportEDocumentsErrorCount.Get(EDocuments."Entry No", ErrorCount);
                if EDocumentErrorHelper.ErrorMessageCount(EDocuments) > ErrorCount then
                    EDocServiceStatus := Enum::"E-Document Service Status"::"Export Error"
                else begin
                    EDocServiceStatus := Enum::"E-Document Service Status"::Exported;
                    EntryNumbers.Add(EDocLog."Entry No.");  // Track for batch storage
                end;
                
                EDocumentLog.InsertLog(EDocuments, EDocumentService, EDocServiceStatus);
                EDocumentProcessing.ModifyServiceStatus(EDocuments, EDocumentService, EDocServiceStatus);
            until EDocuments.Next() = 0;

            // 7. Send batch to integration (only if we have successfully exported documents)
            if EntryNumbers.Count() > 0 then begin
                // Store the batch blob and link to all exported document logs
                EDocDataStorageEntryNo := EDocumentLog.InsertDataStorage(TempBlob);
                foreach EDocLogEntryNo in EntryNumbers do begin
                    EDocLog.Get(EDocLogEntryNo);
                    EDocumentLog.ModifyDataStorageEntryNo(EDocLog, EDocDataStorageEntryNo);
                end;
                
                // Send batch via integration
                EDocIntMgt.SendBatch(EDocuments, EDocumentService, IsAsync);
                
                // Schedule async response checking if needed
                if IsAsync then
                    EDocumentBackgroundJobs.ScheduleGetResponseJob();
            end;
        end;
    end;
end;
```

### Batch Export Logic

**File:** `EDocExport.Codeunit.al` (Lines 188-223)

```al
procedure ExportEDocumentBatch(
    var EDocuments: Record "E-Document"; 
    var EDocService: Record "E-Document Service"; 
    var TempEDocMappingLogs: Record "E-Doc. Mapping Log" temporary; 
    var TempBlob: Codeunit "Temp Blob"; 
    var EDocumentsErrorCount: Dictionary of [Integer, Integer])
begin
    // Iterate through all documents in the batch
    EDocuments.FindSet();
    repeat
        // Get source document
        SourceDocumentHeader.Get(EDocuments."Document Record ID");
        EDocumentProcessing.GetLines(EDocuments, SourceDocumentLines);
        
        // Apply field mappings
        MapEDocument(SourceDocumentHeader, SourceDocumentLines, EDocService, 
            SourceDocumentHeaderMapped, SourceDocumentLineMapped, TempEDocMapping, false);
        
        // Store mapping logs
        if TempEDocMapping.FindSet() then
            repeat
                TempEDocMappingLogs.InitFromMapping(TempEDocMapping);
                TempEDocMappingLogs.Validate("E-Doc Entry No.", EDocuments."Entry No");
                TempEDocMappingLogs.Insert();
            until TempEDocMapping.Next() = 0;
        
        // Track error count before export
        EDocumentsErrorCount.Add(EDocuments."Entry No", 
            EDocumentErrorHelper.ErrorMessageCount(EDocuments));
    until EDocuments.Next() = 0;

    // Create combined batch document
    CreateEDocumentBatch(EDocService, EDocuments, 
        SourceDocumentHeaderMapped, SourceDocumentLineMapped, TempBlob);
end;
```

---

## Key Components

### 1. E-Document Table (Table 6100)

Stores the e-document header information.

| Key Field | Description |
|-----------|-------------|
| `Entry No` | Primary key |
| `Document Record ID` | Reference to source document |
| `Document Type` | Type of document (Invoice, Credit Memo, etc.) |
| `Status` | Overall document status |
| `Direction` | Outgoing or Incoming |
| `Workflow Code` | Associated workflow |

### 2. E-Document Service Status Table (Table 6138)

Tracks the status of each e-document per service.

| Key Field | Description |
|-----------|-------------|
| `E-Document Entry No` | FK to E-Document |
| `E-Document Service Code` | FK to Service |
| `Status` | Service-specific status |

### 3. E-Document Service Status Enum (Enum 6106)

```al
enum 6106 "E-Document Service Status"
{
    value(0;  "Created")                     // Initial state
    value(1;  "Exported")                    // Successfully exported
    value(2;  "Sending Error")               // Send failed
    value(10; "Pending Batch")               // Waiting for batch processing
    value(11; "Export Error")                // Export failed
    value(12; "Pending Response")            // Async - waiting for response
    value(13; "Sent")                        // Successfully sent
    value(14; "Approved")                    // Approved by recipient
    value(15; "Rejected")                    // Rejected by recipient
}
```

---

## Status Workflow

### Immediate Export Flow (Batch Processing Disabled)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Sales Document Posted                                                    │
│         │                                                                 │
│         ▼                                                                 │
│  ┌─────────────┐                                                         │
│  │   Created   │ ─────────────────────────────────────────────────────►  │
│  └─────────────┘                                                         │
│         │                                                                 │
│         ▼                                                                 │
│  ┌─────────────┐    Success    ┌─────────────┐                           │
│  │   Export    │ ─────────────►│  Exported   │                           │
│  └─────────────┘               └─────────────┘                           │
│         │                            │                                    │
│         │ Error                      ▼                                    │
│         ▼                      ┌─────────────┐                           │
│  ┌─────────────┐               │    Send     │                           │
│  │Export Error │               └─────────────┘                           │
│  └─────────────┘                     │                                    │
│                                      │ Async                              │
│                          ┌───────────┴───────────┐                       │
│                          │                       │                        │
│                          ▼                       ▼                        │
│                  ┌───────────────┐      ┌─────────────┐                  │
│                  │Pending Response│     │    Sent     │                  │
│                  └───────────────┘      └─────────────┘                  │
│                          │                                                │
│                          ▼                                                │
│                  ┌─────────────┐                                         │
│                  │  Sent/Error │                                         │
│                  └─────────────┘                                         │
└──────────────────────────────────────────────────────────────────────────┘
```

### Batch Export Flow (Batch Processing Enabled)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Sales Document Posted                                                    │
│         │                                                                 │
│         ▼                                                                 │
│  ┌─────────────┐                                                         │
│  │   Created   │                                                         │
│  └─────────────┘                                                         │
│         │                                                                 │
│         ▼                                                                 │
│  ┌───────────────┐   Job Queue     ┌─────────────┐                       │
│  │ Pending Batch │ ──────────────► │Batch Export │                       │
│  └───────────────┘   (Scheduled)   └─────────────┘                       │
│                                          │                                │
│                               ┌──────────┴──────────┐                    │
│                               │                     │                     │
│                               ▼                     ▼                     │
│                       ┌─────────────┐      ┌─────────────┐               │
│                       │  Exported   │      │Export Error │               │
│                       └─────────────┘      └─────────────┘               │
│                               │                                           │
│                               ▼                                           │
│                       ┌─────────────┐                                    │
│                       │ Batch Send  │                                    │
│                       └─────────────┘                                    │
│                               │                                           │
│                    ┌──────────┴──────────┐                               │
│                    │                     │                                │
│                    ▼                     ▼                                │
│            ┌───────────────┐      ┌─────────────┐                        │
│            │Pending Response│     │    Sent     │                        │
│            │   (Async)      │     │  (Sync)     │                        │
│            └───────────────┘      └─────────────┘                        │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SALES DOCUMENT POSTING                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Sales-Post Codeunit                                                         │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ 1. Posts Sales Document                                                │  │
│  │ 2. Creates Posted Sales Invoice/Credit Memo/Shipment                   │  │
│  │ 3. Fires OnAfterPostSalesDoc event                                     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                     OnAfterPostSalesDoc Event
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  E-Document Subscribers (Codeunit 6103)                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ 1. Gets Document Sending Profile for customer                          │  │
│  │ 2. Calls CreateEDocumentFromPostedDocument()                           │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  E-Doc. Export (Codeunit 6102)                                               │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ 1. Validates workflow configuration                                    │  │
│  │ 2. Creates E-Document record                                           │  │
│  │ 3. Creates E-Document Service Status records                           │  │
│  │ 4. Decision: Batch Processing?                                         │  │
│  │    ├── NO:  ExportEDocument() → Immediate export                       │  │
│  │    └── YES: Status = "Pending Batch" → Wait for job queue              │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                      ┌─────────────┴─────────────┐
                      │                           │
           Immediate Export               Batch Processing
                      │                           │
                      ▼                           ▼
┌──────────────────────────────┐  ┌──────────────────────────────────────────┐
│  ExportEDocument()            │  │  Job Queue Entry                          │
│  ┌─────────────────────────┐  │  │  (E-Doc. Recurrent Batch Send)           │
│  │ • Map document fields   │  │  │  ┌─────────────────────────────────────┐ │
│  │ • Create XML/JSON       │  │  │  │ Scheduled by:                       │ │
│  │ • Store in blob         │  │  │  │ • Batch Start Time                  │ │
│  │ • Status → Exported     │  │  │  │ • Batch Minutes between runs        │ │
│  └─────────────────────────┘  │  │  └─────────────────────────────────────┘ │
└──────────────────────────────┘  └──────────────────────────────────────────┘
                      │                           │
                      │                           ▼
                      │           ┌──────────────────────────────────────────┐
                      │           │  E-Doc. Recurrent Batch Send              │
                      │           │  (Codeunit 6142)                          │
                      │           │  ┌─────────────────────────────────────┐  │
                      │           │  │ 1. Find "Pending Batch" documents   │  │
                      │           │  │ 2. Group by Document Type           │  │
                      │           │  │ 3. ExportEDocumentBatch()           │  │
                      │           │  │ 4. Update statuses                  │  │
                      │           │  │ 5. SendBatch() to integration       │  │
                      │           │  └─────────────────────────────────────┘  │
                      │           └──────────────────────────────────────────┘
                      │                           │
                      └───────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  E-Doc. Integration Management (Codeunit 6134)                               │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ • Send() - Single document                                             │  │
│  │ • SendBatch() - Multiple documents                                     │  │
│  │ • Calls integration interface implementation                           │  │
│  │ • Logs HTTP request/response                                           │  │
│  │ • Handles async response tracking                                      │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  External E-Document Service (API/Web Service)                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Integration Points

### Document Format Interface

**Interface:** `E-Document Format` (Enum 6101)

Implementations must provide:
- `Check()` - Validate document before export
- `Create()` - Generate document content (XML, JSON, etc.)
- `CreateBatch()` - Generate batch document content

### Integration Interface

**Interface:** `IDocumentSender` / `E-Document Integration`

Implementations must provide:
- `Send()` - Send single document
- `SendBatch()` - Send multiple documents
- `GetResponse()` - Check async response status

### Available Integration Types

From the `"Service Integration V2"` field:
- `No Integration` - Export only, no sending
- Custom implementations registered via extension

---

## Error Handling

### Error Tracking

Errors are tracked at multiple levels:

1. **E-Document Level** - Overall document errors
2. **Service Level** - Per-service errors via `E-Document Service Status`
3. **Log Level** - Detailed logs in `E-Document Log` table

### Error Status Values

| Status | Meaning |
|--------|---------|
| `Export Error` | Failed during export phase |
| `Sending Error` | Failed during send phase |
| `Cancel Error` | Failed during cancellation |
| `Approval Error` | Failed during approval |
| `Imported Document Processing Error` | Failed during import processing |

### Error Recovery

The batch job automatically handles:
- **Rerun Delay**: 600 seconds (10 minutes) between retry attempts
- **Error Isolation**: Individual document errors don't fail the entire batch

---

## Configuration Checklist

To enable batch export for sales documents:

1. **Create E-Document Service**
   - Set `Document Format` to appropriate format
   - Set `Service Integration V2` for sending capability
   - Enable `Use Batch Processing`
   - Configure `Batch Start Time` and `Batch Minutes between runs`

2. **Create E-Document Workflow**
   - Create workflow with E-Document events
   - Enable the workflow

3. **Configure Document Sending Profile**
   - Set `Electronic Document` to "Extended E-Document Service Flow"
   - Select the E-Document Workflow

4. **Assign to Customers**
   - Assign Document Sending Profile to customers

5. **Verify Job Queue**
   - Confirm job queue entry is created for batch processing
   - Check job queue status is "Ready"

---

## Summary

The e-document batch export system provides a robust mechanism for:

1. **Automatic Creation**: E-documents are automatically created when sales documents are posted
2. **Flexible Processing**: Supports both immediate and batch export modes
3. **Scheduled Execution**: Batch processing runs on configurable schedules via job queue
4. **Error Resilience**: Individual errors don't prevent batch completion
5. **Status Tracking**: Comprehensive status tracking per document and service
6. **Integration Support**: Extensible integration interface for various external systems

The batch processing mode is particularly useful when:
- External systems have rate limits
- Network costs need to be optimized
- Documents should be grouped for processing efficiency
- Regulatory requirements mandate specific submission windows
