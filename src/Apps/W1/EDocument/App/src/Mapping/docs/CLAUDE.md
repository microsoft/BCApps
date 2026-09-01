# Mapping

The Mapping module provides an optional field-level transformation engine that rewrites values on document records before export or after import. It operates on Text and Code fields only, applying find-and-replace rules or BC Transformation Rules per service configuration. If no mapping records exist for a service, the engine is completely bypassed.

## How it works

Mapping rules are stored in the `E-Doc. Mapping` table (table 6118, `EDocMapping.Table.al`), keyed by service code and auto-increment entry number. Each rule targets a specific table and field (via `Table ID` and `Field ID`), with a `Find Value` / `Replace Value` pair or a reference to a `Transformation Rule` (BC's built-in text transformation framework). The `For Import` boolean flag distinguishes rules applied during inbound processing from those applied during outbound export.

The `E-Doc. Mapping` codeunit (codeunit 6118, `EDocMapping.Codeunit.al`) applies transformations through its `MapRecord` procedure. It works exclusively on temporary RecordRef targets -- passing a non-temporary record raises an error immediately. The mapping runs in three passes with decreasing specificity: first, rules targeting a specific table and specific field; second, rules targeting a specific table but any field (Field ID = 0), which iterates all fields on the record; third, fully generic rules (Table ID = 0, Field ID = 0) that scan every Text/Code field on any record. This layered approach means you can define precise overrides for individual fields while also having broad catch-all substitutions.

Each applied transformation is tracked: the rule is marked as `Used = true` on the mapping record, and a temporary record set of changes is built. The `E-Document Log` codeunit's `InsertMappingLog` procedure then persists these changes to the `E-Doc. Mapping Log` table (table 6123, `EDocMappingLog.Table.al`), creating a permanent audit trail linked to both the E-Document and the specific E-Document Log entry.

The codeunit also provides `PreviewMapping`, which lets users select a service and see what transformations would be applied to a given document without actually modifying anything. This opens the `E-Doc. Changes Preview` page showing header and line changes side by side.

## Things to know

- Only `FieldClass::Normal` fields of type Text or Code are eligible for mapping. FlowFields, FlowFilters, and non-text fields are silently skipped by `ValidateFieldRef`.

- The three-pass specificity order matters: a field-specific rule always runs before a table-wide or generic rule. However, all matching rules at each level are applied -- there is no short-circuit after the first match.

- The `Transformation Rule` field takes precedence over `Find Value` / `Replace Value` when both are present. If a transformation rule is set, the find/replace pair is ignored and `TransformationRule.TransformText` is used instead.

- Mapping rules are marked `Used = true` during processing by modifying the actual mapping record (not a temporary copy). The `PreviewMapping` procedure resets all `Used` flags to false before running, so preview operations do not leave stale state.

- The mapping log's composite key `(E-Doc Log Entry No., E-Doc Entry No.)` allows querying all mappings applied to a specific document or to a specific processing step, supporting both document-level and step-level audit views.

- The `E-Doc. Mapping` table is `Public` but not `Extensible` -- ISVs can read and create mapping records programmatically but cannot add fields to the table.
