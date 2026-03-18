# Endpoints

REST API pages exposing E-Document data for external integrations. Provides read-only access to E-Documents, Service Status, Services, and file content via OData v4 endpoints in `microsoft/edocument/v1.0` API group. Supports external document management systems, approval workflows, and monitoring dashboards.

## Quick reference

- **Parent:** [`src/Processing/API/`](../CLAUDE.md)
- **Files:** 5 .al files
- **API Group:** `edocument`
- **API Publisher:** `microsoft`
- **API Version:** `v1.0`
- **Base URL:** `/api/microsoft/edocument/v1.0/companies({companyId})/`

## How it works

API pages extend Business Central's OData v4 REST endpoints with read-only access to E-Document core entities. Each page exposes a source table with EntityName/EntitySetName mappings (eDocument/eDocuments, eDocumentService/eDocumentServices, etc.) and ODataKeyFields for primary key routing.

The E-Documents API (page 6112) is the main entry point, exposing E-Document header fields (entry number, document number, status, amounts, dates) and a nested part for Service Status records. Clients query `/eDocuments` to list all documents or `/eDocuments({systemId})` to retrieve a single document by SystemId.

Service Status is exposed as both a sub-page part on E-Documents API and a standalone endpoint (page 6136), enabling queries like `/eDocumentServiceStatuses?$filter=status eq 'Sent'` to find all sent documents across all services.

File content access is handled by E-Doc File Content API (page 6115), which exposes E-Doc. Data Storage blobs via a read-only page. Clients retrieve the Data Storage Entry No. from E-Document Log API, then fetch `/eDocFileContents({entryNo})` to download XML/JSON/PDF payloads.

All API pages are InherentEntitlements = X, InherentPermissions = X, Editable = false, DataAccessIntent = ReadOnly, ensuring no data modification via API. Extensible = false prevents external modifications to API contracts.

## Key files

- **EDocumentsAPI.Page.al** -- Main E-Document list endpoint with 21 fields + eDocumentServiceStatus part
- **EDocumentServiceStatusAPI.Page.al** -- Service Status standalone endpoint with 4 fields (Entry No, Service Code, Status, Import Processing Status)
- **EDocumentServicesAPI.Page.al** -- Service configuration endpoint exposing Code + Description
- **EDocFileContentAPI.Page.al** -- Blob storage endpoint exposing Entry No + Data Storage + File Format
- **NewEDocumentsAPI.Page.al** -- Inbound E-Document endpoint (Direction = Incoming) with 16 fields

## Things to know

- **SystemId is ODataKeyFields** -- All API pages use SystemId as primary key for OData routing (enables stable URLs across environments)
- **Document Type and Status exposed as Format(enum)** -- EnumOrdinalValue not exposed; clients receive string values ("Sales Invoice", "Exported", etc.)
- **Service Status embedded as part** -- E-Documents API includes `part(edocumentServiceStatus; "E-Document Service Status API")` with SubPageLink = "E-Document Entry No" = field("Entry No")
- **NewEDocumentsAPI filters by Direction** -- SourceTableView = where(Direction = const(Incoming)) restricts to inbound documents only
- **File Content API exposes blob directly** -- field(dataStorage; Rec."Data Storage") exposes blob field, clients download via $value OData endpoint
- **InherentEntitlements/Permissions = X** -- API respects user's existing permissions; no additional license enforcement (X = maximum permissions user has)
- **DelayedInsert = true** -- Standard API pattern allowing POST without immediate insert (not used since Editable = false, but convention maintained)
- **Extensible = false** -- Prevents external apps from adding fields to API pages (maintains stable API contract across updates)

## API endpoints

### E-Documents API (page 6112)

**Endpoint:** `/eDocuments`

**Entity name:** `eDocument`

**Fields exposed:**
- `systemId` (GUID) -- Primary key for OData routing
- `entryNumber` (int) -- E-Document."Entry No"
- `documentRecordId` (RecordId) -- Source document pointer
- `billPayNumber` (Code[20]) -- Customer/Vendor No.
- `documentNumber` (Code[20]) -- Document No.
- `documentType` (text) -- Format(E-Document Type enum)
- `documentDate` / `dueDate` / `postingDate` (date)
- `amountInclVat` / `amountExclVat` (decimal)
- `orderNumber` (Code[20]) -- Purchase Order No. (inbound) or Sales Order No. (outbound)
- `direction` (enum) -- Incoming or Outgoing
- `incomingEDocumentNumber` (Code[20]) -- External document identifier
- `status` (text) -- Format(E-Document Status enum)
- `sourceType` (enum) -- Sales, Purchase, Service
- `recCompanyVat` / `recCompanyGLN` / `recCompanyName` / `recCompanyAddress` (text) -- Receiving company identifiers
- `currencyCode` (Code[10])
- `workflowCode` (Code[20])
- `fileName` (Text[250])
- `edocumentServiceStatus` (part) -- Nested Service Status records

**Queries:**
- List all: `GET /eDocuments`
- Single document: `GET /eDocuments({systemId})`
- Filter by status: `GET /eDocuments?$filter=status eq 'Exported'`
- Filter by direction: `GET /eDocuments?$filter=direction eq 'Incoming'`
- Expand service status: `GET /eDocuments?$expand=edocumentServiceStatus`

### E-Document Service Status API (page 6136)

**Endpoint:** `/eDocumentServiceStatuses`

**Entity name:** `eDocumentServiceStatus`

**Fields exposed:**
- `systemId` (GUID)
- `eDocumentEntryNo` (int)
- `eDocumentServiceCode` (Code[20])
- `status` (text) -- Format(Service Status enum)
- `importProcessingStatus` (text) -- Format(Import Processing Status enum)

**Queries:**
- List all statuses: `GET /eDocumentServiceStatuses`
- Filter by service: `GET /eDocumentServiceStatuses?$filter=eDocumentServiceCode eq 'PEPPOL'`
- Filter by status: `GET /eDocumentServiceStatuses?$filter=status eq 'Sent'`

### E-Document Services API (page 6114)

**Endpoint:** `/eDocumentServices`

**Entity name:** `eDocumentService`

**Fields exposed:**
- `systemId` (GUID)
- `code` (Code[20])
- `description` (Text[250])

**Queries:**
- List all services: `GET /eDocumentServices`
- Single service: `GET /eDocumentServices({systemId})`

### E-Doc File Content API (page 6115)

**Endpoint:** `/eDocFileContents`

**Entity name:** `eDocFileContent`

**Fields exposed:**
- `systemId` (GUID)
- `entryNo` (int) -- E-Doc. Data Storage."Entry No."
- `dataStorage` (Blob) -- File content (XML, JSON, PDF)
- `fileFormat` (text) -- Format(File Format enum)

**Queries:**
- Get file metadata: `GET /eDocFileContents({systemId})`
- Download file content: `GET /eDocFileContents({systemId})/dataStorage/$value`

**Usage pattern:**
1. Query E-Document Log via UI or custom integration to get "E-Doc. Data Storage Entry No."
2. Query `/eDocFileContents?$filter=entryNo eq {storageEntryNo}` to get SystemId
3. Download blob via `/eDocFileContents({systemId})/dataStorage/$value`

### New E-Documents API (page 6137)

**Endpoint:** `/newEDocuments`

**Entity name:** `newEDocument`

**Fields exposed:** Subset of E-Documents API fields (16 fields vs. 21)

**Source table view:** Direction = const(Incoming) -- Only inbound documents

**Queries:**
- List inbound documents: `GET /newEDocuments`
- Filter by status: `GET /newEDocuments?$filter=status eq 'Unprocessed'`

**Use case:** External workflow systems polling for new inbound invoices awaiting processing

## Integration patterns

### External monitoring dashboard

```javascript
// Fetch all documents in error state
const response = await fetch('/api/microsoft/edocument/v1.0/companies({companyId})/eDocuments?$filter=status eq \'Error\'&$expand=edocumentServiceStatus');
const errorDocs = await response.json();

// Display error count by service
errorDocs.value.forEach(doc => {
    doc.edocumentServiceStatus.forEach(status => {
        console.log(`Document ${doc.documentNumber}: ${status.eDocumentServiceCode} - ${status.status}`);
    });
});
```

### Approval workflow integration

```javascript
// Query new inbound invoices
const response = await fetch('/api/microsoft/edocument/v1.0/companies({companyId})/newEDocuments?$filter=status eq \'Unprocessed\'');
const newInvoices = await response.json();

// Send to external approval system
newInvoices.value.forEach(async invoice => {
    const blob = await fetch(`/api/microsoft/edocument/v1.0/companies({companyId})/eDocFileContents?$filter=entryNo eq ${invoice.dataStorageEntryNo}`);
    const content = await blob.json();
    // POST to approval system with invoice.systemId + content
});
```

### Document archive export

```javascript
// Fetch all sent documents from last month
const lastMonth = new Date();
lastMonth.setMonth(lastMonth.getMonth() - 1);
const response = await fetch(`/api/microsoft/edocument/v1.0/companies({companyId})/eDocuments?$filter=status eq 'Sent' and postingDate ge ${lastMonth.toISOString()}&$expand=edocumentServiceStatus`);
const sentDocs = await response.json();

// Download XML for archival
sentDocs.value.forEach(async doc => {
    const logResponse = await fetch(`/api/microsoft/edocument/v1.0/companies({companyId})/eDocumentLogs?$filter=eDocEntryNo eq ${doc.entryNumber} and status eq 'Sent'`);
    const log = await logResponse.json();
    const storageEntryNo = log.value[0].eDocDataStorageEntryNo;
    const fileContent = await fetch(`/api/microsoft/edocument/v1.0/companies({companyId})/eDocFileContents(${storageEntryNo})/dataStorage/$value`);
    // Save to archive storage
});
```

## Performance notes

- **SystemId lookup is O(1)** -- Clustered index on SystemId enables fast single-record retrieval
- **$expand on service status is N+1 query** -- Each E-Document fetches its Service Status records separately; use $filter on base entity when possible
- **Blob fields not loaded by default** -- Data Storage blob only loaded when accessing $value endpoint or explicitly selecting field
- **API pages use DataAccessIntent = ReadOnly** -- Queries route to read-only replica if available (reduces contention on primary database)
- **InherentPermissions = X respects existing security** -- API doesn't bypass user permissions; clients need Read permission on E-Document tables
