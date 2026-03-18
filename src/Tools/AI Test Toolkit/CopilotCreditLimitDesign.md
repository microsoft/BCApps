# Copilot Credit Limit - Design Document

## 1. Overview

The Copilot Credit Limit feature provides cost control for agent test suites within the AI Test Toolkit. It enables administrators to set monthly credit limits at both the environment and individual suite levels, automatically stopping test execution when limits are reached.

---

## 2. Architecture Principles

### 2.1 Single Responsibility
Each component has a focused purpose:
- **Table:** Data storage only
- **Page:** UI presentation and user interaction
- **Codeunit:** Business logic and enforcement

### 2.2 Extension-Based Design
Agent-specific functionality is isolated in page/table extensions, keeping the core AI Test Toolkit agnostic to specific test types (Copilot vs. Agent vs. MCP).

### 2.3 Fail-Safe Enforcement
- Credit checks occur at multiple points to ensure limits are respected
- Uses `SingleInstance` pattern for state tracking during test runs
- Graceful degradation: tests complete with error rather than abrupt termination

### 2.4 Environment-Wide Scope
- Credit limit setup is stored with `DataPerCompany = false`
- Limits apply across all companies in the environment
- Consistent behavior regardless of company context

---

## 3. Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI Layer                                  │
├─────────────────────────────────────────────────────────────────┤
│  AIT Credit Limits Page     │  Agent Test Suite PageExt         │
│  (Administration)           │  (Notifications & Navigation)     │
└──────────────┬──────────────┴───────────────┬───────────────────┘
               │                              │
               ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Business Logic Layer                         │
├─────────────────────────────────────────────────────────────────┤
│  AIT Credit Limit Mgt.      │  Agent Test Context Impl.         │
│  - Limit checking           │  - Credit consumption queries     │
│  - Status management        │  - Monthly credit aggregation     │
│  - Run-time state tracking  │                                   │
└──────────────┬──────────────┴───────────────┬───────────────────┘
               │                              │
               ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Data Layer                                 │
├─────────────────────────────────────────────────────────────────┤
│  AIT Credit Limit Setup     │  Agent Task Log                   │
│  (Singleton, env-wide)      │  (Task-level consumption)         │
│                             │                                   │
│  AIT Test Suite             │  AIT Log Entry                    │
│  (Suite Credit Limit field) │  (Test execution records)         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Data Model

### 4.1 AIT Credit Limit Setup (Table 149040)

Singleton table storing environment-wide credit configuration.

| Field | Type | Purpose |
|-------|------|---------|
| Primary Key | Code[10] | Always blank (singleton) |
| Monthly Credit Limit | Decimal | Environment-wide monthly cap |
| Enforcement Enabled | Boolean | Toggle to enable/disable enforcement |
| Period Start Date | Date | First day of current tracking month |

**Key Properties:**
- `DataPerCompany = false` - Environment-wide
- `ReplicateData = false` - Not replicated
- Auto-resets period on month change via `GetOrCreate()`

### 4.2 AIT Test Suite Extensions

| Field | Type | Purpose |
|-------|------|---------|
| Suite Credit Limit | Decimal | Per-suite credit cap (0 = no limit) |

**Relationship:** Suite limits are subdivisions of the global limit. Both limits apply simultaneously.

### 4.3 Credit Consumption Calculation

Credits are calculated dynamically from `Agent Task Log` records:
1. Query log entries for the suite within the current period
2. Sum `CopilotCreditsConsumed` from associated agent tasks
3. Filter by `Period Start Date` to ensure monthly boundaries

---

## 5. Enforcement Flow

### 5.1 Pre-Run Check

```
StartAITSuite()
    │
    ├── CheckCreditLimitBeforeRun()
    │   ├── Is Test Type = Agent? ──No──► Allow
    │   ├── Is Enforcement Enabled? ──No──► Allow
    │   ├── Is Global Limit Set? ──No──► Allow
    │   ├── Global Credits >= Limit? ──Yes──► Error
    │   └── Suite Credits >= Suite Limit? ──Yes──► Error
    │
    └── Continue to RunAITests()
```

### 5.2 During-Run Check (Per Test Line)

```
RunAITests() loop
    │
    ├── CheckCreditLimitDuringRun()
    │   └── [Same checks as pre-run, but no error - returns boolean]
    │
    ├── IsCreditLimitReachedDuringRun()?
    │   └── [Check SingleInstance flag set by OnAfterTestMethodRun]
    │
    ├── If either true:
    │   ├── SetCreditLimitReachedStatus()
    │   └── Exit loop
    │
    └── RunAITestLine()
```

### 5.3 Per-Test Method Check

```
OnBeforeTestMethodRun()
    │
    ├── ShouldSkipTestDueToCreditLimit()? ──Yes──► Error (skip test)
    │
    └── Continue test execution

OnAfterTestMethodRun()
    │
    ├── CheckAndHandleCreditLimitAfterTest()
    │   ├── Is Global Limit Exceeded?
    │   └── Is Suite Limit Exceeded?
    │
    └── If either: SetCreditLimitReachedDuringRun()
```

---

## 6. State Management

### 6.1 SingleInstance Pattern

The `AIT Credit Limit Mgt.` codeunit uses `SingleInstance = true` to track state across the test run:

```al
codeunit 149050 "AIT Credit Limit Mgt."
{
    SingleInstance = true;
    
    var
        CreditLimitReachedDuringRun: Boolean;
}
```

**Lifecycle:**
1. `ResetCreditLimitFlag()` - Called at start of suite run
2. `SetCreditLimitReachedDuringRun()` - Called when limit detected
3. `IsCreditLimitReachedDuringRun()` - Checked before each test
4. `ShouldSkipTestDueToCreditLimit()` - Used in event subscriber

### 6.2 Status Transitions

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

When `CreditLimitReached`:
- All running test method lines → `Skipped`
- All pending (blank status) lines → `Skipped`
- Suite status → `CreditLimitReached`

**Note:** The `Skipped` status (enum value 50) distinguishes lines that didn't run due to credit limits from lines that were manually cancelled by users.

---

## 7. User Interface Design

### 7.1 Credit Limits Page

**Purpose:** Central administration of credit limits

**Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Header Group: Monthly Copilot Credit Limits                │
├─────────────────────────────────────────────────────────────┤
│ [Editable]    Monthly Copilot Credit Limit: 200.00         │
│ [Editable]    Enforcement Enabled: Yes                     │
│ [Computed]    Copilot Credits Consumed: 160.00             │
│ [Computed]    Copilot Credits Available: 40.00  [YELLOW]   │
│ [Computed]    Usage: 80.0%                                 │
│ [Display]     Current Period: Mar 1, 2026 - Mar 31, 2026   │
├─────────────────────────────────────────────────────────────┤
│ Repeater: Agent Test Suites                                 │
│ ┌──────┬───────────┬────────┬───────┬───────┬─────┬───────┐│
│ │Code  │Description│Consumed│Limit  │Usage %│Skip │Status ││
│ ├──────┼───────────┼────────┼───────┼───────┼─────┼───────┤│
│ │AGT-01│Sales Agent│ 80.00  │100.00 │ 80.0% │  0  │Running││
│ │AGT-02│Support Bot│ 80.00  │       │       │  3  │Skipped││
│ └──────┴───────────┴────────┴───────┴───────┴─────┴───────┘│
└─────────────────────────────────────────────────────────────┘
```

**Default Filter:** Shows only suites that have consumed credits (toggle available)

**Suite Limit Display:**
- Empty = No suite-specific limit (global only)
- Value = Explicit suite limit

### 7.2 Notifications

Displayed on the AI Eval Suite page for Agent type suites:

| Notification | Trigger | Action | Style |
|--------------|---------|--------|-------|
| Global Warning (80%) | `IsApproachingCreditLimit()` | Open Credit Limits | Warning |
| Suite Warning (80%) | `IsSuiteApproachingCreditLimit()` | Open Credit Limits | Warning |
| Global Limit Reached | `IsGlobalCreditLimitExceeded()` | Open Credit Limits | Error |
| Suite Limit Reached | `IsSuiteCreditLimitExceeded()` | Open Credit Limits | Error |

**Notification IDs:** Fixed GUIDs to enable proper recall when limits change:
- Global Limit: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`
- Suite Limit: `b2c3d4e5-f6a7-8901-bcde-f12345678901`
- Global Warning: `c3d4e5f6-a7b8-9012-cdef-123456789012`
- Suite Warning: `d4e5f6a7-b8c9-0123-defa-234567890123`

### 7.3 Percentage Display & Styling

**Usage Percentage Calculation:**
```al
UsagePercent := Round(CreditsConsumed / CreditLimit * 100, 0.1);
```

**Three-Tier Styling:**
| Usage % | Style | Meaning |
|---------|-------|--------|
| < 80% | Favorable (green) | Safe consumption level |
| 80-99% | Attention (yellow) | Approaching limit |
| >= 100% | Unfavorable (red) | Limit reached |

---

## 8. Installation & Upgrade

### 8.1 Install (New Environments)

```al
trigger OnInstallAppPerDatabase()
begin
    SetupDefaultCreditLimit();  // Creates record with 200 credits
end;
```

### 8.2 Upgrade (Existing Environments)

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

## 9. Performance Considerations

### 9.1 Credit Calculation

Credits are calculated on-demand by querying `Agent Task Log`. For performance:
- Queries are filtered by period start date
- Task IDs are deduplicated before summing
- Results are not cached (ensures accuracy)

### 9.2 Check Frequency

| Check Point | Frequency | Impact |
|-------------|-----------|--------|
| Before suite run | Once per run | Minimal |
| Before each test line | Per line | Low |
| After each test method | Per method | Medium |

**Optimization:** Checks short-circuit early if Test Type ≠ Agent or Enforcement disabled.

---

## 10. Error Handling

### 10.1 Pre-Run Errors

Blocking errors that prevent suite from starting:
- `Cannot start the agent test suite. The monthly credit limit of %1 has been reached.`
- `Cannot start the agent test suite. The suite credit limit of %1 has been reached.`

### 10.2 During-Run Errors

Graceful termination:
- Current test method completes with error: `Copilot credit limit reached. Skipping remaining tests.`
- Subsequent tests are skipped
- Suite transitions to `CreditLimitReached` status
- Run history is logged normally

---

## 11. Security & Permissions

### 11.1 Permission Sets

| Permission Set | Access Level |
|----------------|--------------|
| AI Test Toolkit - Obj | Execute (X) on new objects |
| AI Test Toolkit - Read | Read (R) on Credit Limit Setup |
| AI Test Toolkit - View | IMD on Credit Limit Setup |

### 11.2 Table Access

```al
InherentEntitlements = RIMDX;
InherentPermissions = RIMDX;
```

Credit Limit Setup table has inherent permissions to allow access during install/upgrade triggers.

---

## 12. Extensibility

### 12.1 Current Extension Points

- `OnBeforeRunIteration` event in test run iteration
- Status enum is not extensible (by design)

### 12.2 Future Considerations

- Webhook notifications when limits are reached
- Integration with Azure Cost Management
- Per-user credit tracking
- Historical consumption analytics
- Configurable warning threshold (currently fixed at 80%)
- Email notifications for administrators

---

## 13. Testing Considerations

### 13.1 Test Scenarios

1. **Pre-run blocking:** Verify suite cannot start when limit exceeded
2. **Mid-run stopping:** Verify tests stop within a line when limit hit
3. **Monthly reset:** Verify consumption resets on new month
4. **Suite vs. global:** Verify both limits apply correctly
5. **Notifications:** Verify correct notifications appear/disappear

### 13.2 Test Data Setup

```al
// Set up low limit for testing
AITCreditLimitSetup."Monthly Credit Limit" := 1;
AITCreditLimitSetup."Enforcement Enabled" := true;
AITCreditLimitSetup.Modify();
```

---

## 14. Glossary

| Term | Definition |
|------|------------|
| Copilot Credits | Unit of consumption for AI/agent operations |
| Global Limit | Environment-wide monthly credit cap |
| Suite Limit | Per-test-suite credit cap (subdivision of global) |
| Enforcement | Whether limits are actively enforced |
| Period | Monthly tracking window (1st to last day of month) |
| SingleInstance | AL codeunit pattern for session-wide state |
| Skipped | Line status indicating execution prevented by credit limit |
| Warning Threshold | 80% of limit - triggers warning notification |

---

## 15. Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-03-18 | AI Test Toolkit Team | Initial design || 1.1 | 2026-03-18 | AI Test Toolkit Team | Added 80% warning notifications, percentage display, Skipped line status, evals skipped tracking |