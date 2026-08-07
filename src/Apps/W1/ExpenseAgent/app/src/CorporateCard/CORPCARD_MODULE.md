# Corporate Card Module Documentation

## Overview

The Corporate Card module for Expense Agent provides automated import, normalization, draft creation, and reporting of corporate card transactions into the Business Central Expense framework.

**Namespace:** `Microsoft.ExpenseAgent`  
**Access Level:** `Internal` (all objects)  
**Integration:** Extends standard Expense Agent workflow (no breaking changes)

---

## Architecture

### Design Principles

1. **Automated Import Pipeline** - Provider-driven file import with field mapping validation
2. **Multi-Format Support** - API, CSV, XML, ISO20022, CAMT.053, and CAMT.054 mapping profiles
3. **Configurable Creation Mode** - AutoDraft can create one draft per imported transaction
4. **Scheduled Processing** - Job Queue integration for recurring imports with retry resilience
5. **Standard Workflows** - Leverages platform Expense Report approval and GL posting
6. **Comprehensive Observability** - Telemetry at every step: import → normalization → matching → reporting

### Workflow Stages

```
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 1: PROVIDER IMPORT                                            │
│ - Provider downloads transactions from bank/processor               │
│ - Data injected into Data Exchange framework                        │
│ - Field mapping validation via EACorpCardMapMgt                     │
│ - Transactions imported to staging table (EACorpCardTrans)          │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 2: MERCHANT NORMALIZATION                                     │
│ - Regex patterns applied to normalize merchant names                │
│ - Rules sorted by priority, first match wins                        │
│ - Normalized name + category stored for later use                   │
│ - Codeunit: EACorpCardMerchantNorm (7210)                           │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 3: TRANSACTION MATCHING                                       │
│ - Strategy 1: Exact amount/date match (score 50-100)                │
│ - Strategy 2: Fuzzy merchant name match via Levenshtein (70-85%)    │
│ - Strategy 3: Employee-only match as fallback (score 50)            │
│ - Match type & score stored; transaction status updated             │
│ - Codeunit: EACorpCardEnhancedMatchMgt (7216)                       │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 4: DRAFT CREATION / MANUAL MATCHING                           │
│ - AutoDraft mode: always creates 1 draft per imported transaction   │
│ - ManualLink mode: tries matching first, then optional draft create │
│ - Level 3 detail rows can seed Expense VAT Specification lines      │
│ - Persisted VAT spec lines rely on table autoincrement for Line No. │
│ - Warns if Level 3 totals differ from transaction header amount     │
│ - Codeunit: EACorpCardExpWriter (7212)                              │
│ - MCC mapping to category: Codeunit EACorpCardMCCMgt (7217)         │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 5: REPORT AGGREGATION                                         │
│ - Employee reviews drafts and existing expenses                     │
│ - Creates/updates Expense Report via UI or EACorpCardReportMgt      │
│ - Adds individual expenses to report                                │
│ - Codeunit: EACorpCardReportMgt (7219)                              │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 6: APPROVAL & POSTING                                         │
│ - Employee submits Expense Report for approval                      │
│ - Manager approves via standard Expense Agent workflow              │
│ - Report released to Posted status                                  │
│ - GL postings created via platform ExpenseReportPost (6987)         │
│ - Codeunit: EACorpCardApprovalMgt (7218)                            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Objects Created

### Codeunits (12 total)

| ID | Name | Purpose | Key Procedures |
|----|------|---------|-----------------|
| 7210 | EACorpCardMerchantNorm | Merchant name normalization via regex patterns | NormalizeTransaction, FindMatchingRule, PatternMatches |
| 7211 | EACorpCardMatchMgt | Basic transaction matching (reference only) | MatchTransaction |
| 7212 | EACorpCardExpWriter | Draft Expense creation from transactions | CreateDraftFromTrans, LinkPosted, GetExpenseCategoryFromMCC |
| 7213 | EACorpCardPostImportOrch | Post-import orchestration pipeline | ProcessBatchPostImport |
| 7214 | EACorpCardAuditSubscribers | Centralized telemetry logging | LogImportStarted/Completed/Failed, LogMatchingCompleted, LogDraftCreated, LogReportCreatedFromCorpCard, LogReportSubmittedForApproval, LogReportApprovedForPosting, LogReportRejected |
| 7215 | EACorpCardJQMgt | Job Queue entry lifecycle management | ScheduleProviderImport, UnscheduleProviderImport, UpdateJobQueueFrequency |
| 7216 | EACorpCardEnhancedMatchMgt | Multi-strategy matching with fuzzy algorithm | EnhancedMatchTransaction, CalculateSimilarity, LevenshteinDistance |
| 7217 | EACorpCardMCCMgt | MCC validation and category mapping | ValidateAndMapMCC, GetExpenseCategoryForMCC, InitializeDefaultMCCMappings, IsValidMCC |
| 7218 | EACorpCardApprovalMgt | Expense Report approval workflow | SubmitReportForApproval, ReleaseReportForPosting, RejectReport |
| 7219 | EACorpCardReportMgt | Expense Report aggregation | CreateReportFromCorpCardExpenses, AddExpenseToReport, ReleaseExpenseForReporting |
| 7223 | EACorpCardJQRunner | Job Queue entry point with error resilience | OnRun (Job Queue trigger) |
| 7257 | EACorpCardApiSourceProv | API source payload provider (Phase 1) | OnProvideSourceContent, DownloadSourceContent, AddAuthHeaders |

### Pages (13 total)

| ID | Name | Type | Purpose |
|----|------|------|----------|
| 7220 | EACorpCardBatches | List | Import batch listing with transaction/exception drill-down |
| 7221 | EACorpCardCards | List | Corporate card transaction list (import staging) |
| 7222 | EACorpCardExceptions | List | Import exceptions with resolution tracking |
| 7223 | EACorpCardTransList | List | Imported transaction listing with expense linking |
| 7224 | EACorpCardProviders | List | Provider administration with scheduling actions |
| 7225 | EACorpCardMCCMap | List | Merchant category code to expense category mapping |
| 7227 | EACorpCardMerchantRules | List | Merchant name normalization regex pattern rules |
| 7228 | EACorpCardDashboard | RoleCenter | Import reconciliation dashboard with navigation |
| 7229 | EACorpCardJQSchedule | List+Card | Job Queue schedule management UI for providers |
| 7235 | EACorpCardJQScheduleSubpage | Subpage | Read-only Job Queue entry details filtered by provider |
| 7231 | EACorpCardDashboardFactbox | ListPart | Recent import batches sorted chronologically |
| 7232 | EACorpCardStatisticsFactbox | CardPart | KPI statistics (30-day rolling aggregation) |
| 7099 | EACorpCardL3Details | List | Imported Level 3 VAT/tax detail lines per transaction |

### Tables (0 new)

The module uses only **platform tables**:
- **EACorpCardTrans** - Corporate card transaction staging (custom but part of broader ExpenseAgent framework)
- **Expense** - Individual expense records (platform)
- **Expense Report Header / Line** - Report aggregation (platform)
- **Data Exch.** / **Data Exch. Field** - File import mapping (platform)
- **Job Queue Entry** - Scheduled job storage (platform)

---

## Data Flow

### Import Flow

```
Provider.Download()
    → Creates Data Exchange record
    → Injects source file content (API/CSV/XML/CAMT)
    → API source is resolved via OnProvideSourceContent event subscriber
            ↓
Provider.ParseToStaging()
    → Validates field mappings (EACorpCardMapMgt)
    → Imports data to EACorpCardTrans (Status=Imported)
    → Includes mapped MCC values for XML/L3 transactions
    → Imports Level 3 detail rows to EACorpCardTransDetail (when present)
    → Calls EACorpCardPostImportOrch.ProcessBatchPostImport()
            ↓
EACorpCardPostImportOrch.ProcessBatchPostImport()
    → For each transaction:
        1. EACorpCardMerchantNorm.NormalizeTransaction()
        2. If Create Mode = AutoDraft: EACorpCardExpWriter.CreateDraftFromTrans()
        3. Else try EACorpCardEnhancedMatchMgt.EnhancedMatchTransaction()
        4. If unmatched + Auto-Create: EACorpCardExpWriter.CreateDraftFromTrans()
        5. If Level 3 details exist: create Expense VAT Specification lines
    → Log results via AuditSubscribers
            ↓
Provider.Ack()
    → Mark batch as Completed
    → Send audit notification
```

### Matching Algorithm

**Strategy Priority (executed in order):**

1. **Exact Amount-Date Match** (Score: 50-100)
   - Query: Same user, Status=Open, Currency match
   - Criteria: Amount within tolerance, Date within window
   - Score: `100 - (DateDiffDays × 5) - ((AmountDiff / Tolerance) × 10)`
   - Returns: Match Type=Full

2. **Fuzzy Merchant Name Match** (Score: 70-85)
   - Query: All open expenses for same user
   - Algorithm: Levenshtein distance (max 100 char)
   - Similarity: `1 - (EditDistance / MaxLen)`, threshold ≥ 0.70
   - Returns: Match Type=Expense

3. **Employee-Only Match** (Score: 50)
   - Query: Any first open expense for same user
   - No scoring, manual review expected
   - Returns: Match Type=Employee

**Levenshtein Algorithm:**
- Dynamic programming 2D matrix (max 100×100)
- Handles character insertions, deletions, substitutions
- Case-insensitive (text normalized to lowercase)
- Returns edit distance (0 = identical, MaxLen = completely different)

### Expense Report Creation Flow

```
Employee selects "Create Report from Corp Card Expenses"
    ↓
EACorpCardReportMgt.CreateReportFromCorpCardExpenses(EmployeeNo)
    → Finds all Expense records where:
        - Expense User No. = EmployeeNo
        - Status in [Open, Released]
        - Expense Report No. = empty
    → Creates new Expense Report Header
    → Links all matching expenses to new report
    → Returns Report No.
    ↓
Employee Reviews & Submits Report
    → Status: Open → Pending Approval
    ↓
EACorpCardApprovalMgt.SubmitReportForApproval(ReportNo)
    → Validates report has ≥1 expense
    → Updates Status = Pending Approval
    → Logs event
    ↓
Manager Approval (Standard Expense Agent Workflow)
    → Uses "Enable Approval Workflow" setup flag
    → Routes to configured approvers (per setup)
    ↓
Report Released & Posted
    → EACorpCardApprovalMgt.ReleaseReportForPosting()
    → Status: Pending Approval → Released
    ↓
Platform ExpenseReportPost (Codeunit 6987)
    → Creates GL journal lines
    → Creates Expense Ledger Entries
    → Status: Released → Posted
```

---

## Configuration & Setup

### Pre-Deployment (Instance Setup)

1. **Enable Expense Agent**
   - Navigate: Expense Agent Setup
   - Flag: "Enable Agent" = true
   - Set No. Series for Expenses and Expense Reports

2. **Configure Providers**
   - Navigate: Corp Card Providers
   - For each provider: Set Code, Name, Enable flag
    - Upload first payload or configure API connection
    - For API providers set:
      - Feed Type = API
      - API Endpoint = bank/provider endpoint
      - Auth Type = None, ApiKey, OAuth2, or Basic
      - Secret Ref = Azure Key Vault secret name (required for all auth types except None)
    - Keep Data Exchange Definition/Mapping configured for the response payload format

#### Phase 1 Configuration Example (API Provider)

Use the following as a baseline provider record for testing:

| Field | Example Value | Notes |
|------|----------------|-------|
| Code | `CORPCARDAPI` | Provider identifier (max 20 chars) |
| Description | `Corporate Card API (Sandbox)` | Free text |
| Enabled | `true` | Required to run import |
| Feed Type | `API` | Routes through API source provider |
| Auth Type | `ApiKey` | `None`, `ApiKey`, `OAuth2`, or `Basic` |
| API Endpoint | `https://sandbox.bank.example.com/v1/corp-card/transactions` | Phase 1 uses HTTP GET |
| Secret Ref | `CorpCardApiKeySandbox` | Azure Key Vault secret name |
| Data Exch Def Code | `EACCCSV` | Must match response format mapping |
| Data Exch Map Code | `CSV` | Header/detail mapping line code |
| Source File Name | `CorpCardApiPayload.csv` | Optional, helps format detection |
| Import Frequency (Min) | `1440` | Daily schedule example |

Validation checklist for this sample:
- `Test Import` creates a batch and stores Data Exchange content.
- Parsed rows appear in Corp Card Transactions.
- No mandatory mapping errors for Card Id, Provider Trans Id, Trans Date, Amount.

#### Phase 1 Configuration Example (OAuth2 Bearer Token)

Use the following when the provider expects an `Authorization: Bearer <token>` header and the token is stored in Key Vault:

| Field | Example Value | Notes |
|------|----------------|-------|
| Code | `CORPCARDOAUTH` | Provider identifier (max 20 chars) |
| Description | `Corporate Card API (OAuth2 Token)` | Free text |
| Enabled | `true` | Required to run import |
| Feed Type | `API` | Routes through API source provider |
| Auth Type | `OAuth2` | Phase 1 uses secret value as bearer token |
| API Endpoint | `https://sandbox.bank.example.com/v2/transactions` | Phase 1 uses HTTP GET |
| Secret Ref | `CorpCardOAuthBearerSandbox` | Azure Key Vault secret with bearer token value |
| Data Exch Def Code | `EACCL3VAT` | Use mapping that matches API payload structure |
| Data Exch Map Code | `L3HDR` | Header mapping for transaction rows |
| Source File Name | `CorpCardApiPayload.xml` | Optional, helps format detection |
| Import Frequency (Min) | `60` | Hourly schedule example |

Validation checklist for this sample:
- `Test Import` returns HTTP 2xx and creates a batch.
- Imported transactions include required mapped fields.
- If Level 3 payload is returned, `L3DTL` rows are parsed and visible in Level 3 details.

3. **Configure Import Parameters**
    - Navigate: Expense Agent Setup → Corporate Card
    - Corp Card Create Mode
    - Corp Card Date Match Window (first-time default: 7)
    - Corp Card Amount Tolerance (first-time default: 5)
    - Corp Card Auto Create Draft (first-time default: true)
    - Corp Card Default Provider

4. **Enable Approval Workflow (Optional)**
   - Navigate: Expense Agent Setup
   - Flag: "Enable Approval Workflow" = true
   - Configure approvers per employee/department

### Post-Deployment (First-Time Tasks)

1. **Apply Corp Card Default Settings**
    - Navigate: Expense Agent Setup → Setup → Apply corp card default settings
    - Runs codeunit EACreateCorpCardSetup and now also initializes MCC mappings and related Expense Categories.
    - MCC/category seeding is idempotent (existing records are not duplicated).

    Seeded MCC mappings from sample feeds:
    - 4112 (Rail Passenger Transport) → GROUNDTRAN
    - 4121 (Taxicabs and Limousines) → GROUNDTRAN
    - 4511 (Airlines) → AIRLINE
    - 4722 (Travel Agencies) → TRAVELAGENCY
    - 5111 (Office Supplies) → OFFICESUPPLIES
    - 5541 (Service Stations) → CAR
    - 5812 (Restaurants) → MEALS
    - 5943 (Stationery and Office Stores) → OFFICESUPPLIES
    - 7011 (Hotels and Lodging) → HOTELS
    - 7523 (Parking Lots and Garages) → PARKING

    Legacy demo mappings retained:
    - 7394 (Car Rental) → RENTALCARS
    - 7399 (Business Services) → MISC
    - 5542 (Fuel Dispensers) → CAR

2. **Apply Corp Card Level 3 Demo**
    - Navigate: Expense Agent Setup → Setup → Apply corp card level 3 demo
    - Creates provider `CORPCARDL3` and demo Data Exchange definition `EACCL3VAT`
    - Seeds header line mapping `L3HDR` and detail line mapping `L3DTL`
    - Ensures provider-specific corporate card links exist for `CORPCARDL3`
    - Initializes default MCC mappings and mapped Expense Categories (idempotent)
    - Builds sample payload using actual card IDs assigned to `CORPCARDL3`
    - Uploads sample payload for mixed VAT detail scenarios

### VAT Specification Line Numbering

When VAT specification rows are created from imported Level 3 details:

- Temporary aggregation records may use explicit line numbers for in-memory grouping.
- Persisted `Expense VAT Specification` rows are inserted with `Line No.` reset, so table autoincrement assigns unique values.
- This prevents duplicate-key collisions on (`Expense No.`, `Line No.`) while preserving standard table behavior.

3. **Access Corporate Card Features**
   - Navigate: Expense Management Role Center → Corporate Card group
   - Available actions:
     - **Corp Card Dashboard:** View import statistics & recent batches
     - **Corp Card Providers:** Manage providers & scheduling
    - **Corp Card Setup:** Opens Expense Agent Setup (Corporate Card group)
     - **Merchant Normalization Rules:** Add custom regex patterns
     - **MCC Code Mappings:** Map category codes to expense categories

4. **Add Custom Merchant Rules**
   - From Role Center: Corp Card → Merchant Normalization Rules
   - For each pattern: Set Regex pattern, normalized name, category, priority
   - Active flag: Enable/disable rules without deletion

5. **Schedule Provider Imports**
   - From Role Center: Corp Card → Corp Card Providers
   - For each enabled provider:
     - Action: Schedule Import
     - Frequency: Immediate/Hourly/Daily/Weekly
     - Job Queue created with retry logic (max 3 attempts)

### Sample Card-ID Conventions

Static samples use provider-specific card ID prefixes to avoid cross-provider ambiguity:

- CSV sample (`CorpCard-Sample-60.csv`) uses `CRDCSV-xxxx`
- CAMT.053 sample (`CorpCard-Sample-60-SEPA-CAMT053.xml`) uses `CRDC53-xxxx`
- CAMT.054 sample (`CorpCard-Sample-60-SEPA-CAMT054.xml`) uses `CRDC54-xxxx`
- ISO20022 sample (`CorpCardISO20022Sample.xml`) uses `CRDISO-xxxx`
- Level 3 sample (`CorpCard-Sample-Level3.xml`) uses `CRDL3-xxxx`

For runtime Level 3 demo payloads, card IDs are generated from provider cards linked to `CORPCARDL3`.

---

## Telemetry Events

All events logged to platform telemetry with:
- **DataClassification:** SystemMetadata (no PII)
- **TelemetryScope:** ExtensionPublisher
- **Category:** "Corporate Card"

### Import Lifecycle (0000UCS - 0000UCT)

| Event ID | Event | Trigger | Verbosity | Data |
|----------|-------|---------|-----------|------|
| 0000UCS | ImportStarted | Provider starts import | Normal | Provider Code, Batch No. |
| 0000UCT | ImportCompleted | Batch finishes successfully | Normal | Provider Code, Batch No., Imported count, Exception count, Duplicate count |
| 0000UCU | ImportFailed | Batch fails with error | Warning | Provider Code, Batch No., Error message |

### Processing Pipeline (0000UCV - 0000UCX)

| Event ID | Event | Trigger | Verbosity | Data |
|----------|-------|---------|-----------|------|
| 0000UCV | MatchingCompleted | Post-import matching finishes | Normal | Matched count, Unmatched count |
| 0000UCW | DraftCreated | New expense draft created | Normal | Transaction Entry No., Expense No. |
| 0000UCX | JobQueueScheduled | Import job queued | Normal | Provider Code, Frequency |

### Report Workflow (0000UCY - 0000UD1)

| Event ID | Event | Trigger | Verbosity | Data |
|----------|-------|---------|-----------|------|
| 0000UCY | ReportCreatedFromCorpCard | Report auto-created from corp card exps | Normal | Report No., Employee No. |
| 0000UCZ | ReportSubmittedForApproval | Employee submits report | Normal | Report No., User ID |
| 0000UD0 | ReportApprovedForPosting | Manager approves & releases | Normal | Report No., Approver ID |
| 0000UD1 | ReportRejected | Manager rejects report | Warning | Report No., Rejector ID, Reason |

---

## Integration Points

### With Existing Objects

| Object | Integration | Purpose |
|--------|-----------|---------|
| **Data Exchange Framework** | Used for file parsing | Validates field mappings via EACorpCardMapMgt |
| **Expense Table** | Receives drafted transactions | Individual expense records created on no match |
| **Expense Report Header/Line** | Aggregates expenses | Report-level approval & GL posting |
| **Job Queue Entry** | Schedules recurring imports | Retry logic: max 3 attempts, status updates |
| **Expense Status Enum** | Defines workflow states | Open → Released → Pending Approval → (Posted via Report) |
| **MCC Merchant Category Codes** | Category mapping | 4-digit codes map to Expense Category for GL account determination || **Expense Management Role Center** | Navigation hub | New "Corporate Card" group with 5 actions for dashboard/setup/config |
| **Expense User Page** | Employee integration | CorporateCards action shows employee's corporate card cards |
### With External Systems

| System | Method | Details |
|--------|--------|---------|
| **Bank/Card Processor** | Provider.Download() | API pull (Phase 1) or file payload import via Data Exchange |
| **GL (via Report Posting)** | ExpenseReportPost (6987) | Platform handles journal creation |
| **Approval Workflow** | Standard Expense Agent workflow | Uses existing approval rules & routes |

### API Provider Integration (Phase 1)

- Feed Type `API` is routed through the existing provider pipeline.
- Source content is injected by codeunit `EACorpCardApiSourceProv` through the `OnProvideSourceContent` event.
- Retrieved API payload is written into the Data Exchange file content blob and parsed by existing mappings.
- Existing post-import orchestration is unchanged (normalization, matching, draft creation, L3 detail handling).

Auth behavior in Phase 1:
- `None`: no auth header is added.
- `ApiKey`: sends header `x-api-key: <secret>`.
- `OAuth2`: sends header `Authorization: Bearer <secret>` (pre-issued token pattern).
- `Basic`: sends header `Authorization: Basic <secret>`.
- `Cert`: currently not supported in Phase 1.

---

## Navigation & UI Integration

### Role Center Hub (ExpenseManagementRoleCenter)

A **"Corporate Card"** section is available in the main Expense Management Role Center with 5 key actions:

```
ExpenseManagementRoleCenter (6933)
└── Corporate Card Group
    ├─ Corp Card Dashboard (7228)
    │  └─ Shows: Recent batches, statistics, import status
    │  └─ Actions: Providers, Transactions, Batches, Exceptions, Setup
    ├─ Corp Card Providers (7224)
    │  └─ Manage provider credentials & scheduling
    ├─ Corp Card Setup
    │  └─ Opens Expense Agent Setup (Corporate Card settings)
    ├─ Merchant Normalization Rules (7227)
    │  └─ Create/edit regex patterns for merchant standardization
    └─ MCC Code Mappings (7225)
       └─ Map merchant category codes to expense categories
```

**Access:** Expense Management Role Center → Sections → Corporate Card

### Dashboard Navigation

The **EACorpCardDashboard** (RoleCenter 7228) provides drill-down navigation:

| Navigation Area | Target | Purpose |
|-----------------|--------|---------|
| Providers | EACorpCardProviders (7224) | View/manage all providers |
| Transactions | EACorpCardTransList (7223) | View imported transactions |
| Batches | EACorpCardBatches (7220) | View import batches |
| Exceptions | EACorpCardExceptions (7222) | View & resolve import errors |
| Setup | Expense Agent Setup (6996) | Configure import parameters |

### Employee Integration

**ExpenseUser.Page** (Individual employee card) includes:

- **CorporateCards** action in Navigation area
- Filters: Shows only corporate cards for that employee
- Navigates to: **EACorpCardCards** page
- Purpose: Employee views their assigned corporate cards

### List Relationships

Pages are interlinked with drill-down actions:

| Page | Drill-Down Actions |
|------|-------------------|
| EACorpCardBatches (7220) | → Show Transactions, Run Matching |
| EACorpCardTransList (7223) | → Open Matched Expense, Show Level 3 Details |
| EACorpCardExceptions (7222) | → Mark Resolved, View Batch, View Transaction |

---

## Key Features

### Intelligent Matching

✅ **Multi-Strategy:** Tries 3 progressively fallback strategies  
✅ **Fuzzy Algorithm:** Levenshtein distance for typo tolerance  
✅ **Scoring:** 0-100 scale with degradation for date/amount variance  
✅ **Configurable:** Match window + amount tolerance via setup  

### Draft-Per-Transaction Mode

✅ **AutoDraft 1:1:** One imported transaction creates one draft expense  
✅ **Amount Integrity:** Draft amount equals transaction amount  
✅ **Deterministic Output:** No reuse of existing open expenses in AutoDraft mode  

### Merchant Normalization

✅ **Regex Patterns:** Custom pattern matching for merchant name standardization  
✅ **Priority-Based:** Rules sorted by priority, first match wins  
✅ **Category Mapping:** Patterns can assign expense category automatically  
✅ **MCC Integration:** 4-digit code mapping with auto-created category seeds  

### Job Queue Scheduling

✅ **Recurring Imports:** Daily/weekly/hourly frequency options  
✅ **Automatic Retry:** 3 attempts, status auto-updates  
✅ **Resilient:** Catches errors, logs, continues next cycle  
✅ **Manageable:** UI for schedule create/update/delete  

### Comprehensive Logging

✅ **10 Telemetry Events:** Full lifecycle visibility  
✅ **Audit Trail:** All actions timestamped and attributed  
✅ **Error Tracking:** Warnings on import/rejection failures  
✅ **No PII:** SystemMetadata classification only  

---

## Error Handling & Recovery

### Import Errors

| Scenario | Action | Result |
|----------|--------|--------|
| Provider file format error | Logged as exception | Transaction marked Status=Exception, batch continues |
| Field mapping missing | Validation error raised | Import stops, user notified, batch marked Failed |
| No data in file | Import fails with explicit error | Batch marked Failed with diagnostics |

### Matching Errors

| Scenario | Action | Result |
|----------|--------|--------|
| Expense User No. missing | Expense draft creation fails, logged | Transaction marked unmatched |
| Amount tolerance = 0 (exact only) | No exact match found | Falls through to fuzzy/employee match |
| No open expenses for user | All 3 strategies fail | Status = Imported (awaits manual action) |

### Level 3 Reconciliation Warning

When Level 3 detail rows are present, draft creation compares the summed detail totals against the transaction header amount.

If values differ (rounded to 2 decimals), processing continues but a warning is written to transaction field `Reject Reason` for manual review before report submission.

### Job Queue Errors

| Scenario | Action | Result |
|----------|--------|--------|
| Provider API timeout | Error caught in JQRunner | Rerun count increments, status=Scheduled |
| After max attempts (3) | Status set to Error | User must manually retry or investigate |
| Provider marked disabled | Skipped in RunAllEnabledProviders | No error, silently skipped |

---

## Performance Considerations

### Batch Processing

- **Typical batch size:** 100-500 transactions per provider per cycle
- **Matching time:** ~10ms per transaction (Levenshtein + query)
- **Post-import time:** ~500-2000ms per batch (normalization + matching + draft creation)
- **Recommendation:** Run imports in background (Job Queue) for batches >1000 records

### Memory

- **Levenshtein matrix:** 100×100 dynamic programming (capped at 100 chars per string)
- **Merchant rules:** Loaded into memory (cache friendly, typically <1000 rules)
- **Transaction buffer:** ProcessBatchPostImport uses FindSet/Next (streaming, low memory)

### Database

- **Indexes recommended:**
  - EACorpCardTrans: (Batch No., Status)
  - EACorpCardTrans: (Expense User No., Trans Date, Amount)
  - Expense: (Expense User No., Status, Currency)
  - Expense: (Expense Report No.)

---

## Testing Checklist

- [ ] Import a provider CSV file with 10+ transactions
- [ ] Verify 3 are matched exactly, 3 are matched fuzzy, 4 are unmatched
- [ ] Create draft expenses for unmatched (Auto-Create=true)
- [ ] Create expense report and add 3-5 expenses
- [ ] Submit report for approval
- [ ] Manager approves/rejects (if approval workflow enabled)
- [ ] Post report and verify GL journal entries created
- [ ] Check telemetry events in Application Insights (if configured)

---

## Known Limitations

1. **MCC Category Scope:** Demo MCC/category mappings are seeded for sample coverage; production tenants should review and extend mappings based on local card programs
2. **Max String Length:** Levenshtein algorithm capped at 100 characters (longer strings truncated)
3. **Regex Performance:** Complex regex patterns may slow normalization (use specific patterns)
4. **Single Approver:** Approval workflow uses first approver from setup (no chain routing)
5. **No Receipt Matching:** Does not support image-based receipt OCR (future enhancement)
6. **API Scope (Phase 1):** API ingestion uses HTTP GET and relies on Data Exchange mappings for response parsing; no custom request body/verb configuration yet
7. **OAuth2 Scope (Phase 1):** OAuth2 auth type uses a secret value as bearer token and does not yet perform dynamic token acquisition per provider
8. **Certificate Auth (Phase 1):** Certificate-based provider auth is not yet implemented

---

## Future Enhancements

- [ ] **Receipt Image Matching:** Attachment-based expense verification via OCR
- [ ] **Multi-Transaction Grouping:** Detect related transactions for per-diem/group expenses
- [ ] **Vendor Master Integration:** Link transactions to vendor records (AP reconciliation)
- [ ] **Rule-Based Auto-Approval:** Trusted vendor/amount workflows (no manager review)
- [ ] **Advanced Reporting:** Reconciliation reports, variance analysis, expense trends
- [ ] **ML-Based Categorization:** Machine learning for MCC/category prediction

---

## Support & Troubleshooting

### Import Not Running

**Symptom:** No new transactions in staging  
**Check:**
1. Provider enabled? → EACorpCardProvider.Enabled = true
2. Job Queue scheduled? → EACorpCardProviders page, Schedule Import action
3. Job Queue running? → Monitor Job Queue Entry table for status
4. Provider credentials valid? → Test via "Test Import" action on provider

### API Provider Returns No Transactions

**Symptom:** API provider import runs but no staging transactions are created  
**Check:**
1. Provider Feed Type is `API`
2. API endpoint is reachable from environment and returns non-empty payload
3. Auth Type/Secret Ref are correct and secret exists in Azure Key Vault
4. Data Exchange Definition/Line Mapping match the API response structure
5. Imported response format aligns with expected parser profile (XML/CSV/etc.)

### Matching Accuracy Low

**Symptom:** Many transactions unmatched  
**Check:**
1. Date window too narrow? → Increase Expense Agent Setup."Corp Card Date Match Window"
2. Amount tolerance too strict? → Increase Expense Agent Setup."Corp Card Amount Tolerance"
3. Merchant names different? → Add regex normalization rules in EACorpCardMerchantRule
4. No open expenses for employees? → Ensure Open expenses exist before import

### Draft Expenses Not Created

**Symptom:** Unmatched transactions but no drafts  
**Check:**
1. Auto-Create enabled? → Set Expense Agent Setup."Corp Card Auto Create Draft" = true
2. Create mode? → For strict 1:1 creation set Expense Agent Setup."Corp Card Create Mode" = AutoDraft
3. Expense User No. valid? → Verify transaction has expense user linked
4. Transaction status? → Should be Status=Imported before post-import processing

### File Format Visibility

**Symptom:** Unsure which profile will be used for import  
**Check:** Corp Card Providers page → `Detected Source Format` column (CSV/XML/CAMT/Not set/Unknown)

### Level 3 Detail Visibility

**Symptom:** Need to inspect imported VAT/tax sub-lines for one transaction  
**Check:** Corp Card Transactions page → action `Show Level 3 Details`

### "Card Id is missing" Validation Exceptions

**Symptom:** Import exceptions show `Card Id is missing.` and no transactions are inserted  
**Check:**
1. Provider has corporate card links (`EACorpCard`) for that provider code
2. Sample payload card IDs match cards linked to the same provider
3. Re-run `Apply corp card level 3 demo` to refresh provider links and payload
4. Verify provider `Data Exch Def Code`/`Data Exch Map Code` still point to the expected line definition

---

## Object ID Allocation

**Range:** [7210–7299] (90 IDs)  
**Used in Sprint 3:** 7210-7219, 7223, 7257 (12 codeunits + 7 pages)  
**Available:** 7220-7222, 7225-7256, 7258-7299 (77 IDs for future enhancements)

---

**Document Version:** 1.5  
**Last Updated:** 2026-07-31  
**Module Status:** Active (API/CSV/XML/ISO20022/CAMT.053/CAMT.054 import and AutoDraft 1:1 flow enabled)
