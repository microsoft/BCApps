# Endpoints — Business Logic

REST API access patterns for E-Document monitoring, file retrieval, and external workflow integration. This document describes API query patterns, data relationships, and integration scenarios.

## Core workflows

### Query document by SystemId

1. **External system receives webhook** -- E-Document processing completes, webhook sends SystemId to external system
2. **Query single document** -- `GET /eDocuments({systemId})`
3. **Response includes header fields** -- Entry No, Document No, Status, Amounts, Dates, Bill-to/Pay-to No., etc.
4. **Expand service status** -- Add `?$expand=edocumentServiceStatus` to include nested Service Status records
5. **Parse response** -- Extract status, check for errors, route to appropriate handler

### Poll for new inbound documents

1. **External workflow system polls API** -- `GET /newEDocuments?$filter=status eq 'Unprocessed'`
2. **Response returns inbound documents** -- Direction = Incoming, Status = Unprocessed (awaiting user action)
3. **For each document, retrieve file content** -- Use Entry No to query logs, extract Data Storage Entry No, download blob via `/eDocFileContents`
4. **Send to approval system** -- POST to external approval API with SystemId + file content
5. **Approval callback** -- External system calls Business Central webhook or custom codeunit to approve/reject

### Monitor document processing status

1. **Dashboard queries all documents** -- `GET /eDocuments?$filter=postingDate ge {startDate}` (e.g., last 7 days)
2. **Expand service status** -- `?$expand=edocumentServiceStatus` to include per-service statuses
3. **Group by status** -- Count documents in each status bucket (Exported, Sent, Approved, Error)
4. **Drill down on errors** -- Filter `?$filter=status eq 'Error'` to show error list
5. **Retrieve error details** -- Query E-Document Logs via custom integration (not exposed in API) or use Business Central web client link

### Download archived file content

1. **Query E-Document** -- `GET /eDocuments({systemId})`
2. **Extract Entry No** -- From response: `entryNumber` field
3. **Query logs for Data Storage Entry No** -- Custom integration queries E-Document Log table filtered by Entry No + Status = 'Sent', extracts "E-Doc. Data Storage Entry No."
4. **Query file metadata** -- `GET /eDocFileContents?$filter=entryNo eq {storageEntryNo}`
5. **Extract SystemId** -- From response: `systemId` field
6. **Download blob** -- `GET /eDocFileContents({systemId})/dataStorage/$value` returns raw XML/JSON/PDF content
7. **Save to archive** -- Store in external document management system with metadata (Document No, Posting Date, etc.)

### Bulk export for compliance audit

1. **Query date range** -- `GET /eDocuments?$filter=postingDate ge {startDate} and postingDate le {endDate} and direction eq 'Outgoing'`
2. **Paginate results** -- Use `?$top=100&$skip=0` for batched retrieval (OData paging)
3. **For each document, download file** -- Follow "Download archived file content" workflow
4. **Generate audit report** -- Aggregate document counts by type, status, service
5. **Store in compliance archive** -- Export to long-term storage with metadata CSV

## Key procedures

### E-Documents API (page 6112)

**Field mappings:**
- `systemId` → Rec.SystemId (GUID primary key)
- `entryNumber` → Rec."Entry No" (integer PK in E-Document table)
- `documentType` → Format(Rec."Document Type") (converts enum to text: "Sales Invoice", "Purchase Invoice", etc.)
- `status` → Format(Rec.Status) (converts enum to text: "Exported", "Sent", "Error", etc.)
- `direction` → Rec.Direction (enum: Incoming or Outgoing)
- `edocumentServiceStatus` → part("E-Document Service Status API") with SubPageLink

**Nested part access:**
- OData expands part via `$expand=edocumentServiceStatus`
- Returns array of Service Status records for this E-Document
- Each element has: eDocumentEntryNo, eDocumentServiceCode, status, importProcessingStatus

### E-Document Service Status API (page 6136)

**Field mappings:**
- `systemId` → Rec.SystemId
- `eDocumentEntryNo` → Rec."E-Document Entry No" (FK to E-Document)
- `eDocumentServiceCode` → Rec."E-Document Service Code" (FK to E-Document Service)
- `status` → Format(Rec.Status) (Service Status enum)
- `importProcessingStatus` → Format(Rec."Import Processing Status") (Unprocessed, Processing, Processed)

**Standalone queries:**
- `GET /eDocumentServiceStatuses?$filter=status eq 'Sent'` -- All Service Status records with Status = Sent (multi-document result)
- `GET /eDocumentServiceStatuses?$filter=eDocumentServiceCode eq 'PEPPOL'` -- All statuses for PEPPOL service

### E-Doc File Content API (page 6115)

**Field mappings:**
- `systemId` → Rec.SystemId
- `entryNo` → Rec."Entry No" (E-Doc. Data Storage primary key)
- `dataStorage` → Rec."Data Storage" (Blob field, exposed as $value endpoint)
- `fileFormat` → Format(Rec."File Format") (XML, JSON, PDF, TXT)

**Blob download:**
- `GET /eDocFileContents({systemId})/dataStorage/$value` returns raw blob bytes
- Content-Type header set based on File Format enum (application/xml, application/json, application/pdf, text/plain)
- No Base64 encoding; binary stream returned directly

### New E-Documents API (page 6137)

**Source table view:**
- SourceTableView = where(Direction = const(Incoming))
- Filters to inbound documents only (purchase invoices, vendor receipts)

**Use case:**
- External workflow systems polling for new inbound documents
- Approval dashboards showing pending invoices
- Document intake monitoring

**Field subset:**
- Exposes 16 fields vs. 21 on full E-Documents API (omits outbound-specific fields like workflowCode)

## Integration patterns

### Webhook-driven document retrieval

```javascript
// Business Central webhook sends POST to external system on document status change
app.post('/webhook/edocument-status-changed', async (req, res) => {
    const { systemId, status } = req.body;

    if (status === 'Sent') {
        // Fetch full document details
        const doc = await bcApi.get(`/eDocuments(${systemId})?$expand=edocumentServiceStatus`);

        // Send confirmation email to customer
        await emailService.send({
            to: doc.customerEmail,
            subject: `Invoice ${doc.documentNumber} sent`,
            body: `Your invoice has been submitted via e-invoicing.`
        });
    }

    res.sendStatus(200);
});
```

### Scheduled batch export

```javascript
// Nightly job exports previous day's documents to archive
cron.schedule('0 2 * * *', async () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    const docs = await bcApi.get(`/eDocuments?$filter=postingDate eq ${yesterday.toISOString().split('T')[0]}`);

    for (const doc of docs.value) {
        // Retrieve log to get Data Storage Entry No (requires custom integration, not in standard API)
        const log = await bcApi.get(`/eDocumentLogs?$filter=eDocEntryNo eq ${doc.entryNumber} and status eq 'Sent'`);
        if (log.value.length === 0) continue;

        const storageEntryNo = log.value[0].eDocDataStorageEntryNo;

        // Fetch file content
        const fileMetadata = await bcApi.get(`/eDocFileContents?$filter=entryNo eq ${storageEntryNo}`);
        const fileSystemId = fileMetadata.value[0].systemId;
        const fileContent = await bcApi.get(`/eDocFileContents(${fileSystemId})/dataStorage/$value`);

        // Store in long-term archive
        await archiveService.store({
            documentNo: doc.documentNumber,
            postingDate: doc.postingDate,
            content: fileContent,
            format: fileMetadata.value[0].fileFormat
        });
    }
});
```

### Real-time status dashboard

```javascript
// Dashboard polls API every 30 seconds for status updates
async function refreshDashboard() {
    const stats = {
        pending: 0,
        sent: 0,
        approved: 0,
        error: 0
    };

    // Fetch documents from last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const docs = await bcApi.get(`/eDocuments?$filter=postingDate ge ${sevenDaysAgo.toISOString()}`);

    docs.value.forEach(doc => {
        switch (doc.status) {
            case 'Processing':
            case 'Exported':
            case 'Pending Batch':
                stats.pending++;
                break;
            case 'Sent':
            case 'Pending Response':
                stats.sent++;
                break;
            case 'Approved':
                stats.approved++;
                break;
            case 'Export Error':
            case 'Sending Error':
            case 'Imported Document Processing Error':
                stats.error++;
                break;
        }
    });

    updateUI(stats);
}

setInterval(refreshDashboard, 30000);
```

### Inbound document approval workflow

```javascript
// External approval system polls for new inbound documents
async function processNewInboundDocuments() {
    const newDocs = await bcApi.get(`/newEDocuments?$filter=status eq 'Unprocessed'`);

    for (const doc of newDocs.value) {
        // Retrieve file content
        const log = await bcApi.get(`/eDocumentLogs?$filter=eDocEntryNo eq ${doc.entryNumber}`);
        const storageEntryNo = log.value[0].eDocDataStorageEntryNo;
        const fileContent = await bcApi.get(`/eDocFileContents?$filter=entryNo eq ${storageEntryNo}`);
        const fileBlob = await bcApi.get(`/eDocFileContents(${fileContent.value[0].systemId})/dataStorage/$value`);

        // Send to approval system
        const approvalRequest = await approvalApi.post('/approvals', {
            documentId: doc.systemId,
            vendor: doc.billPayNumber,
            amount: doc.amountInclVat,
            xmlContent: fileBlob
        });

        // Store approval request ID for callback
        await db.saveApprovalMapping(doc.systemId, approvalRequest.id);
    }
}
```

## Error handling

- **404 Not Found** -- SystemId not found in E-Document table (document deleted? Invalid GUID?)
- **401 Unauthorized** -- User lacks Read permission on E-Document table
- **400 Bad Request** -- Invalid OData query syntax (e.g., malformed $filter expression)
- **500 Internal Server Error** -- Business Central runtime error (e.g., deadlock, constraint violation)
- **200 OK with empty value array** -- Valid query, no matching records (e.g., `$filter=status eq 'NonExistentStatus'`)

## Performance notes

- **SystemId lookups are O(1)** -- Clustered index on SystemId, fast single-record retrieval
- **$filter on indexed fields** -- Status, Direction, Posting Date indexed for fast filtering
- **$expand triggers sub-query** -- Each expanded part fetches related records via separate query; avoid in high-volume scenarios
- **$top and $skip for pagination** -- OData server-side paging recommended for large result sets (> 100 records)
- **DataAccessIntent = ReadOnly** -- API queries route to read-only replica if available (reduces primary database load)
- **Blob fields lazy-loaded** -- Data Storage blob not loaded until $value endpoint accessed (reduces bandwidth)
