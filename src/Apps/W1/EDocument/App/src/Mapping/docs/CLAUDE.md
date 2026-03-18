# Mapping

The Mapping folder implements a generic RecordRef-based transformation engine that modifies field values on source documents before e-document export or after import. It supports find-replace rules, transformation rules, and preview functionality for testing mappings without committing changes.

## Quick reference

- **Files:** 8 AL files (1 codeunit, 2 tables, 5 pages)
- **ID range:** 6118 (mapping table/codeunit/pages)
- **Dependencies:** System.IO (Transformation Rule)
- **Extensibility:** Public MapRecord procedures, events for custom mappings

## How it works

The mapping engine uses RecordRef to access fields dynamically without compile-time dependencies on specific tables. When E-Document Core processes a document, it optionally calls **EDoc Mapping.MapRecord** with the source RecordRef and a service-specific mapping configuration. The codeunit iterates all mapping rules in 3 passes (specific field, table-level, generic) and applies transformations using either Transformation Rule codeunits or simple find-replace logic.

Mappings are stored per E-Document Service and can target specific Table ID + Field ID combinations or apply to any field on a table. The "Used" flag tracks which rules were actually applied during a mapping session, enabling audit trails. A preview mode shows before/after values without modifying the source record.

The changes preview UI displays header and line changes separately with visual indenting, allowing users to verify transformations before configuring them on services. Mapping logs record every applied transformation for traceability.

## Structure

- `EDocMapping.Codeunit.al` -- Core RecordRef mapping engine
- `EDocMapping.Table.al` -- Mapping rule storage (service code, table ID, field ID, transformation)
- `EDocMappingLog.Table.al` -- Applied mapping audit trail
- `EDocMapping.Page.al` -- Mapping configuration list
- `EDocMappingPart.Page.al` -- Embedded part for service card
- `EDocChangesPreview.Page.al` -- Before/after comparison UI
- `EDocChangesPart.Page.al` -- Header/line changes display
- `EDocMappingLogs.Page.al` -- Applied mapping history

## Documentation

- [Business logic](business-logic.md) -- 3-pass algorithm, transformation rules, preview mode
- [Data model](data-model.md) -- Mapping table schema, log structure, key indexes

## Things to know

- **Temp record requirement:** MapRecord only accepts temporary RecordRef targets (enforced by IsTemporary check). This prevents accidental modification of committed database records.
- **Copy-before-modify:** The codeunit calls TempRecordTarget.Copy(RecordSource) to duplicate the source, then applies transformations to the copy. Caller is responsible for inserting the modified record.
- **3-pass execution order:** (1) Specific field mappings (Table ID + Field ID specified), (2) Table-level mappings (Table ID specified, Field ID = 0), (3) Generic mappings (both = 0). This allows granular overrides.
- **Text/Code fields only:** ValidateFieldRef filters out FlowField, Media, and non-text types. Only FieldClass::Normal with Type::Text or Type::Code are transformed.
- **Used flag reset:** PreviewMapping calls ModifyAll(Used, false) before mapping to clear previous session state, then filters Used = true to show which rules actually applied.
- **Line number tracking:** SetLineNo stores a line identifier (e.g., Sales Line."Line No.") in mapping log entries, enabling line-level filtering in logs UI.
- **First mapping indent:** The "FirstMapping" flag controls visual indenting in preview (0 = header change, 1 = line change).
- **Entry No. sequence:** Mapping logs use an auto-incremented Entry No. field to track application order within a session.
- **Transformation Rule fallback:** If "Transformation Rule" is specified, it takes precedence over "Find Value"/"Replace Value". If blank, falls back to simple find-replace.
- **Service-scoped configuration:** Mapping records are filtered by Code = E-Document Service.Code, allowing different rules per service (useful for service-specific requirements like date formats).
