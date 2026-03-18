# Mapping

Field-level transformation rules applied to document records during import or export. This module lets administrators define find/replace pairs and transformation rules per service without writing code, keeping country-specific or partner-specific value mappings as configuration data.

## How it works

`EDocMapping.Table.al` stores rules keyed by service code. Each rule targets a Table ID + Field ID combination and specifies either a `Transformation Rule` reference (from BC's standard Transformation Rule table) or a simple `Find Value` / `Replace Value` pair. The `For Import` flag separates import-time mappings from export-time ones.

`EDocMapping.Codeunit.al` applies the rules via RecordRef reflection. It processes mappings in three passes: first specific-table-and-field rules, then any-field-on-specific-table rules (Field ID = 0), then fully generic rules (Table ID = 0, Field ID = 0). Only Text and Code fields are eligible -- other field types are silently skipped by `ValidateFieldRef`. When a rule fires, the `Used` flag is set on the mapping record and a temporary change record is collected for the audit trail.

`EDocMappingLog.Table.al` stores the audit trail. Each entry references an E-Document Log entry and records the table, field, original value, and replacement value. The log is written by `E-Document Log.InsertMappingLog`.

## Things to know

- Mappings operate on RecordRef, so a typo in the Table ID or Field ID will not cause a compile error -- it will either silently skip the field or fail at runtime.
- The target record must be temporary (`NonTempRecordErr` guard). Mapping always writes to a temp copy, never directly to the database.
- The `Used` flag is reset to false before each preview or export run via `ModifyAll(Used, false)`, so it reflects the most recent execution only.
- Generic rules (Table ID = 0) apply to every text/code field on every record -- use them carefully to avoid unintended replacements.
- The preview feature (`PreviewMapping`) lets users select a service and see what changes would be applied to a real document before committing, using the `EDocChangesPreview` page.
- Mapping log entries are linked to E-Document Log entries, not directly to E-Documents, enabling per-state-transition audit.
