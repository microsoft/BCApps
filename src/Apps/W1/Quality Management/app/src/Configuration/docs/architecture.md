# Configuration Module - Architecture

## Three Configuration Layers

### Layer 1: Generation Rules (When)

`Qlty. Inspection Gen. Rule` defines the "when" condition:

```
Entry No.  | Sort Order | Intent    | Source Table | Table Filter | Template Code | Trigger
1          | 10         | Automatic | Purch. Line  | Item = 1000  | VENDOR-QC     | OnReceive
2          | 20         | Automatic | Purch. Line  | (any)        | GENERAL-QC    | OnReceive
```

**Matching logic (`QltyInspecGenRuleMgmt`):**
1. Filter rules by source table
2. Apply Sort Order (ascending) — evaluate rules in order
3. Check table filter against the source record
4. First match wins → return template code

**Trigger types:** Each integration module defines its own trigger enum (e.g., `QltyPurchaseOrderTrigger`). The generation rule stores the trigger as an integer, with the enum providing the named values.

**Scheduling:** If `Schedule Group` is set, `QltyJobQueueManagement` creates a BC Job Queue Entry that periodically calls `QltyScheduleInspection` report to create inspections on schedule.

### Layer 2: Inspection Templates (What)

```
Template Header (Code = "VENDOR-QC")
    ├── Template Line 1: Test = "VISUAL-CHECK", Results: Pass/Fail
    ├── Template Line 2: Test = "DIMENSION", Value type: Numeric, Min: 9.8, Max: 10.2
    └── Template Line 3: Test = "SURFACE", Results: A/B/C/Reject
```

**Template Line details:**
- Linked to a `Qlty. Test` record (test definition with value type)
- Has result visibility and finish-allowed rules per result value
- Can define result conditions (see Layer 3)

**Test value types (`QltyTestValueType`):**
- `Numeric` - Decimal measurement
- `Text` - Free text
- `Boolean` - Yes/No
- `Lookup` - Selection from `Qlty. Test Lookup Value` list
- `LargeText` - Long text (memo)

### Layer 3: Result Conditions (What Happens)

`Qlty. I. Result Condit. Conf.` defines consequences of result selection:

```
Template Code | Line No. | Result | Action               | Item Tracking Block
VENDOR-QC     | 30       | Reject | AutoDisposition=Transfer | Yes
VENDOR-QC     | 30       | A/B/C  | (none)               | No
```

**Result conditions can trigger:**
- Auto-disposition action on inspection finish
- Item tracking blocking/unblocking
- Failure state on the line

## Source Configuration

`Qlty. Inspect. Source Config.` answers: "Given a record from Table X, how do I find the item no., lot no., quantity, location, etc. to put on the inspection header?"

**Traversal (`QltyTraversal`):** Handles complex relationships. For example, a Warehouse Receipt Line may need to traverse to its associated Purchase Line to find the vendor or item attributes. The traversal codeunit follows configured field paths across table relationships.

**Auto-configuration (`QltyAutoConfigure`):** Pre-populates source configuration for standard BC tables (Purchase Line, Transfer Line, Assembly Line, etc.) during installation or when users run the assisted setup.

## Key Design Decisions

**Sort Order over code:** Rule priority is a user-editable integer rather than a code-based switch. This lets non-developers adjust prioritization without changing AL code.

**Filter as string:** Generation rule table filters are stored as filter strings applied dynamically via `SetView()`. This allows arbitrary filter criteria without requiring new fields.

**Result conditions are copied to inspection:** When an inspection is created, `Qlty. I. Result Condit. Conf.` records are copied to the inspection. This ensures that even if configuration changes after creation, the inspection behaves according to the rules at creation time.
