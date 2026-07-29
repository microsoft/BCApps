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
2. **Multi-Format Support** - CSV, generic XML, and SEPA CAMT mapping profiles
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
│ - Transactions imported to staging table (EACorpCardTrans)         │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 2: MERCHANT NORMALIZATION                                     │
│ - Regex patterns applied to normalize merchant names                │
│ - Rules sorted by priority, first match wins                        │
│ - Normalized name + category stored for later use                   │
│ - Codeunit: EACorpCardMerchantNorm (7210)                          │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 3: TRANSACTION MATCHING                                       │
│ - Strategy 1: Exact amount/date match (score 50-100)               │
│ - Strategy 2: Fuzzy merchant name match via Levenshtein (70-85%)   │
│ - Strategy 3: Employee-only match as fallback (score 50)            │
│ - Match type & score stored; transaction status updated             │
│ - Codeunit: EACorpCardEnhancedMatchMgt (7216)                      │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 4: DRAFT CREATION / MANUAL MATCHING                           │
│ - AutoDraft mode: always creates 1 draft per imported transaction   │
│ - ManualLink mode: tries matching first, then optional draft create │
│ - Codeunit: EACorpCardExpWriter (7212)                             │
│ - MCC mapping to category: Codeunit EACorpCardMCCMgt (7217)        │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 5: REPORT AGGREGATION                                         │
│ - Employee reviews drafts and existing expenses                      │
│ - Creates/updates Expense Report via UI or EACorpCardReportMgt     │
│ - Adds individual expenses to report                                │
│ - Codeunit: EACorpCardReportMgt (7219)                             │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 6: APPROVAL & POSTING                                         │
│ - Employee submits Expense Report for approval                      │
│ - Manager approves via standard Expense Agent workflow              │
│ - Report released to Posted status                                  │
│ - GL postings created via platform ExpenseReportPost (6987)        │
│ - Codeunit: EACorpCardApprovalMgt (7218)                           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Objects Created

### Codeunits (11 total)

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

### Pages (12 total)

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
    → Injects source file content (CSV/XML/CAMT)
            ↓
Provider.ParseToStaging()
    → Validates field mappings (EACorpCardMapMgt)
    → Imports data to EACorpCardTrans (Status=Imported)
    → Calls EACorpCardPostImportOrch.ProcessBatchPostImport()
            ↓
EACorpCardPostImportOrch.ProcessBatchPostImport()
    → For each transaction:
        1. EACorpCardMerchantNorm.NormalizeTransaction()
        2. If Create Mode = AutoDraft: EACorpCardExpWriter.CreateDraftFromTrans()
        3. Else try EACorpCardEnhancedMatchMgt.EnhancedMatchTransaction()
        4. If unmatched + Auto-Create: EACorpCardExpWriter.CreateDraftFromTrans()
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

1. **Initialize MCC Mappings**
   ```al
   var MCCMgt: Codeunit EACorpCardMCCMgt;
   begin
     MCCMgt.InitializeDefaultMCCMappings();
   end;
   ```
   Creates 6 default mappings:
   - 4511 (Airlines) → Travel
   - 7011 (Hotels) → Travel
   - 5812 (Restaurants) → Meals
   - 7394 (Car Rental) → Travel
   - 7399 (Business Services) → Office Supplies
   - 5542 (Fuel) → Transportation

2. **Access Corporate Card Features**
   - Navigate: Expense Management Role Center → Corporate Card group
   - Available actions:
     - **Corp Card Dashboard:** View import statistics & recent batches
     - **Corp Card Providers:** Manage providers & scheduling
    - **Corp Card Setup:** Opens Expense Agent Setup (Corporate Card group)
     - **Merchant Normalization Rules:** Add custom regex patterns
     - **MCC Code Mappings:** Map category codes to expense categories

3. **Add Custom Merchant Rules**
   - From Role Center: Corp Card → Merchant Normalization Rules
   - For each pattern: Set Regex pattern, normalized name, category, priority
   - Active flag: Enable/disable rules without deletion

4. **Schedule Provider Imports**
   - From Role Center: Corp Card → Corp Card Providers
   - For each enabled provider:
     - Action: Schedule Import
     - Frequency: Immediate/Hourly/Daily/Weekly
     - Job Queue created with retry logic (max 3 attempts)

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
| **Bank/Card Processor** | Provider.Download() | OAuth2/API/SFTP file download |
| **GL (via Report Posting)** | ExpenseReportPost (6987) | Platform handles journal creation |
| **Approval Workflow** | Standard Expense Agent workflow | Uses existing approval rules & routes |

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
| EACorpCardTransList (7223) | → Open Matched Expense |
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
✅ **MCC Integration:** Alternative 4-digit code mapping for category  

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

1. **MCC Initialization Manual:** Default MCC mappings must be initialized by user (not auto on setup)
2. **Max String Length:** Levenshtein algorithm capped at 100 characters (longer strings truncated)
3. **Regex Performance:** Complex regex patterns may slow normalization (use specific patterns)
4. **Single Approver:** Approval workflow uses first approver from setup (no chain routing)
5. **No Receipt Matching:** Does not support image-based receipt OCR (future enhancement)

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

---

## Object ID Allocation

**Range:** [7210–7299] (90 IDs)  
**Used in Sprint 3:** 7210-7219, 7223 (11 codeunits + 7 pages)  
**Available:** 7220-7222, 7225-7299 (78 IDs for future enhancements)

---

**Document Version:** 1.1  
**Last Updated:** 2026-07-29  
**Module Status:** Active (CSV/XML/CAMT import and AutoDraft 1:1 flow enabled)
