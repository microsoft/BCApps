# Corporate Card Module Documentation

## Overview

The Corporate Card module for Expense Agent provides automated import, normalization, draft creation, reporting, and payment reconciliation of corporate card transactions in Business Central.

**Namespace:** `Microsoft.ExpenseAgent`  
**Access Level:** `Internal` (all objects)  
**Integration:** Extends standard Expense Agent workflow (no breaking changes)

---

## Architecture

### Design Principles

1. **Automated Import Pipeline** - Provider-driven file import with field mapping validation
2. **Multi-Format Support** - CSV, XML, ISO20022, CAMT.053, and CAMT.054 mapping profiles
3. **Configurable Creation Mode** - AutoDraft can create one draft per imported transaction
4. **Scheduled Processing** - Job Queue integration for recurring imports with retry resilience
5. **Standard Workflows** - Leverages platform Expense Report approval, GL posting, Payment Reconciliation, and Bank Account posting
6. **Comprehensive Observability** - Telemetry at every step: import → normalization → matching → reporting
7. **Low-Risk Banking Integration** - Retains `EACorpCardTrans` as the provider and audit record while using standard banking records for financial settlement

### Workflow Stages

```
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 1: PROVIDER IMPORT                                            │
│ - Provider supplies uploaded transaction data                       │
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
│ - Codeunit: EACorpCardMerchantNorm (7420)                           │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 3: TRANSACTION MATCHING                                       │
│ - Strategy 1: Exact amount/date match (score 50-100)                │
│ - Strategy 2: Fuzzy merchant name match via Levenshtein (70-85%)    │
│ - Strategy 3: Employee-only match as fallback (score 50)            │
│ - Match type & score stored; transaction status updated             │
│ - Codeunit: EACorpCardEnhancedMatchMgt (7426)                       │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 4: DRAFT CREATION / MANUAL MATCHING                           │
│ - AutoDraft mode: always creates 1 draft per imported transaction   │
│ - ManualLink mode: tries matching first, then optional draft create │
│ - Level 3 detail rows can seed Expense VAT Specification lines      │
│ - Persisted VAT spec lines rely on table autoincrement for Line No. │
│ - Warns if Level 3 totals differ from transaction header amount     │
│ - Codeunit: EACorpCardExpWriter (7422)                              │
│ - MCC mapping to category: Codeunit EACorpCardMCCMgt (7427)         │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 5: REPORT AGGREGATION                                         │
│ - Employee reviews drafts and existing expenses                     │
│ - Creates/updates Expense Report via UI or EACorpCardReportMgt      │
│ - Adds individual expenses to report                                │
│ - Codeunit: EACorpCardReportMgt (7429)                              │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 6: APPROVAL & POSTING                                         │
│ - Employee submits Expense Report for approval                      │
│ - Manager approves via standard Expense Agent workflow              │
│ - Report released to Posted status                                  │
│ - GL postings created via platform ExpenseReportPost (6987)         │
│ - Codeunit: EACorpCardApprovalMgt (7428)                            │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 7: PAYMENT RECONCILIATION                                     │
│ - Credit-card expense posting marks the source transaction ready    │
│ - Configured cards create standard Payment Application lines        │
│ - Lines debit the card-paid clearing account and credit the bank    │
│ - Standard posting creates Bank Account Ledger/Statement entries    │
│ - Durable links retain transaction and posted report traceability   │
│ - Codeunit: EA Corp Card Bank Rec Mgt (7440)                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Objects Created

### Codeunits (12 total)

| ID | Name | Purpose | Key Procedures |
|----|------|---------|-----------------|
| 7420 | EACorpCardMerchantNorm | Merchant name normalization via regex patterns | NormalizeTransaction, FindMatchingRule, PatternMatches |
| 7421 | EACorpCardMatchMgt | Basic transaction matching (reference only) | MatchTransaction |
| 7422 | EACorpCardExpWriter | Draft Expense creation from transactions | CreateDraftFromTrans, LinkPosted, GetExpenseCategoryFromMCC |
| 7423 | EACorpCardPostImportOrch | Post-import orchestration pipeline | ProcessBatchPostImport |
| 7424 | EACorpCardAuditSubscribers | Centralized telemetry logging | LogImportStarted/Completed/Failed, LogMatchingCompleted, LogDraftCreated, LogReportCreatedFromCorpCard, LogReportSubmittedForApproval, LogReportApprovedForPosting, LogReportRejected |
| 7425 | EACorpCardJQMgt | Job Queue entry lifecycle management | ScheduleProviderImport, UnscheduleProviderImport, UpdateJobQueueFrequency |
| 7426 | EACorpCardEnhancedMatchMgt | Multi-strategy matching with fuzzy algorithm | EnhancedMatchTransaction, CalculateSimilarity, LevenshteinDistance |
| 7427 | EACorpCardMCCMgt | MCC validation and category mapping | ValidateAndMapMCC, GetExpenseCategoryForMCC, InitializeDefaultMCCMappings, IsValidMCC |
| 7428 | EACorpCardApprovalMgt | Expense Report approval workflow | SubmitReportForApproval, ReleaseReportForPosting, RejectReport |
| 7429 | EACorpCardReportMgt | Expense Report aggregation | CreateReportFromCorpCardExpenses, AddExpenseToReport, ReleaseExpenseForReporting |
| 7433 | EACorpCardJQRunner | Job Queue entry point with error resilience | OnRun (Job Queue trigger) |
| 7440 | EA Corp Card Bank Rec Mgt | Creates Payment Application reconciliations and maintains posted banking links | CreateReconciliation, expense-posting and bank-posting subscribers |

### Pages and Page Extensions (16 total)

| ID | Name | Type | Purpose |
|----|------|------|----------|
| 7430 | EACorpCardBatches | List | Import batch listing with transaction/exception drill-down |
| 7431 | EACorpCardCards | List | Corporate card transaction list (import staging) |
| 7432 | EACorpCardExceptions | List | Import exceptions with resolution tracking |
| 7433 | EACorpCardTransList | List | Imported transaction listing with expense linking |
| 7434 | EACorpCardProviders | List | Provider administration with scheduling actions |
| 7435 | EACorpCardMCCMap | List | Merchant category code to expense category mapping |
| 7437 | EACorpCardMerchantRules | List | Merchant name normalization regex pattern rules |
| 7438 | EACorpCardDashboard | RoleCenter | Import reconciliation dashboard with navigation |
| 7439 | EACorpCardJQSchedule | List+Card | Job Queue schedule management UI for providers |
| 7445 | EACorpCardJQScheduleSubpage | Subpage | Read-only Job Queue entry details filtered by provider |
| 7441 | EACorpCardDashboardFactbox | ListPart | Recent import batches sorted chronologically |
| 7442 | EACorpCardStatisticsFactbox | CardPart | KPI statistics (30-day rolling aggregation) |
| 7099 | EACorpCardL3Details | List | Imported Level 3 VAT/tax detail lines per transaction |
| 7440 | EA Payment Rec. Journal | Page extension | Shows corporate card transaction and posted expense report references |
| 7441 | EA Bank Account Stmt. Lines | Page extension | Shows durable corporate card and posted expense report references |
| 7442 | EA Bank Acc. Ledger Entries | Page extension | Shows the originating corporate card transaction |

### Tables and Table Extensions

The module retains its existing Expense Agent records and extends standard banking records:

- **EACorpCardTrans** - Provider transaction, enrichment, matching, workflow, and audit record
- **EACorpCard** - Card configuration, including the optional Bank Account used for reconciliation
- **Expense** - Individual expense records (platform)
- **Expense Report Header / Line** - Report aggregation (platform)
- **Data Exch.** / **Data Exch. Field** - File import mapping (platform)
- **Job Queue Entry** - Scheduled job storage (platform)
- **Bank Acc. Reconciliation Line** (table extension 7440) - Working link to the transaction and posted expense report
- **Bank Account Statement Line** (table extension 7441) - Durable posted-statement links
- **Bank Account Ledger Entry** (table extension 7442) - Durable transaction link on the bank entry
- **Gen. Journal Line** (table extension 7443) - Carries the transaction reference through standard posting

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
    → Credit-card lines credit the employee posting group's card-paid account
    → EACorpCardTrans status becomes ReadyForReconciliation
            ↓
EA Corp Card Bank Rec Mgt (Codeunit 7440)
    → If the card has no Bank Account No.: stops at ReadyForReconciliation
    → If configured: creates/reuses a Payment Application reconciliation
    → Creates one fully applied line for each posted corporate-card expense
    → Statement amount = -(Amount - Non-Refundable Amount)
    → Converts expense currency to reimbursement currency when required
    → Applies the line to the card-paid G/L clearing account
    → Status: ReadyForReconciliation → ReconciliationCreated
            ↓
Standard Bank Acc. Reconciliation Post
    → Posts the applied journal line and creates Bank Account Ledger Entry
    → Full posting also creates Bank Account Statement/Line
    → Status: BankEntryCreated → Reconciled
    → Removes transient reconciliation references when working lines are deleted
```

Payment Application reconciliations are grouped by posted expense report and Bank Account. `EACorpCardTrans` remains the source audit record; `Bank Account Statement Line` is a posted archive and is not used as an import or staging table.

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
    - Select the feed type and configure its Data Exchange definition and mapping
    - Upload a source payload

3. **Configure Corporate Card Bank Accounts (Optional)**
   - Navigate: Corporate Cards
   - Set **Bank Account No.** on each card that should use standard Payment Reconciliation
   - The Bank Account currency must equal the posted expense report reimbursement currency
   - Leave the field blank to retain the existing expense-only workflow

4. **Configure Import Parameters**
    - Navigate: Expense Agent Setup → Corporate Card
    - Corp Card Create Mode
    - Corp Card Date Match Window (first-time default: 7)
    - Corp Card Amount Tolerance (first-time default: 5)
    - Corp Card Auto Create Draft (first-time default: true)
    - Corp Card Default Provider

5. **Enable Approval Workflow (Optional)**
   - Navigate: Expense Agent Setup
   - Flag: "Enable Approval Workflow" = true
   - Configure approvers per employee/department

### Post-Deployment (First-Time Tasks)

1. **Apply Corp Card Default Settings**
    - Navigate: Expense Agent Setup → Setup → Apply corp card default settings
    - Runs codeunit EACreateCorpCardSetup and now also initializes MCC mappings and related Expense Categories.
    - Creates the LCY bank account `CORPCARD` and assigns it to cards whose Bank Account No. is blank.
    - Reuses `CHECKING`, `PREC`, and `SEPA CAMT` configuration when those standard records are available.
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

3. **Contoso Demo Data**
    - Adds the dedicated LCY bank account `CORPCARD` for corporate card settlement
    - Configures the standard Payment Reconciliation number series and bank statement import format
    - Assigns `CORPCARD` to regular and Level 3 demo cards only when their Bank Account No. is blank

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
| **Bank Acc. Reconciliation/Line** | Standard Payment Application working document | Applies the card settlement to the card-paid G/L account |
| **Bank Account Ledger Entry** | Standard bank posting output | Records the corporate-card settlement against the configured Bank Account |
| **Bank Account Statement/Line** | Standard posted reconciliation archive | Retains transaction and posted expense report references |
| **Gen. Journal Line** | Standard posting bridge | Carries the corporate-card transaction reference into the bank ledger entry |
| **Job Queue Entry** | Schedules recurring imports | Retry logic: max 3 attempts, status updates |
| **Expense Status Enum** | Defines workflow states | Open → Released → Pending Approval → (Posted via Report) |
| **MCC Merchant Category Codes** | Category mapping | 4-digit codes map to Expense Category for G/L account determination |
| **Expense Management Role Center** | Navigation hub | New "Corporate Card" group with 5 actions for dashboard/setup/config |
| **Expense User Page** | Employee integration | CorporateCards action shows employee's corporate card cards |
### With External Systems

| System | Method | Details |
|--------|--------|---------|
| **Bank/Card Processor** | Provider.Download() | File payload import via Data Exchange |
| **GL (via Report Posting)** | ExpenseReportPost (6987) | Platform handles journal creation |
| **Banking (via Payment Application)** | Bank Acc. Reconciliation Post | Platform creates bank ledger and posted statement records |
| **Approval Workflow** | Standard Expense Agent workflow | Uses existing approval rules & routes |

---

## Navigation & UI Integration

### Role Center Hub (ExpenseManagementRoleCenter)

A **"Corporate Card"** section is available in the main Expense Management Role Center with 5 key actions:

```
ExpenseManagementRoleCenter (6933)
└── Corporate Card Group
    ├─ Corp Card Dashboard (7438)
    │  └─ Shows: Recent batches, statistics, import status
    │  └─ Actions: Providers, Transactions, Batches, Exceptions, Setup
    ├─ Corp Card Providers (7434)
    │  └─ Manage provider credentials & scheduling
    ├─ Corp Card Setup
    │  └─ Opens Expense Agent Setup (Corporate Card settings)
    ├─ Merchant Normalization Rules (7437)
    │  └─ Create/edit regex patterns for merchant standardization
    └─ MCC Code Mappings (7435)
       └─ Map merchant category codes to expense categories
```

**Access:** Expense Management Role Center → Sections → Corporate Card

### Dashboard Navigation

The **EACorpCardDashboard** (RoleCenter 7438) provides drill-down navigation:

| Navigation Area | Target | Purpose |
|-----------------|--------|---------|
| Providers | EACorpCardProviders (7434) | View/manage all providers |
| Transactions | EACorpCardTransList (7433) | View imported transactions |
| Batches | EACorpCardBatches (7430) | View import batches |
| Exceptions | EACorpCardExceptions (7432) | View & resolve import errors |
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
| EACorpCardBatches (7430) | → Show Transactions, Run Matching |
| EACorpCardTransList (7433) | → Open Matched Expense, Show Level 3 Details |
| EACorpCardExceptions (7432) | → Mark Resolved, View Batch, View Transaction |

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

### Standard Payment Reconciliation

- ✅ **Opt-In:** Existing behavior is unchanged when a card has no Bank Account configured
- ✅ **Standard Posting:** Uses Payment Application instead of custom bank-ledger posting
- ✅ **Accounting Accuracy:** Clears the posted card-paid amount after non-refundable reductions and currency conversion
- ✅ **Traceability:** Links the source transaction, posted expense report, reconciliation, bank ledger entry, and statement line
- ✅ **Idempotency:** A transaction cannot create a second reconciliation while linked to an existing working line
- ✅ **Recovery:** Deleting a working line clears stale references and makes an unposted transaction ready again

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

### Payment Reconciliation Errors

| Scenario | Action | Result |
|----------|--------|--------|
| Card has no Bank Account No. | Skip automatic reconciliation creation | Transaction remains ReadyForReconciliation; existing expense behavior is preserved |
| Bank Account currency differs from reimbursement currency | Raise an explicit validation error | No reconciliation line is created |
| Linked posted expense is not Credit Card reimbursement type | Raise standard field validation | No reconciliation line is created |
| Transaction already has a reconciliation reference | Reject duplicate creation | Existing working reference is preserved |
| Working reconciliation line is manually deleted | Clear transient reference | Unposted transaction returns to ReadyForReconciliation |
| Reconciliation is posted as payments only | Create the bank ledger entry and clear the deleted working reference | Status remains BankEntryCreated; no posted statement is created |

### Job Queue Errors

| Scenario | Action | Result |
|----------|--------|--------|
| Provider import failure | Error caught in JQRunner | Rerun count increments, status=Scheduled |
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
- [ ] Configure Bank Account No. on the corporate card and post a credit-card expense report
- [ ] Verify one Payment Application reconciliation is created per posted report and Bank Account
- [ ] Verify statement amounts are negative and exclude non-refundable amounts
- [ ] Verify different expense and reimbursement currencies use the reimbursement amount
- [ ] Post payments and reconcile; verify Bank Account Ledger Entry and Bank Account Statement Line links
- [ ] Delete an unposted reconciliation line and verify the transaction returns to ReadyForReconciliation
- [ ] Check telemetry events in Application Insights (if configured)

---

## Known Limitations

1. **MCC Category Scope:** Demo MCC/category mappings are seeded for sample coverage; production tenants should review and extend mappings based on local card programs
2. **Max String Length:** Levenshtein algorithm capped at 100 characters (longer strings truncated)
3. **Regex Performance:** Complex regex patterns may slow normalization (use specific patterns)
4. **Single Approver:** Approval workflow uses first approver from setup (no chain routing)
5. **No Receipt Matching:** Does not support image-based receipt OCR (future enhancement)
6. **Opt-In Reconciliation:** Cards without Bank Account No. do not create Payment Application reconciliations
7. **Currency Constraint:** The configured Bank Account currency must match the expense report reimbursement currency
8. **Runtime Test Infrastructure:** Reconciliation integration tests require a Business Central AL test runtime; compiler validation alone does not execute them

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
4. Source payload uploaded? → Check the provider's source file name and payload record count

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

### Payment Reconciliation Not Created

**Symptom:** The expense report was posted, but no Payment Application reconciliation exists

**Check:**
1. Corporate Card has **Bank Account No.** configured
2. Posted Expense Report Line has Reimbursement Type = Company Credit Card
3. Bank Account currency matches the Posted Expense Report reimbursement currency
4. Corporate Card Transaction contains the Posted Expense Report No.
5. Transaction status is Ready for Reconciliation and has no existing reconciliation reference
6. Use `Create Payment Reconciliation` on Corp Card Transactions to retry after correcting configuration

### "Card Id is missing" Validation Exceptions

**Symptom:** Import exceptions show `Card Id is missing.` and no transactions are inserted  
**Check:**
1. Provider has corporate card links (`EACorpCard`) for that provider code
2. Sample payload card IDs match cards linked to the same provider
3. Re-run `Apply corp card level 3 demo` to refresh provider links and payload
4. Verify provider `Data Exch Def Code`/`Data Exch Map Code` still point to the expected line definition

---

## Object ID Allocation

**Ranges:** [7420–7449], [7458–7477] (50 IDs per object type)
**Used:** 8 tables, 4 table extensions, 13 pages, 3 page extensions, 22 codeunits, 6 enums, and 3 permission sets
**Available:** 42 tables, 46 table extensions, 37 pages, 47 page extensions, 28 codeunits, 44 enums, and 47 permission sets

---

**Document Version:** 1.6

**Last Updated:** 2026-09-25

**Module Status:** Active (multi-format import, AutoDraft 1:1, Level 3 details, and opt-in standard Payment Reconciliation enabled)
