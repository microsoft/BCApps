# Corporate Card Module Documentation

## Overview

The Corporate Card module for Expense Agent provides automated import, normalization, draft creation, and reporting of corporate card transactions in Business Central.

**Namespace:** `Microsoft.ExpenseAgent`  
**Access Level:** `Internal` (all objects)  
**Integration:** Extends standard Expense Agent workflow (no breaking changes)

---

## Architecture

### Design Principles

1. **Automated Import Pipeline** - Provider-driven file import with field mapping validation
2. **File Import** - CSV and flat XML through Data Exchange mappings
3. **Configurable Creation Mode** - AutoDraft can create one draft per imported transaction
4. **Job Queue Setup** - Creates a daily job on hold; an administrator must enable it
5. **Standard Workflows** - Leverages platform Expense Report approval and G/L posting
6. **Observability** - Feature Telemetry for imports, matching, drafts, scheduling, and accounting transitions
7. **Accounting Boundary** - A dedicated corporate-card bank account represents the provider liability; the payment bank account represents real cash

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
│ - Case-insensitive substring patterns normalize merchant names      │
│ - Rules sorted by priority, first match wins                        │
│ - Normalized name stored for later use; MCC maps to category         │
│ - Codeunit: EACorpCardMerchantNorm (7420)                           │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 3: TRANSACTION MATCHING                                       │
│ - Strategy 1: Exact amount/date match (score 50-100)                │
│ - Strategy 2: Fuzzy merchant name match via Levenshtein (70-100)     │
│ - No employee-only fallback: unmatched stays for manual review      │
│ - Runs in ManualLink mode; AutoDraft does not match                  │
│ - Match type & score stored; transaction status updated             │
│ - Codeunit: EACorpCardEnhancedMatchMgt (7426)                       │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 4: DRAFT CREATION / MANUAL MATCHING                           │
│ - AutoDraft creates a draft unless a no-suffix expense match exists │
│ - ManualLink mode: tries matching first, then optional draft create │
│ - Level 3 detail import is not implemented                           │
│ - Codeunit: EACorpCardExpWriter (7422)                              │
│ - MCC mapping to category: Codeunit EACorpCardMCCMgt (7427)         │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 5: REPORT AGGREGATION                                         │
│ - Employee reviews drafts and existing expenses                     │
│ - Creates/updates Expense Report via standard Expense Agent UI      │
│ - EACorpCardReportMgt (7429) exists but has no callers               │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 6: APPROVAL & POSTING                                         │
│ - Employee submits Expense Report for approval                      │
│ - Manager approves via standard Expense Agent workflow              │
│ - Report released, then posted through the standard workflow        │
│ - GL postings created via platform ExpenseReportPost (6987)         │
│ - EACorpCardApprovalMgt (7428) exists but has no callers             │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 7: POSTED EXPENSE TRACEABILITY                                │
│ - Credit-card expense posting links the posted report               │
│ - Source corporate-card transaction status becomes Posted           │
│ - Credits the provider's Corporate Card Bank Account                │
│ - Creates a Bank Account Ledger Entry on that account                │
│ - Creates no activity on the real Payment Bank Account              │
│ - Codeunit: EA Corp Card Post Mgt (7440)                            │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 8: SETTLEMENT PREPARATION AND POSTING                         │
│ - Provider setup defines Corporate Card and Payment Bank Accounts   │
│ - One settlement groups one or more validated statements            │
│ - Account, currency, identity, and total snapshots are validated    │
│ - Ready to Post creates no journal or ledger entries                │
│ - Posting transfers Payment Bank to Corporate Card Bank             │
│ - Stores both bank ledger entries, transaction, and G/L register    │
│ - Codeunit: EA Corp Card Settlement Mgt (7443)                      │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 9: RECONCILIATION AND PERIOD CLOSURE                          │
│ - Matches every transaction to exactly one card-bank ledger entry   │
│ - Verifies amount, currency, bank account, and posted report        │
│ - Revalidates the two posted settlement bank entries                │
│ - Captures reconciliation totals and closes the statement period    │
│ - Real payment-bank withdrawal uses standard Bank Acc. Reconcile    │
│ - Codeunit: EA Corp Card Statement Mgt (7441)                       │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 10: REVERSAL AND CORRECTION                                   │
│ - Standard transaction reversal reverses both settlement entries    │
│ - Stores reversal bank entries, transaction, G/L register, and user │
│ - Preserves original settlement lines as inactive audit history     │
│ - Invalidates closed statements and preserves prior closure details │
│ - Corrected statements can be settled and closed again              │
│ - Canceling a posted expense returns its transaction to Matched      │
│ - Codeunits: Settlement, Statement, and Post Mgt                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Objects Created

### Corporate Card Codeunits (selected)

The `CorporateCard/Codeunits` folder contains 24 codeunits. The primary workflow codeunits include:

| ID | Name | Purpose | Key Procedures |
|----|------|---------|-----------------|
| 7420 | EACorpCardMerchantNorm | Merchant name normalization via case-insensitive substring patterns | NormalizeTransaction, FindMatchingRule, PatternMatches |
| 7421 | EACorpCardMatchMgt | Basic transaction matching (reference only) | MatchTransaction |
| 7422 | EACorpCardExpWriter | Draft Expense creation from transactions | CreateDraftFromTrans, LinkPosted, GetExpenseCategoryFromMCC |
| 7423 | EACorpCardPostImportOrch | Post-import orchestration pipeline | ProcessStatementPostImport |
| 7424 | EACorpCardAuditSubscribers | Centralized telemetry logging; report/approval logging methods are not called by the active workflow | LogImportStarted/Completed/Failed, LogMatchingCompleted, LogDraftCreated, LogReportCreatedFromCorpCard, LogReportSubmittedForApproval, LogReportApprovedForPosting, LogReportRejected |
| 7425 | EACorpCardJQMgt | Job Queue entry lifecycle management | ScheduleProviderImport, UnscheduleProviderImport, UpdateJobQueueFrequency |
| 7426 | EACorpCardEnhancedMatchMgt | Multi-strategy matching with fuzzy algorithm | EnhancedMatchTransaction, CalculateSimilarity, LevenshteinDistance |
| 7427 | EACorpCardMCCMgt | MCC validation and category mapping | ValidateAndMapMCC, GetExpenseCategoryForMCC, InitializeDefaultMCCMappings, IsValidMCC |
| 7428 | EACorpCardApprovalMgt | Unused approval helper; not connected to the standard workflow | SubmitReportForApproval, ReleaseReportForPosting, RejectReport |
| 7429 | EACorpCardReportMgt | Unused report aggregation helper | CreateReportFromCorpCardExpenses, AddExpenseToReport, ReleaseExpenseForReporting |
| 7433 | EACorpCardJQRunner | Job Queue entry point; no custom retry handling | OnRun (Job Queue trigger) |
| 7440 | EA Corp Card Post Mgt | Links posted expense reports and propagates posted-expense cancellation to corporate-card reconciliation | LinkPostedExpense, HandleCanceledPostedExpense |
| 7441 | EA Corp Card Statement Mgt | Validates imports, closes reconciled statement periods, and invalidates closure after corrections | ValidateStatement, ReopenStatement, GetReconciliationSummary, CloseStatement, InvalidateReconciliation |
| 7443 | EA Corp Card Settlement Mgt | Prepares, posts, validates, and reverses provider settlements | SetReadyToPost, Reopen, PostSettlement, ReverseSettlement |

### Corporate Card Pages and Page Extensions

| ID | Name | Type | Purpose |
|----|------|------|----------|
| 7431 | EACorpCardCards | List | Corporate card configuration and assignment |
| 7432 | EACorpCardExceptions | List | Import exceptions with resolution tracking |
| 7433 | EACorpCardTransList | List | Imported transaction listing with expense linking |
| 7434 | EACorpCardProviders | List | Provider administration with scheduling actions |
| 7435 | EACorpCardMCCMap | List | Merchant category code to expense category mapping |
| 7437 | EACorpCardMerchantRules | List | Merchant name substring rules |
| 7438 | EACorpCardDashboard | Card | Import reconciliation dashboard with navigation |
| 7439 | EACorpCardJQSchedule | ListPlus | Job Queue schedule management UI for providers |
| 7445 | EACorpCardJQScheduleSubpage | ListPart | Read-only Job Queue entry details filtered by provider |
| 7441 | EACorpCardDashboardFactbox | ListPart | Recent import statements sorted chronologically |
| 7442 | EACorpCardStatisticsFactbox | CardPart | KPI statistics (30-day rolling aggregation) |
| 7443 | EA Corp Card Statements | List | Provider statement list and status overview |
| 7444 | EA Corp Card Statement | Document | Provider statement header, matching, and validation |
| 7436 | EA Corp Card Details | List | Level 3 detail view (no current import populates it) |
| 7446 | EA Corp Card Statement Trans | ListPart | Read-only transactions belonging to the provider statement |
| 7430 | EA Corp Card Settlements | List | Provider settlement list and status overview |
| 7447 | EA Corp Card Settlement | Document | Settlement header, statement selection, and readiness validation |
| 7448 | EA Corp Card Settlement Lines | ListPart | Validated provider statements included in a settlement |
| 7440 | EA Payment Rec. Journal | Page extension | Shows corporate card transaction and posted expense report references |
| 7441 | EA Bank Account Stmt. Lines | Page extension | Shows durable corporate card and posted expense report references |
| 7442 | EA Bank Acc. Ledger Entries | Page extension | Shows the originating corporate card transaction |

### Tables and Table Extensions

The module retains its existing Expense Agent records and models provider statements separately from standard banking records:

- **EA Corp Card Statement** - Imported statement header, source metadata, period, currency, total, counters, and validation status
- **EA Corp Card Settlement** - Provider settlement identity, amount, account snapshots, posting references, reversal references, and lifecycle status
- **EA Corp Card Settlement Line** - Links complete validated statements to one settlement, snapshots statement values, and retains inactive reversed relationships for audit
- **EACorpCardTrans** - Child statement transaction, enrichment, expense matching, workflow, and audit record
- **EA Corp Card Trans Detail** - Level 3 detail schema; current CSV/XML imports do not populate it
- **EACorpCard** - Card configuration and employee assignment
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
Import statement (file-based feeds)
    → Selects a file and writes directly to Data Exch. File Content
    → Does not create a statement if file selection is canceled
            ↓
Provider.Download()
    → Reuses the selected file's Data Exchange record
    → Automated feed implementations download their own input
            ↓
Provider.ParseToStaging()
    → Validates field mappings (EACorpCardMapMgt)
    → Imports data to EACorpCardTrans (Status=Imported)
    → Includes mapped MCC values for CSV/XML transactions
    → Calls EACorpCardPostImportOrch.ProcessStatementPostImport()
            ↓
EACorpCardPostImportOrch.ProcessStatementPostImport()
    → For each transaction:
        1. EACorpCardMerchantNorm.NormalizeTransaction()
        2. If Create Mode = AutoDraft: EACorpCardExpWriter.CreateDraftFromTrans()
        3. If Create Mode = ManualLink: try EACorpCardEnhancedMatchMgt.EnhancedMatchTransaction()
        4. If still unmatched and Auto-Create is enabled: create a draft
    → Log results via AuditSubscribers
            ↓
Provider.Ack()
    → Raises OnAfterAck (does not change statement status)
Import orchestrator
    → Marks successful statement as Imported; failed statement as Failed
    → Deletes the source Data Exchange record and parsed fields on success or failure
    → Retains statement file name, SHA256 hash, and import diagnostics
```

File content is never stored on the provider master record. A failed file import requires selecting the file again; there is no retained input for an unattended retry. Cleanup occurs when the orchestrator finalizes the attempt, not as crash recovery after a terminated session.

### Matching Algorithm

**Strategy Priority (ManualLink mode only; AutoDraft skips matching):**

1. **Exact Amount-Date Match** (Score: 50-100)
   - Query: Same user, Status=Open, not linked to a card transaction, Currency match
   - Criteria: Amount within tolerance, Date within window
   - Score: `100 - (DateDiffDays × 5) - ((AmountDiff / Tolerance) × 10)`
   - Returns: Match Type=Full

2. **Fuzzy Merchant Name Match** (Score: 70-100)
   - Query: Same user, Status=Open, not linked to a card transaction; does not compare amount, currency, date, or sign
   - Algorithm: Levenshtein distance (max 100 char)
   - Similarity: `1 - (EditDistance / MaxLen)`, threshold ≥ 0.70
   - Returns: Match Type=Expense

Transactions with no exact or fuzzy match remain Imported for manual review or become drafts when Auto-Create is enabled. There is no employee-only fallback.

**Levenshtein Algorithm:**
- Dynamic programming 2D matrix (max 100×100)
- Handles character insertions, deletions, substitutions
- Case-insensitive (text normalized to lowercase)
- Returns edit distance (0 = identical, MaxLen = completely different)

### Expense Report Creation Flow

```
Employee adds draft expenses to an Expense Report in the standard UI
    → Submits for approval through the standard Expense Agent workflow
    → Approved report is released and posted by ExpenseReportPost (6987)
    → For expenses linked to a card transaction, posting credits the
      provider's Corporate Card Bank Account and creates its bank ledger entry
    → EA Corp Card Post Mgt links the posted report to the transaction
    → Transaction status becomes Posted
    → Does not create a Payment Bank Account settlement entry
```

`EACorpCardTrans` remains the source audit record for matching the provider transaction to the expense. The separate `EACorpCardReportMgt` and `EACorpCardApprovalMgt` helpers have no callers; do not use them as a description of the active workflow. Provider-statement settlement and payment-bank reconciliation are separate processes.

### Provider Statement Reconciliation

```
Provider statement header
    → Identifies provider, statement number, period, currency, and provider total
            ↓
EACorpCardTrans child records
    → Are imported directly as the statement transactions
    → Preserve provider transaction identity, card, date, amount, and currency
            ↓
Statement validation
    → Rejects missing imported transactions
    → Rejects duplicate provider statement identities and incomplete imports
    → Rejects transactions that are not matched to an expense
    → Verifies period, currency, and statement total
            ↓
Status = Validated
```

Provider statement validation creates no journal, Payment Application, Bank Account Ledger Entry, or bank reconciliation. Settlement posting is a later and separate process.

### Reversal and Correction Lifecycle

Posted settlements are reversed through the standard Business Central transaction reversal API. The reversal creates the compensating G/L and Bank Account Ledger Entries and applies the standard safeguards for already-reversed, closed, or reconciled bank entries. The settlement retains the original and reversal entry references, transaction number, G/L register, reason, date-time, and user.

Reversal marks the original settlement-to-statement lines as inactive instead of deleting them. A closed statement moves to `ReconciliationRequired`; its prior closure count, amount, date-time, and user are preserved as audit history. The corrected statement can then be included in a replacement settlement and closed again after reconciliation.

Canceling a posted expense report follows the same correction boundary: the related statement closure is invalidated, the corporate-card transaction returns from `Posted` to `Matched`, and its posted report reference is cleared after the standard accounting reversal.

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
    - XML column paths must include the full line path, for example `/CorporateCardTransactions/Transaction/MCC`; the standard importer derives each column's relative path from the line's Data Line Tag
    - Use **Import statement** to select and immediately import a CSV or flat XML file

3. **Configure Import Parameters**
    - Navigate: Expense Agent Setup → Corporate Card
    - Corp Card Create Mode
    - Corp Card Date Match Window (default: 7; applying defaults resets 0 to 7)
    - Corp Card Amount Tolerance (default: 5; applying defaults resets 0 to 5)
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
    - Creates the LCY bank account `CORPCARD` for future provider-settlement scenarios, but does not assign it to individual cards.
    - Reuses `CHECKING`, `PREC`, and `SEPA CAMT` configuration when those standard records are available; this does not add CAMT corporate-card import support.
    - MCC/category seeding is idempotent (existing records are not duplicated).

    Seeded MCC mappings from sample feeds:
    - 4112 (Rail Passenger Transport) → GROUNDTRAN
    - 4121 (Taxicabs and Limousines) → GROUNDTRAN
    - 4511 (Airlines) → AIRLINE
    - 4722 (Travel Agencies) → AIRLINE
    - 5111 (Office Supplies) → MISC
    - 5541 (Service Stations) → CAR
    - 5812 (Restaurants) → MEALS
    - 5943 (Stationery and Office Stores) → MISC
    - 7011 (Hotels and Lodging) → HOTELS
    - 7523 (Parking Lots and Garages) → PARKING

    Legacy demo mappings retained:
    - 7394 (Car Rental) → RENTALCARS
    - 7399 (Business Services) → MISC
    - 5542 (Fuel Dispensers) → CAR

2. **Contoso Demo Data**
    - Adds the dedicated LCY bank account `CORPCARD` for corporate card settlement
    - Configures the standard Payment Reconciliation number series and bank statement import format

### Level 3 Details

CSV/XML import does not insert `EA Corp Card Trans Detail` rows, so Level 3 VAT specification creation and total-difference warnings are not reached in the current import flow. The expense writer contains a helper for detail rows supplied by another source; if rows are present, it assigns `Expense VAT Specification` line numbers explicitly, starting at 1.

3. **Access Corporate Card Features**
   - Navigate: Expense Management Role Center → Corporate Card group
   - Available actions:
     - **Corp Card Dashboard:** View import statistics & recent statements
     - **Corp Card Providers:** Manage providers & scheduling
     - **Corp Card Setup:** Opens Expense Agent Setup (Corporate Card group)
     - **Corporate Cards:** Manage card assignments
     - **Merchant Normalization Rules:** Add substring patterns
     - **MCC Code Mappings:** Map category codes to expense categories

4. **Add Custom Merchant Rules**
   - From Role Center: Corp Card → Merchant Normalization Rules
   - For each pattern: Set text to find, normalized name, and priority. Matching ignores case and strips `*` characters before searching. The rule's Expense Category field is not applied by normalization; draft categorization uses MCC mapping.
   - Active flag: Enable/disable rules without deletion

5. **Schedule Provider Imports**
   - From Role Center: Corp Card → Corp Card Providers
   - For each enabled automated-feed provider:
     - Action: Schedule Import
     - Creates a recurring Job Queue entry for 08:00 daily (1440 minutes), regardless of the provider's Import Frequency setting
     - Entry starts **On Hold**; set it to Ready in Job Queue Entries to run it
     - The feed implementation downloads its own input and manages acknowledgment and retry progress
     - Maximum number of job-queue attempts is 3; the module does not implement a separate retry loop
   - Built-in Data Exchange, CSV, and XML feeds are interactive only. Their Schedule Import action is disabled; existing jobs targeting them are skipped.

### Statement Card Identification

`Card Id` is an internal Business Central code, not a credit card number. Do not include it in statement files or Data Exchange mappings. Both static samples and generated demo payloads use `CardLast4` instead: a CSV column or XML element containing only the last **four** digits (`0001` through `0006` in the static samples). Full numbers and other values are rejected without copying the supplied value into diagnostics.

Card resolution is provider-scoped:

- A supplied `CardLast4` must identify exactly one card whose `Masked Card No.` ends in those digits. Configure only a masked value ending in the last four digits on the Corporate Cards page. A blocked or ambiguous card produces a row exception; an unrecognized suffix never falls back to another employee's expense.
- If `CardLast4` is empty, the importer requires exactly one open, unlinked credit-card expense with the same transaction date, amount, and currency, and exactly one card for that expense user and provider. The resolved internal card and expense candidate are saved in staging.
- Post-import processing rechecks the fallback match under an expense-table lock before linking. If it changed or is no longer unique, the transaction becomes an exception rather than creating a new draft or guessing another expense. A valid fallback links the existing expense even in AutoDraft mode.

Unknown or blocked cards, missing references without a unique expense match, and invalid suffixes are reported as row-level validation exceptions. Other valid rows can still import. Existing custom mappings to `Card Id` must be changed; the built-in mapping setup replaces its legacy card-ID mapping with `Card Last 4`.

---

## Telemetry Events

Corporate-card events use `Feature Telemetry` under the existing Expense Agent feature name (`ExpenseAgentSetup.GetFeatureName()`). Each event has its own ID and name, so they appear in the standard Expense Agent feature usage reports. Import failures use `LogError`; the other events use `LogUsage`. The import failure records the controlled import stage, not the raw error text.

### Import Lifecycle (0000UCS - 0000UCU)

| Event ID | Event | Trigger | Verbosity | Data |
|----------|-------|---------|-----------|------|
| 0000UCS | ImportStarted | Provider starts import | Usage | Provider Code, Statement Entry No. |
| 0000UCT | ImportCompleted | Statement finishes successfully | Usage | Provider Code, Statement Entry No., Imported count, Exception count, Duplicate count |
| 0000UCU | ImportFailed | Statement fails | Error | Provider Code, Statement Entry No., Import stage (not raw error text) |

### Processing Pipeline (0000UCV - 0000UCX)

| Event ID | Event | Trigger | Verbosity | Data |
|----------|-------|---------|-----------|------|
| 0000UCV | MatchingCompleted | Post-import matching finishes | Usage | Matched count, Unmatched count |
| 0000UCW | DraftCreated | New expense draft created | Usage | Transaction Entry No., Expense No. |
| 0000UCX | JobQueueScheduled | Import job queued | Usage | Provider Code, Frequency |

### Report Workflow (0000UCY - 0000UD1)

| Event ID | Event | Trigger | Verbosity | Data |
|----------|-------|---------|-----------|------|
| 0000UCY | ReportCreatedFromCorpCard | Unused ReportMgt helper | Usage | No custom dimensions |
| 0000UCZ | ReportSubmittedForApproval | Unused ApprovalMgt helper | Usage | No custom dimensions |
| 0000UD0 | ReportApprovedForPosting | Unused ApprovalMgt helper | Usage | No custom dimensions |
| 0000UD1 | ReportRejected | Unused ApprovalMgt helper | Usage | No custom dimensions |

`0000UCY`–`0000UD1` have no active callers through the standard report workflow; they are defined but do not fire in normal corporate-card processing.

### Accounting Lifecycle (0000UD2 - 0000UD4)

| Event ID | Event | Trigger | Type | Data |
|----------|-------|---------|------|------|
| 0000UD2 | StatementClosed | Statement reconciliation closes | Usage | Provider Code, Statement Entry No. |
| 0000UD3 | SettlementPosted | Provider settlement posts | Usage | Provider Code, Settlement Entry No. |
| 0000UD4 | SettlementReversed | Posted settlement reverses | Usage | Provider Code, Settlement Entry No. |

---

## Integration Points

### With Existing Objects

| Object | Integration | Purpose |
|--------|-----------|---------|
| **Data Exchange Framework** | Used for file parsing | Validates field mappings via EACorpCardMapMgt |
| **Expense Table** | Receives drafted transactions | Individual expense records created on no match |
| **Expense Report Header/Line** | Aggregates expenses | Report-level approval & GL posting |
| **EA Corp Card Statement/Transaction** | Provider statement reconciliation | Verifies imported statement transactions against expenses |
| **Bank Acc. Reconciliation/Line** | Not used by provider statement validation | Matches the posted settlement withdrawal on the Payment Bank Account to the real bank statement |
| **Bank Account Ledger Entry** | Corporate-card liability and settlement accounting | Expense posting creates the card-account liability; settlement posting and reversal create the bank-to-bank transfer entries |
| **Job Queue Entry** | Stores recurring automated-feed import schedule | Created On Hold at 1440-minute intervals, maximum 3 attempts; administrator must enable it |
| **Expense Status Enum** | Defines workflow states | Open → Released → Pending Approval → (Posted via Report) |
| **MCC Merchant Category Codes** | Category mapping | 4-digit codes map to Expense Category for G/L account determination |
| **Expense Management Role Center** | Navigation hub | "Corporate Card" group with 6 actions for dashboard/cards/setup/config |
| **Expense User Page** | Employee integration | CorporateCards action shows employee's corporate card cards |
### With External Systems

| System | Method | Details |
|--------|--------|---------|
| **Bank/Card Processor** | Provider.Download() | File payload import via Data Exchange |
| **GL (via Report Posting)** | ExpenseReportPost (6987) | Platform handles journal creation |
| **Banking** | Standard journal posting, transaction reversal, and Bank Acc. Reconciliation | Posts and reverses settlement transfers; reconciles the Payment Bank Account withdrawal |
| **Approval Workflow** | Standard Expense Agent workflow | Uses existing approval rules & routes |

---

## Navigation & UI Integration

### Role Center Hub (ExpenseManagementRoleCenter)

A **"Corporate Card"** section is available in the main Expense Management Role Center with 6 actions:

```
ExpenseManagementRoleCenter (6933)
└── Corporate Card Group
    ├─ Corp Card Dashboard (7438)
    │  └─ Shows: Recent statements, statistics, import status
    │  └─ Actions: Providers, Transactions, Statements, Exceptions, Setup
    ├─ Corp Card Providers (7434)
    │  └─ Manage provider credentials & scheduling
    ├─ Corporate Cards (7431)
    │  └─ Manage card configuration and assignments
    ├─ Corp Card Setup
    │  └─ Opens Expense Agent Setup (Corporate Card settings)
    ├─ Merchant Normalization Rules (7437)
    │  └─ Create/edit substring patterns for merchant standardization
    └─ MCC Code Mappings (7435)
       └─ Map merchant category codes to expense categories
```

**Access:** Expense Management Role Center → Sections → Corporate Card

### Dashboard Navigation

The **EACorpCardDashboard** (Card page 7438) provides navigation:

| Navigation Area | Target | Purpose |
|-----------------|--------|---------|
| Providers | EACorpCardProviders (7434) | View/manage all providers |
| Transactions | EACorpCardTransList (7433) | View imported transactions |
| Statements | EA Corp Card Statements (7443) | View imported statements |
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
| EA Corp Card Statements (7443) | → Open statement, validate statement |
| EACorpCardTransList (7433) | → Open Provider Statement, Open Matched Expense, Level 3 Details (empty for current imports) |
| EACorpCardExceptions (7432) | → Mark Resolved, View Statement, View Transaction |

---

## Key Features

### Intelligent Matching

- **ManualLink:** Tries exact amount/date match, then fuzzy merchant-name match; no employee-only fallback
- **Fuzzy Algorithm:** Levenshtein distance with a 70% threshold, considering merchant names only
- **Scoring:** Exact matching scores 50–100; fuzzy matching scores 70–100
- **Configurable:** Exact-match window and tolerance via setup; AutoDraft skips matching

### Draft-Per-Transaction Mode

✅ **AutoDraft 1:1:** One imported transaction creates one draft expense  
✅ **Amount Integrity:** Draft amount equals transaction amount  
✅ **Deterministic Output:** No reuse of existing open expenses in AutoDraft mode  

### Merchant Normalization

- **Substring Patterns:** Case-insensitive merchant-name matching (asterisks stripped)
- **Priority-Based:** Rules sorted by priority, first match wins
- **Category Mapping:** Drafts use MCC mappings; a merchant rule's Expense Category field is not used by normalization
- **MCC Integration:** 4-digit code mapping with auto-created category seeds

### Job Queue Scheduling

- **Daily Job Setup:** Creates a 1440-minute recurring entry at 08:00, initially On Hold
- **Automated Feeds Only:** Built-in Data Exchange, CSV, and XML feeds require interactive file selection and cannot be scheduled
- **Job Queue Attempts:** Configured maximum of 3; no custom retry loop
- **Manual Enablement:** Administrator must set the entry to Ready; the automated feed supplies its own input
- **Manageable:** UI for schedule creation and removal

### Comprehensive Logging

- **Feature Telemetry:** Expense Agent usage and error events for imports, matching, drafts, scheduling, statement closure, and settlement posting/reversal
- **Defined but Unused:** Four report/approval events have no active callers
- **Error Tracking:** Import failures log a controlled stage through `LogError`; detailed errors surface separately

### Expense Posting Boundary

- ✅ **No Employee Reimbursement:** Credit-card expenses do not create employee reimbursement entries
- ✅ **Liability Posting:** Card-linked credit-card lines credit the provider's Corporate Card Bank Account and create a Bank Account Ledger Entry; unlinked credit-card lines use the employee posting group's card-paid G/L account
- ✅ **No Premature Settlement:** Expense posting does not create a Payment Bank Account settlement entry
- ✅ **Traceability:** The corporate-card transaction retains its linked expense and posted expense report

### Provider Statement Boundary

- ✅ **Single Imported Model:** The statement header owns the imported corporate-card transactions directly
- ✅ **No Duplicate Storage:** No second statement-line copy or transaction-linking step is required
- ✅ **Reconciliation Controls:** Incomplete imports, duplicate statements, import exceptions, and expense-unmatched transactions block validation
- ✅ **Balanced Statement:** Period, currency, and total must agree before validation
- ✅ **No Bank Activity:** Statement matching and validation create no banking records

### Reversal Boundary

- ✅ **Standard Accounting Reversal:** Settlement correction uses the standard transaction reversal API
- ✅ **Immutable Audit History:** Reversed settlement relationships remain as inactive lines
- ✅ **Closure Invalidation:** Corrections move closed statements to `ReconciliationRequired` and preserve the previous closure snapshot
- ✅ **Replacement Lifecycle:** Corrected statements can be settled and closed again
- ✅ **Bank Reconciliation Safeguards:** Standard reversal restrictions prevent reversal of closed or reconciled bank entries

---

## Error Handling & Recovery

### Import Errors

| Scenario | Action | Result |
|----------|--------|--------|
| Invalid file format or missing mapping | Import raises an error | Whole statement marked Failed; error shown to user |
| Missing mapped field on a row | Validation exception recorded when row validation returns false | Row rejected; other valid rows can continue |
| Unknown/blocked card, card without an Expense User, or blocked MCC mapping | Import raises an error | Whole statement marked Failed, not merely an unmatched row |
| No data in file | Import fails with explicit error | Statement marked Failed with diagnostics |

### Matching Errors

| Scenario | Action | Result |
|----------|--------|--------|
| No eligible open expense in ManualLink mode | Exact and fuzzy matches fail | Draft created if Auto-Create is enabled; otherwise transaction stays Imported |
| Amount tolerance = 0 | Exact matching permits only an equal amount | Applying setup defaults resets 0 to 5; fuzzy matching does not check amount |
| Card has no Expense User | Draft creation raises an error | Whole import fails |

### Level 3 Details

The current import does not populate detail rows, so the VAT specification and total-difference warning paths in `EACorpCardExpenseWriter` do not run for CSV/XML imports. The transaction list has a Level 3 Details action, but it has nothing to show unless another source supplies those rows.

### Job Queue Errors

| Scenario | Action | Result |
|----------|--------|--------|
| Entry remains On Hold | Job Queue does not run it | Administrator must set it to Ready |
| Provider import failure | Import orchestrator marks the statement Failed and reports the error | Job Queue's configured maximum is 3 attempts; JQRunner has no custom retry loop |
| File import fails | Source Data Exchange record and parsed fields are deleted; metadata and diagnostics remain | Use Import statement and select the file again |
| Scheduled job targets a file-based feed | Built-in Data Exchange, CSV, and XML feeds are skipped, including in all-provider batches | Use the interactive Import statement action instead |
| Provider marked disabled | JQRunner skips it | Re-enable the provider before scheduling another import |

All-provider batches fetch one enabled automated-feed provider at a time, without holding a provider result set across commits. Each provider import owns its transaction boundaries. Custom automated-feed implementations must manage their own acknowledgment and retry progress; file-based feeds are never included in a batch.

---

## Performance Considerations

### Statement Processing

- Non-strict Data Exchange fallback reuses raw values cached by column during the existing field scan. The cache is reset for each line, avoiding repeated field queries without retaining the whole statement.
- Expense-based card resolution loads the provider's card assignments and credit-card payment methods once per call. Candidate expenses use temporary-record lookups rather than per-expense database queries; the selected card is reread before checking whether it is blocked.
- Processing visits each imported transaction to normalize the merchant and either create a draft (AutoDraft) or attempt matching (ManualLink).
- Automated-feed Job Queue entries are created On Hold; enable the entry and configure the feed before relying on background import. File-based feeds use interactive Import statement instead. No statement-size or throughput benchmark is guaranteed.

### Memory

- **Levenshtein matrix:** 100×100 dynamic programming (capped at 100 chars per string)
- **Merchant rules:** Queried in priority order per transaction, using case-insensitive substring matching
- **Transaction buffer:** ProcessStatementPostImport uses FindSet/Next (streaming, low memory)

### Database

- **Indexes recommended:**
  - EACorpCardTrans: (Statement No., Status)
  - EACorpCardTrans: (Expense User No., Trans Date, Amount)
  - Expense: (Expense User No., Status, Currency)
  - Expense: (Expense Report No.)

---

## Testing Checklist

- [ ] Import a provider CSV file with 10+ transactions
- [ ] In ManualLink mode, verify exact and fuzzy matching against eligible open expenses
- [ ] With Auto-Create enabled, verify unmatched transactions become drafts
- [ ] Create expense report and add 3-5 expenses
- [ ] Submit report for approval
- [ ] Manager approves/rejects (if approval workflow enabled)
- [ ] Post report and verify GL journal entries created
- [ ] Verify the corporate-card transaction is linked to the posted expense report and has status Posted
- [ ] Verify expense-report posting creates a provider Corporate Card Bank Account Ledger Entry, but no Payment Bank Account settlement entry
- [ ] Verify card-linked credit-card expense posting credits the provider Corporate Card Bank Account
- [ ] Import a provider statement with its transactions
- [ ] Verify missing, duplicate, and expense-unmatched transactions block statement validation
- [ ] Verify statement period, currency, and total validation
- [ ] Verify a validated statement creates no journal or banking records
- [ ] Verify settlement posting debits the Corporate Card Bank Account and credits the Payment Bank Account
- [ ] Verify settlement posting stores both bank ledger entry numbers, transaction number, and G/L register
- [ ] Verify a posted settlement cannot be posted again
- [ ] Verify each statement transaction has exactly one correctly signed corporate-card bank entry
- [ ] Verify missing, duplicate, wrong-account, wrong-currency, and wrong-amount bank entries block closure
- [ ] Verify the posted settlement pair is unchanged before closure
- [ ] Verify statement closure captures reconciled count, amount, user, and date-time
- [ ] Verify the statement-period corporate-card liability clears to zero
- [ ] Verify closed statements and their transactions are immutable
- [ ] Reverse a posted settlement and verify compensating bank entries and reversal audit references
- [ ] Verify reversal invalidates statement closure and preserves the previous closure snapshot
- [ ] Verify reversed settlement lines remain as inactive audit history
- [ ] Post a replacement settlement and verify the corrected statement can be closed again
- [ ] Cancel a posted expense and verify its statement requires reconciliation and its transaction returns to Matched
- [ ] Verify already-reversed, closed, or bank-reconciled settlement entries cannot be reversed
- [ ] Check import/matching/draft/job-scheduling telemetry in Application Insights (if configured)

---

## Known Limitations

1. **MCC Category Scope:** Demo MCC/category mappings are seeded for sample coverage; production tenants should review and extend mappings based on local card programs
2. **Max String Length:** Levenshtein algorithm capped at 100 characters (longer strings truncated)
3. **Pattern Syntax:** Merchant normalization uses substring matching, not regular expressions; `*` characters are stripped
4. **Report Helpers:** Corporate-card ReportMgt and ApprovalMgt have no callers; approval runs through the standard Expense Agent workflow
5. **No Receipt Matching:** Does not support image-based receipt OCR (future enhancement)
6. **Reversal Prerequisites:** Standard Business Central reversal restrictions apply; closed, reconciled, or already-reversed bank entries must be corrected through the relevant standard process
7. **Runtime Test Infrastructure:** Posting and reversal integration tests require a Business Central AL test runtime; compiler validation alone does not execute them
8. **Level 3 Import:** No current CSV/XML import creates detail rows or VAT specifications from Level 3 data
9. **Scheduled Imports:** Schedule action creates an On Hold daily entry and does not use the provider Import Frequency setting

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
2. File-based feed? → Use Import statement and select a file for every attempt, including retries
3. Automated feed Job Queue entry created? → EACorpCardProviders page, Schedule Import action
4. Automated feed Job Queue entry set to Ready? → New entries start On Hold

### Matching Accuracy Low

**Symptom:** Many transactions unmatched  
**Check:**
1. Create mode ManualLink? → AutoDraft creates drafts without matching
2. Exact-match date window or amount tolerance too narrow? → Review Expense Agent Setup settings
3. Merchant names different? → Add substring normalization rules in EACorpCardMerchantRule
4. No open unlinked expenses for the user? → Fuzzy matching only checks merchant name and user, not amount/date/currency

### Draft Expenses Not Created

**Symptom:** Unmatched transactions but no drafts  
**Check:**
1. Auto-Create enabled? → Set Expense Agent Setup."Corp Card Auto Create Draft" = true
2. Create mode? → For strict 1:1 creation set Expense Agent Setup."Corp Card Create Mode" = AutoDraft
3. Expense User No. valid? → Verify transaction has expense user linked
4. Transaction status? → Should be Status=Imported before post-import processing

### File Format Visibility

**Symptom:** Unsure which profile will be used for import  
**Check:** Corp Card Providers page → Feed Type, Data Exch Def Code, and Data Exch Map Code. CSV and flat XML are supported. Choose the matching feed type and mapping before selecting the file; a CAMT-looking file name does not enable CAMT import.

### Level 3 Detail Visibility

**Symptom:** Level 3 Details action shows no VAT/tax sub-lines

**Check:** This is expected for current CSV/XML imports; no detail rows are created.

### Unresolved Card Validation Exceptions

**Symptom:** Import exceptions report that no card could be identified, or that the supplied suffix is ambiguous or blocked.
**Check:**
1. The file supplies `CardLast4`, not the internal `Card Id` or a full number.
2. Exactly one card for the provider has a masked number ending in those four digits and is not blocked.
3. Without a suffix, exactly one open, unlinked credit-card expense matches the transaction date, amount, and currency, with exactly one provider card for its expense user.
4. Verify provider `Data Exch Def Code`/`Data Exch Map Code` still point to the expected line definition and do not map internal card identifiers.

---

## Object ID Allocation

**Corporate-card allocation in app.json:** 7420–7449 (30 IDs per object type). The app also declares 6900–6999 and 7073–7137; `EA Corp Card Stats Calculator` uses codeunit 6913.

**Objects in the CorporateCard folder:** 10 tables, 4 table extensions, 18 pages, 3 page extensions, 24 codeunits, 7 enums, 2 interfaces, and 3 permission sets. Corporate-card objects outside that folder include codeunit 7442 and table/page 7449.

---

**Document Version:** 1.8

**Last Updated:** 2026-10-16

**Module Status:** Active (CSV/flat XML import, AutoDraft 1:1, manual matching, and provider-bank expense-posting traceability; Level 3 import is not implemented)
