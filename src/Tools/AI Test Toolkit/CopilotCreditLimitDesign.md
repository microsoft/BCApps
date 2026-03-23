# Copilot Credit Limit - Design Document

## 1. Overview

The Copilot Credit Limit feature provides cost control for eval suites within the AI Test Toolkit. It uses an interface-based strategy pattern (`AIT Eval Limit Provider`) to allow different test types to define their own limit-checking behavior. Currently, only the **Agent** test type enforces limits (monthly Copilot credit caps), while **Copilot** and **MCP** types use a no-op implementation.

---

## 2. Architecture Principles

### 2.1 Strategy Pattern via Interface
Limit-checking behavior is abstracted behind the `AIT Eval Limit Provider` interface, implemented per test type through the `AIT Test Type` enum. The core test suite engine is fully agnostic to the specifics of any limit implementation.

### 2.2 Stateless Enforcement
All limit checks query the database on every call. There is no cached state or `SingleInstance` flag for limit tracking. This guarantees accuracy at the cost of additional DB reads per check.

### 2.3 Enum-Driven Dispatch
The `AIT Test Type` enum declares a `DefaultImplementation` of `AIT Eval No Limit` (null object). Only the `Agent` value overrides this with `AIT Eval Monthly Copilot Cred.`. New test types automatically get no-op limit behavior unless explicitly configured.

### 2.4 Extension-Based Design
Agent-specific UI (notifications, navigation, metrics) is isolated in page extensions, keeping the core AI Test Toolkit agnostic to specific test types.

### 2.5 Environment-Wide Scope
- Credit limit setup is stored with `DataPerCompany = false`
- Limits apply across all companies in the environment
- Consistent behavior regardless of company context

---

## 3. Component Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        UI Layer                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  AIT Eval Monthly Copilot Cred.   │  Agent Test Suite PageExt              │
│  Page (Administration)            │  (Notifications & Navigation)          │
└──────────────┬────────────────────┴──────────────────┬──────────────────────┘
               │                                       │
               ▼                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Interface Layer                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  «interface» AIT Eval Limit Provider                                        │
│  ┌──────────────────────────────────┬──────────────────────────────────┐    │
│  │ AIT Eval Monthly Copilot Cred.  │  AIT Eval No Limit               │    │
│  │ (Agent test type)               │  (Default for Copilot, MCP)      │    │
│  │ - Monthly credit enforcement    │  - All methods are no-ops        │    │
│  │ - Notifications & warnings      │  - IsLimitReached() → false      │    │
│  └──────────────────────────────────┴──────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────────────────────┤
│  AIT Test Type Enum (dispatch)      │  AIT Test Suite Mgt. (orchestration) │
│  - DefaultImpl = No Limit           │  - StartAITSuite, RunAITests         │
│  - Agent → Monthly Copilot Cred.    │  - RunAITestLine, LogSkippedEval     │
└──────────────┬──────────────────────┴──────────────────┬────────────────────┘
               │                                         │
               ▼                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Data Layer                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  AIT Credit Limit Setup (149040)    │  Agent Task Log                      │
│  (Singleton, env-wide)              │  (Task-level consumption)            │
│                                     │                                      │
│  AIT Test Suite                     │  AIT Log Entry                       │
│  (Test Type field → enum dispatch)  │  (Test execution + skipped records)  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Interface Contract

### 4.1 AIT Eval Limit Provider

```al
interface "AIT Eval Limit Provider"
{
    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite");
    procedure IsLimitReached(): Boolean;
    procedure HandleLimitReached(var AITTestSuite: Record "AIT Test Suite");
    procedure ShowNotifications();
    procedure OpenSetupPage();
}
```

| Method | Purpose | Called By |
|--------|---------|-----------|
| `CheckBeforeRun` | Pre-run gate. Raises `Error()` if the limit is already reached, preventing the suite from starting. | `StartAITSuite`, `RunAITestLine` |
| `IsLimitReached` | Stateless boolean check. Queries current consumption vs. limit. | `RunAITests` loop, `OnBeforeTestMethodRun`, `OnAfterTestMethodRun`, `RunAITestLine` post-run |
| `HandleLimitReached` | Sets suite status to `CreditLimitReached` and marks pending/running lines as `Skipped`. | `RunAITests` loop when `IsLimitReached()` returns true |
| `ShowNotifications` | Sends/recalls page notifications (limit reached, 80% warning, enforcement disabled). | `AgentTestSuite.PageExt` on `OnAfterGetCurrRecord` |
| `OpenSetupPage` | Opens the setup page for the limit provider. Also used as notification action handler. | `AgentTestSuite.PageExt` action, notification actions |

### 4.2 Implementations

| Implementation | Codeunit | Applies To | Behavior |
|----------------|----------|------------|----------|
| `AIT Eval Monthly Copilot Cred.` | 149039 | Agent | Full enforcement: monthly credit tracking, notifications, error on limit |
| `AIT Eval No Limit` | 149041 | Copilot, MCP (default) | Null object: all methods are no-ops, `IsLimitReached()` returns `false` |

---

## 5. Data Model

### 5.1 AIT Credit Limit Setup (Table 149040)

Singleton table storing environment-wide credit configuration.

| Field | Type | Purpose |
|-------|------|---------|
| Primary Key | Code[10] | Always blank (singleton) |
| Monthly Credit Limit | Decimal | Environment-wide monthly cap |
| Enforcement Enabled | Boolean | Toggle to enable/disable enforcement |
| Period Start Date | Date | First day of current tracking month |

**Key Properties:**
- `DataPerCompany = false` — Environment-wide
- `ReplicateData = false` — Not replicated
- `InherentEntitlements/Permissions = RIMDX` — Accessible during install/upgrade
- Auto-resets period on month change via `GetOrCreate()`
- `GetPeriodEndDate()` computes the last day of the period month

### 5.2 AIT Test Type Enum (149041)

Drives interface dispatch. `Extensible = false`.

| Value | Caption | AIT Eval Limit Provider Implementation |
|-------|---------|----------------------------------------|
| 0 | Copilot | `AIT Eval No Limit` (default) |
| 1 | Agent | `AIT Eval Monthly Copilot Cred.` |
| 2 | MCP | `AIT Eval No Limit` (default) |

### 5.3 Credit Consumption Calculation

Credits are calculated dynamically via `Agent Test Context Impl.`:
1. `GetTotalCreditsConsumedThisMonth(PeriodStartDate)` — queries all agent task consumption since period start
2. `GetCopilotCreditsForPeriod(SuiteCode, PeriodStartDate)` — per-suite consumption for the page display
3. No caching — every call hits the database for accuracy

---

## 6. Enforcement Flow

### 6.1 Pre-Run Check

```
StartAITSuite()
    │
    ├── AITEvalLimitProvider := AITTestSuite."Test Type"
    ├── AITEvalLimitProvider.CheckBeforeRun(AITTestSuite)
    │   ├── IsLimitReached(Credits, Limit)?
    │   │   ├── Enforcement disabled? ──► exit(false)
    │   │   ├── Limit <= 0? ──► exit(false)
    │   │   └── Credits >= Limit? ──► exit(true)
    │   └── If true ──► Error('Cannot start... limit %1 reached. Consumed: %2')
    │
    └── Continue to RunAITests()
```

### 6.2 During-Run Check (Per Test Line)

```
RunAITests() loop
    │
    ├── AITEvalLimitProvider.IsLimitReached()?
    │   └── If true: CreditLimitReached := true
    │
    ├── If CreditLimitReached:
    │   ├── AITEvalLimitProvider.HandleLimitReached(AITTestSuite)
    │   │   ├── SetRunStatus → CreditLimitReached
    │   │   └── ModifyAll Running/Starting/" " lines → Skipped
    │   └── Exit loop
    │
    └── RunAITestLine()
```

### 6.3 Per-Test Method Check

```
OnBeforeTestMethodRun()
    │
    ├── AITEvalLimitProvider.IsLimitReached()?
    │   └── If true:
    │       ├── Skip := true  (Test Runner skips execution)
    │       ├── LogSkippedEval()  (AIT Log Entry with Status::Skipped)
    │       └── exit
    │
    └── Continue test execution (reset counters, start scenario)

OnAfterTestMethodRun()
    │
    ├── AITEvalLimitProvider.IsLimitReached()?
    │   └── If true: exit (don't log — test was already skipped by platform)
    │
    └── Normal logging (tokens, turns, accuracy)
```

### 6.4 Post-Line Check

```
RunAITestLine() — after Codeunit.Run returns
    │
    ├── AITEvalLimitProvider.IsLimitReached()?
    │   └── If true: Line Status → Skipped
    │   └── If false: Line Status → Completed
    │
    └── Log telemetry, run history
```

---

## 7. State Management

### 7.1 Stateless Design

There are **no SingleInstance state flags** for limit tracking. Every limit check calls `IsLimitReached()` which:
1. Reads `AIT Credit Limit Setup` from DB
2. Queries `Agent Test Context Impl.GetTotalCreditsConsumedThisMonth()`
3. Compares consumption against configured limit
4. Returns boolean

This eliminates stale-state bugs at the cost of repeated DB queries during a run.

### 7.2 Status Transitions

```
         ┌──────────────┐
         │   Running    │
         └──────┬───────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌─────────────────┐
│Complete│ │Cancelled│ │CreditLimitReached│
└────────┘ └────────┘ └─────────────────┘
```

When `CreditLimitReached` (via `HandleLimitReached`):
- All `Running` test method lines → `Skipped`
- All `Starting` test method lines → `Skipped`
- All blank-status test method lines → `Skipped`
- Suite status → `CreditLimitReached`

### 7.3 Skipped Eval Tracking

When a test method is skipped due to credit limits, `LogSkippedEval()` creates an `AIT Log Entry` with:
- `Status = Skipped`
- `Message = 'Eval skipped due to Copilot credit limit being reached.'`
- `Procedure Name` = the function that was skipped

These entries feed FlowFields on `AIT Test Suite` and `AIT Run History` (`No. of Tests Skipped`).

---

## 8. User Interface Design

### 8.1 Credit Limits Page (`AIT Eval Monthly Copilot Cred.`, Page 149048)

**Purpose:** Central administration of credit limits. PageType = Worksheet.

**Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Label: "Credit limits control when new evals can be        │
│  started. Once the limit is reached, no new evals can      │
│  start, but any eval already in progress is allowed to     │
│  finish. Actual consumption may slightly exceed the limit." │
├─────────────────────────────────────────────────────────────┤
│ [Toggle]     Limits Enabled: Yes                            │
│ [Editable]   Monthly Copilot Credit Limit: 200.00          │
│ [Computed]   Copilot Credits Consumed: 160.00              │
│ [Computed]   Copilot Credits Available: 40.00  [YELLOW]    │
│ [Computed]   Usage: 80.0%                                  │
│ [Display]    Current Period: Mar 1, 2026 - Mar 31, 2026    │
├─────────────────────────────────────────────────────────────┤
│ Repeater: Agent Test Suites                                │
│ ┌──────┬───────────┬──────────────────────────────────┐    │
│ │Code  │Description│Copilot Credits Consumed (Month)  │    │
│ ├──────┼───────────┼──────────────────────────────────┤    │
│ │AGT-01│Sales Agent│ 80.00                            │    │
│ │AGT-02│Support Bot│ 80.00                            │    │
│ └──────┴───────────┴──────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

- **SourceTableView:** Filtered to `Test Type = Agent` only
- **Default Filter:** Shows only suites that have consumed credits (toggle to show all)
- **Monthly Credit Limit field:** Editable only when enforcement is enabled

### 8.2 Notifications (on Agent Test Suite page)

Three mutually exclusive notification paths, managed by `ShowNotifications()`:

| State | Notification | Action |
|-------|-------------|--------|
| Enforcement disabled | "Copilot credit limit enforcement is disabled. Eval execution costs are not bounded." | View credit limits |
| Limit reached | "The monthly Copilot credit limit has been reached." | View credit limits |
| ≥ 80% used | "Warning: X% of the monthly Copilot credits have been consumed." | View credit limits |

**Notification IDs:** Fixed GUIDs ensure proper send/recall lifecycle:
- Enforcement Disabled: `b2acb24d-dbc8-4bda-99c9-8bed0d470fd8`
- Global Limit Reached: `fbb7ec95-3427-400f-9fad-34d6009858c9`
- Global Warning (80%): `f365e625-24bb-491b-bd85-83d66d5557ae`

When enforcement is disabled, limit/warning notifications are recalled. When enforcement is enabled, the disabled notification is recalled.

### 8.3 Percentage Display & Styling

**Three-Tier Styling:**
| Usage % | Style | Meaning |
|---------|-------|---------|
| < 80% | Favorable (green) | Safe consumption level |
| 80-99% | Attention (yellow) | Approaching limit |
| ≥ 100% | Unfavorable (red) | Limit reached |

---

## 9. Installation & Upgrade

### 9.1 Install (New Environments)

```al
trigger OnInstallAppPerDatabase()
begin
    SetupDefaultCreditLimit();  // Creates record with 200 credits
end;
```

### 9.2 Upgrade (Existing Environments)

```al
trigger OnUpgradePerDatabase()
begin
    SetupDefaultCreditLimit();
end;

// Uses Upgrade Tag pattern to run only once:
// 'MS-AITestToolkit-InsertDefaultCreditLimit-20260318'
```

**Default Values:**
- Monthly Credit Limit: 200
- Enforcement Enabled: true
- Period Start Date: First day of current month

---

## 10. Performance Considerations

### 10.1 Credit Calculation

Credits are calculated on-demand by querying `Agent Task Log`. For performance:
- Queries are filtered by period start date
- Task IDs are deduplicated before summing
- Results are **not** cached (ensures accuracy)

### 10.2 Check Frequency

| Check Point | Frequency | Impact |
|-------------|-----------|--------|
| `CheckBeforeRun` | Once per run | Minimal |
| `IsLimitReached` in RunAITests loop | Per test method line | Low-Medium |
| `IsLimitReached` in OnBefore/AfterTestMethodRun | Per test method | Medium |
| `IsLimitReached` post-line in RunAITestLine | Per line | Low |

**Optimization:** The `AIT Eval No Limit` implementation short-circuits immediately (`exit(false)`) for non-Agent test types, with zero DB access.

---

## 11. Error Handling

### 11.1 Pre-Run Error

Blocking error that prevents the suite from starting:
- `'Cannot start the agent eval suite. The monthly credit limit for evals of %1 has been reached. Current consumption: %2.'`

This is raised by `CheckBeforeRun` using the private `IsLimitReached(var CopilotCreditConsumed, var MonthlyCreditLimit)` overload to get both values in a single DB pass.

### 11.2 During-Run Handling

Graceful wind-down (no `Error()` raised during execution):
- `IsLimitReached()` returns `true` → remaining methods skipped via `Skip := true`
- Skipped methods logged as `AIT Log Entry` with `Status::Skipped`
- Suite transitions to `CreditLimitReached` status
- Run history is logged normally

---

## 12. Security & Permissions

### 12.1 Permission Sets

| Permission Set | Access Level |
|----------------|--------------|
| AI Test Toolkit - Obj | Execute (X) on new objects |
| AI Test Toolkit - Read | Read (R) on Credit Limit Setup |
| AI Test Toolkit - View | IMD on Credit Limit Setup |

### 12.2 Table Access

```al
InherentEntitlements = RIMDX;
InherentPermissions = RIMDX;
```

Credit Limit Setup table has inherent permissions to allow access during install/upgrade triggers.

---

## 13. File Layout

```
src/
  Limits/
    AITEvalLimitProvider.Interface.al          ← Interface definition
    CopilotCredits/
      AITEvalMonthlyCopilotCred.Codeunit.al   ← Agent implementation (149039)
      AITEvalMonthlyCopilotCred.Page.al       ← Credit limits admin page (149048)
      AITCreditLimitSetup.Table.al            ← Singleton config table (149040)
    None/
      AITEvalNoLimit.Codeunit.al              ← Null object implementation (149041)
  TestSuite/
    AITTestType.Enum.al                       ← Enum with interface dispatch (149041)
    AITTestSuiteMgt.Codeunit.al               ← Orchestration (calls interface)
  AITTestRunIteration.Codeunit.al             ← Test method event subscribers
  Agent/
    AgentTestSuite.PageExt.al                 ← Agent-specific UI, notifications
```

---

## 14. Extensibility

### 14.1 Adding a New Limit Strategy

To add a new limit type for a future test type (e.g., MCP with token-based limits):
1. Create a new codeunit implementing `AIT Eval Limit Provider`
2. Set the `Implementation` on the corresponding `AIT Test Type` enum value
3. No changes needed in `AIT Test Suite Mgt.` or `AIT Test Run Iteration`

### 14.2 Current Extension Points

- `OnBeforeRunIteration` event in `AIT Test Run Iteration`
- `AIT Test Type` enum is `Extensible = false` (by design — new types require code changes)

### 14.3 Future Considerations

- Configurable warning threshold (currently fixed at 80%)
- Historical consumption analytics / trends
- Webhook or email notifications when limits are reached

---

## 15. Testing Considerations

### 15.1 Test Scenarios

1. **Pre-run blocking:** Verify suite cannot start when limit exceeded
2. **Mid-run stopping:** Verify tests stop and remaining methods are skipped
3. **Monthly reset:** Verify consumption resets on new month
4. **Enforcement toggle:** Verify notifications and behavior change correctly
5. **Skipped eval tracking:** Verify AIT Log Entries with Status::Skipped are created
6. **No-op implementation:** Verify Copilot/MCP test types are unaffected

### 15.2 Test Data Setup

```al
AITCreditLimitSetup."Monthly Credit Limit" := 1;
AITCreditLimitSetup."Enforcement Enabled" := true;
AITCreditLimitSetup.Modify();
```

---

## 16. Glossary

| Term | Definition |
|------|------------|
| Copilot Credits | Unit of consumption for AI/agent operations |
| Eval Limit Provider | Interface abstracting limit-checking behavior per test type |
| Enforcement | Whether limits are actively enforced |
| Period | Monthly tracking window (1st to last day of month) |
| Skipped | Line/entry status indicating execution prevented by credit limit |
| Warning Threshold | 80% of limit — triggers warning notification |
| Null Object | Design pattern: `AIT Eval No Limit` provides safe no-op behavior |

---

## 17. Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-03-18 | AI Test Toolkit Team | Initial design |
| 1.1 | 2026-03-18 | AI Test Toolkit Team | Added 80% warning notifications, percentage display, Skipped line status, evals skipped tracking |
| 2.0 | 2026-03-23 | AI Test Toolkit Team | Major rewrite to match interface-based architecture. Removed per-suite limits, SingleInstance state flags, AIT Credit Limit Mgt. codeunit. Documented AIT Eval Limit Provider interface contract, enum dispatch, stateless enforcement, file layout, null object pattern. |