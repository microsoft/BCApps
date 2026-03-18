# Service — Data Model

Service configuration defines integration endpoints, processing rules, and status tracking for E-Document flows. This model separates service definition (1 record) from per-document status tracking (N records per service).

## Core entities

### E-Document Service (table 6103)

Configuration record defining an integration endpoint and its processing rules.

**Key fields:**
- `Code` (PK, Code[20]) -- Unique service identifier
- `Description` (Text[250]) -- Human-readable name
- `Document Format` (enum) -- PEPPOL BIS 3.0, Data Exchange, custom formats
- `Service Integration V2` (enum) -- HTTP Send, Email, No Integration, external integrations (with privacy consent validation)
- `Use Batch Processing` (bool) -- Enables batch export mode
- `Batch Mode` (enum) -- Threshold (export when N documents ready) or Recurrent (scheduled time-based export)
- `Batch Threshold` (int) -- Document count trigger for Threshold mode
- `Batch Start Time` / `Batch Minutes between runs` -- Recurrent mode schedule
- `Batch Recurrent Job Id` (GUID) -- Job queue entry link for cleanup
- `Auto Import` (bool) -- Enables scheduled import polling
- `Import Start Time` / `Import Minutes between runs` -- Import job schedule
- `Import Recurrent Job Id` (GUID) -- Import job queue entry link
- `Import Process` (enum) -- Version 1.0 (legacy) or Version 2.0 (draft-based)
- `Automatic Import Processing` (enum) -- No (stop at Unprocessed), Yes (auto-create drafts)
- `Read into Draft Impl.` (enum) -- How to read structured data into purchase draft (AOAI Function, ADI, custom)
- `Processing Customizations` (enum) -- Service-level import customization flags
- `Embed PDF in export` (bool) -- Attach PDF to structured export (PEPPOL-specific)
- `Export Eligibility Evaluator` (enum) -- Custom filter for which documents to export

**Import parameter fields (V1.0 legacy):**
- `Validate Receiving Company` (bool, default true) -- Check company VAT/GLN matches
- `Resolve Unit Of Measure` (bool, default true) -- Map UOM codes to Item UOM
- `Lookup Item Reference` (bool, default true) -- Match vendor item references
- `Lookup Item GTIN` (bool, default true) -- Match items by GTIN
- `Lookup Account Mapping` (bool, default true) -- Use E-Doc. Mapping rules
- `Validate Line Discount` (bool, default true) -- Verify discount percentages
- `Apply Invoice Discount` (bool, default true) -- Calculate invoice-level discount
- `Verify Totals` (bool, default true) -- Check document total matches lines
- `Create Journal Lines` (bool) -- Create Gen. Journal Lines instead of purchase document
- `General Journal Template Name` / `Batch Name` -- Target journal for line creation

**V2.0 draft settings:**
- `Verify Purch. Total Amounts` (bool, default true) -- Validate totals when posting draft
- `Processing Customizations` (enum) -- Custom processing flags (no blanket orders, etc.)

**Keys:**
- Primary: `Code` (clustered)

**Relationships:**
- 1:N → E-Doc. Service Supported Type (junction to document types)
- 1:N → E-Document Service Status (per-document status tracking)
- 1:N → E-Document Log (via Service Status)
- N:1 → Gen. Journal Template (for journal line creation)
- N:1 → Gen. Journal Batch

**Triggers:**
- `OnDelete` -- Validates service not used in active workflows, deletes supported types, removes batch/import job queue entries

### E-Document Service Status (table 6138)

Composite status tracking per service per document. One E-Document can have multiple status records if sent through multiple services.

**Key fields:**
- `E-Document Entry No` (PK, int) -- FK to E-Document
- `E-Document Service Code` (PK, Code[20]) -- FK to E-Document Service
- `Status` (enum) -- Service-specific status (Exported, Sent, Pending Response, Approved, Rejected, etc.)
- `Import Processing Status` (enum) -- Inbound processing state (Unprocessed, Processing, Processed)

**Keys:**
- Primary: `E-Document Entry No` + `E-Document Service Code` (clustered)
- Secondary: `Status` + `E-Document Service Code` (for batch job filtering)
- Secondary: `E-Document Entry No` + `Status` (for multi-service status aggregation)

**Relationships:**
- N:1 → E-Document (composite parent)
- N:1 → E-Document Service
- 1:N → E-Document Log (drill-down to history)
- 1:N → E-Document Integration Log (HTTP request/response audit)

**Calculated methods:**
- `Logs()` -- Count of E-Document Log entries for this service/document
- `IntegrationLogs()` -- Count of HTTP request/response logs
- `ShowLogs()` / `ShowIntegrationLogs()` -- Drill-down actions

### E-Doc. Service Supported Type (table 6122)

Junction table mapping services to document types they can process.

**Key fields:**
- `E-Document Service Code` (PK, Code[20]) -- FK to E-Document Service
- `Source Document Type` (PK, enum) -- E-Document Type (Sales Invoice, Credit Memo, etc.)

**Keys:**
- Primary: `E-Document Service Code` + `Source Document Type` (clustered)

**Usage:**
- Filters which posted documents trigger export via this service
- Displayed as sub-page on E-Document Service card
- Checked during document posting eligibility evaluation

### Service Participant (table 6140, Participant/ subdirectory)

Trading partner registry mapping GLN/VAT identifiers to vendor records.

**Key fields:**
- `Participant Identifier` (PK, Text[50]) -- GLN, VAT number, or custom ID
- `Participant Name` (Text[250]) -- Trading partner name
- `Vendor No.` (Code[20]) -- FK to Vendor
- `E-Document Service Code` (Code[20]) -- FK to E-Document Service (optional filter)

**Usage:**
- Inbound document reception resolves "To:" participant GLN/VAT to Vendor record
- Enables multi-tenant scenarios where same GLN maps to different vendors per service

## Relationships

```
E-Document Service (1) ──────┬───── (N) E-Doc. Service Supported Type
                               │              └─ (maps to) E-Document Type (enum)
                               │
                               ├───── (N) E-Document Service Status
                               │              ├─ FK to E-Document (composite parent)
                               │              ├─── (N) E-Document Log
                               │              └─── (N) E-Document Integration Log
                               │
                               ├───── (N) Service Participant
                               │              └─ FK to Vendor
                               │
                               ├───── (1) Gen. Journal Template (optional)
                               │              └─── (1) Gen. Journal Batch
                               │
                               └───── (referenced by) Workflow Step Argument
```

## Field usage patterns

### Service configuration lifecycle

1. **Creation** -- Code + Description + Document Format + Service Integration V2
2. **Supported types** -- Insert E-Doc. Service Supported Type records for each document type
3. **Outbound batch settings** -- If using batch, set Batch Mode + Threshold/Schedule, trigger HandleRecurrentBatchJob()
4. **Inbound import settings** -- If auto-importing, set Auto Import + schedule, trigger HandleRecurrentImportJob()
5. **Import parameters** -- Configure 13 boolean flags (V1.0) or Processing Customizations (V2.0)

### Status tracking lifecycle

1. **Service Status creation** -- First export/import creates E-Document Service Status record with Status = "Processing"
2. **Status transitions** -- Each state change inserts E-Document Log entry (Status + Processing Status + timestamp)
3. **Multi-service routing** -- Same E-Document can have Status records for multiple services (e.g., send to PEPPOL + archive to SharePoint)
4. **Aggregated header status** -- E-Document.Status calculated via IEDocumentStatus interface examining all Service Status records
5. **Audit trail** -- Logs remain even if Service Status deleted; provides full history

## Composite key patterns

**E-Document Service Status uses dual foreign keys:**
- Primary key = (E-Document Entry No, E-Document Service Code)
- Enables one document to have multiple statuses (one per service)
- Indexed for fast "all documents for service X in status Y" queries (batch processing)

**E-Doc. Service Supported Type filters eligibility:**
- Junction table prevents M:N direct relationship
- Indexed by Service Code + Document Type for O(1) eligibility checks
- Supports scenarios where service A exports invoices but service B exports both invoices and credit memos

## Performance notes

- **Service Status log counts are computed on demand** -- Logs()/IntegrationLogs() call Count() instead of storing denormalized counters; avoids update contention
- **Batch job GUID storage** -- Batch/Import Recurrent Job Id fields enable O(1) job cleanup on service deletion (no job queue entry scan)
- **Status filtering indexes** -- Key2 (Status, Service Code) enables fast batch job queries; Key3 (Entry No, Status) enables fast multi-service aggregation
- **Supported Type junction table** -- Small, stable table cached in memory; eligibility checks don't hit database per document
