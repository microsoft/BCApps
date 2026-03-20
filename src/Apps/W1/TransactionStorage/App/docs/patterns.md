# Patterns

## 1. Incremental Extraction via SystemModifiedAt

**Problem**: Avoid re-exporting unchanged records on every scheduled run.

**Solution**: TransactStorageTableEntry table tracks `Last Handled DateTime` per table. TransactStorageExportData.SetRangeOnDataTable() filters records where SystemModifiedAt is between last_handled_datetime and task_start_datetime. Only modified records are exported.

**Files**:
- C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Table\TransactStorageTableEntry.Table.al
- C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransactStorageExportData.Codeunit.al

**Benefit**: Reduces payload size and processing time. Handles millions of records incrementally.

---

## 2. Binary Search Volume Limiting

**Problem**: Prevent memory exhaustion when a single table has millions of modified records.

**Solution**: TransactStorageExportData.CalcFilterRecordToDateTime() implements binary search:
- First pass: Halves date range until record count <= 200,000 (day-level granularity)
- Second pass: Refines end date to millisecond precision to maximize records within limit
- Unprocessed records handled in next scheduled run

**File**: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransactStorageExportData.Codeunit.al

**Benefit**: Caps memory usage per export run. Ensures predictable performance even with high-volume tables.

---

## 3. Distributed Tenant Scheduling

**Problem**: Avoid thundering herd if all tenants schedule exports at the same time.

**Solution**: TransStorageScheduleTask.CalcTenantExportStartTime() uses first 2 hex characters of AAD tenant ID (0x00 to 0xFF = 256 values) to distribute start times across 2:00-4:40 AM window (160 minutes). Each tenant gets a consistent but unique start time.

**File**: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransStorageScheduleTask.Codeunit.al

**Benefit**: Load balancing across Azure infrastructure. Prevents service degradation during peak export hours.

---

## 4. Chunked JSON Staging

**Problem**: Large tables produce JSON arrays too large to hold in memory.

**Solution**: TransactStorageExportData.CollectDataFromTable() writes JSON in 50,050-record chunks to TransStorageExportData temp table (blob fields). Final upload concatenates chunks without loading entire dataset into memory.

**File**: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransactStorageExportData.Codeunit.al

**Benefit**: Memory-efficient processing of millions of records. Prevents OutOfMemory errors.

---

## 5. Master Data Referential Completeness

**Problem**: Transaction records reference master data (Customer, Vendor, GL Account). Archive must be self-contained for auditing.

**Solution**: TransactStorageExportData.HandleTableFieldSet() identifies foreign key references in exported records. Collects referenced master data into separate tables (TransactStorageCustData, TransactStorageVendData, etc.). Uploads master data JSON alongside transaction JSON.

**File**: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransactStorageExportData.Codeunit.al

**Benefit**: Archive contains complete context. No need to query live system for master data during audits.

---

## 6. Dual Azure Function Endpoints

**Problem**: Azure Functions have different size limits and routing needs for text vs binary data.

**Solution**: TransactionStorageABS exposes two upload methods:
- **UploadJSONText()**: Sends transaction and master data JSON as text payload
- **UploadBinaryData()**: Sends incoming documents as base64 payload

**File**: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransactionStorageABS.Codeunit.al

**Benefit**: Fine-grained Azure routing and rate limiting. Separates high-volume document uploads from structured data.

---

## 7. Resilient Retry with Backoff

**Problem**: Transient errors (network failures, Azure throttling) should trigger retry. Permanent errors (timeout, OutOfMemory) should not.

**Solution**: TransStorageErrorHandler implements retry logic:
- 4 attempts max (tracked in TransactStorageSetup.NoOfTasksAttempts)
- 5-15 minute random backoff (prevents synchronized retry storm)
- Special handling:
  - Timeout: No reschedule (prevents infinite retry loop)
  - OutOfMemory: No reschedule (prevents server instability)
  - Duplicate task exists: No reschedule
- 7-day consecutive failure monitoring: Logs critical alert if first attempt fails 7 days in a row

**Files**:
- C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransStorageErrorHandler.Codeunit.al
- C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Table\TransactStorageSetup.Table.al

**Benefit**: Maximizes reliability without overwhelming infrastructure. Clear signal when manual intervention needed.

---

## 8. Event-driven Task Trigger

**Problem**: Scheduling export synchronously during posting would block user operations.

**Solution**: TransStoragePostingState (SingleInstance codeunit) captures GL posting flag via OnAfterGLFinishPosting event. Defers scheduling to OnAfterCompanyClose event (user logout). Posting completes immediately; export scheduling happens asynchronously.

**File**: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransStoragePostingState.Codeunit.al

**Benefit**: Non-blocking design. User experience unaffected by export scheduling overhead.

---

## Pattern Summary

| Pattern | File | Benefit |
|---------|------|---------|
| Incremental extraction | TransactStorageExportData.Codeunit.al | Reduces payload size |
| Binary search volume limiting | TransactStorageExportData.Codeunit.al | Caps memory usage |
| Distributed tenant scheduling | TransStorageScheduleTask.Codeunit.al | Load balancing |
| Chunked JSON staging | TransactStorageExportData.Codeunit.al | Memory-efficient |
| Master data referential completeness | TransactStorageExportData.Codeunit.al | Self-contained archive |
| Dual Azure endpoints | TransactionStorageABS.Codeunit.al | Fine-grained routing |
| Resilient retry with backoff | TransStorageErrorHandler.Codeunit.al | Maximizes reliability |
| Event-driven task trigger | TransStoragePostingState.Codeunit.al | Non-blocking design |

These patterns work together to provide a scalable, reliable, and performant transaction archival system for Business Central SaaS environments.
