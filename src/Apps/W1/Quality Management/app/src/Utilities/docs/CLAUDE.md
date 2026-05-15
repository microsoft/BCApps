# Utilities

Helper codeunits for expression evaluation, value parsing, and source field extraction. These are the computational workhorses used by the result evaluation engine and inspection creation logic.

## How it works

The utilities break down into three areas:

**Expression evaluation** (`QltyExpressionMgmt`) -- evaluates Text Expression test formulas that can reference other inspection line values. For example, a formula might calculate "Pass Rate = Pass Count / Total Count * 100" using values from other lines in the same inspection.

**Value parsing** (`QltyValueParsing`, `QltyBooleanParsing`) -- converts text test values into typed values for condition evaluation. `QltyValueParsing` handles numeric, date, and option conversions. `QltyBooleanParsing` handles complex boolean condition expressions with ranges, comparisons, lists, and logical operators.

**Source traversal** (`QltyTraversal`) -- extracts source fields (item no., lot no., location, quantity, etc.) from various BC record types. Given a RecordId, it determines the table type and reads the relevant fields. This enables inspection creation from any BC table without hardcoding.

## Things to know

- **QltyBooleanParsing is the condition engine** -- it parses expressions like `>=80`, `10..20`, `RED|GREEN`, and `true` against test values. Understanding this codeunit is essential for understanding how result conditions work.
- **QltyTraversal uses RecordRef** -- it dynamically reads fields from source records using RecordRef/FieldRef, supporting any BC table without compile-time dependencies.
- **Expression formulas reference by line number** -- Text Expression tests use line numbers to reference other inspection lines, not field names. This means reordering template lines can break expressions.
