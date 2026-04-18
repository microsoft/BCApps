# Business Logic

## Overview

The Transaction Storage extension implements an event-driven architecture that captures Business Central transactions, schedules background exports, and uploads data to Azure Blob Storage for long-term archival.

## Trigger Mechanism

**TransStoragePostingState** (SingleInstance codeunit) decouples posting from export:

- Subscribes to **OnAfterGLFinishPosting** (Gen. Jnl.-Post Line) -- sets internal flag when GL entries are posted
- Subscribes to **OnAfterCompanyClose** (LogInManagement) -- checks flag at user logout; if set, calls TransStorageScheduleTask to schedule export
- Non-blocking design -- posting completes immediately without waiting for export

## Scheduling Logic

**TransStorageScheduleTask** validates environment and creates a background task:

1. **Environment validation** -- ensures SaaS production environment (skips on-prem, demo, evaluation)
2. **Duplicate prevention** -- checks if a valid scheduled task already exists; if so, exits without creating duplicate
3. **Retry reset** -- sets NoOfTasksAttempts to 3 in TransactStorageSetup
4. **Start time calculation** -- reads Earliest Start Time from setup; if that time has passed today, schedules for tomorrow; otherwise schedules for today
5. **Tenant distribution** -- CalcTenantExportStartTime() uses first 2 hex characters of AAD tenant ID to distribute start times across 2:00-4:40 AM window (prevents thundering herd)
6. **Task creation** -- creates TaskScheduler record with:
   - Run codeunit: TransactStorageExport
   - Error handler: TransStorageErrorHandler
   - Scheduled start time

## Export Process

**TransactStorageExport.OnRun()** delegates to **TransactStorageExportData.ExportData()**:

1. **Table iteration** -- processes 29 hard-coded tables (GL Entry, Sales Header, Sales Line, Purchase Header, etc.)
2. **Date range filtering** -- for each table, calls SetRangeOnDataTable():
   - SystemModifiedAt between last_handled_datetime (from TransactStorageTableEntry) and task_start_datetime
   - Volume limiting via CalcFilterRecordToDateTime() if record count exceeds 200,000
3. **Record collection** -- CollectDataFromTable() iterates records:
   - Converts each record to JSON object (field whitelist per table)
   - Chunks JSON into 50,050-record arrays stored in TransStorageExportData temp table (blob parts)
4. **Document collection** -- for GL Entry records, collects related incoming documents:
   - Filters by posting date and document number
   - Converts attached documents to base64
5. **Master data collection** -- HandleTableFieldSet() identifies foreign key references:
   - Collects referenced Customers, Vendors, GL Accounts, etc.
   - Ensures archive is self-contained with all referenced master data
6. **Upload** -- calls TransactionStorageABS.ArchiveTransactionsToABS():
   - Uploads JSON text (transaction data + master data)
   - Uploads base64 documents
   - Uploads execution log
   - Uploads metadata file

## Volume Limiting

**CalcFilterRecordToDateTime()** implements binary search to cap record count at 200,000:

1. **First pass** -- halves date range until record count <= 200,000 (day-level granularity)
2. **Second pass** -- refines end date to millisecond precision to maximize records within limit
3. **Result** -- returns adjusted SystemModifiedAt filter; unprocessed records handled in next scheduled run

## Azure Upload

**TransactionStorageABS** uploads to Azure Blob Storage:

- **Endpoints** -- separate Azure Function endpoints for JSON text and base64 documents
- **Secrets** -- retrieved from Key Vault (configured in TransactStorageSetup)
- **Container** -- formatted CVR number (company registration number)
- **Blob folder structure** -- {TenantID}_{EnvironmentName}/{YYYYMMDD}
- **Retention policy** -- 6 years or fiscal year-end + 6 years (configurable via Deletion Date Expression in setup)

## Retry Logic

**TransStorageErrorHandler** captures task errors and decides whether to reschedule:

1. **Attempt exhaustion** -- if 4 attempts consumed, logs critical alert and stops
2. **Timeout** -- no reschedule (prevents infinite retry loop on slow queries)
3. **OutOfMemory** -- no reschedule (prevents server instability)
4. **Duplicate prevention** -- checks if valid task exists before rescheduling
5. **Reschedule** -- if retriable error, schedules new task 5-15 minutes later (random backoff), decrements NoOfTasksAttempts
6. **Consecutive failure monitoring** -- if 7 consecutive first-attempt failures detected, logs critical alert

## Flow Diagram

```
┌─────────────────────┐
│  GL Posting Event   │
│ (Gen. Jnl.-Post)    │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ TransStoragePosting │
│   State (flag set)  │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│   User Logout       │
│ (OnAfterCompanyClose)│
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ TransStorageSchedule│
│  Task (create task) │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ TaskScheduler (2-4AM│
│  next day, run code-│
│  unit:TransactStorage│
│  Export)             │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ TransactStorageExport│
│  .OnRun()            │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ TransactStorageExport│
│  Data.ExportData()   │
│ (29 tables, filter by│
│  SystemModifiedAt,   │
│  volume limiting)    │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ CollectDataFromTable│
│ (JSON chunking,      │
│  50,050 records/chunk)│
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ Collect documents   │
│ (incoming docs by    │
│  posting date + doc  │
│  no, base64 encode)  │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ Collect master data │
│ (customers, vendors, │
│  GL accounts via FK  │
│  references)         │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ TransactionStorageABS│
│ .ArchiveTransactions │
│  ToABS()             │
│ (upload JSON, docs,  │
│  log, metadata)      │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│  Azure Blob Storage │
│ (container: CVR,     │
│  folder: TenantID_   │
│  EnvName/YYYYMMDD,   │
│  retention: 6 years) │
└─────────────────────┘

ERROR PATH:
┌─────────────────────┐
│ TransStorageError   │
│  Handler (on task   │
│  error)              │
└──────────┬──────────┘
           │
           v
   ┌───────┴───────┐
   │  Retriable?   │
   └───┬───────┬───┘
       │       │
      YES      NO
       │       │
       v       v
   Reschedule  Log critical
   (5-15 min   alert, stop
   backoff,    retry
   decrement
   attempts)
```
