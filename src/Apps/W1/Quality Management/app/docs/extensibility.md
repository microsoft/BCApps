# Extensibility

## Overview

Quality Management publishes 28+ integration events at major decision points in the inspection lifecycle. The extensibility surface covers inspection creation, result evaluation, template/test configuration, inspection finishing, and source document filtering. The app also integrates with BC's workflow engine for event-driven automation.

## Customize inspection creation

The `QltyInspectionCreate` codeunit publishes events around the creation flow:

- **OnBeforeCreateInspection** -- intercept before any creation logic runs. Use to cancel creation for specific scenarios or modify input parameters.
- **OnAfterCreateInspectionBeforeDialog** -- modify the inspection header after creation but before the UI shows it to the user.
- **OnAfterCreateInspectionAfterDialog** -- post-UI actions after the user has seen/modified the new inspection.
- **OnBeforeFindExistingInspection** -- customize the logic that searches for existing inspections (relevant when `Inspection Creation Option` is "Use existing").
- **OnBeforeCreateReinspection** / **OnAfterCreateReinspection** -- customize re-inspection creation.
- **OnCustomCreateInspectionBehavior** -- extend the `Inspection Creation Option` enum with custom creation strategies. Subscribe to this to handle your own enum values.

## Customize result evaluation

- **OnBeforeEvaluateNumericTestValue** (in `QltyInspectionLine` and `QltyResultEvaluation`) -- intercept numeric value parsing to support custom numeric formats or validation.
- **OnValidateExpressionFormula** (in `QltyTest` and `QltyInspectionTemplateLine`) -- validate custom expression syntax beyond the built-in parser.

## Customize test and template configuration

- **OnBeforeAssistEditDefaultValue** (in `QltyTest`) -- extend the default value entry UI with custom assist-edit behavior.
- **OnBeforeAssistAllowableValues** (in `QltyTest`) -- extend the allowable values entry UI.
- **OnBeforeIsNumericFieldType** (in `QltyTest`) -- extend numeric field type detection for custom value types.

## Customize inspection lifecycle

Events on `QltyInspectionHeader`:

- **OnBeforeFinishInspection** / **OnBeforeReopenInspection** -- validate or cancel finish/reopen actions.
- **OnInspectionFinished** / **OnInspectionReopen** -- react to lifecycle changes (e.g., trigger external notifications, update related records).
- **OnAfterFindLineUpdateResultFromLines** / **OnBeforeFindLineUpdateResultFromLines** -- customize how line results aggregate to the header result.

## Customize source document filtering

- **OnBeforeSetRecordFiltersToFindInspectionFor** / **OnAfterSetRecordFiltersToFindInspectionFor** -- customize how the system searches for inspections related to a specific source record. Use this when the standard source field matching doesn't cover your scenario.

## Workflow integration

The Workflow module subscribes to BC's workflow engine with these events:

- **When a Quality Inspection is Created** -- trigger workflows on new inspections
- **When a Quality Inspection is Finished** -- trigger workflows on completion

Workflow responses can: block/unblock lots, move inventory, create negative adjustments, create transfer orders, create purchase returns, create re-inspections, and send notifications. This enables fully automated quality disposition pipelines.
