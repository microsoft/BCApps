# Transaction Storage

Compliance archival system that exports Business Central transaction data and
document attachments to Azure Blob Storage. Designed for regulatory requirements
(e.g., Denmark Bookkeeping Act) requiring machine-readable transaction preservation.

## Quick reference

**App ID:** `c832ba23-ab01-45f5-8cb2-bfdf061a7a8c`
**Object range:** 6200-6250
**Core objects:** 14 (6 tables, 6 codeunits, 1 page, 1 enum)
**Dependencies:** None
**Target markets:** SaaS production environments with compliance requirements

## How it works

### Trigger mechanism

The system uses an event-driven approach to initiate exports:

1. **GL posting** (OnAfterGLFinishPosting) sets a flag indicating transactions occurred
2. **User logout** (OnAfterCompanyClose) detects the flag and schedules a background export task
3. **Background task** runs asynchronously, typically during scheduled time slots (2:00-4:40 AM)

### Incremental export

The system tracks `last_handled_datetime` per table using `SystemModifiedAt` timestamps.
Only new or modified records since the last export are included. This prevents
re-exporting unchanged data.

### Data scope

Exports **29 tables** covering the full transaction audit trail:

- **Ledger entries:** G/L Entry, VAT Entry, Customer/Vendor Ledger, Item Ledger, FA Ledger
- **Documents:** Sales/Purchase Invoice/Credit Memo headers and lines
- **Reminders:** Reminder/Finance Charge headers and lines
- **Master data:** GL Account, Customer, Vendor, Bank, Fixed Asset (referenced by transactions)

### Chunking and limits

- Records exported in chunks of **50,050 records** to manage memory
- Binary search algorithm limits each table to **200,000 records per run**
- This prevents runaway exports on large datasets

### Azure upload

- **Dual endpoints:** JSON text endpoint for transactions + base64 document endpoint for attachments
- **Authentication:** OAuth2 certificate auth with secrets from Azure Key Vault
- **Blob container:** Formatted Company Registration Number (CVR)
- **Blob path:** `{AAD-Tenant-ID}_{Env-Name}/{YYYYMMDD}/`
- **Retention:** 6 years (or 6 years from fiscal year-end)

### Document attachments

Incoming document attachments linked to GL entries are exported as base64-encoded
files. Maximum size: **100MB per attachment**.

### Error handling

- **Retry logic:** Up to 4 attempts with 5-15 minute random delay
- **Timeout detection:** Handles long-running operations
- **OutOfMemory handling:** Graceful degradation on memory exhaustion
- **Critical alerts:** 7-day consecutive failure monitoring

### Scheduling

- **Distributed scheduling:** Tenant export times spread across 2:00-4:40 AM
- **Time slot calculation:** Based on tenant ID hex digits to prevent server load spikes

## Structure

All objects are in the flat `src/` folder:

- **Tables (6):** Setup, export status tracking, failure monitoring, task scheduling
- **Codeunits (6):** Export orchestration, Azure upload, retry logic, scheduling, event subscribers
- **Page (1):** Setup page for configuration
- **Enum (1):** Export status values
- **Permissions:** Permission set definitions in `Permissions/` folder

## Documentation

Reference materials are in the parent `TransactionStorage/` folder:

- **README.md** -- Overview and compliance context
- **Business Central Transactions and Receipts API Specification.md** -- API contract for Azure endpoint

## Things to know

### Country-specific behavior

- **Denmark:** First run date = 2024-01-01 (when regulation took effect)
- Other countries may have different start dates or opt-in configuration

### Environment filtering

The system **only runs in SaaS production** environments. It skips:

- Demo companies
- Evaluation companies
- Sandbox environments

This prevents test data from polluting compliance archives.

### Background tasks

Exports run as Task Scheduler background tasks. They do not block user sessions
and can be monitored via the Task Scheduler page. If a task fails, the retry
logic reschedules it automatically.

### Azure Functions dependency

The system requires a deployed Azure Function endpoint to receive exported data.
The endpoint URL, certificate thumbprint, and Key Vault details are configured
in the setup table. Without valid Azure configuration, exports will fail silently
until corrected.

### SystemModifiedAt tracking

The incremental export relies on `SystemModifiedAt` timestamps, which are
automatically maintained by the platform. Do not manually modify these fields
or the export will skip records.
