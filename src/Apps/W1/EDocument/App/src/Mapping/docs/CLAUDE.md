# Mapping

Field-level value transformation rules applied to document records before
export or during import. Mappings are configured per E-Document Service
and let users replace or transform field values without code changes.

## How mappings work

Each `E-Doc. Mapping` row specifies a service code, an optional table/field
target, a `Transformation Rule` (from BC's standard Transformation Rule
table) or a simple `Find Value` / `Replace Value` pair, and a `For Import`
boolean.

The `E-Doc. Mapping` codeunit applies rules in three passes:

1. Specific table + specific field -- transforms only the named field
2. Specific table + field ID 0 -- scans all text/code fields on that table
3. Table ID 0 + field ID 0 -- scans all text/code fields on any table

Only text and code fields are eligible. Mappings are applied to a
**temporary copy** of the record (the codeunit enforces this), so they
do not modify the real document -- the transformed copy is what gets
serialized to XML or used for import.

## Import vs export

The `For Import` boolean distinguishes rules that apply during inbound
processing from those used during export. Both share the same table and
UI, but are filtered separately at runtime.

## Preview

Sales and Purchase document page extensions expose a "Preview E-Document
Mapping" action. This lets users pick a service and see which fields
would change, without actually exporting. The preview runs the mapping
engine against the current record and displays results in the
`E-Doc. Changes Preview` page.

## Mapping log

The `E-Doc. Mapping Log` table records every field transformation that was
actually applied during a real export or import. Each log entry references
the E-Document Log entry and captures the table, field, original value,
and replacement value. This provides an audit trail of what was changed.
