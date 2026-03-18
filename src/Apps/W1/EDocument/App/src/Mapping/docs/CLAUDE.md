# Mapping

Metadata-driven field value transformation during import and export. Lets administrators configure find-and-replace rules per service without writing code.

## How it works

`EDocMapping.Table.al` stores user-defined mapping rules: a Find Value, a Replace Value, and an optional Transformation Rule reference. Each rule is scoped to a service (linked by Code) and flagged for import, export, or both via the "For Import" field. Rules are evaluated in sequence during document processing.

`EDocMapping.Codeunit.al` applies the rules using RecordRef for dynamic field access -- it does not need compile-time knowledge of the target table structure. This means mappings work across any document type without per-table code.

The system leverages BC's existing Transformation Rule framework, so all standard transformations are available -- uppercase, lowercase, trim, regex replacement, date formatting, and custom rules. This avoids reinventing transformation logic.

## Mapping log

`EDocMappingLog.Table.al` records every rule that fired for each document, creating an audit trail of transformations. This is critical for debugging "why did field X end up with value Y?" questions -- you can trace back through the log to see which mapping rule changed it and what the original value was.

## UI

`EDocMapping.Page.al` and `EDocMappingPart.Page.al` provide the configuration interface, typically accessed from the E-Document Service card. `EDocChangesPreview.Page.al` and `EDocChangesPart.Page.al` let users preview what mappings would do before committing, which is useful when setting up a new service connection.
