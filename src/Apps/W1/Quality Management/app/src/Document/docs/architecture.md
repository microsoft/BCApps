# Document Module - Architecture

## Responsibilities

This module owns:
1. The **data model** for quality inspections (Header + Lines)
2. The **creation logic** that converts generation rule matches into inspection documents
3. The **UI** for inspectors to view and fill in inspections
4. The **status lifecycle** management (Open → Finished, re-open, re-inspect)

It does NOT own:
- When to trigger creation (→ Generation Rules in Configuration)
- What to ask (→ Templates in Configuration)
- What to do after finishing (→ Dispositions)
- How to integrate with specific BC modules (→ Integration)

## Data Flow: Inspection Creation

```
Caller (Integration event or user action)
    │
    ▼
QltyInspectionCreate.CreateInspectionWithVariant(Variant, IsManual)
    │
    ├─ QltyInspecGenRuleMgmt.FindMatchingRule(RecordRef)
    │       └─ Evaluates Qlty. Inspection Gen. Rule table
    │          Returns template code
    │
    ├─ QltyInspectSourceConfig → QltyTraversal
    │       └─ Maps source record fields → Inspection Header fields
    │
    ├─ Creates Qlty. Inspection Header
    │
    └─ Creates Qlty. Inspection Lines from Template Lines
            └─ Copies Qlty. Inspection Result Condition Config
```

## Status Lifecycle

```
                    CreateInspectionWithVariant()
                              │
                              ▼
                    ┌─────────────────┐
                    │   Open          │◄──── Re-open
                    └────────┬────────┘
                             │ Set Status = Finished
                             ▼
                    ┌─────────────────┐
                    │   Finished      │
                    └────────┬────────┘
                             │ Re-inspect action
                             ▼
                    ┌─────────────────┐
                    │   New Header    │ (Re-inspection No. + 1)
                    │   Open          │
                    └─────────────────┘
```

When an inspection is **Finished**:
- `ProcessFinishInspection()` runs in `OnValidate` of Status field
- Result conditions are evaluated (`QltyResultConditionMgmt`)
- Item tracking may be blocked if configured
- Workflow may be triggered if configured
- Source document may be updated if `UpdateSourceBehavior` is configured

## Re-inspection Chain

All re-inspections share the same base `No.` (from number series). The chain is:

| No. | Re-inspection No. | Most Recent Re-inspection |
|---|---|---|
| QI-001 | 0 | false |
| QI-001 | 1 | false |
| QI-001 | 2 | true |

To get the current inspection for a given `No.`: filter on `Most Recent Re-inspection = true`.

## Inspection Creation - Error Handling

`CreateInspectionWithVariant` returns `Boolean` (true = success). Detailed status available via `GetLastCreateStatus()` returning `Qlty. Inspection Create Status` enum:

- `Created` - New inspection was created
- `AlreadyExists` - An open inspection already exists for this source record
- `NoMatchingRules` - No generation rule matched the source record
- `Error` - Creation failed (check error message)

The codeunit has `AvoidThrowingErrorWhenPossible` flag for silent failure in batch scenarios.

## Page Architecture

```
QltyInspectionList (list)
    └─ drill-down → QltyInspection (card)
            ├─ QltyInspectionSubform (lines subform)
            └─ QltyMostRecentPicture (picture part)

QltyInspectionLines (standalone lines, used in subforms from other pages)
```

The inspection card is the main UI. Inspectors fill in result values on each line in the subform.
