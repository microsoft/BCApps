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
value(X; CreditLimitReached)
{
    Caption = 'Credit Limit Reached';
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
| Warning threshold | Not needed |
| Notifications | Not needed |
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
│ Copilot Credits Available:    550.00                        │
│ Current Period:               March 1, 2026 - March 31, 2026│
├─────────────────────────────────────────────────────────────┤
│ Agent Test Suites (showing suites with credits consumed)    │
├──────────┬─────────────────┬──────────┬─────────┬──────────┤
│ Code     │ Description     │ Consumed │ Limit   │ Status   │
├──────────┼─────────────────┼──────────┼─────────┼──────────┤
│ AGENT-01 │ Sales Agent     │ 150.00   │ 200.00  │ Running  │
│ AGENT-02 │ Support Agent   │ 200.00   │ 300.00  │ Completed│
│ AGENT-03 │ Inventory Agent │ 100.00   │         │ Cancelled│
└──────────┴─────────────────┴──────────┴─────────┴──────────┘
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
