# Additional fields

An EAV (Entity-Attribute-Value) pattern that lets administrators configure arbitrary additional fields on import purchase lines without schema changes. This allows per-service customization of which `Purch. Inv. Line` fields are carried from historical invoices into new e-document drafts.

## How it works

`ED Purchase Line Field Setup` (6112) defines which fields from `Purch. Inv. Line` should be tracked per E-Document Service. Administrators select fields via a setup page, and the system persists which field numbers are enabled.

When an e-document draft line is being prepared, `E-Document Line - Field` (6110) stores the actual values. Its `Get` procedure follows a three-tier resolution: first check for a physical record (user-customized value), then fall back to historical values from `E-Doc. Purchase Line History`, and finally default to blank. The source is returned as an option so the UI can show provenance.

The pages (`EDocAdditionalFieldsSetup`, `EDocLineAdditionalFields`, `EDocFieldValueEdit`, `EDocLineValues`, `EDocOptionValueSelector`, `EDocPurchLineFields`) provide the administration and per-line editing UI.

## Things to know

- The setup table explicitly omits fields that are already part of the draft tables (amount, quantity, description, type, etc.) and document-specific fields (document no., line no., blanket order references). The `FieldsToOmit` list in `EDPurchaseLineFieldSetup` enforces this.

- Field values are stored in typed columns (`Text Value`, `Decimal Value`, `Date Value`, `Boolean Value`, `Code Value`, `Integer Value`). The correct column is chosen based on the `Field.Type` metadata from the `Purch. Inv. Line` table definition.

- The old `EDoc. Purch. Line Field Setup` (6109) is obsolete and replaced by `ED Purchase Line Field Setup` (6112), which adds per-service scoping via the `E-Document Service` field in the primary key.

- Historical value loading works through `E-Doc. Purchase Line History` -- when a previous invoice was posted for the same vendor/line pattern, the system reads the field value from the posted `Purch. Inv. Line` via RecordRef and FieldRef.
