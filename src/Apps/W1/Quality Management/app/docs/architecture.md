# Quality Management - Architecture

## Architectural Overview

The Quality Management app follows a **configuration-driven inspection** architecture. Instead of hard-coding when and how inspections occur, all behavior is data-driven through three layers of configuration:

```
[Source Configuration]  What tables/fields map into inspections
        ↓
[Inspection Template]   What questions/tests to ask
        ↓
[Generation Rule]       When to trigger inspection creation
```

At runtime, `QltyInspectionCreate` (codeunit 20404) ties these together: given a source record, it finds matching generation rules, selects the right template, and creates a structured inspection document.

## Layer Breakdown

### 1. Configuration Layer (`src/Configuration/`)

**Inspection Templates** (`Configuration/Template/`)
- `Qlty. Inspection Template Hdr.` (table) - Template header with code, description, sampling settings
- `Qlty. Inspection Template Line` (table) - Individual test/question lines within a template
- `Qlty. Test` (table) - Reusable test definitions (value type, lookup values, case sensitivity)
- `Qlty. Test Lookup Value` (table) - Allowed values for lookup-type tests

**Generation Rules** (`Configuration/GenerationRule/`)
- `Qlty. Inspection Gen. Rule` (table 20404) - Defines trigger conditions: source table, filter criteria, template to use, sort order for matching priority
- `Qlty. Inspec. Gen. Rule Mgmt.` (codeunit) - Evaluates rules against source records
- `Qlty. Job Queue Management` (codeunit) - Handles scheduled (non-event-triggered) inspection creation via job queue
- Trigger enums per module: `QltyPurchaseOrderTrigger`, `QltyTransferOrderTrigger`, `QltyAssemblyTrigger`, `QltyProductionOrderTrigger`, `QltyWhseReceiptTrigger`, `QltyWarehouseTrigger`

**Source Configuration** (`Configuration/SourceConfiguration/`)
- `Qlty. Inspect. Source Config.` (table) - Maps a source table to inspection fields (item no., quantity, lot, location, etc.)
- `Qlty. Inspect. Src. Fld. Conf.` (table) - Per-field mapping configuration
- `Qlty. Traversal` (codeunit) - Navigates complex record relationships to extract source field values

**Result Configuration** (`Configuration/Result/`)
- `Qlty. Inspection Result` (table) - Defines named result options for template lines
- `Qlty. I. Result Condit. Conf.` (table) - Conditional configuration based on result values (auto-disposition, failure states, item tracking block)
- `Qlty. Result Condition Mgmt.` (codeunit) - Evaluates result conditions
- `Qlty. Result Evaluation` (codeunit) - Determines pass/fail based on line results

### 2. Document Layer (`src/Document/`)

**Core tables:**
- `Qlty. Inspection Header` (table 20405) - One per inspection. Tracks: no., template, status, source quantity, item/lot/location, re-inspection chain
- `Qlty. Inspection Line` (table 20406) - One per template line. Tracks: test result, failure state, visibility, finish-allowed flags

**Status lifecycle:**
```
Open → (Inspector fills lines) → Finished
         ↑                           ↓
         └─── Re-open ←──────────────┘
```
Re-inspections create new Header records linked via `Re-inspection No.` counter and `Most Recent Re-inspection` flag.

**Creation:**
- `Qlty. Inspection - Create` (codeunit 20404) - Main entry point. `CreateInspectionWithVariant()` accepts any Record/RecordRef/RecordId. Matches generation rules, resolves template, maps source fields.
- `Qlty. Create Inspection` (report) - Batch creation from source records
- `Qlty. Schedule Inspection` (report) - Job-queue triggered creation

**Navigation:**
- `Qlty. Document Navigation` (codeunit) - Handles navigation between inspection and source document

### 3. Integration Layer (`src/Integration/`)

Each integration sub-module subscribes to events from the corresponding BC module and calls `QltyInspectionCreate` when trigger conditions are met.

| Sub-module | Integrated BC Areas |
|---|---|
| `Integration/Receiving/` | Purchase Orders, Sales Returns, Warehouse Receipts |
| `Integration/Manufacturing/` | Production Orders (output + routing), Consumption Journal |
| `Integration/Assembly/` | Assembly Orders |
| `Integration/Inventory/` | Item tracking (lot/serial/package), transfers, item availability |
| `Integration/Warehouse/` | Warehouse entries, receipts |
| `Integration/Foundation/` | Attachments (photos), Navigate integration |

**Pattern:** Each integration codeunit (e.g. `QltyReceivingIntegration`) subscribes to `OnAfterPost` / `OnBeforePost` events in the base app and calls into `QltyInspectionCreate`. Table extensions add inspection-related fields (e.g. `QltyTransferHeader.TableExt.al` adds inspection status to transfer orders).

### 4. Dispositions Layer (`src/Dispositions/`)

After finishing an inspection, dispositions define what action to take on the inspected inventory. Each disposition implements the `IQltyDisposition` interface.

| Disposition | Action |
|---|---|
| `QltyDispTransfer` | Create transfer order to move inventory |
| `QltyDispWarehousePutAway` | Create warehouse put-away |
| `QltyDispInternalPutAway` | Create internal put-away |
| `QltyDispPurchaseReturn` | Create purchase return order |
| `QltyDispNegAdjustInv` | Post negative inventory adjustment |
| `QltyDispChangeTracking` | Change item tracking (lot/serial/package) |
| `QltyDispMoveItemReclass` | Move via item reclassification journal |
| `QltyDispMoveWhseReclass` | Move via warehouse reclassification |
| `QltyDispMoveWorksheet` | Move via movement worksheet |
| `QltyDispInternalMove` | Internal move |

`QltyDispositionBuffer` (table) holds the working data during disposition processing.

### 5. Workflow Layer (`src/Workflow/`)

Optional approval workflow integration using BC's standard workflow engine:
- `QltyWorkflowSetup` - Registers workflow events and responses
- `QltyWorkflowApprovals` - Handles approval request logic
- `QltyWorkflowResponse` - Implements workflow response actions
- `QltyStartWorkflow` - Triggers workflow from inspection actions

### 6. Setup (`src/Setup/`)

- `Qlty. Management Setup` (singleton table) - App-wide settings: number series, default behaviors for item tracking, inspection creation options, add-picture handling, update-source behavior
- `QltyManagementSetupGuide` - Assisted setup wizard
- `QltyDemoDataMgmt` - Demo data provisioning

## Key Design Patterns

**Interface-based Dispositions:** All disposition actions implement `IQltyDisposition` interface, making it easy to add new disposition types without changing core logic.

**Variant-based Inspection Creation:** `CreateInspectionWithVariant()` accepts `Variant` (Record/RecordRef/RecordId), decoupling integrations from specific table types.

**Event-driven Integration:** All BC module integrations use event subscribers rather than direct calls, keeping the base app unmodified.

**Rule Priority + Sort Order:** Multiple generation rules can match a source record; the one with the lowest Sort Order wins. This enables complex conditional logic without code.

**Re-inspection Chain:** A re-inspection is a new Header record with the same base `No.` but incremented `Re-inspection No.`. The `Most Recent Re-inspection` flag on the latest record simplifies filtering.
