# Additional fields subsystem

Additional fields enable storing custom e-document fields that don't map to standard Purchase Line fields. This subsystem provides configuration UI for defining custom fields, EAV storage for field values, and UI integration for viewing/editing values during import review.

## How it works

Users define custom fields via E-Doc. Purch. Line Field Setup table, specifying field number, caption, data type (Text, Decimal, Date, Boolean, Code, Integer), and optional default value. Field definitions are service-specific, enabling different formats to have different custom field sets.

During Read step, when AI extraction or ADI mapping encounters fields that aren't in the standard mapping tables, the system checks if they match configured custom field definitions. If found, values are stored in E-Document Line - Field table using EAV pattern (one record per line per field, with value stored in type-specific column).

The E-Doc. Line Additional Fields page displays custom fields as a FactBox on the imported line review page. Users can view extracted values, edit them before Finish step, or add missing values. The E-Doc. Line Values page shows all custom fields for a line in a grid, enabling bulk editing.

During Finish step, IEDocumentFinishDraft implementations can read custom field values from E-Document Line - Field table and apply them to Purchase Line records (via table extensions) or related records (dimensions, item attributes, routing notes).

## Things to know

- **EAV for extensibility** -- Using Entity-Attribute-Value pattern avoids modifying core tables for format-specific fields. Custom fields are isolated in E-Document Line - Field table, preventing schema bloat.
- **Field number namespace** -- Custom field numbers start at 50000 to avoid conflicts with standard AL field numbers. Partners can define field numbers in their extension ranges.
- **Type-safe storage** -- E-Document Line - Field has dedicated columns for each data type (Text Value, Decimal Value, Date Value, etc.). The system validates type consistency when storing/retrieving values.
- **Service-scoped definitions** -- Custom field definitions are per-service, enabling PEPPOL to have different custom fields than a proprietary XML format. Field setup is filtered by "E-Document Service" field.
- **Validation support** -- Custom fields can have Option type values, with allowed values defined in EDPurchaseLineFieldSetup table. The E-Doc. Option Value Selector page enforces selection from valid options.
- **Default values** -- Field definitions can specify default values used when extracted data lacks the field. Defaults are applied during Read step if source data omits the field.
- **Finish draft integration** -- Custom field values persist in E-Document Line - Field after Finish step completes, enabling audit of exactly what was extracted vs. what was applied to Purchase Line. Values remain linked to E-Document for reference.
