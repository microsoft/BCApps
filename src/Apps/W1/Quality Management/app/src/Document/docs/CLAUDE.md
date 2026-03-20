# Document Module - AI Context

The Document module is the runtime core of Quality Management — it contains the inspection document (header + lines) and all logic for creating, processing, and completing inspections.

## Files in This Module

| File | Purpose |
|---|---|
| `QltyInspectionHeader.Table.al` | Core inspection document. Tracks source, item, lot, location, status, re-inspection chain. |
| `QltyInspectionLine.Table.al` | Inspection lines (one per template test). Stores result value, failure state. |
| `QltyInspectionCreate.Codeunit.al` | **Main entry point** for inspection creation. Matches generation rules, resolves templates, maps source fields. |
| `QltyCreateInspection.Report.al` | Batch create inspections from source records. |
| `QltyInspection.Page.al` | Inspection card (single inspection view). |
| `QltyInspectionList.Page.al` | Inspection list page. |
| `QltyInspectionSubform.Page.al` | Lines subform embedded in card. |
| `QltyInspectionLines.Page.al` | Standalone lines page. |
| `QltyMostRecentPicture.Page.al` | Page part showing the most recent attached photo. |
| `QltyDocumentNavigation.Codeunit.al` | Navigate from inspection to source document. |
| `QltyInspectionStatus.Enum.al` | Open, Finished |
| `QltyInspectionCreateStatus.Enum.al` | Created, AlreadyExists, NoMatchingRules, Error |
| `QltyLineFailureState.Enum.al` | None, Failed, FailedWithComment |

## Key Patterns

**Creating an inspection:** Always use `QltyInspectionCreate`:
```al
QltyInspectionCreate.CreateInspectionWithVariant(SourceRecord, IsManualCreation);
```

**Finishing an inspection:** Set `Status = Finished` on the header. The `OnValidate` trigger calls `ProcessFinishInspection()` which evaluates result conditions.

**Re-inspection:** Creates a new Header record with same base `No.` but `Re-inspection No. + 1`. Previous record's `Most Recent Re-inspection` is set to false.

## Relevant Docs
- `docs/architecture.md` - Full system architecture and layer overview
- `docs/data-model.md` - Table field details and relationships
- `src/Configuration/docs/` - Templates and generation rules that drive inspection creation
