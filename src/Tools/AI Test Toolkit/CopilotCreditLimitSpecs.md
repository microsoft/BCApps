# Copilot Credit Limit Specifications

## Overview
Allow administrators to control and monitor copilot credit consumption for agent test suites, preventing runaway costs by stopping new task queuing when limits are reached.

---

## 1. Credit Limit Configuration Page

### Page Details
- **Page Type:** Card or Worksheet
- **Name:** "AI Test Credit Limits" (or similar)

### Header/Summary Section

| Field | Type | Description |
|-------|------|-------------|
| Monthly Credit Limit | Decimal (Editable) | Maximum credits allowed for current month (environment-wide) |
| Credits Consumed | Decimal (Computed) | Sum of credits used this month across all agent test suites |
| Credits Available | Decimal (Computed) | Limit - Consumed |
| Current Period | Date Range (Display) | Start/End of current month |

### Repeater Section (Agent Test Suites Only)

| Field | Type | Description |
|-------|------|-------------|
| Test Suite Code | Code | Link to suite |
| Description | Text | Suite description |
| Credits Consumed (Month) | Decimal | Credits used by this suite in current month |
| Suite Credit Limit | Decimal (Editable) | Per-suite limit (0 = no suite-specific limit) |
| Status | Enum | Current suite status |

### Credit Limit Behavior
- Per-suite limits are **subdivisions** of the global limit
- Example: Global limit = 10 credits, 10 suites each with limit = 5
  - When global consumption reaches 10, **all suites stop** regardless of individual suite consumption
- Suite limits provide additional granularity but do not override the global cap

---

## 2. New Test Suite Status

### Current Statuses
- `Running`
- `Completed`
- `Cancelled`

### New Status
- **`CreditLimitReached`**

### Behavior When Status = CreditLimitReached
- Suite stops queuing new agent tasks
- Already-running tasks complete (cannot be stopped mid-execution)
- User can see why suite stopped
- Suite does **not** automatically resume when limits are increased or reset
- User must manually start a new run

### Status Transitions
```
Running → CreditLimitReached  (when credit limit hit)
CreditLimitReached → Cancelled (manual cancellation)
```

**Line Status Transitions:**
```
Running → Skipped    (when credit limit hit during execution)
" " → Skipped        (pending lines when credit limit hit)
```

**Note:** There is no automatic transition from `CreditLimitReached` back to `Running`. Users must manually initiate a new run after limits are adjusted. This prevents accidental consumption of newly allocated credits.

---

## 3. Credit Limit Enforcement Logic

### Check Points
1. Before starting a new suite run
2. Before queuing each new agent task within a run
3. After each task completes (update consumed credits, check if limit exceeded for next task)

### Enforcement Rules
1. **Suite Limit Check:** If suite has a limit (> 0) and `Suite Credits >= Suite Limit`, block new tasks for that suite
2. **Global Limit Check:** If `Total Credits Consumed >= Monthly Credit Limit`, block new tasks for all suites
3. **Priority:** Suite limit checked first, then global limit

### Edge Case: Single Task Exceeds Remaining Credits
- If queuing a task would potentially exceed remaining credits, **do not queue it**
- Other tasks in the same run should not be queued either
- Suite transitions to `CreditLimitReached` status

### Already Queued Tasks
- Tasks already in queue when limit is hit: These complete (we cannot un-queue them)
- No new tasks are added after limit is reached

---

## 4. Data Model Changes

### New Table: "AIT Credit Limit Setup"

| Field | Type | Description |
|-------|------|-------------|
| Primary Key | Code | Single record (blank or fixed code) |
| Monthly Credit Limit | Decimal | Environment-wide monthly limit |
| Enforcement Enabled | Boolean | Toggle to enable/disable enforcement |
| Period Start Date | Date | Start of current tracking period (auto-set to 1st of month) |

### Changes to "AIT Test Suite" Table

| Field | Type | Description |
|-------|------|-------------|
| Suite Credit Limit | Decimal | Per-suite limit (0 = no suite-specific limit, uses global only) |
| Credits Consumed Current Month | Decimal | FlowField summing credits for current month |

### Changes to "AIT Test Suite Status" Enum

Add new value:
```al
value(50; CreditLimitReached)
{
    Caption = 'Credit Limit Reached';
}
```

### Changes to "AIT Line Status" Enum

Add new value:
```al
value(50; Skipped)
{
    Caption = 'Skipped';
}
```

### New FlowField on "AIT Test Suite" Table

```al
field(82; "No. of Lines Skipped"; Integer)
{
    Caption = 'No. of Lines Skipped';
    FieldClass = FlowField;
    CalcFormula = count("AIT Test Method Line" where("Test Suite Code" = field("Code"), Status = const(Skipped)));
}
```

---

## 5. Monthly Reset Behavior

- **Automatic Reset:** Credits consumed counter resets on the 1st of each month
- **Manual Override:** Admin can manually adjust the Monthly Credit Limit at any time to allow more consumption
- **No Manual Reset:** Admin cannot manually reset consumed credits mid-month; they should increase the limit instead

---

## 6. Scope Decisions

| Topic | Decision |
|-------|----------|
| Per-suite limits relationship to global | Subdivisions (global limit always applies) |
| Historical tracking | Not needed (covered elsewhere) |
| Warning threshold | Show warning at 80% consumption |
| Notifications | Show notifications when limits reached or approaching |
| Override to run over limit | Not allowed; admin must increase quota |
| Limit granularity | Per-suite; run data accumulates to suite total |

---

## 7. Implementation Tasks

### Phase 1: Data Model
- [x] Create "AIT Credit Limit Setup" table
- [x] Add `Suite Credit Limit` field to "AIT Test Suite" table
- [x] Add `CreditLimitReached` to "AIT Test Suite Status" enum
- [x] Add FlowField for current month credits consumed

### Phase 2: Credit Limit Page
- [x] Create "AIT Credit Limits" page
- [x] Header section with global limit and computed fields
- [x] Repeater showing agent-type suites with per-suite limits

### Phase 3: Enforcement Logic
- [x] Implement credit check before queuing new agent tasks
- [x] Implement status transition to `CreditLimitReached`
- [x] Implement monthly reset logic
- [x] Update task queuing codeunit to respect limits

### Phase 4: UI Integration
- [x] Show credit limit info on AIT Test Suite page (for agent type)
- [x] Add navigation to Credit Limits page from suite list

---

## 8. UI Mockup (Conceptual)

```
┌─────────────────────────────────────────────────────────────┐
│ AI Eval Copilot Credit Limits                               │
├─────────────────────────────────────────────────────────────┤
│ Monthly Copilot Credit Limit: [1000.00]                     │
│ Copilot Credits Consumed:     450.00                        │
│ Copilot Credits Available:    550.00  (45.0%)               │
│ Current Period:               March 1, 2026 - March 31, 2026│
├─────────────────────────────────────────────────────────────┤
│ Agent Test Suites (showing suites with credits consumed)    │
├────────┬──────────────┬────────┬───────┬────────┬─────┬─────────────────┤
│ Code   │ Description  │Consumed│ Limit │Usage % │Skip │ Status          │
├────────┼──────────────┼────────┼───────┼────────┼─────┼─────────────────┤
│AGENT-01│ Sales Agent  │ 150.00 │200.00 │ 75.0%  │  0  │ Running         │
│AGENT-02│ Support Agent│ 200.00 │300.00 │ 66.7%  │  0  │ Completed       │
│AGENT-03│ Inventory    │ 100.00 │100.00 │100.0%  │  3  │ CreditLimitReach│
└────────┴──────────────┴────────┴───────┴────────┴─────┴─────────────────┘
```

---

## 9. Feedback and Refinements (v2)

Based on initial implementation feedback, the following refinements were made:

### 9.1 Default Credit Limit on Install

- **Requirement:** On installation, automatically configure a default monthly credit limit of **200 Copilot credits**
- **Implementation:** Updated `AIT Install` codeunit to insert default `AIT Credit Limit Setup` record
- **Rationale:** Provides immediate cost protection out-of-the-box without requiring manual configuration

### 9.2 Filtered Suite View

- **Requirement:** By default, show only agent test suites that have consumed Copilot credits in the current period
- **Implementation:** Added "Show All Suites" toggle action on the Credit Limits page
- **Default State:** Filtered to suites with credits consumed (toggle off)
- **Toggle On:** Shows all agent test suites
- **Rationale:** Reduces noise by focusing attention on suites that have actually incurred costs

### 9.3 Consistent Naming

- **Requirement:** Use "Copilot Credits" consistently throughout the page, not just "Credits"
- **Changes:**
  - Page caption: "AI Eval Copilot Credit Limits"
  - Group caption: "Monthly Copilot Credit Limits"
  - Field captions: "Monthly Copilot Credit Limit", "Copilot Credits Consumed", "Copilot Credits Available"
  - Suite fields: "Copilot Credits Consumed (Month)", "Suite Copilot Credit Limit"
- **Rationale:** Provides clarity that this feature specifically tracks Copilot credits, distinguishing from other potential cost types

### 9.4 Suite Limit Display

- **Requirement:** Avoid confusion when suite limit is 0 (no limit set)
- **Previous:** Displayed "0.00" which could be misinterpreted as "zero allowed"
- **Updated:** Display empty/blank field when no suite-specific limit is set
- **Behavior:**
  - Empty field = no suite-specific limit (global limit still applies)
  - Numeric value = explicit suite limit
- **Rationale:** Makes it visually clear which suites have explicit limits configured vs. those using only the global limit

---

## 10. Feedback and Refinements (v3)

Based on further testing feedback, the following refinements were made:

### 10.1 Improved Credit Limit Enforcement

- **Requirement:** Stop executing new tests as soon as the credit limit is reached, not just between test lines
- **Implementation:**
  - Added `SingleInstance` tracking in `AIT Credit Limit Mgt.` codeunit
  - Check credit limit after each test method completes (OnAfterTestMethodRun)
  - If limit exceeded, set a flag and skip remaining tests in current codeunit
  - Reset flag at the start of each suite run
- **Behavior:**
  - Tests within a line (codeunit) are checked after each completes
  - Once limit is reached, remaining tests in that codeunit error with "Copilot credit limit reached"
  - Suite transitions to `CreditLimitReached` status
  
### 10.2 Credit Limit Notifications

- **Requirement:** Show notifications on the AI Eval Suite page when limits are reached
- **Implementation:** Added two distinct notifications:
  1. **Global Credit Limit Notification:** Shown when monthly environment-wide limit is exceeded
  2. **Suite Credit Limit Notification:** Shown when suite-specific limit is exceeded
- **Behavior:**
  - Notifications appear on page load/refresh for Agent type suites
  - Each notification includes an "Open Credit Limits" action button
  - Notifications are recalled when limits are no longer exceeded

### 10.3 Credits Available Styling

- **Requirement:** Show unfavorable (red) styling when no credits are available
- **Implementation:** Updated `CreditsAvailable` field styling:
  - `Favorable` (green) when credits > 0
  - `Unfavorable` (red) when credits <= 0
- **Rationale:** Provides immediate visual feedback when limits are reached

---

## 11. Feedback and Refinements (v4)

Based on continued testing feedback, the following refinements were made:

### 11.1 Warning Notification at 80%

- **Requirement:** Alert users when approaching credit limit (before it's reached)
- **Implementation:** Added two warning notifications:
  1. **Global Warning:** Shown when 80%+ of monthly credits consumed
  2. **Suite Warning:** Shown when 80%+ of suite credits consumed
- **Behavior:**
  - Warning notifications appear on page load/refresh before limits are reached
  - Each warning includes an "Open Credit Limits" action button
  - Warnings are replaced by "limit reached" notifications once 100% consumed
- **Rationale:** Gives users advance notice to adjust limits or pause testing

### 11.2 Percentage Usage Display

- **Requirement:** Show usage percentage for better understanding of consumption
- **Implementation:**
  - Added `Usage %` display in Credit Limits page header
  - Added `Suite Usage %` column in suite repeater
  - Values displayed as "85.0%" format
- **Styling:** Three-tier color coding:
  - `Favorable` (green): < 80% usage
  - `Attention` (yellow): 80-99% usage
  - `Unfavorable` (red): >= 100% usage
- **Rationale:** Provides immediate visual indication of consumption level relative to limit

### 11.3 Skipped Line Status

- **Requirement:** Distinguish lines skipped due to credit limit from cancelled lines
- **Previous:** Lines were marked as `Cancelled` when credit limit reached
- **Updated:** Lines are now marked as `Skipped` when credit limit prevents execution
- **New Enum Value:** Added `Skipped` (value 50) to `AIT Line Status` enum
- **Caption:** "Skipped"
- **Rationale:** Provides clarity on why lines didn't execute (credit limit vs. user cancellation)

### 11.4 Evals Skipped Tracking

- **Requirement:** Track and display how many evals were skipped due to credit limits
- **Implementation:**
  - Added `No. of Lines Skipped` FlowField to `AIT Test Suite` table
  - CalcFormula counts lines with Status = Skipped
  - Displayed in AI Test Suite page under "Latest Run" section
  - Also displayed in Credit Limits page suite repeater
- **Styling:** Uses `Attention` (yellow) style to highlight skipped lines
- **Rationale:** Helps users understand impact of credit limits on test coverage

---

## 12. Open Issues (Code Review Feedback)

The following issues were identified during code review and need to be addressed in a future iteration.

### 12.1 Architectural: Agent-folder codeunit referenced from base TestSuite folder

`AIT Credit Limit Mgt.` (codeunit 149050) lives under `src/Agent/` which is correct since credit limits apply to agent test suites. However, `AITTestSuiteMgt.Codeunit.al` in `src/TestSuite/` (the base/shared layer) directly references it in three places:
- `StartAITSuite` — calls `CheckCreditLimitBeforeRun` before starting a suite run
- `RunAITests` — calls `CheckCreditLimitDuringRun` and `IsCreditLimitReachedDuringRun` in the test-line loop, and `SetCreditLimitReachedStatus` when the limit is hit
- `RunAITestLine` — checks `IsCreditLimitReachedDuringRun` to set line status to Skipped after a test completes

This creates an upward dependency from the base objects (`TestSuite/`) to the specialized objects (`Agent/`). To fix this, introduce an interface (e.g., `ICreditLimitCheck`) in the `TestSuite/` folder and implement it in the `Agent/` folder. The implementation could be tied to the `"Test Type"` enum value on the test suite so the correct implementation is resolved at runtime based on whether the suite is of type Agent.

### 12.2 Suite and line status not set to Skipped when error is raised at run start

When `CheckCreditLimitBeforeRun` detects the limit is already reached, it raises an `Error()` (see `GlobalCreditLimitExceededErr` / `SuiteCreditLimitExceededErr` in `AIT Credit Limit Mgt.`). This error aborts execution immediately, but the suite status and individual line statuses are **not** transitioned to `CreditLimitReached` / `Skipped` respectively, and the skipped-eval count is not reflected. Only when the limit is hit *during* a run (via `SetCreditLimitReachedStatus`) are statuses updated. The pre-run check path needs the same status handling so that the UI accurately reflects why nothing ran and how many evaluations were skipped.

### 12.3 Credit Limits page does not explain enforcement behavior

The `AIT Credit Limits` page (page 149048, captioned "AI Eval Copilot Credit Limits") shows the limit, consumption, and availability, but does not communicate the actual enforcement behavior to the user. Specifically, the page should clarify that:
- New tests are **not started** when the limit is reached, but an already-running test is allowed to finish (meaning actual consumption can exceed the configured limit).
- This is a deliberate design choice: stopping a test mid-way would waste the credits already consumed for the partial execution.

Without this context, users may be surprised that consumption exceeds the limit or may not understand how enforcement works. A brief instructional text or tooltip on the page would address this.

### 12.4 Object naming: AITCreditLimits should be AIT Copilot Credit Limit

The current object names use inconsistent terminology:
- Table: `AIT Credit Limit Setup` (table 149040)
- Page: `AIT Credit Limits` (page 149048)
- Codeunit: `AIT Credit Limit Mgt.` (codeunit 149050)

These should be renamed to include "Copilot" for consistency with the UI captions (which already say "Copilot Credit") and to distinguish from other potential credit/limit concepts. Suggested naming convention: `AIT Copilot Credit Limit Setup`, `AIT Copilot Credit Limits`, `AIT Copilot Credit Limit Mgt.`, etc.

### 12.5 Review SingleInstance codeunit design for credit limit state

`AIT Credit Limit Mgt.` uses `SingleInstance = true` with a module-level `CreditLimitReachedDuringRun` boolean flag to track whether the limit was hit during a run. This flag is reset in `ResetCreditLimitFlag()` at the start of `RunAITests` and set via `SetCreditLimitReachedDuringRun()`. It is also checked from `AITTestRunIteration.Codeunit.al` in the `OnBeforeTestMethodRun` subscriber via `ShouldSkipTestDueToCreditLimit()`.

This design is functional and simple but warrants a review to confirm it is robust in all scenarios — for example, whether the state is always correctly reset across consecutive runs within the same session, and whether there are edge cases where the flag could be stale (e.g., if a run errors out before `ResetCreditLimitFlag` is called on the next run). A focused review of this pattern should be done before shipping.

### 12.6 Remove per-suite credit limits — keep only global limit

The current implementation supports both a global monthly credit limit (on `AIT Credit Limit Setup`) and per-suite limits (the `"Suite Credit Limit"` field on `AIT Test Suite`). This adds significant complexity across the codebase for a feature that is not needed at this stage. We should simplify to **global limits only** and remove all per-suite limit code. Affected areas include:

- **`AIT Credit Limit Mgt.` (codeunit 149050):** Suite-specific checks in `CheckCreditLimitBeforeRun` (checks `AITTestSuite."Suite Credit Limit"` and raises `SuiteCreditLimitExceededErr`), `CheckCreditLimitDuringRun` (same pattern), `IsSuiteCreditLimitExceeded`, `GetSuiteCreditsRemaining`, `GetSuiteCreditUsagePercentage`, `IsSuiteApproachingCreditLimit`, and the `SuiteCreditLimitExceededErr` label.
- **`AIT Credit Limits` page (page 149048):** The `"Suite Credit Limit"` editable field and validation trigger, the `SuiteUsagePercentage` / `SuiteUsageStyle` display, and the `UpdateSuiteCreditLimitDisplay` / `UpdateSuiteUsagePercentage` helper procedures.
- **`Agent Test Suite` page extension (`AgentTestSuite.PageExt.al`):** Suite-specific credit limit notifications (`SuiteLimitNotification`, `SuiteWarningNotification`) and their associated action handlers.
- **`AIT Test Suite` table extension (`AgentTestSuite.TableExt.al`):** The `"Suite Credit Limit"` field definition.
- **Spec sections 1, 3, 4, 6, 9.4:** References to per-suite limits in the spec should be updated or removed.

### 12.7 Review and remove unused methods

Several methods in the codebase appear to have no callers and should be reviewed for removal:

- **`GetCreditsRemaining()`** in `AIT Credit Limit Mgt.` (codeunit 149050, line 127): No callers found in the workspace. Computes global remaining credits but is never called — the Credit Limits page computes this inline instead.
- **`GetSuiteCreditsRemaining()`** in `AIT Credit Limit Mgt.` (codeunit 149050, line 148): No callers found. This will also be removed as part of 12.6 (per-suite limit removal), but is unused even today.
- **`CreditLimitReachedDuringRunErr`** label in `AIT Credit Limit Mgt.` (line 17): Declared but never referenced in any `Error()` call. The actual error raised when skipping tests due to credit limits is `CreditLimitReachedSkipTestErr` in `AITTestRunIteration.Codeunit.al`.

A full audit of all public methods in the credit limit codeunits should be done to identify any other dead code before shipping.
