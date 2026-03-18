# Mapping

Field-level find/replace transformation rules applied during export and import. This is how a BC field value gets translated to an external format value (or vice versa) without modifying the format codeunit itself.

## How it works

The `E-Doc. Mapping` table (6118) stores rules per E-Document Service. Each rule targets a specific table/field combination (or acts as a wildcard when Table ID or Field ID is zero) and defines either a find/replace pair or a reference to a BC Transformation Rule. The `For Import` boolean distinguishes import-direction rules from export-direction ones.

The `E-Doc. Mapping` codeunit (6118) applies these rules using `MapRecord`. It works in three passes over the target record: first, rules with both Table ID and Field ID set (specific field on specific table), then rules with Table ID but no Field ID (any text/code field on that table), then fully generic rules (Table ID = 0, Field ID = 0, applied to every text/code field). Only Normal class fields of type Text or Code are eligible -- FlowFields and non-text types are skipped.

Mapping always operates on a temporary copy of the record. The codeunit errors if you pass a non-temporary RecordRef. Each transformation that actually changes a value is recorded in a `TempEDocMapping` temporary record, which can later be persisted to `E-Doc. Mapping Log` (table 6123) via the logging codeunit.

The `PreviewMapping` procedure lets users see what would change before committing. It opens a service picker, runs the mapping against the current document header and lines, then displays the results in `E-Doc. Changes Preview`.

## Things to know

- Rules are applied in specificity order: exact field match first, then table-wide, then global. Within each tier, all matching rules run in `FindSet` order.
- Transformation Rule integration uses BC's standard `Transformation Rule` table. If a rule has a `Transformation Rule` code, the find/replace fields are ignored and the transformation rule's logic runs instead.
- The `Used` boolean on mapping records is toggled during processing to track which rules fired. It is reset to false before each mapping run via `ModifyAll(Used, false)`.
- Mapping only touches Text and Code fields. If you need to transform an Option or Integer value, you would need to handle that in your format codeunit.
- `E-Doc. Mapping Log` links to both `E-Document Log` (which specific operation) and `E-Document` (which document), recording the before/after values for audit purposes.
